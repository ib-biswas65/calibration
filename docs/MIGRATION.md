# Migrating to a new Windows PC

Moving the live ITE Calibration stack (app + database + certificate files) from
the current production Windows PC to a different one. Written ahead of a
planned move; fill in the placeholders and the open questions at the bottom
before running this for real.

**Decision (2026-09-15): the app is rebuilt fresh on the new PC from git; only
the database and certificate files are carried over as irreplaceable data.**
This is a deliberate change from shipping the exact running Docker images —
the app is also getting bug fixes, new features, an ops cleanup, and a UI
redesign before the move, so "the exact bits currently running" is not even
the thing you want on the new PC. See "Why the app doesn't need to be copied
byte-for-byte" below for why this is safe now (it wasn't, in August).

Placeholders: `<OLD-IP>`, `<NEW-IP>`, `<STAMP>` (e.g. `20260922`), `<TRANSFER>`
(USB drive or network share path, e.g. `E:\ite-migrate`). Run all PowerShell as
Administrator. `C:\Calibration` is assumed to be the repo checkout on the old
PC (per `deploy.ps1` and `register-task.ps1`) — adjust every path below if
yours differs.

## Constraint: this is one-shot, not a live cutover

**The old PC will be completely unreachable once it's gone** — no remote
access, no one on-site, nothing to fall back to. There's also a **multi-day
gap** between capturing the migration bundle and actually setting up the new
PC. Together this rules out the normal safety nets:

- **No rollback.** Every other section below that used to say "fall back to
  the old PC" no longer applies — see the rewritten section 5.
- **No re-capture.** If something in the bundle is missing or corrupt, there
  is no going back to grab it. The bundle captured before the old PC leaves
  is the *only* copy of the live data that will ever exist.
- **No side-by-side debugging.** You can't compare the new PC against the old
  one while both are up, because they never will be at the same time on
  migration day.

This changes what "done" means for the capture step: it isn't done when the
files are copied, it's done when a **full test restore on a spare machine has
actually verified the bundle works**, while the old PC is still there to
recapture from if it doesn't. Section 2a below is new and exists specifically
for this. Do not skip it.

## Why the app doesn't need to be copied byte-for-byte

The 2026-08-14 incident (see `docs/DEPLOYMENT.md`) happened because the
running production image had a month of code that was **never committed to
git**, so rebuilding from the git tree silently shipped an older version.
That risk applied *then* because git and the deployed image had quietly
diverged, and nobody knew until they rebuilt.

That's not the situation now: `docs/ARCHITECTURE.md` and the 2026-08-14
recovery commits (`9bcc0ef`, `d55003a`, `3a78a4b`, `c08b1e3`) brought git back
in sync with what should run, and there's an explicit decision to actively
develop the app further (bug fixes, features, ops cleanup, UI redesign)
before it goes on the new PC. So the new PC is **meant** to run something
different from whatever the old PC's baked images contain — building fresh
from git is not a risk here, it's the goal. The one rule that keeps this
safe: **always build the new PC's images from a specific, reviewed git commit
you can name** (tag it), never from an uncommitted or in-progress state — the
same discipline that failed in August, just pointed the right direction now.

What still can't come from git, because it's real operational data that only
ever existed on the running machine:

- The live Postgres database (calibration runs, users, audit log).
- The certificate volume (`cal_data` — generated `.docx` files and run
  inputs).

Both of those are still gitignored (`deploy-package/cal_data.tar.gz`, and the
`seed/db_full.sql` in the repo is a stale snapshot, not live data) and are the
entire subject of this runbook now.

It also avoids piping the SQL dump through PowerShell. `backup-windows.ps1`'s
`pg_dump ... > file` redirect can re-encode through PowerShell's text pipeline
(UTF-16, console codepage), which risks corrupting the Japanese text in
certificate/batch data. This runbook keeps the dump inside Docker (`pg_dump
-f` + `docker cp`) end to end.

## 0. Before migration day

1. **Finish and merge the app refinement work** (bug fixes, features, ops
   cleanup, UI redesign) to `main` before picking a build commit — this
   doesn't have to be finished on the old PC or block the DB capture below,
   but the new PC's build should come from a finished, reviewed state, not a
   WIP branch. That's the one rule that keeps "build fresh from git" safe
   (see above).
2. **Pick and tag the exact commit the new PC will run:**
   ```bash
   git tag -a windows-migration-<STAMP> -m "Build for new production PC" main
   git push origin windows-migration-<STAMP>
   ```
   This gives you a fixed, nameable reference for the build step in section
   3, instead of "whatever `main` happens to be that day."
3. On the **old PC**, check for uncommitted work that never made it to git
   (July's code was never committed; don't assume this tree is clean — if
   there's something real here, decide whether it needs to be ported into
   the refinement work before the tag in step 0.2, since it won't otherwise
   reach the new PC):
   ```powershell
   git -C C:\Calibration status
   git -C C:\Calibration log -1 --format="%h %ad %s" --date=short
   ```
4. On the **old PC**, note the current `.env` values as a reference (the new
   PC gets fresh secrets, not these, but the allowed-origins value is useful
   context):
   ```powershell
   Select-String -Path C:\Calibration\deploy-package\.env -Pattern "^ITE_ALLOWED_ORIGINS|^POSTGRES_USER|^POSTGRES_DB"
   ```
5. On the **old PC**, note the Postgres version in use, so the new PC's build
   pulls the same major version:
   ```powershell
   docker inspect --format "{{.Config.Image}}" ite-calibration-postgres-1
   docker exec ite-calibration-postgres-1 postgres --version
   ```
6. Prepare the new PC (section 2 below) ahead of time so migration day is only
   capture + copy + restore.
7. **Decide the capture timing given the multi-day gap.** Capturing too early
   means anything entered on the old PC afterward is lost forever (no
   re-capture once it's gone); capturing too late risks not leaving time for
   the dry-run restore (2a) before the PC disappears. Recommended order:
   - Do a **rehearsal capture** now, well before the old PC needs to leave,
     and run the full dry-run restore (2a) against it on a spare machine.
     This validates the *procedure*, not necessarily fresh data.
   - Do the **real, final capture** as close as possible to the moment the
     old PC actually becomes unavailable — ideally the same day/hour — so
     the live-data gap is minutes, not days. Everything entered between the
     final capture and the PC's departure is unrecoverable.
   - If the old PC will sit idle (no new calibration runs) during the gap
     between capture and departure, the timing above matters less — confirm
     this with whoever operates it day to day.

## 1. What has to be physically copied (this is now just data, not the app)

| Item | Source on old PC | Why not git |
|---|---|---|
| `db-<STAMP>.sql` | fresh `pg_dump` of the live DB | `seed/db_full.sql` is a stale snapshot, and gitignored anyway |
| `cal_data-<STAMP>.tar.gz` | fresh tar of the `ite-calibration_cal_data` volume | gitignored, never in the repo — this is the certificates + run inputs |
| `.env` (reference only, not restored verbatim) | `C:\Calibration\deploy-package\.env` | just to know the old `ITE_ALLOWED_ORIGINS`/DB name; the new PC gets fresh secrets (section 3) |
| `C:\ite-calibration-backups\` | optional | last 30 days of daily backups, extra fallback if the fresh dump is somehow bad |

**Not copied, and no longer needed at all:** the running Docker images. The
new PC builds its own from the tagged commit in step 0.2. Not copied either:
the `pg_data` volume as raw files — the SQL dump replaces it (an optional raw
copy is in section 6 as extra insurance).

If the new PC won't have reliable internet access to `docker build` (pulling
base images, pip/npm packages), see the note at the top of section 3 —
building elsewhere and transferring the images is still an option, it's just
no longer the default path.

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

2. **Dump the database** without touching PowerShell text encoding:
   ```powershell
   docker exec ite-calibration-postgres-1 pg_dump -U ite --clean --if-exists -f /tmp/db-<STAMP>.sql ite
   docker cp ite-calibration-postgres-1:/tmp/db-<STAMP>.sql "$S\db-<STAMP>.sql"
   docker exec ite-calibration-postgres-1 rm /tmp/db-<STAMP>.sql
   ```
   Sanity check — should start with `-- PostgreSQL database dump` and NOT show
   `FF FE` (UTF-16 signature) at the head. `Format-Hex -Count` doesn't exist
   in Windows PowerShell 5.1 (the production PC's default shell) — pipe to
   `Select-Object` instead:
   ```powershell
   Get-Content "$S\db-<STAMP>.sql" -TotalCount 5
   Format-Hex "$S\db-<STAMP>.sql" | Select-Object -First 1
   ```
   If you see `FF FE`, the dump went through PowerShell somewhere — redo the
   step, never use `>`.

3. **Record row counts** to compare after restore:
   ```powershell
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;" | Out-File "$S\rowcounts-old.txt"
   docker exec ite-calibration-postgres-1 psql -U ite -d ite -c "SELECT count(*), max(created_at) FROM calibration_runs;"
   ```

4. **Tar the certificate volume** (same method as `backup-windows.ps1` — runs
   inside alpine, no Windows encoding involved):
   ```powershell
   $SFwd = $S.Replace("\", "/")
   docker run --rm -v "ite-calibration_cal_data:/source:ro" -v "${SFwd}:/backup" alpine tar czf /backup/cal_data-<STAMP>.tar.gz -C /source .
   docker run --rm -v "ite-calibration_cal_data:/source:ro" alpine sh -c "find /source -type f | wc -l; du -sh /source" | Out-File "$S\volume-stats-old.txt"
   Get-Content "$S\volume-stats-old.txt"
   ```

5. **Copy the old `.env` for reference** (not restored verbatim — see
   section 3 — but useful to have the old `ITE_ALLOWED_ORIGINS`/DB name on
   hand while configuring the new one):
   ```powershell
   Copy-Item C:\Calibration\deploy-package\.env "$S\dot-env-<STAMP>-reference.txt"
   ```
   Optional, last 30 days of daily backups:
   ```powershell
   robocopy C:\ite-calibration-backups "$S\old-daily-backups" /E /R:2 /W:2
   ```

6. **Hash everything, then copy to at least two separate transfer media, and
   re-verify each independently.** With no fallback and no re-capture, a
   single USB drive that fails or gets lost is a total data-loss event —
   don't rely on one copy.
   ```powershell
   Get-ChildItem $S -File | Get-FileHash -Algorithm SHA256 | Select-Object Hash, Path | Out-File "$S\SHA256SUMS.txt"
   robocopy $S "<TRANSFER-1>\ite-migrate-<STAMP>" /E /R:3 /W:5
   robocopy $S "<TRANSFER-2>\ite-migrate-<STAMP>" /E /R:3 /W:5
   ```
   Verify each copy's hashes against `SHA256SUMS.txt` right there on the old
   PC, before you consider the capture done — this is your last chance to
   redo it if a copy failed.

7. **This is the real thing, not a rehearsal, once you're past step 2a
   (below) and satisfied.** There is no "bring the old app back up and
   recapture later" — once the old PC leaves, this bundle is what the new PC
   will run forever. If this capture is a rehearsal (see the timing note in
   step 0.7), say so explicitly to whoever handles the final capture, so
   nobody mistakes rehearsal data for the real migration.

## 2a. Prove the bundle actually restores — before the old PC is unreachable

This is the step that replaces "we can always go back and check." **This Mac
(this machine, with Docker via Colima) can do this dry run** — you don't need
a spare Windows box for it, because the point is to validate the DB dump +
certificate volume restore procedure and the app build from git, not to
byte-match production hardware. Do it **while the old PC is still
available**, so if anything fails you can fix the capture and redo it
immediately instead of finding out after it's too late.

One caveat: this Mac is `arm64`; the production Windows PC is `amd64`.
`docker build` produces images for whatever platform it's building on, so a
dry-run build here doesn't prove the Windows build will succeed — it proves
the **Dockerfiles, dependencies, and restore steps are correct**, which is
most of the risk. If you want the platform itself covered too, either add
`docker buildx build --platform linux/amd64 ...` here (slower, emulated,
but a real cross-check) or treat the actual new-PC build in section 3 as
the first true build for that platform and budget a bit of slack for
dependency surprises Docker Hub/PyPI/npm might raise on a fresh machine.

1. Copy one of the two bundle copies from step 2.6 onto this Mac (or wherever
   you're doing the dry run).
2. Check out the tagged commit from step 0.2 in a scratch location and run
   all of section 3 ("On the new PC: restore") against it, in full, including
   the build, the row-count comparison (3.7), volume file-count comparison
   (3.8), and the smoke test (3.10) — log in, open a run, download a `.docx`,
   open the file.
3. Only once this dry run passes cleanly is the capture considered validated.
   If anything fails, go back to section 2, fix it, and redo the capture (you
   still have the old PC at this point — that's the whole reason this step
   exists).
4. Tear down afterward (`docker compose down -v` in the scratch checkout) so
   it doesn't linger as a second, drifting copy of production data on this
   machine.

## 3. On the new PC: build fresh, then restore the data

If the new PC has **no reliable internet access** to pull base images and
`pip`/`npm` dependencies during `docker build`, do the build step (3.4) on a
connected machine instead (this Mac works, or any machine with internet and
Docker), `docker save` the two resulting images, carry them over on the same
transfer media as the DB/volume bundle, and `docker load` them on the new PC
in place of step 3.4. Everything else below is unchanged either way.

1. **Prerequisites:** Docker Desktop installed and running (WSL2 backend),
   `docker compose` v2, account in the `docker-users` group (needed for the
   backup task later), `C:` drive file sharing enabled in Docker Desktop, and
   (for the default path) internet access.
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

3. **Clone the repo and check out the tagged commit** from step 0.2 — not
   `main`, the specific tag, so what runs here is exactly what passed the dry
   run in 2a:
   ```powershell
   git clone https://github.com/ib-biswas65/calibration.git C:\Calibration
   Set-Location C:\Calibration
   git checkout windows-migration-<STAMP>
   ```

4. **Build the images and tag them** the way `deploy-package/docker-compose.yml`
   expects (`image:` references, not `build:`):
   ```powershell
   docker build -t ite-calibration-api:latest apps\api
   docker build -t ite-calibration-web:latest apps\web
   docker pull postgres:16-alpine
   docker pull nginx:1.27-alpine
   ```
   Tag a dated copy right away, so a future rebuild has something to roll
   back to (the DEPLOYMENT.md habit, now established fresh on this machine):
   ```powershell
   docker tag ite-calibration-api:latest ite-calibration-api:migrated-<STAMP>
   docker tag ite-calibration-web:latest ite-calibration-web:migrated-<STAMP>
   ```

5. **Set up `.env` with fresh secrets** — unlike the old plan, you don't need
   to match the old PC's password or JWT secret, since this is a new Postgres
   instance and the dump will be loaded into a role it creates:
   ```powershell
   Set-Location C:\Calibration\deploy-package
   Copy-Item .env.example .env
   python3 -c "import secrets; print(secrets.token_hex(32))"   # for ITE_JWT_SECRET
   notepad .env
   ```
   Set a strong `POSTGRES_PASSWORD` (and match it into `ITE_DATABASE_URL`),
   a fresh `ITE_JWT_SECRET`, and `ITE_ALLOWED_ORIGINS` for the new machine's
   address (see section 4). Note: a fresh JWT secret invalidates any
   outstanding password-reset/invite links from the old system — plan to
   re-send those if any are pending.
   ```powershell
   Select-String -Path .env -Pattern "changeme|dev-only-change-me"
   ```
   Expected: no matches.

6. **Start Postgres and wait for healthy:**
   ```powershell
   docker compose up -d postgres
   docker inspect --format "{{.State.Health.Status}}" ite-calibration-postgres-1
   ```
   Repeat until `healthy`. This creates the `ite` role/DB using the fresh
   password from step 3.5.

7. **Restore the database** (again via `docker cp` + `psql -f`, no PowerShell
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

8. **Restore the certificate volume:**
   ```powershell
   docker volume create ite-calibration_cal_data | Out-Null
   $SFwd = $S.Replace("\", "/")
   docker run --rm -v "ite-calibration_cal_data:/target" -v "${SFwd}:/backup" alpine sh -c "cd /target && tar xzf /backup/cal_data-<STAMP>.tar.gz"
   docker run --rm -v "ite-calibration_cal_data:/source:ro" alpine sh -c "find /source -type f | wc -l; du -sh /source"
   Get-Content "$S\volume-stats-old.txt"
   ```
   File count must match; size within a few percent.

9. **Start everything and verify:**
   ```powershell
   docker compose up -d
   docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}"
   Invoke-RestMethod http://localhost/api/health | ConvertTo-Json
   docker logs ite-calibration-api-1 --tail=40
   ```
   Expected: all four containers Up, api + postgres `(healthy)`, health
   returns ok. Unlike the old image-copy plan, alembic **will** apply
   migrations here if the schema doesn't already match this build's models —
   that's normal for a fresh build against a restored dump, not a red flag by
   itself. Watch the log for actual errors, not just "applying migration X."
   Any run mid-`processing` at freeze time is now reset to failed — expected.

10. **Browser smoke test** from another PC on the LAN, using the real address
    users will type: log in, open History, open a run, download a `.docx`,
    open it. A login CORS/origin error means `ITE_ALLOWED_ORIGINS` doesn't
    contain the URL exactly as typed (scheme + host + port, no trailing
    slash) — fix `.env` then `docker compose up -d api`.

11. **Register the backup task and run it once:**
    ```powershell
    powershell -ExecutionPolicy Bypass -File C:\Calibration\register-task.ps1
    powershell -ExecutionPolicy Bypass -File C:\Calibration\deploy-package\backup-windows.ps1
    Get-ChildItem C:\ite-calibration-backups
    ```
    Edit the hardcoded path in `register-task.ps1` first if the repo isn't at
    `C:\Calibration`. Copy over old daily backups if you brought them.

12. **Reboot test:** reboot the PC, wait 2 minutes, re-run step 3.9's checks.

## 4. Cutover plan

1. **Address.** Since the old PC won't be present to conflict with, the new
   PC can most likely just take the same IP/hostname the lab already uses —
   no `.env` change beyond what's already there, no user retraining, no
   bookmarks to update. Only assign it a new address if that's genuinely
   easier logistically; in that case set
   `ITE_ALLOWED_ORIGINS=http://localhost,http://<NEW-IP>` and tell users the
   new URL ahead of time (there's no old address to keep working alongside it
   as a bridge — the old PC is gone).
2. **Order:** section 2 (final capture — see 0.7 on timing) → 2a (already
   done, earlier, as a dry run) → section 3 (restore + verify on the new PC)
   → confirm address per 4.1 → users test → done. Downtime is the gap between
   final capture and a verified-working new PC — minimize this by doing 2a
   ahead of time so section 3 is a repeat of something already proven to
   work, not a first attempt.
3. **Sessions:** cookies are per-host, so everyone logs in again once.
   Passwords/users carry over in the dump.
4. **GitHub Actions self-hosted runner:** nothing is installed on the old PC
   today, workflow jobs just queue (see `docs/DEPLOYMENT.md`). Don't install a
   runner on the new PC as part of this move. If ever re-enabled, both
   DEPLOYMENT.md warnings apply unchanged — `main` needs branch protection
   first.
5. **There is no fallback period.** Once the old PC is gone, the new PC *is*
   production — there's no "keep the old one around for two weeks just in
   case." This is exactly why section 2a (dry run before the old PC leaves)
   carries all the weight that a fallback period would otherwise cover. Treat
   passing 2a as the actual go/no-go gate, not the cutover itself.

## 5. There is no rollback — plan accordingly

With the old PC gone, "rollback" can only mean **re-running the restore from
the bundle**, not reverting to a running old system. Concretely:

1. If something goes wrong on the new PC *after* the dry run (2a) already
   passed, the fix is almost always operational (wrong `.env` value, Docker
   Desktop misconfigured, a step skipped) rather than a bad bundle — redo the
   relevant part of section 3 from the still-intact bundle copy on the new
   PC's own disk.
2. If the bundle itself turns out to be bad (missed in 2a, or a copy
   corrupted in transit), there is nothing to recover from except the second
   transfer-medium copy made in step 2.6. This is the entire reason for
   keeping two copies — verify both are readable *before* leaving the old
   PC's location, not after.
3. Any calibration work done on the old PC between the final capture and its
   departure is unrecoverable, by design of this constraint — this is what
   the timing guidance in step 0.7 is trying to minimize, not eliminate.
4. Because of 1–3, treat the dry run in section 2a as mandatory, not
   optional. It is the only point in this whole process where a mistake is
   still cheap to fix.

## 6. Risks and how to detect them

| Risk | How it shows up | Detect / prevent |
|---|---|---|
| Building from an unreviewed/WIP commit instead of the tagged one | New PC runs unfinished refinement work, or misses a fix that was supposed to be included | Always build from the tag in step 0.2, never `main` directly; `git checkout windows-migration-<STAMP>` in 3.3 |
| App schema/behavior doesn't match the restored data as cleanly as hoped (this is now a *new* app, not a byte-copy) | Alembic migration errors, or the app runs but behaves unexpectedly against old data shapes | This is exactly what the mandatory dry run (2a) exists to catch, before the old PC is gone |
| New PC has no internet access for `docker build` | Build fails pulling base images or `pip`/`npm` packages | Confirm internet access ahead of time (open question below); fall back to building elsewhere and `docker save`/`load` (note at top of section 3) |
| Dump mangled by PowerShell text encoding | Japanese text as mojibake, or psql failing on a UTF-16 file | Never pipe SQL through PowerShell; use `pg_dump -f`+`docker cp` (2.2) and `docker cp`+`psql -f` (3.7); `Format-Hex` check; batch_name spot check |
| Data entered on old PC after the dump | New PC missing the latest runs | Freeze in 2.1; keep old stack stopped until verified; compare `count(*)`/`max(created_at)` |
| Volume and DB out of sync (run mid-process at freeze) | Run rows with missing files or vice versa | Freeze api before both captures; expect that run reset to failed on first start |
| `.env` secrets weak or left as placeholders | Postgres auth failures; predictable JWT secret | `Select-String ... changeme` check in 3.5; generate a real random secret |
| `ITE_ALLOWED_ORIGINS` doesn't match the URL typed | Login POST rejected by Origin middleware; GETs still work | Test from a second PC with the real URL (3.10); fix `.env`, `docker compose up -d api` |
| Orphaned/misnamed volumes | Restored into `cal_data` instead of `ite-calibration_cal_data`; API sees empty data dir | Compose project name is `ite-calibration`; use exact names in 3.8; `docker volume ls` should show only `ite-calibration_pg_data` and `ite-calibration_cal_data` |
| Postgres major version mismatch | Would only matter with a raw `pg_data` copy — the SQL dump restores into any 16.x | Pull `postgres:16-alpine` explicitly in 3.4, matching the version noted in 0.5 |
| Docker Desktop differences | compose v1 absent (fine — v2 syntax used throughout), file sharing off, Hyper-V vs WSL2 | Step 3.1 checks |
| Bind-mount path syntax | `docker run -v` with backslashes fails silently | Forward slashes as in both scripts |
| `register-task.ps1` hardcoded path/permissions | Task runs but backup aborts | Same `C:\Calibration` path, account in `docker-users`, run once by hand (3.11) |
| Bundle has a gap discovered only after the old PC is gone | Missing certs, wrong row counts, build/restore failure | Mandatory dry run (2a), doable right on this Mac, while the old PC can still be recaptured from |
| One transfer-medium copy is corrupt/lost | Only the second copy is usable, or nothing is | Two independent copies (2.6), both hash-verified before leaving the old PC's site |
| Data entered on old PC between final capture and its departure | Permanently missing from the new PC | Minimize the gap per the timing guidance in 0.7; accept this loss is real if the gap can't be closed |
| Uncommitted source only on old disk | Lost once old PC is gone | `git status` in 0.3 — port anything real into the refinement work before tagging in 0.2 |

**Optional extra insurance** during the freeze (old PC, everything stopped) —
a raw copy of the Postgres data directory, only useful if the SQL dump turns
out unusable, and only restorable onto the same Postgres major:
```powershell
docker compose stop postgres
docker run --rm -v "ite-calibration_pg_data:/source:ro" -v "${SFwd}:/backup" alpine tar czf /backup/pg_data-raw-<STAMP>.tar.gz -C /source .
docker compose start postgres
```

## Open questions

Resolved: the old PC will be completely unreachable once it leaves (no
remote access, no one on-site); there's a multi-day gap between capture and
the new PC's setup; the app is rebuilt fresh from a tagged git commit rather
than shipped as exact images; and the dry run (2a) happens on this Mac, not a
spare Windows box. Remaining questions:

1. **Will the new PC have internet access** to `docker build`/`pip install`/
   `npm install` during setup? If not, plan on building the images elsewhere
   (this Mac, or any connected machine) and transferring them via
   `docker save`/`load` instead (noted at the top of section 3).
2. What's the actual scope of "refine the application" — which bug fixes,
   which features, what ops cleanup, what UI redesign? This needs its own
   scoping conversation before any of it is implemented; it isn't blocking
   the DB/migration plan above, but it does need to land and be tagged
   (step 0.2) before the new PC's build.
3. Will the new PC take over the old PC's IP/hostname (4.1), or does it need
   a new address? How do lab users reach the app today?
4. Exactly when does the old PC become unreachable relative to when you can
   do the final capture — same day, or is there slack? This decides how much
   of the 0.7 timing guidance you can actually follow.
5. Is the repo really at `C:\Calibration` on the old PC, and is `git status`
   clean there?
6. Will the old PC still be used for real calibration work between the
   rehearsal capture and the final capture? If yes, only the final capture
   (done as late as possible) can be trusted as complete.
7. Should `backup-windows.ps1` be fixed to the byte-safe `pg_dump -f` +
   `docker cp` form as a follow-up, and should an existing daily backup file
   be checked for the UTF-16 signature first?
8. Any plan to re-enable the GitHub Actions self-hosted runner on the new PC?
   (Recommended: no, not as part of this move.)
