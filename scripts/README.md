# scripts/

One-shot operational scripts. Not part of the API runtime.

## migrate_historical.py

Re-processes legacy Excel calibration batches through the live calibration engine
and inserts proper `CalibrationRun` + `Logger` + `LoggerResult` rows into the
running Postgres. Idempotent by `Logger.serial_no` — already-migrated serials
are skipped.

### Prerequisites

1. The live Docker stack is running (`docker compose -f infra/docker-compose.yml --env-file infra/.env ps`).
2. `scripts/historical_batches.json` has been reviewed and corrected for your batches.
3. The legacy files are available on the host (default: `Old Method/`).
4. `template.docx` is at the repo root.

### Usage

```bash
# 1. Copy script, config, template, and source files INTO the api container
docker cp scripts/__init__.py        ite-calibration-api-1:/app/scripts/
docker cp scripts/migrate_historical.py ite-calibration-api-1:/app/scripts/
docker cp scripts/historical_batches.json ite-calibration-api-1:/app/scripts/
docker cp template.docx              ite-calibration-api-1:/tmp/template.docx
docker cp "Old Method"               ite-calibration-api-1:/tmp/old_method

# 2. Dry-run first — proves config + files line up
docker exec -w /app ite-calibration-api-1 \
  python -m scripts.migrate_historical \
    --config scripts/historical_batches.json \
    --inputs-root /tmp/old_method \
    --template /tmp/template.docx \
    --dry-run

# 3. Real run
docker exec -w /app ite-calibration-api-1 \
  python -m scripts.migrate_historical \
    --config scripts/historical_batches.json \
    --inputs-root /tmp/old_method \
    --template /tmp/template.docx
```

Note: `--inputs-root` points at the container path where you copied the legacy
files. Because the config's `workbook` field reads `Old Method/No. 2450 - …`,
the script strips the leading `Old Method/` only if you set `--inputs-root` to
the `Old Method` directory directly. The config paths are joined to
`--inputs-root` as-is, so either set `--inputs-root /tmp/old_method` and use
config paths like `No. 2450 - No. 2554.xlsx`, OR set `--inputs-root /tmp` and
keep `Old Method/No. 2450 - …`. The committed config uses the latter form so
that local dry-runs with `--inputs-root .` work from the repo root.
