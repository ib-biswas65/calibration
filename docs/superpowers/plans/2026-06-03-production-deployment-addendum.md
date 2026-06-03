# Production Deployment — Addendum: Stub-Data Cleanup

> Amends `2026-06-03-production-deployment.md`. Insert before Phase 2 Task 7.

## Why this addendum exists

A first attempt at the migration ran on 2026-06-03 and discovered the
plan's clean-slate assumption was wrong:

- The (now-deleted) `scripts/ingest_historical.py` had previously inserted
  ~215 stub records for the same batches `migrate_historical.py` targets.
- Stubs were created by **filename scan only** — they have `cert_no`,
  `cert_path` (pointing at OneDrive paths), but **no `per_setpoint`** and
  **no `max_deviation_c`**.
- `migrate_historical.py`'s idempotency check is `Logger.serial_no` existence,
  so it skipped 232 of 237 serials. Only 5 loggers were migrated for real.
- Result: duplicate `CalibrationRun` rows per batch (old stub + new real),
  with the old one carrying no measurement data.

The migration attempt was rolled back via snapshot restore. We are now back at
the pre-migration state with the stub records intact.

## Stub-record fingerprint

The stub rows are unambiguously identifiable:

```sql
-- The 3 stub CalibrationRuns
SELECT id, batch_name, start_cert_no FROM calibration_runs
WHERE batch_name IN (
  'March 6th 2026 — ITE Calibration',
  'March 12th 2026 — ITE Calibration',
  'April 15th 2026 — ITE Calibration'
);

-- Stub LoggerResults: per_setpoint is empty or null
SELECT COUNT(*) FROM logger_results
WHERE per_setpoint IS NULL OR jsonb_typeof(per_setpoint) = 'null'
   OR (jsonb_typeof(per_setpoint) = 'array' AND jsonb_array_length(per_setpoint) = 0);
```

The other 4 CalibrationRuns in the DB (October 2025, November 2025, June 2025
fragments) are **out of scope** for `migrate_historical.py`'s config — leave
them alone.

## Recommended path: delete stubs, re-run migration

This is the cleanest end state. Old stub batches disappear; new real batches
take their place; nothing is duplicated. The `.docx` files referenced by stub
`cert_path` values are in OneDrive (outside the Docker volume) and were never
served by the API — deleting the rows orphans nothing important.

### Task 6.5: Stub cleanup (new)

**Files:** none modified. SQL only.

- [ ] **Step 1: Snapshot volumes again** (pre-cleanup rollback insurance)

```bash
mkdir -p .snapshot
docker run --rm \
  -v ite-calibration_pg_data:/v:ro \
  -v "$(pwd)/.snapshot":/b \
  alpine tar czf /b/pg_data.before_stub_cleanup.tar.gz -C /v .
```

- [ ] **Step 2: Count what we're about to delete (dry-run)**

```bash
docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "
SELECT
  (SELECT COUNT(*) FROM calibration_runs
    WHERE batch_name IN (
      'March 6th 2026 — ITE Calibration',
      'March 12th 2026 — ITE Calibration',
      'April 15th 2026 — ITE Calibration'
    )) AS stub_runs,
  (SELECT COUNT(*) FROM logger_results lr
    WHERE lr.run_id IN (
      SELECT id FROM calibration_runs WHERE batch_name IN (
        'March 6th 2026 — ITE Calibration',
        'March 12th 2026 — ITE Calibration',
        'April 15th 2026 — ITE Calibration'
      )
    )) AS stub_results;
"
```

Expected: `stub_runs=3`, `stub_results≈230`.

- [ ] **Step 3: Delete stub runs (cascades to RunFiles + LoggerResults)**

```bash
docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "
DELETE FROM calibration_runs WHERE batch_name IN (
  'March 6th 2026 — ITE Calibration',
  'March 12th 2026 — ITE Calibration',
  'April 15th 2026 — ITE Calibration'
);
"
```

Expected: `DELETE 3`.

- [ ] **Step 4: Delete orphan Loggers**

`LoggerResult.logger_id` has `ON DELETE SET NULL`, so the Loggers from the
stubs were not auto-deleted by Step 3. Identify and remove them:

```bash
docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "
DELETE FROM loggers
WHERE id NOT IN (
  SELECT DISTINCT logger_id FROM logger_results WHERE logger_id IS NOT NULL
);
"
```

Expected: `DELETE ≈230`.

- [ ] **Step 5: Verify the DB is clean**

```bash
docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "
SELECT batch_name, status FROM calibration_runs ORDER BY created_at;
SELECT COUNT(*) AS loggers FROM loggers;
SELECT COUNT(*) AS results_without_persetpoint
  FROM logger_results
  WHERE per_setpoint IS NULL
     OR jsonb_typeof(per_setpoint) = 'null'
     OR (jsonb_typeof(per_setpoint) = 'array' AND jsonb_array_length(per_setpoint) = 0);
"
```

Expected:
- 4 remaining runs (Oct 2025, Nov 2025, and any June 2025 batches — none in scope).
- `loggers` count drops by ~230.
- `results_without_persetpoint` is 0 (or only the small Oct/Nov set, which is acceptable).

If anything looks off, stop and restore from the Step 1 snapshot:

```bash
cd infra && docker compose --env-file .env down && cd ..
docker volume rm ite-calibration_pg_data
docker run --rm -v ite-calibration_pg_data:/v -v "$(pwd)/.snapshot":/b alpine \
  sh -c "cd /v && tar xzf /b/pg_data.before_stub_cleanup.tar.gz"
cd infra && docker compose --env-file .env up -d && cd ..
```

No commit for this task — it is DB-only.

## Then proceed with Task 7 unchanged

After the stub cleanup, the existing Task 7 in the parent plan will work as
designed. The `Logger.serial_no` idempotency check will no longer short-circuit
the per-batch loop, and the expected `Total migrated: ~215` will hold.

## Alternative (rejected): upgrade-in-place

The script could `UPDATE` existing `LoggerResult` rows that lack `per_setpoint`
instead of `INSERT`ing fresh ones. We rejected this because:

1. The duplicate `CalibrationRun` rows would still exist — the script always
   creates a new run row for each batch, so you'd see both
   `"March 6th 2026 — ITE Calibration"` and `"Batch 1 — March 4, 2026 (cert 1645)"`
   in History indefinitely. The cleanup path resolves both layers.
2. The old stubs reference OneDrive `cert_path` values that the API cannot
   serve; users clicking those links would get 404s. Cleanup removes that
   foot-gun.
3. Upgrade-in-place doubles the surface area of the migration script (two code
   paths instead of one) for no clear benefit.

## Notes

- The other 4 pre-existing CalibrationRuns (Oct 2025, Nov 2025, June 2025
  fragments) are **not** in scope for `migrate_historical.py` — `ingest_oldwork.py`
  produced them with real `per_setpoint` data. Do not delete those.
- Snapshots from before the rolled-back attempt (`.snapshot/*.before_migration.tar.gz`,
  ~47 MB) can be deleted after this addendum's cleanup completes successfully.
