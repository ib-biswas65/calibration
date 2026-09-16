# Post-redesign implementation plan (2026-09-16)

Phased, prioritized plan for everything found open at the end of the
2026-09-16 session: correctness bugs, ops/deploy bugs, CI and process gaps,
the unresolved "Upcoming" report, and the remaining design polish. Nothing
here is implemented yet. Each item says what it is, why it matters, what it
depends on, whether the user has to decide something first, and how much
process it needs (per the `dev-pipeline` skill: **just do it** / **spec** /
**design doc** / **ADR**).

Ground truth was checked against the repo on 2026-09-16 (see "State at time
of writing"). Where a claim from the session could not be confirmed in the
tree, it says so.

**This document supersedes and incorporates
`docs/superpowers/plans/2026-08-17-calibration-ui-overhaul.md`.** That older
plan was never merged and still exists only on the branch
`origin/claude/calibration-ui-overhaul-plan-6uo67q` (left as-is, not deleted).
Its confirmed root cause for the Upcoming-calibrations bug and its cert_no
detail have been folded into Phase 4 and Phase 2 below; everything else it
covered lives on as Phase 6. This document is the authoritative plan going
forward.

---

## State at time of writing (read this first)

Verified with `git status` / `git log` / `gh api`:

- HEAD is `a544001` on `main`, in sync with `origin/main`. The matcher fix
  (`4911ab5`) and the backup-script fix (`f538bd1`) are committed and pushed.
- **The working tree is NOT clean**, even though `HANDOFF.md` says it is.
  Uncommitted right now:
  - the `0008` migration rename (`apps/api/alembic/versions/0008_add_logger_result_failure_reason.py`
    -> `0008_add_failure_reason.py`, staged as a rename with modifications).
    This is the fix for the silent full-chain rollback on a fresh DB. If this
    is lost, next week's migration to the new PC boots against an empty schema.
  - the whole visual redesign and the WCAG contrast fix:
    `apps/web/index.html`, `apps/web/src/theme/tokens.css`,
    `apps/web/src/components/{AppShell,ConfirmDialog,DataTable,FileDropZone,StatTile,StatusPill,Toast}.module.css`,
    `apps/web/src/components/Sidebar.tsx`.
  - new untracked files: `DESIGN.md`, `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`.
- `main` has no branch protection (`gh api .../branches/main/protection` -> 404).
- The repo is public, so branch protection is available without a paid plan.
- `deploy-package/` lives at the **repo root**, not under `apps/api/`.
- `tests/test_telemetry.py` and the string `opentelemetry` do not exist
  anywhere in the tree today (only in `HANDOFF.md` and the daily log). That
  item is probably already resolved; confirm and close it rather than fix it.
- `ruff check apps/api` reports 22 errors (6 auto-fixable). This is why CI has
  been red since 2026-08-14.

---

## Recommended order across all themes

Read this as "do it in this order unless the user says otherwise".

1. **Phase 0, today**: commit and push what is sitting in the working tree
   (the `0008` fix especially), fix the records, get a fresh-context review of
   the session's changes.
2. **Phase 1**: make CI genuinely green, then turn on the guardrails (branch
   protection, secret scan, style check, Dependabot). Everything after this
   lands through a PR that CI actually checks.
3. **Phase 2**: the five known correctness bugs, worst first (`cert_no`
   uniqueness, silent regeneration failure, timezone offset, refresh race,
   timing side-channel), **plus the Upcoming-calibrations data-integrity gap
   (Phase 4 below), same class of bug and now fully scoped.** It is no
   longer blocked on the user — root cause is confirmed and the fix is
   designed — so build it alongside 2.1-2.5 rather than after Phase 3. Give
   it its own migration revision, allocated after 2.1's and 2.3's so the
   three don't race each other.
4. **Phase 3**: ops/deploy fixes. Two of these (`setup-windows.ps1`,
   `AGENT-SETUP.md` password generator) touch the migration path, so they
   should be done **before next week's PC move**, and can be pulled forward
   ahead of Phase 2 if the move date is fixed.
5. **Phase 4**: build the confirmed fix for "Upcoming calibrations shows
   nothing" (see Phase 4 below) — sequenced with Phase 2, not after Phase 3.
6. **Phase 5**: remaining design polish and mobile-width verification.
7. **Phase 6**: carried-over scope from the 2026-08-17 UI overhaul plan
   (archive/restore, admin audit trail, New Calibration UX, Overview
   overhaul, Loggers page improvements, PDF export). Not prioritized by this
   session — pick up only once the user explicitly prioritizes it.

Parallel workstream, do not fold into the above: the Windows PC migration
(`docs/MIGRATION.md`, GitHub issues #2/#3/#4). Its only hard dependency on
this plan is Phase 0 (the `0008` fix must be on `main`) and Phase 3 items
3.1 and 3.2.

---

## Phase 0: land what already exists (today, blocks everything)

### 0.1 Commit the `0008` migration rename on its own

- **What**: commit the staged rename `apps/api/alembic/versions/0008_add_failure_reason.py`
  (revision ID now within Alembic's 32-char `alembic_version.version_num`
  column). Verify with `alembic upgrade head` against a throwaway Postgres
  (`docker run --rm postgres:16-alpine`) and `SELECT * FROM alembic_version`
  showing `0008_add_failure_reason`.
- **Why**: on a fresh DB the old revision ID made Alembic roll back the whole
  chain silently. Next week's migration is a fresh build. Severity: critical
  for the migration, harmless on the current production DB (already at 0008
  under the old name? **check**: if production's `alembic_version` holds the
  old long ID, the rename needs a one-line `UPDATE alembic_version SET
  version_num = '0008_add_failure_reason'` in the migration runbook, or the
  new code will refuse to find the revision). This check is the one thing to
  do before committing.
- **Depends on**: nothing.
- **Needs user**: no.
- **Tier**: just do it, but add the production `alembic_version` check to
  `docs/MIGRATION.md`.

### 0.2 Commit the redesign and contrast fix

- **What**: commit the `apps/web` CSS/TSX changes plus `DESIGN.md` as one
  `feat(web): ITE brand redesign` commit (or two: redesign, then
  `fix(web): WCAG contrast on status colors`). Run `npm test`, `tsc --noEmit`,
  `npm run build` first and put the results in the commit message.
- **Why**: weeks of visual work exist only on this disk.
- **Needs user**: no.
- **Tier**: just do it.

### 0.3 Decide what to do with `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`

- **What**: these are GitNexus/agent config. Either commit them (they are
  harmless in a public repo, no secrets) or add to `.gitignore`.
- **Needs user**: yes, small. Default recommendation: commit them, they help
  the next agent.
- **Tier**: just do it once decided.

### 0.4 Fix the records

- **What**: `HANDOFF.md` says the tree is clean and does not mention the
  redesign, the contrast fix, the `0008` bug, or the five open correctness
  bugs. `logs/DAILY-2026-09-16.md` stops after the matcher fix. Run
  `/handoff` after 0.1-0.3 so the next session starts from files alone.
- **Needs user**: no.
- **Tier**: just do it.

### 0.5 Fresh-context review of the session's changes

- **What**: run `code-review` (medium effort) against the diff
  `a544001~3..HEAD` plus the Phase 0 commits, using an agent that did not
  write the code. Scope: `matcher.py`, `ref_loader.py`, `cal_loader.py`,
  `routes/runs.py::_do_process`, the pass-rate SQL in `routes/runs.py` and
  `routes/overview.py`, `StatusPill`, `RunDetailPage`, `HistoryPage`,
  `tokens.css`. Specific things to look for: any remaining path where a
  setpoint target can reach certificate output; whether `partial` status is
  handled everywhere `complete` was (filters, overview counts, CLI).
- **Why**: the dev-pipeline skill flags "15+ direct pushes to main, no review"
  as a known failure mode, and the matcher change alters certificate content.
- **Needs user**: no.
- **Tier**: just do it. Findings become items in Phase 2 if real.

---

## Phase 1: make CI real, then lock the door

Order inside this phase matters: branch protection with a required check is
useless (or blocks everyone) until that check is green.

### 1.1 Pay down the 22 ruff errors

- **What**: `cd apps/api && .venv/bin/ruff check . --fix` for the 6 auto-fixable,
  then hand-fix the other 16. Do not change behaviour; if a lint error hides a
  real bug, note it and fix it in Phase 2 instead.
- **Why**: the Lint step has failed on every push since 2026-08-14, so the
  Test step in `.github/workflows/ci.yml` has never run. Right now CI proves
  nothing.
- **Alternative** (user decision): mark Lint `continue-on-error: true` and
  fix later. Not recommended; 22 errors is an hour of work and
  `continue-on-error` tends to become permanent.
- **Needs user**: only if choosing the alternative.
- **Tier**: just do it.

### 1.2 Make the app bootable outside Docker

- **What**: `apps/api/ite_api/main.py:50` hardcodes
  `Config("/app/alembic.ini")`. Resolve it relative to the package
  (`Path(__file__).resolve().parents[1] / "alembic.ini"`) with an env
  override (`ITE_ALEMBIC_INI`). Keep `/app/alembic.ini` working inside the
  image (the relative path resolves to the same file there).
- **Why**: without this, nothing that imports the real app (TestClient,
  scripts, CI) works outside a container.
- **Depends on**: nothing, but 1.3 needs it.
- **Tier**: just do it, with a test that boots the app via TestClient.

### 1.3 Fix the `engine` fixture vs Alembic collision

- **What**: `apps/api/tests/conftest.py`'s `engine` fixture runs
  `Base.metadata.create_all()`; the app's lifespan runs `alembic upgrade head`
  on the same testcontainers Postgres; second one to run hits
  `DuplicateTable`. Pick one schema source for tests. Recommended: tests run
  `alembic upgrade head` (so migrations are exercised, which would have
  caught the `0008` bug), and the `client` fixture disables the app's own
  startup migration via a setting (`ITE_RUN_MIGRATIONS_ON_STARTUP=false`) or
  a dependency override. Then actually run the route tests under
  `apps/api/tests/routes/` and see which ones pass for the first time.
- **Why**: route-level tests using `client` have probably never passed;
  auth, audit, and certificate lookup routes are effectively untested.
- **Depends on**: 1.2.
- **Tier**: just do it. Budget for surprises: expect some route tests to fail
  for real reasons once they run; those become Phase 2 items.

### 1.4 Close the `test_telemetry.py` item

- **What**: the file is not in the tree. Confirm with `git log --all --
  '*test_telemetry*'` whether it was deleted or never committed, then delete
  the item from `HANDOFF.md`. If it reappears from a stash, either add
  `opentelemetry-api` to `[project.optional-dependencies].dev` in
  `apps/api/pyproject.toml` or delete the test.
- **Tier**: just do it.

### 1.5 Confirm CI green end to end

- **What**: push (or open a PR, see 1.8) and watch both `api` and `web` jobs
  pass with the Test step actually executed. The `api` Test job needs
  Docker for testcontainers; `ubuntu-latest` has it, but confirm the run
  time is acceptable (set a job `timeout-minutes`).
- **Depends on**: 1.1-1.4.
- **Tier**: just do it.

### 1.6 Add `secrets-scan` and `style-check` jobs

- **What**: add the two jobs from the `dev-pipeline` skill's CI template to
  `.github/workflows/ci.yml` (the repo predates the template). Style check
  for the web side = `tsc --noEmit` + eslint if configured; the api side is
  already ruff.
- **Depends on**: 1.5 (so the new jobs start green).
- **Tier**: just do it.

### 1.7 Enable Dependabot alerts

- **What**: `gh api -X PUT repos/ib-biswas65/calibration/vulnerability-alerts`
  and add `.github/dependabot.yml` for `pip` (`apps/api`) and `npm`
  (`apps/web`), weekly, grouped.
- **Why**: currently disabled; the app handles auth and customer data.
- **Depends on**: nothing (but PRs it opens will be noisy until 1.5).
- **Tier**: just do it.

### 1.8 Branch protection on `main` and the PR workflow

- **What**: `gh api -X PUT repos/ib-biswas65/calibration/branches/main/protection`
  with: required status checks `api — lint + test`, `web — lint + test + build`
  (plus the 1.6 jobs), strict up-to-date, no force push, no deletion. With a
  single developer, "required reviews: 1" would block self-merge; instead
  require the checks and rely on the fresh-context agent review (0.5 pattern)
  recorded in the PR description.
- **Why**: the repo is public, so nothing blocks this. It also makes
  re-enabling `deploy.yml` safe one day (`docs/DEPLOYMENT.md` says auto-sync
  of the production tree is only safe if `main` is protected).
- **Depends on**: 1.5. Do NOT turn this on before CI is green or every merge
  is blocked.
- **Needs user**: yes. Decision: adopt PR-per-change from Phase 2 onward, or
  keep direct push and only require the checks on push? Recommendation:
  PR-per-change for anything under `apps/`, direct push allowed for
  `docs/`, `logs/`, `HANDOFF.md`, `PROGRESS.md` (use a path filter in CI so
  docs-only pushes do not wait on tests).
- **Tier**: just do it once decided. Record the decision in `PROGRESS.md`,
  not an ADR (easily reversible).

### 1.9 TDD checkpoint discipline

- **What**: process rule, no code. From Phase 2 on, each bug fix is two
  commits on its branch: `test: reproduce <bug>` (red) then `fix: <bug>`
  (green). The `dev-pipeline` skill asks for this and it was skipped on
  2026-09-16.
- **Tier**: just do it.

---

## Phase 2: correctness bugs (worst first)

All land via PR after Phase 1. Each is red-test-then-fix.

### 2.1 Non-unique `cert_no` on `LoggerResult` (HIGH)

- **Where**: `apps/api/ite_api/db/models/calibration.py:95`
  (`cert_no: String(20), nullable=True, index=True`, no unique constraint);
  lookup at `apps/api/ite_api/routes/runs.py:679` (`find_by_cert_no` does
  `.first()` on a plain equality filter). `cert_no` is assigned in
  `apps/api/ite_api/calibration/engine.py` (`_format_cert_no`) from the run's
  `start_cert_no`, so two runs started with overlapping ranges produce
  duplicates.
- **Why**: certificate-number lookup (the thing a customer quotes back) can
  return another run's logger. Certificates are legal documents.
- **Fix shape**:
  1. Query production for existing duplicates first
     (`SELECT cert_no, count(*) FROM logger_results GROUP BY 1 HAVING count(*)>1`).
     This is a hard **prerequisite**, not a nice-to-have: the old 2026-08-17
     UI overhaul plan (see the top-of-document note) independently reached
     this same bug and flagged that if the historical import produced any
     duplicates, a unique-index migration fails outright against a live
     database. It does not claim production already has duplicates, only
     that the audit must run before the migration does. Ship a read-only
     check script alongside the migration.
  2. Decide the rule: unique across all results, or unique among
     non-invalid/non-superseded results (a re-run of the same loggers may
     legitimately re-issue the same number, see `docs/CHANGE_LOG.md`'s cert
     re-issue entry). **Already decided, see "Open questions" item 4**: unique
     among valid/current certificates only.
  3. Migration `0009` adding a partial unique index on
     `logger_results (cert_no)`, scoped to the decided rule (the old plan's
     own sketch of this index used `WHERE cert_no IS NOT NULL` with no
     valid/current scoping, and even folded archived runs into the same
     uniqueness domain so numbers could never be reissued — that is stricter
     than the decided rule above; take the mechanism from it, not that
     predicate).
  4. `find_by_cert_no` returns 409/ambiguous if more than one match instead of
     silently `.first()`.
  5. Guard at run creation: refuse a `start_cert_no` whose range collides
     with `[start, start + n_sheets)`. **Repeat the same check at process
     time**, not just at creation — the sheet count isn't known until then,
     and two operators can hold two draft runs at once.
  6. Engine layer: wrap the per-logger insert so an `IntegrityError` marks
     the run `failed` with a readable `failure_reason` instead of a raw
     traceback.
  7. Optional, cheap, and already scoped by the old plan: a
     `GET /api/runs/next-cert-no` endpoint (`MAX(cert_no)` cast to `bigint`,
     safe because all existing data is numeric zero-padded per
     `scripts/migrate_historical.py:213`) to replace the hardcoded
     `startCertNo = "0000001000"` in `NewCalibrationPage.tsx:37` and stop
     relying on the operator to type the right number; today `_do_process`
     assigns sequentially from that starting value at `runs.py:743-747`.
- **Needs user**: no further decision — step 2's rule is already decided
  (see above).
- **Tier**: spec (short, one page in `docs/superpowers/specs/`), because it
  changes a business rule on issued certificates and needs a migration.

### 2.2 Silent certificate regeneration failure after date edit (HIGH)

- **Where**: `apps/api/ite_api/routes/runs.py:599` `patch_dates` commits the
  new dates, then `background_tasks.add_task(_regenerate_all_certificates, ...)`
  (line 630). `_regenerate_all_certificates` (line 634) catches `Exception`
  per result and only logs (`_log.exception(...)`). Nothing is stored, the
  API already returned 200.
- **Why**: DB says the new date, the `.docx` on disk may still say the old
  one, and the user has no way to know. Same class of bug as the matcher one:
  the certificate can disagree with the record.
- **Fix shape**: record the outcome on the row (`LoggerResult.cert_regenerated_at`
  or reuse `failure_reason` with a `cert_stale` marker), surface it in
  `RunDetailPage` (a "certificate out of date, regenerate" pill using the
  existing `StatusPill` invalid style), and add a "retry regeneration"
  endpoint. Consider making the regeneration synchronous for small runs; it
  is per-run, not per-fleet.
- **Needs user**: no for the fix, yes for whether a stale cert should block
  download.
- **Tier**: just do it, with a red test that makes regeneration throw and
  asserts the marker is set.

### 2.3 `testing_start` / `testing_end` stored with wrong UTC offset (MEDIUM, latent)

- **Where**: `apps/web/src/pages/NewCalibrationPage.tsx:85` sends
  `testingStart + ":00Z"`, i.e. the `datetime-local` value (local wall clock,
  JST) is labelled as UTC. Also check `PATCH /runs/{id}` (`routes/runs.py:289`)
  and `scripts/migrate_historical.py` for the same pattern. Stored values are
  9 hours off.
- **Why**: not displayed anywhere yet, so nothing is visibly wrong today, but
  any future report, sort, or certificate field using these dates will be off
  by up to a day.
- **Fix shape**: convert with `new Date(localValue).toISOString()` in the
  frontend (browser local tz -> real UTC), assert tz-aware on the API model,
  and a one-off data migration `0010` shifting existing rows by -9h **only if
  the user confirms all historical entries were made in JST** and that no
  other writer (`migrate_historical.py`) already stored correct UTC.
- **Needs user**: yes, for the historical-data decision only. The frontend
  fix can go in immediately.
- **Tier**: just do it (frontend), spec paragraph for the data migration.

### 2.4 Refresh-token rotation race (MEDIUM)

- **Where**: `apps/api/ite_api/routes/auth.py`, the refresh endpoint and
  `UserSession` rotation (`create_refresh_token` / `hash_refresh_token`,
  `revoked_at` handling around lines 79-130). Two concurrent requests near
  access-token expiry both present the same refresh cookie; the first rotates
  and revokes it, the second is rejected and the client logs out.
- **Why**: spurious logouts, worse on the dashboard pages that fire several
  requests at once.
- **Fix shape**: standard grace window. Keep the old token valid for ~30 s
  after rotation (store `rotated_at` + `replaced_by` on `UserSession`, accept
  a rotated token within the window and return the same new pair), or
  serialize refresh on the client (single in-flight refresh promise in
  `apps/web/src/api/`). Client-side serialization is smaller and has no
  security trade-off; do that first, add the server grace window only if
  logouts persist.
- **Needs user**: no.
- **Tier**: just do it, red test = two refreshes with the same token, both
  must succeed within the window (or, client-side, a unit test that N
  concurrent 401s trigger one refresh call).

### 2.5 Login timing side-channel (LOW, cheap)

- **Where**: `apps/api/ite_api/routes/auth.py:71`
  `if user is None or user.disabled or not verify_password(...)`. Short-circuit
  means no bcrypt/argon run when the account does not exist, so "no such user"
  responds much faster than "wrong password". Check registration/password
  reset (`pr.used_at`, line 157) for the same shape.
- **Fix shape**: always run `verify_password` against a fixed dummy hash when
  `user is None` (module-level constant produced by `hash_password` at import),
  then evaluate the combined condition.
- **Needs user**: no.
- **Tier**: just do it. Test: assert `verify_password` is called exactly once
  on both paths (mock), do not try to assert on wall-clock timing.

---

## Phase 3: ops and deploy

### 3.1 Apply the `backup-windows.ps1` fixes to `setup-windows.ps1` (do before the PC move)

- **Where**: `deploy-package/setup-windows.ps1` line ~126 restores the DB with
  a PowerShell pipe into `psql -U ite -d ite -q` (UTF-16 re-encoding corrupts
  Japanese text, same bug fixed in `backup-windows.ps1` in `f538bd1`), and
  the `try { docker version | Out-Null } catch { ... }` at line 49 never
  fires in PowerShell 5.1 for a non-terminating native command error.
- **Fix shape**: copy the exact patterns from `backup-windows.ps1`:
  `docker exec -i ... psql < file` via `cmd /c` or `Start-Process` with
  redirected stdin (byte-safe), and `docker version *> $null; if ($LASTEXITCODE -ne 0) { ... }`.
- **Why**: `docs/MIGRATION.md` adapts this script's structure for the move.
- **Needs user**: no.
- **Tier**: just do it. Verify on a Windows box or with the collaborator
  before the move; cannot be tested on macOS.

### 3.2 `AGENT-SETUP.md` password generator (do before the PC move)

- **Where**: `deploy-package/AGENT-SETUP.md` lines 65-80,
  `[Convert]::ToBase64String($bytes2)` can emit `/`, `+`, `=`, which break the
  `ITE_DATABASE_URL` the same doc builds.
- **Fix**: generate from an explicit alphabet (`[char[]]` of `A-Za-z0-9`) or
  hex (`-join ($bytes | ForEach-Object { $_.ToString('x2') })`), and state the
  constraint next to the snippet.
- **Tier**: just do it.

### 3.3 Staging shares production Postgres credentials

- **Where**: `deploy-package/docker-compose.staging.yml` reads the same
  `POSTGRES_USER/PASSWORD/DB` env vars as `deploy-package/docker-compose.yml`
  from the same `.env`.
- **Fix**: `env_file: .env.staging` with its own credentials and a different
  volume name; document in `docs/DEPLOYMENT.md`.
- **Needs user**: only if staging is actually used on the production PC
  (confirm; if nobody runs staging, delete the file instead).
- **Tier**: just do it.

### 3.4 `deploy.ps1` cannot deploy new code (decision, not a quick fix)

- **Where**: `deploy-package/deploy.ps1` + `.github/workflows/deploy.yml`.
  `docs/DEPLOYMENT.md` "Auto-deploy on push" section: compose uses `image:`
  not `build:`, so `up -d --build` rebuilds nothing; images arrive as
  `deploy-package/images/*.tar.gz` built elsewhere; no self-hosted runner is
  installed; `git pull` on the production tree is what caused the July
  corruption.
- **Why**: today the only working deploy is the manual rebuild in
  `docs/DEPLOYMENT.md`. That is acceptable for a one-lab app, but the dormant
  workflow is a trap.
- **Options** (user decides):
  a. Delete `deploy.yml` and `deploy.ps1`; keep the documented manual rebuild
     as the official path. Cheapest, matches current reality.
  b. Build images in GitHub Actions on tag, push to GHCR, and make `deploy.ps1`
     a `docker compose pull && up -d` with no `git pull`. Needs the new PC to
     have internet (one of the 8 open migration questions).
  c. Keep the tarball flow and make `deploy.ps1` load the tarballs.
- **Depends on**: 1.8 (any auto-deploy needs protected `main`), and the
  migration's internet-access answer.
- **Tier**: design doc (short) + ADR, because the choice is hard to reverse
  and affects how the lab receives updates.

---

## Phase 4: "Upcoming calibrations shows nothing" — root cause confirmed, fix designed, ready to implement

This is no longer a "reproduce and scope" item. The root cause was
independently found and fully designed in the older, unmerged
2026-08-17 UI overhaul plan (see the top-of-document note); it matches
exactly the one concrete symptom already on record in "Open questions" item
7 (no upcoming calibrations at all, not a wrong subset — a
complete-empty-result bug, not a filtering edge case).

### Root cause (confirmed)

`UpcomingPage.tsx:24-25` filters on `next_due_at != null`.
**`Logger.next_due_at` is never written by any automated path in the
system:**

- `_do_process` creates loggers with `Logger(serial_no=name.strip())` and
  nothing else (`runs.py:759-763`);
- the historical import does the same (`scripts/migrate_historical.py:225`);
- the only writer is the manual `PATCH /api/loggers/{id}` (`loggers.py:72`),
  which nobody calls automatically.

So the column is NULL fleet-wide and the page's filter excludes every
logger, unconditionally. This matches the "shows nothing at all" symptom
exactly.

### Fix design (carried over from the old plan's §7 cross-cutting section)

- **Schema**: a new migration adding to `loggers` — `last_calibrated_at DATE
  NULL` and `due_override BOOLEAN NOT NULL DEFAULT false` (set when an
  engineer manually edits a due date, so recomputation doesn't stomp it).
  Add `ITE_CAL_INTERVAL_MONTHS` (default `12`) to `config.py` as a single
  knob rather than a per-logger field. Allocate this migration's revision
  after 2.1's `0009` and 2.3's `0010` so the three don't collide (the old
  plan called this `0009`, but that number is now taken by 2.1's cert_no
  index — the number is not load-bearing, the ordering relative to those two
  migrations is).
- **One helper, `recompute_logger_schedule(db, logger_id)`**:
  `last_calibrated_at` = the **test date** of the most recent `complete`,
  non-archived run holding a result for that logger; `next_due_at` =
  `last_calibrated_at + ITE_CAL_INTERVAL_MONTHS`; skipped entirely when
  `due_override` is set.
- **Use `calibration_runs.testing_start`** (date part) as the test date —
  explicitly *not* `certificate_date`/`doc_date_jp` and *not* `created_at`.
  Rationale (from the old plan, worth keeping verbatim since it heads off a
  wrong re-derivation):
  - `created_at` is when the row was inserted — the historical import ran in
    2026-06 for batches tested in March, so this would schedule those
    loggers months late.
  - `certificate_date`/`doc_date_jp` is the date the *document* was issued,
    typically a day or two after testing — close, but not the test date.
  - `testing_start` is the actual testing window, and migration
    `0005_fix_test_date_jp` re-derived `test_date_jp` from it precisely
    because the certificate had been printing the issue date as the test
    date. In the live database `test_date_jp` *is* `testing_start`, and it's
    `NOT NULL`, so no fallback is needed.
- **Call the helper from every path that changes run history**: after
  `_do_process` completes, after a run is archived or restored (archiving
  the newest run must roll a logger's due date back to the previous one —
  relevant once Phase 6's archive/restore work exists), after
  `PATCH /runs/{id}/dates`, and after a deviation correction changes a
  verdict.
- **Backfill script** in `scripts/`, with `--dry-run`, recomputing the whole
  fleet from existing `logger_results`. This is what makes the Upcoming page
  light up for the first time. Loggers with no completed run get
  `last_calibrated_at = NULL` and land in a "Never calibrated" bucket rather
  than a fabricated due date.
  - **Data caveat**: `scripts/historical_batches.json` contains batches
    whose stated test date and `testing_start` disagree (Batch 1 is named
    "March 4" but carries `testing_start: 2026-03-10`). Migration `0005`
    already normalised certificates to `testing_start`, so the backfill is
    self-consistent, but spot-check a few historical loggers against the
    paper certificates before trusting the resulting due dates.
- **Once due dates exist**, the page itself also has a real off-by-one
  worth fixing in the same pass: `daysUntil` (`UpcomingPage.tsx:9`) parses
  `new Date("2026-08-17")` as UTC midnight, then compares it to a local
  `Date.now()` — compare date-only values in local time instead. Also note
  the 200-row cap hardcoded in `list_loggers` (`loggers.py:38`) with no sort
  parameter — a larger fleet would silently truncate the Upcoming list even
  once dates are populated; moving bucketing server-side
  (`GET /api/loggers/upcoming?within_days=90`) avoids that, but is UI polish
  on top of the actual fix and can be scoped separately if time-boxed.
- **Needs user**: no further decision on the root cause or fix shape — this
  proceeds straight to implementation.
- **Tier**: spec (short), because it adds a migration and a new call
  contract used from four places; use the `bug-resolution` pipeline for the
  write-up since it started life as a bug report.

---

## Phase 5: remaining design polish

Lowest priority; everything already inherits the new tokens.

### 5.1 Mobile-width verification (375 px and 768 px)

- **What**: Playwright screenshots of every page at both widths; fix
  overflow, sidebar behaviour, table horizontal scroll (`DataTable.module.css`).
- **Tier**: just do it via `ui-design-system`'s verification loop.

### 5.2 Bespoke polish on the untouched pages

- **What**: Login, Loggers, Admin Users, Settings, Certificate lookup. Apply
  the `DESIGN.md` patterns (glass panels, accent quartet, mono for numbers).
  Contrast-check every new colour use with the same ratio computation used
  on 2026-09-16; nothing below 4.5:1 for text.
- **Needs user**: yes, to confirm these five pages are the whole list and
  whether Login should get the brand mark treatment.
- **Tier**: just do it per page; no spec.

### 5.3 Fold the redesign into `docs/ARCHITECTURE.md`

- One paragraph pointing at `DESIGN.md` and `tokens.css` as the source of
  truth for the theme.
- **Tier**: just do it.

---

## Phase 6: carried over from the 2026-08-17 UI overhaul plan

This is real prior planning work, not something re-derived in this session
— it is the remaining content of `docs/superpowers/plans/2026-08-17-calibration-ui-overhaul.md`
(unmerged, still on `origin/claude/calibration-ui-overhaul-plan-6uo67q`) that
has no equivalent anywhere in Phases 0-5. It was **not part of this
session's priority-setting** and should not be treated as equally urgent as
Phases 0-5 without the user explicitly prioritizing it. Each item below is a
one-line pointer into the old plan's detail, not a rewrite.

- **Archive/restore semantics for calibration runs** — see the old plan's
  "§2 Calibrations page — archive a run". Today `DELETE /api/runs/{run_id}`
  (`runs.py:317`) is a hard delete that unlinks certificates and reference
  files from disk; the old plan redesigns it as a soft archive (new
  `archived_at`/`archived_by`/`archive_reason` columns, a restore endpoint,
  archived runs excluded from working views but still resolvable by
  certificate number) with hard deletion demoted to an explicit CLI-only
  purge command.
- **Admin audit trail** — see the old plan's "§6 Admin audit trail". Audit
  rows are already written (`audit.py`) but the only reader is
  `GET /api/runs/{run_id}/audit` (`runs.py:564`), scoped to one run; the old
  plan adds a paginated `GET /api/audit` plus an Admin → Audit page. Notes
  `audit_log.run_id` is deliberately not a foreign key
  (`db/models/audit_log.py:21`) so entries survive a CLI purge.
- **New Calibration page UX fixes (date defaults, draft persistence)** —
  see the old plan's "§3a" and "§3b". Root causes: setpoint windows default
  to `1900-01-01`/`2999-12-31` sentinels (`NewCalibrationPage.tsx:11-15`),
  and there is no persistence anywhere in `apps/web/src` (confirmed by grep),
  so navigating away loses the whole form. The old plan defaults windows to
  today and adds a versioned, debounced `localStorage` draft with a discard
  banner.
- **Overview page overhaul** — see the old plan's "§1 Overview page — UI
  overhaul". Reworks the KPI row to be clickable, adds an "attention rail"
  for failed/processing runs, and includes one backend change (drop the
  30-day cutoff on the recent-runs rail specifically, keep it for the
  30-day stats).
- **Loggers page improvements** — see the old plan's "§5 Loggers page —
  completeness, freshness, sorting". Not in the task's original enumeration,
  but has no equivalent in Phases 0-5 either, so it's tracked here rather
  than dropped: server-side sort/pagination and natural (numeric-aware)
  ordering for `list_loggers` (`loggers.py:38` has a hardcoded 200-row cap
  and no sort parameter today), serial normalisation to stop duplicate
  logger rows, and a reconciliation CLI to backfill missing `loggers` rows.
- **PDF export** — see the old plan's "§3e Word or PDF certificate
  download". Certificates are `.docx`-only today; the old plan's approach is
  LibreOffice + `fonts-noto-cjk` in the API container (Word-native
  conversion isn't available since the API runs in a Linux container on the
  Windows host), starting with a fidelity spike against the real Japanese
  certificate template before building the conversion endpoints.

---

## Parallel context: Windows PC migration (not part of this plan)

Tracked in `docs/MIGRATION.md` and GitHub issues #2/#3 (done), #4 (waiting
on collaborator), plus 8 open logistics questions. Only these items of this
plan touch it:

- 0.1 (`0008` rename must be on `main` and the production `alembic_version`
  row checked before the move).
- 3.1 and 3.2 (setup script and password generator used during the move).
- 3.4's option (b) depends on the migration's internet-access answer.

---

## Open questions — resolved 2026-09-16

All 10 decided before starting execution. Recorded here so a future session
doesn't need to re-ask.

1. **Process (blocked 1.8) — DECIDED: PR-per-change for `apps/`.** Branch
   protection requires green CI before merge for anything under `apps/`;
   docs/records (`HANDOFF.md`, `PROGRESS.md`, `logs/`) keep pushing directly
   via a path filter.
2. **Lint debt (blocked 1.1) — DECIDED: fix now.** Pay down all 22 ruff
   errors before moving on, not `continue-on-error`.
3. **Agent config files (blocked 0.3) — DECIDED: commit them.** `CLAUDE.md`,
   `AGENTS.md`, `.claude/skills/` go into the repo as-is.
4. **Certificate numbering rule (blocked 2.1) — DECIDED: unique among
   valid/current certificates only.** A legitimate re-issue may reuse a
   `cert_no` once the original is superseded/invalid — matches the existing
   cert re-issue precedent in `docs/CHANGE_LOG.md`. The partial unique index
   in 2.1's fix shape should enforce uniqueness scoped to non-superseded,
   non-invalid results, not a global constraint.
5. **Historical dates (blocked the data-migration half of 2.3) — DECIDED:
   yes, all JST, blanket -9h correction is safe.** Proceed with the one-off
   migration `0010` shifting existing `testing_start`/`testing_end` values;
   still double-check `scripts/migrate_historical.py`'s own writes before
   applying, per 2.3's fix shape, in case that one path already wrote UTC.
6. **Stale certificates (shapes 2.2) — DECIDED: flag, don't block.** Show
   the "certificate out of date, regenerate" warning (via `StatusPill`'s
   invalid style) but allow download of the existing file while it's
   pending regeneration.
7. **Upcoming page (blocked Phase 4) — DECIDED: investigate directly, and
   the user gave one concrete symptom:** it shows **no upcoming calibrations
   at all**, not a wrong subset — a complete-empty-result bug, not a
   filtering edge case. Load the verified production dump (from GitHub issue
   #2) locally and reproduce before touching code.
8. **Staging (blocked 3.3) — DECIDED: it IS used.** Do not delete
   `docker-compose.staging.yml`; give it its own `.env.staging` and a
   separate Postgres volume so it stops sharing production credentials.
9. **Deploy path (blocked 3.4) — DECIDED: delete the dormant auto-deploy.**
   Remove `deploy.yml` and `deploy.ps1`; the documented manual rebuild in
   `docs/DEPLOYMENT.md` remains the official path. No GHCR investment.
10. **Design polish scope (blocked 5.2) — DECIDED: yes to both.** Login,
    Loggers, Admin Users, Settings, and Certificate lookup are the full
    Phase 5 list, and Login gets the same brand mark + accent-quartet
    treatment as the sidebar.
