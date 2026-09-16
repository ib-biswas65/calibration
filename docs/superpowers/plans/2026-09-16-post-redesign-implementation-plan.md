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
   timing side-channel).
4. **Phase 3**: ops/deploy fixes. Two of these (`setup-windows.ps1`,
   `AGENT-SETUP.md` password generator) touch the migration path, so they
   should be done **before next week's PC move**, and can be pulled forward
   ahead of Phase 2 if the move date is fixed.
5. **Phase 4**: reproduce and scope the "Upcoming calibrations" report. This
   is blocked on the user, so ask the question now (see "Open questions") and
   slot the work wherever the answer arrives.
6. **Phase 5**: remaining design polish and mobile-width verification.

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
  2. Decide the rule: unique across all results, or unique among
     non-invalid/non-superseded results (a re-run of the same loggers may
     legitimately re-issue the same number, see `docs/CHANGE_LOG.md`'s cert
     re-issue entry).
  3. Migration `0009` adding the partial unique index matching the rule.
  4. `find_by_cert_no` returns 409/ambiguous if more than one match instead of
     silently `.first()`.
  5. Guard at run creation: refuse a `start_cert_no` whose range collides.
- **Needs user**: yes, step 2 (what is the intended uniqueness rule, and
  what to do with any existing duplicates).
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

## Phase 4: "Upcoming calibrations and other features aren't working properly"

- **Where**: `apps/web/src/pages/UpcomingPage.tsx`. There is no `upcoming`
  route in `apps/api/ite_api/routes/`; the page derives its list client-side
  from another endpoint (loggers/runs). Structurally it matched its API on a
  read-through, so the failure is either data (e.g. next-due dates missing
  or in the wrong timezone, see 2.3), a filter that excludes everything, or
  a different page the user means by "other features".
- **Blocked on the user**: need (1) the exact page(s), (2) what they expected
  to see vs what they saw, (3) a logger or run they expected to appear, (4)
  browser and whether it is the production PC. Alternatively, spin up the
  stack with a copy of the production dump (collaborator's issue #2 dump is
  verified) and click through every page; that is the fastest way to turn
  "not working properly" into concrete bugs.
- **Tier**: `bug-resolution` pipeline once reproduced. Until then it is not
  schedulable; do not guess at fixes.

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
