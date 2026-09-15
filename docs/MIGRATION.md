# Migrating to a new Windows PC

Moving the live ITE Calibration stack (app + database + certificate files) from
the current production Windows PC to a different one. Written ahead of a
planned move; fill in the placeholders and the open questions at the bottom
before running this for real.

Placeholders: `<OLD-IP>`, `<NEW-IP>`, `<STAMP>` (e.g. `20260922`), `<TRANSFER>`
(USB drive or network share path, e.g. `E:\ite-migrate`). Run all PowerShell as
Administrator. `C:\Calibration` is assumed to be the repo checkout on the old
PC (per `deploy.ps1` and `register-task.ps1`) — adjust every path below if
yours differs.

## Why this isn't just "copy the git repo"

`deploy-package/images/`, `deploy-package/cal_data.tar.gz`, and every `.env`
file are gitignored — they exist **only** on the machine that's currently
running the app, never in git. Rebuilding images from source instead of
copying the running ones is exactly what caused the 2026-08-14 incident (see
`docs/DEPLOYMENT.md`): the production image had a month of code that was never
committed, so a rebuild from the git tree silently regressed the API. This
runbook copies the exact running images and verifies their IDs at every step
instead of trusting git or a rebuild.

It also avoids piping the SQL dump through PowerShell. `backup-windows.ps1`'s
`pg_dump ... > file` redirect can re-encode through PowerShell's text pipeline
(UTF-16, console codepage), which risks corrupting the Japanese text in
certificate/batch data. This runbook keeps the dump inside Docker (`pg_dump
-f` + `docker cp`) end to end.

## 0. Before migration day (old PC, no downtime)

1. Record what's actually running — you'll compare against this later:
   ```powershell
   docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}"
   docker inspect --format "{{.Name}} runs image ID {{.Image}}" ite-calibration-api-1 ite-calibration-web-1 ite-calibration-postgres-1 ite-calibration-edge-1
   docker images --format "table {{.Repository}}`t{{.Tag}}`t{{.ID}}`t{{.CreatedAt}}" | Select-String "ite-calibration|postgres|nginx"
   ```
2. Confirm the `:latest` tag still points at what the containers actually run
   (the DEPLOYMENT.md lesson, as one check):
   ```powershell
   docker inspect --format "{{.Id}}" ite-calibration-api:latest
   docker inspect --format "{{.Image}}" ite-calibration-api-1
   docker inspect --format "{{.Id}}" ite-calibration-web:latest
   docker inspect --format "{{.Image}}" ite-calibration-web-1
   ```
   If they differ, retag so `:latest` follows the running container:
   ```powershell
   docker tag ite-calibration-api:latest ite-calibration-api:tag-was-latest-<STAMP>
   docker tag <running-api-image-id> ite-calibration-api:latest
   ```
   Repeat for web if needed.
3. Check for uncommitted work on the old PC (July's code was never committed;
   don't assume this tree is clean):
   ```powershell
   git -C C:\Calibration status
   git -C C:\Calibration log -1 --format="%h %ad %s" --date=short
   ```
4. Note the current `.env` values you'll need to reason about later:
   ```powershell
   Select-String -Path C:\Calibration\deploy-package\.env -Pattern "^ITE_ALLOWED_ORIGINS|^POSTGRES_USER|^POSTGRES_DB"
   ```
5. Note the Postgres version in use:
   ```powershell
   docker inspect --format "{{.Config.Image}}" ite-calibration-postgres-1
   docker exec ite-calibration-postgres-1 postgres --version
   ```
6. Prepare the new PC (section 2 below) ahead of time so migration day is only
   capture + copy + restore.

## 1. What has to be physically copied (none of this comes from git)

| Item | Source on old PC | Why not git |
|---|---|---|
| `ite-images-<STAMP>.tar` | `docker save` of the running api + web images | `deploy-package/images/` is gitignored, doesn't exist in the repo; a rebuild regressed the API by a month on 2026-08-14 |
| `db-<STAMP>.sql` | fresh `pg_dump` of the live DB | `seed/db_full.sql` is a stale snapshot, and gitignored anyway |
| `cal_data-<STAMP>.tar.gz` | fresh tar of the `ite-calibration_cal_data` volume | gitignored, never in the repo — this is the certificates + run inputs |
| `.env` | `C:\Calibration\deploy-package\.env` | gitignored — holds the real Postgres password and JWT secret |
| `C:\Calibration\` (whole folder) | robocopy | may hold uncommitted source; is what `register-task.ps1`/`deploy.ps1` point at |
| `C:\ite-calibration-backups\` | optional | last 30 days of daily backups, extra fallback |

Not copied: the `pg_data` volume as raw files — the SQL dump replaces it (an
optional raw copy is in section 5 as extra insurance).

## 2. On the old PC: capture everything (downtime starts here)

```powershell
$S = "C:\ite-migrate-<STAMP>"
New-Item -ItemType Directory -Path $S -Force | Out-Null
```

1. **Freeze the app** so DB and volume stay consistent with each other.
   Postgres stays up; users lose access from here.
   ```powershell
   Set-Location C:\Calibration\deploy-package
   docker compose stop edge web api
   docker ps --format "table {{.Names}}`t{{.Status}}"
   ```
   Expected: only `ite-calibration-postgres-1` is Up. Check the History page
   beforehand for any run stuck `processing` — it'll be reset to failed on the
   next API start, which is expected.

2. **Save the exact running images** (tags survive `docker load`; confirmed
   correct in step 0.2). Include any rollback tags `docker images
   ite-calibration-api` shows.
   ```powershell
   docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | Select-String "ite-calibration"
   docker save -o "$S\ite-images-<STAMP>.tar" ite-calibration-api:latest ite-calibration-web:latest
   docker save -o "$S\base-images-<STAMP>.tar" postgres:16-alpine nginx:1.27-alpine
   docker inspect --format "{{.Id}}" ite-calibration-api:latest ite-calibration-web:latest | Out-File "$S\image-ids.txt"
   Get-Content "$S\image-ids.txt"
   ```

3. **Dump the database** without touching PowerShell text encoding:
   ```powershell
   docker exec ite-calibration-postgres-1 pg_dump -U ite --clean --if-exists -f /tmp/db-<STAMP>.sql ite
   docker cp ite-calibration-postgres-1:/tmp/db-<STAMP>.sql "$S\db-<STAMP>.sql"
   docker exec ite-calibration-postgres-1 rm /tmp/db-<STAMP>.sql
   ```
   Sanity check — should start with `-- PostgreSQL database dump` and NOT show
   `FF FE` (UTF-16 signature) at the head:
   ```powershell
   Get-Content "$S\db-<STAMP>.sql" -TotalCount 5
   Format-Hex "$S\db-<STAMP>.sql" -Count 4
   ```
   If you see `FF FE`, the dump went through PowerShell somewhere — redo the
   step, never use `>`.

4. **Record row counts** to compare after restore:
   ```powershell
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;" | Out-File "$S\rowcounts-old.txt"
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT count(*), max(created_at) FROM calibration_runs;"
   ```

5. **Tar the certificate volume** (same method as `backup-windows.ps1` — runs
   inside alpine, no Windows encoding involved):
   ```powershell
   $SFwd = $S.Replace("\", "/")
   docker run --rm -v "ite-calibration_cal_data:/source:ro" -v "${SFwd}:/backup" alpine tar czf /backup/cal_data-<STAMP>.tar.gz -C /source .
   docker run --rm -v "ite-calibration_cal_data:/source:ro" alpine sh -c "find /source -type f | wc -l; du -sh /source" | Out-File "$S\volume-stats-old.txt"
   Get-Content "$S\volume-stats-old.txt"
   ```

6. **Copy secrets and the whole repo folder**:
   ```powershell
   Copy-Item C:\Calibration\deploy-package\.env "$S\dot-env-<STAMP>.txt"
   robocopy C:\Calibration "$S\Calibration" /E /COPY:DAT /R:2 /W:2 /XD node_modules .venv
   ```
   Optional, last 30 days of daily backups:
   ```powershell
   robocopy C:\ite-calibration-backups "$S\old-daily-backups" /E /R:2 /W:2
   ```

7. **Hash everything, then copy to the transfer medium and re-verify:**
   ```powershell
   Get-ChildItem $S -File | Get-FileHash -Algorithm SHA256 | Select-Object Hash, Path | Out-File "$S\SHA256SUMS.txt"
   robocopy $S "<TRANSFER>\ite-migrate-<STAMP>" /E /R:3 /W:5
   ```

8. **Decide on the old app's state during restore.** Cleanest: leave the old
   stack stopped (postgres can stay up harmlessly) until the new PC passes all
   checks in section 3. If you bring the old app back up before cutover, treat
   this capture as a rehearsal and repeat steps 2.1–2.7 for the real cutover.

## 3. On the new PC: restore

Do this manually rather than via `setup-windows.ps1` — its structure is right
(images → postgres → DB → volume → up) but it restores the stale seed dump via
a `Get-Content` pipe (encoding risk) and gives no chance to check image IDs
between load and start. These steps fix both.

1. **Prerequisites:** Docker Desktop installed and running (WSL2 backend),
   `docker compose` v2, account in the `docker-users` group (needed for the
   backup task later), `C:` drive file sharing enabled in Docker Desktop.
   ```powershell
   docker version
   docker compose version
   ```

2. **Copy the migration folder in and verify hashes** — every hash must
   match; do not continue on a mismatch:
   ```powershell
   robocopy "<TRANSFER>\ite-migrate-<STAMP>" "C:\ite-migrate-<STAMP>" /E /R:3 /W:5
   $S = "C:\ite-migrate-<STAMP>"
   Get-ChildItem $S -File | Where-Object Name -ne "SHA256SUMS.txt" | Get-FileHash -Algorithm SHA256 | Select-Object Hash, Path
   Get-Content "$S\SHA256SUMS.txt"
   ```

3. **Place the repo and restore `.env`:**
   ```powershell
   robocopy "$S\Calibration" C:\Calibration /E /R:2 /W:2
   Copy-Item "$S\dot-env-<STAMP>.txt" C:\Calibration\deploy-package\.env -Force
   Set-Location C:\Calibration\deploy-package
   Select-String -Path .env -Pattern "changeme|dev-only-change-me"
   ```
   Expected: no matches. **Do not regenerate `ITE_JWT_SECRET` or
   `POSTGRES_PASSWORD`** — the password must match the dump's roles, and the
   secret keeps outstanding invite/reset links valid. Edit only
   `ITE_ALLOWED_ORIGINS` for the new machine's address (see section 4).

4. **Load images and confirm IDs match** what you recorded on the old PC —
   stop if they differ:
   ```powershell
   docker load -i "$S\base-images-<STAMP>.tar"
   docker load -i "$S\ite-images-<STAMP>.tar"
   docker inspect --format "{{.Id}}" ite-calibration-api:latest ite-calibration-web:latest
   Get-Content "$S\image-ids.txt"
   ```
   Tag rollback copies immediately:
   ```powershell
   docker tag ite-calibration-api:latest ite-calibration-api:migrated-<STAMP>
   docker tag ite-calibration-web:latest ite-calibration-web:migrated-<STAMP>
   ```

5. **Start Postgres and wait for healthy:**
   ```powershell
   docker compose up -d postgres
   docker inspect --format "{{.State.Health.Status}}" ite-calibration-postgres-1
   ```
   Repeat until `healthy`. This creates the `ite` role/DB from `.env`, which
   is why the password must match the old one.

6. **Restore the database** (again via `docker cp` + `psql -f`, no PowerShell
   text handling):
   ```powershell
   docker cp "$S\db-<STAMP>.sql" ite-calibration-postgres-1:/tmp/db.sql
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -q -v ON_ERROR_STOP=0 -f /tmp/db.sql
   docker exec ite-calibration-postgres-1 rm /tmp/db.sql
   ```
   A few `does not exist, skipping` notices are normal (`--clean --if-exists`
   against an empty DB); any `ERROR` line is not. Compare counts:
   ```powershell
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;"
   Get-Content "$S\rowcounts-old.txt"
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT count(*), max(created_at) FROM calibration_runs;"
   ```
   Run `ANALYZE;` if estimates look off. Confirm Japanese text survived:
   ```powershell
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT batch_name FROM calibration_runs ORDER BY created_at DESC LIMIT 3;"
   ```

7. **Restore the certificate volume:**
   ```powershell
   docker volume create ite-calibration_cal_data | Out-Null
   $SFwd = $S.Replace("\", "/")
   docker run --rm -v "ite-calibration_cal_data:/target" -v "${SFwd}:/backup" alpine sh -c "cd /target && tar xzf /backup/cal_data-<STAMP>.tar.gz"
   docker run --rm -v "ite-calibration_cal_data:/source:ro" alpine sh -c "find /source -type f | wc -l; du -sh /source"
   Get-Content "$S\volume-stats-old.txt"
   ```
   File count must match; size within a few percent.

8. **Start everything and verify:**
   ```powershell
   docker compose up -d
   docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}"
   Invoke-RestMethod http://localhost/api/health | ConvertTo-Json
   docker logs ite-calibration-api-1 --tail=40
   ```
   Expected: all four containers Up, api + postgres `(healthy)`, health
   returns ok, and the API log shows alembic finding **nothing to migrate**
   (same image → same schema already). If it applies migrations, you're not
   running the same image — go back to step 3.4. Any run mid-`processing` at
   freeze time is now reset to failed — expected.

9. **Browser smoke test** from another PC on the LAN, using the real address
   users will type: log in, open History, open a run, download a `.docx`,
   open it. A login CORS/origin error means `ITE_ALLOWED_ORIGINS` doesn't
   contain the URL exactly as typed (scheme + host + port, no trailing
   slash) — fix `.env` then `docker compose up -d api`.

10. **Register the backup task and run it once:**
    ```powershell
    powershell -ExecutionPolicy Bypass -File C:\Calibration\register-task.ps1
    powershell -ExecutionPolicy Bypass -File C:\Calibration\deploy-package\backup-windows.ps1
    Get-ChildItem C:\ite-calibration-backups
    ```
    Edit the hardcoded path in `register-task.ps1` first if the repo isn't at
    `C:\Calibration`. Copy over old daily backups if you brought them.

11. **Reboot test:** reboot the PC, wait 2 minutes, re-run step 3.8's checks.

## 4. Cutover plan

1. **Address.** Two options:
   - **(a) New PC takes over the old IP/hostname** — no `.env` change, no user
     retraining. Requires the old PC off the network or renumbered first.
     Best if the lab reaches the app by IP/hostname.
   - **(b) New PC gets a new address** — set
     `ITE_ALLOWED_ORIGINS=http://localhost,http://<NEW-IP>` and tell users
     the new URL. Keep the old IP in the list only during fallback if the old
     PC is genuinely offline (otherwise it's confusing).
2. **Order:** section 2 (freeze + capture) → section 3 (restore + verify on
   new PC while old stack stays stopped) → switch address per 4.1 → users
   test → done. Downtime ≈ capture + restore time (this dataset is small: DB
   dump well under 1 MB compressed).
3. **Sessions:** cookies are per-host, so everyone logs in again once.
   Passwords/users carry over in the dump.
4. **Old PC after cutover** — stop, don't delete:
   ```powershell
   Set-Location C:\Calibration\deploy-package
   docker compose stop
   Unregister-ScheduledTask -TaskName "ITE Calibration Backup" -Confirm:$false
   ```
   Stopping (not `down -v`) preserves images and volumes for rollback. If the
   old PC keeps its IP under option (b), also disable Docker Desktop autostart
   or it'll come back on reboot and answer on port 80.
5. **GitHub Actions self-hosted runner:** nothing is installed on the old PC
   today, workflow jobs just queue (see `docs/DEPLOYMENT.md`). Don't install a
   runner on the new PC as part of this move. If ever re-enabled, both
   DEPLOYMENT.md warnings apply unchanged — `main` needs branch protection
   first.
6. **Fallback period:** keep the old PC intact ≥2 weeks and until, on the new
   PC: one real calibration run has completed end-to-end with a downloaded
   certificate, the 02:00 backup task has produced ≥2 good backups, and one
   reboot has come back clean.

## 5. Rollback

1. New PC: `docker compose stop` (from `deploy-package/`).
2. Old PC: `docker compose up -d`, re-run `register-task.ps1`, restore the
   address if moved.
3. Any runs created on the new PC in the interim exist only there — repeat
   section 2 on the new PC and section 3 steps 6–7 on the old one to bring
   them back, or accept the loss if they were test runs. Decide which before
   cutover (open question below).

## 6. Risks and how to detect them

| Risk | How it shows up | Detect / prevent |
|---|---|---|
| Shipped image ≠ running image (tag moved after container start — the exact 2026-08-14 failure mode) | New API behaves like older code; alembic applies migrations on start; tz-naive comparison errors | Step 0.2 ID check before save; step 3.4 ID check after load; step 3.8 confirms no migrations run |
| Dump mangled by PowerShell text encoding | Japanese text as mojibake, or psql failing on a UTF-16 file | Never pipe SQL through PowerShell; use `pg_dump -f`+`docker cp` (2.3) and `docker cp`+`psql -f` (3.6); `Format-Hex` check; batch_name spot check |
| Data entered on old PC after the dump | New PC missing the latest runs | Freeze in 2.1; keep old stack stopped until verified; compare `count(*)`/`max(created_at)` |
| Volume and DB out of sync (run mid-process at freeze) | Run rows with missing files or vice versa | Freeze api before both captures; expect that run reset to failed on first start |
| `.env` regenerated instead of copied | Postgres auth failures; JWT secret change invalidates outstanding links | Copy the real file (2.6, 3.3); only edit `ITE_ALLOWED_ORIGINS` |
| `ITE_ALLOWED_ORIGINS` doesn't match the URL typed | Login POST rejected by Origin middleware; GETs still work | Test from a second PC with the real URL (3.9); fix `.env`, `docker compose up -d api` |
| Orphaned/misnamed volumes | Restored into `cal_data` instead of `ite-calibration_cal_data`; API sees empty data dir | Compose project name is `ite-calibration`; use exact names in 3.7; `docker volume ls` should show only `ite-calibration_pg_data` and `ite-calibration_cal_data` |
| Postgres major version mismatch | Only matters for a raw `pg_data` copy — the SQL dump restores into any 16.x | Ship `postgres:16-alpine` in `base-images` tar (2.2) |
| Docker Desktop differences | compose v1 absent (fine — v2 syntax used throughout), file sharing off, Hyper-V vs WSL2 | Step 3.1 checks |
| Bind-mount path syntax | `docker run -v` with backslashes fails silently | Forward slashes as in both scripts |
| `register-task.ps1` hardcoded path/permissions | Task runs but backup aborts | Same `C:\Calibration` path, account in `docker-users`, run once by hand (3.10) |
| Old PC comes back on the same IP | Two apps with diverging data | 4.4: stop stack, unregister task, disable autostart / take off network |
| Uncommitted source only on old disk | Lost if old PC wiped (not a runtime problem — images are self-contained) | `git status` in 0.3; whole-folder robocopy in 2.6 |

**Optional extra insurance** during the freeze (old PC, everything stopped) —
a raw copy of the Postgres data directory, only useful if the SQL dump turns
out unusable, and only restorable onto the same Postgres major:
```powershell
docker compose stop postgres
docker run --rm -v "ite-calibration_pg_data:/source:ro" -v "${SFwd}:/backup" alpine tar czf /backup/pg_data-raw-<STAMP>.tar.gz -C /source .
docker compose start postgres
```

## Open questions

1. Will the new PC take over the old PC's IP/hostname (4.1a), or get a new
   address (4.1b)? How do lab users reach the app today?
2. Are both PCs on the network simultaneously during the move, or is transfer
   USB-only?
3. What downtime window next week, and is any calibration run likely to be
   in progress then?
4. Is the repo really at `C:\Calibration` on the old PC, and is `git status`
   clean there?
5. Should runs created on the new PC during the fallback period count as real
   data (must be carried back on rollback) or test data?
6. Should `backup-windows.ps1` be fixed to the byte-safe `pg_dump -f` +
   `docker cp` form as a follow-up, and should an existing daily backup file
   be checked for the UTF-16 signature first?
7. Any plan to re-enable the GitHub Actions self-hosted runner on the new PC?
   (Recommended: no, not as part of this move.)
