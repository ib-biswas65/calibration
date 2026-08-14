# Production deployment (Windows PC)

This describes how the app actually runs in production, on the Windows PC at the
calibration lab. Read this before debugging "the app is broken" — most confusion
in the past came from not knowing which of these three things you were looking at.

## The three things people mean by "the app"

1. **The web dashboard** (`apps/web` + `apps/api`) — the only thing currently in
   use. Runs as four Docker containers: `postgres`, `api`, `web` (nginx serving
   the built SPA), `edge` (nginx reverse proxy on port 80). This is what's meant
   by "the app" everywhere below.
2. ~~The Flet desktop prototype (`src/`)~~ — **removed 2026-08-14**. It was an
   early cross-platform desktop UI experiment, superseded by the web dashboard,
   and had gone stale (missing dependencies, not wired to the real backend). Do
   not recreate it; if desktop packaging is ever needed again, start a fresh
   design discussion instead of resurrecting this code.
3. **CLI tooling** (`ite-api` entrypoint in `apps/api`, `scripts/`) — used for
   one-off admin/migration tasks, not a running service.

## How production is deployed

- `deploy-package/` is the folder that gets copied to the Windows PC.
  `deploy-package/setup-windows.ps1` loads pre-built images from
  `deploy-package/images/api.tar.gz` and `images/web.tar.gz` (built elsewhere,
  see below) and starts the stack with `deploy-package/docker-compose.yml`.
- `infra/` holds the equivalent Compose files for **local development**
  (`infra/docker-compose.yml` builds from source; `infra/docker-compose.prod.yml`
  mirrors the deploy-package prod compose for reference/testing).
- Check what's actually running on the Windows PC with:
  ```bash
  docker ps
  docker compose -f deploy-package/docker-compose.yml ps
  ```

## The #1 source of confusion: images are baked snapshots

**Editing a file under `apps/api/` or `apps/web/` on disk does nothing to the
running containers.** The containers run whatever was baked into the image at
`docker build` time — there is no source bind-mount in production. If you fix a
bug in the source tree, the running app is still broken until you:

```bash
cd apps/api        # or apps/web
docker build -t ite-calibration-api:latest .     # rebuild the image
cd ../../deploy-package                          # or wherever compose lives
docker compose up -d --no-deps api               # recreate just that container
```

Before rebuilding, tag the current image so you can roll back:
```bash
docker tag ite-calibration-api:latest ite-calibration-api:backup-<date>
```

This matters because a container can be "healthy" and running clean code for
*weeks* while the git working tree next to it is completely broken (this
happened — see Incident History below) — and the reverse is also true: fixing
the git tree does **nothing** for a running container until you rebuild.

## Auto-deploy on push (currently dormant — read before re-enabling)

`.github/workflows/deploy.yml` runs `deploy-package/deploy.ps1` on a
**self-hosted runner** on every push to `main`. That script does
`git pull` in `C:\Calibration` and then `docker compose up -d` — i.e. **any
push to main force-syncs this machine's working tree and restarts the stack.**

As of 2026-08-14 no runner is installed on this machine, so the workflow's
jobs simply queue on GitHub and nothing happens locally. Two warnings if you
ever reinstall a runner:

1. A `git pull` was exactly what detonated the July merge corruption (see
   Incident History). Auto-sync of a production working tree is only safe if
   `main` is protected and reviewed.
2. `deploy.ps1` runs `docker compose up -d --build` against
   `deploy-package/docker-compose.yml`, which uses `image:` (pre-baked), not
   `build:` — so a code push does **not** actually rebuild images. Rebuilding
   remains a manual step (see above).

## Debugging a failed run — where to actually look

1. **Container health / crash**: `docker ps`, `docker logs <container>`.
   Note: this deployment's containers don't have log persistence configured, so
   `docker logs` may only show the last few restarts worth of output — don't
   trust "no errors in the logs" as proof nothing failed if the container has
   restarted recently.
2. **Real request traffic**: `docker logs ite-calibration-edge-1` (the nginx
   edge container) shows every HTTP request that hit the stack, with status
   codes. This is the most reliable way to confirm whether a request from the
   browser ever reached the backend.
3. **Actual run status/errors**: the source of truth for a calibration run's
   outcome is Postgres, not the container logs:
   ```bash
   docker exec -e PGPASSWORD=<password> ite-calibration-postgres-1 \
     psql -U ite -d ite -c \
     "SELECT id, status, failure_reason, created_at, completed_at FROM calibration_runs ORDER BY created_at DESC LIMIT 5;"
   ```
   `failure_reason` contains the full Python traceback for failed runs.
4. **Input files for a given run** are kept on the data volume even after
   failure, so you can reproduce/replay against them:
   ```bash
   docker exec ite-calibration-api-1 sh -c \
     "find /var/lib/ite-calibration/data/runs/<run-id> -type f"
   ```

## Incident history

- **2026-07-09 → 2026-08-14: broken git merge deleted ~7,600 files from
  `origin/main`.** A bad merge commit recorded two parents but its tree matched
  only an unrelated empty skeleton, silently discarding the real codebase from
  git history (though not from disk, until something force-synced to it).
  Restored from the last good commit; fixed in `9bcc0ef`. **This never affected
  the running Docker containers** — their images were built hours before the
  bad merge and are self-contained (no source bind-mount). It only became a
  real problem for anything that read `apps/api`/`src` directly off disk
  (scripts run outside Docker), and for anyone who tried to rebuild an image
  from the broken tree.
- **2026-08-13: calibration run failures were a real, separate bug**, not
  related to the git corruption. `ref_loader.py`'s CSV format auto-detection
  required strictly zero-padded `MM/DD` and `HH:MM:SS` timestamps, but the
  reference logger hardware exports `M/D H:MM` (no zero-padding, no seconds).
  Every reference file failed format detection with
  `ValueError: Could not detect CSV format`. Fixed by relaxing the regex/parse
  formats in `apps/api/ite_api/calibration/ref_loader.py`.

- **2026-08-14: rebuilding the image from the restored git tree regressed the
  API by a month.** The production image had been built on 2026-07-09 from the
  Windows working tree, which contained a month of code (tz-aware setpoint
  handling in `matcher.py`, audit-log user attribution, the date-edit and
  deviation-correction endpoints, traceback persistence in `failure_reason`,
  and `ite_api/calibration/template.docx`) that was **never committed to git**
  — git's last good commit was 2026-06-09. Rebuilding from the restored tree
  therefore shipped June code, and the first test run failed on the
  tz-naive/tz-aware comparison bug that the July image had already fixed.
  Recovered by extracting `/app/ite_api` from the backed-up July image
  (`docker cp` from a container of `ite-calibration-api:pre-ref-loader-fix`),
  diffing against the repo, and committing the July code. **Before rebuilding
  a production image, always diff the running image's source against the repo**
  — never assume git matches what's deployed.

**Lesson**: when "the app is broken," check in this order: (1) is the failure
actually in the currently-running container (check `edge` logs + Postgres
`calibration_runs.failure_reason`), not a guess based on the git working tree;
(2) is the git tree even what's driving the running container (it usually
isn't, in this deployment); (3) only then look at source code.
