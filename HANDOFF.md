# Handoff

## State
`main` is at `41953c6`, clean. Pushed to origin. Zero open PRs, zero
unmerged feature branches other than the still-unclaimed
`origin/add-otel-instrumentation`.

**The Direction C dense redesign is merged, live-tested, and its e2e
suite now runs in CI.** All 12 plan tasks complete and reviewed clean
(see [logs/DAILY-2026-09-21.md](logs/DAILY-2026-09-21.md)); a final
whole-branch review's findings were fixed and re-reviewed clean. `tsc`,
`vitest` (15/15), and `vite build` are green. **One parked, non-blocking
item remains**: `DESIGN.md` still describes `ConfirmDialog` as losing its
border entirely, but the shipped CSS deliberately keeps a 2px border — a
one-line doc/code mismatch, not a functional defect.

**2026-09-22: live testing found 7 real, pre-existing bugs, all now fixed
and verified; a root-cause pass then found and fixed the systemic gaps
that let them ship undetected.** Full detail in
[logs/DAILY-2026-09-22.md](logs/DAILY-2026-09-22.md). Summary:

**Bugs found and fixed:**
1. DB migration `0008_add_failure_reason` never actually applied (fixed
   operationally that day, then root-caused and hardened — see below).
2. e2e suite's ambiguous `getByLabel(/password/i)` locator (`53267f8`).
3. `admin.spec.ts` — reserved-TLD seed email, wrong heading regex, invite
   test never opening the form (`defbb01`, 3/3 pass).
4. `history.spec.ts` — reserved-TLD seed email, wrong empty-state text, a
   Table/Cards toggle test for a feature that doesn't exist on History,
   deleted (`b5d2ea9`, 2/2 pass).
5. `auth.spec.ts`/`loggers.spec.ts` — same reserved-TLD seed email
   (`5949f23`, 3/3 pass).
6. CLI `create-admin` silently no-op'd under `python -m ite_api.cli` —
   missing `__main__` guard (`63c76ed`).

**Root-cause finding**: every one of the above lives exactly where
automated verification stopped short of the real, live path, and where
existing automation failed silently instead of loudly (CI never ran e2e
at all; `test_cli.py` used `CliRunner`, bypassing the `__main__` bug
class; the migration step didn't check it actually succeeded). Also
found while investigating: **a second GitHub Actions workflow
(`deploy.yml`) auto-deploys `main` to a self-hosted Windows runner on
every push, with zero dependency on the CI job passing — and currently
has 0 registered runners**, so every push since 2026-09-16 has queued a
deploy job that silently sits for 24h and auto-cancels. No actual
production deploy has happened via this path in 6 days. Not yet
investigated further — see Open Questions.

**Fixes from the root-cause pass** (6 parallel subagents, all verified,
all file-disjoint):
- `apps/api/ite_api/routes/runs.py`'s 18 import-order lint errors fixed
  — root cause was one misplaced `_log = logging.getLogger(...)` line
  sitting inside the import block (`45985a6`).
- 5 more scattered lint errors across `overview.py`/`test_engine.py`/
  `test_auth.py` fixed (`fd0fea6`).
- **`click`/`typer` version drift** breaking `--help` on every CLI
  invocation: pinned `click<8.2.0`, added a real subprocess-level smoke
  test (`test_cli_smoke.py`) since the existing test used `CliRunner` and
  bypassed this bug class (`b3eb0d4`, full suite 86/86 pass).
- **`create-admin` had no email validation**, while login used Pydantic
  `EmailStr` — a CLI-created admin could be permanently unable to log in.
  Fixed with `TypeAdapter(EmailStr)` validation mirroring the existing
  password-length check; `test_cli.py` updated (the email domain it used
  was itself unusable) plus a new rejection test added (`ac6ce47`, 3/3
  pass, live-verified against the running container).
- **Migration startup hardened**: moved the migration step out of
  `main.py`'s per-worker `lifespan` (which raced across the app's 2
  uvicorn workers — this was the actual root cause of bug #1 above) into
  a new `docker-entrypoint.sh`/`ite_api/migrate.py` that runs once before
  any worker forks, and made a stale-schema mismatch **fatal** instead of
  silent. Verified by reproducing the exact stuck-at-0007 symptom against
  a disposable Postgres and confirming it now raises (`3a5c373`, 86/86
  pass).
- **e2e suite wired into CI** (`102dea3`): a new `e2e` job in
  `.github/workflows/ci.yml`, gated on the `web` job passing first, runs
  Postgres as a GHA service container, builds and runs the real API
  Docker image (needed because `migrate.py` resolves `/app/alembic.ini`,
  only valid inside the built image), seeds the admin, serves the
  frontend via `npm run dev` (proxy support), and runs the full
  Playwright suite with real health-check polling. Dry-run verified twice
  locally, including once against only the committed Dockerfile/migrate
  path from a genuinely empty DB — 8/8 specs passed in ~5.5s. Two
  documented-but-unverified assumptions: GHA's `--network host` pattern
  (standard on Linux runners, not literally exercised outside a real GHA
  run) and cross-step process backgrounding inside real Actions infra.

**Combined verification after all 6 fixes**: `ruff check` on `apps/api`
100% clean, full backend suite 86/86 pass, CI workflow YAML valid, zero
dangling Docker containers/networks from any agent's dry-runs, zero test
accounts remaining in the real database.

**Not yet fixed/decided**:
- The deploy-runner-offline finding above — needs investigation (was it
  deregistered? never connected? tied to the Windows-session mystery
  below?).
- P0.4 from the original analysis (alerting when a deploy job sits
  unclaimed) — held, needs the user's call on a notification channel
  (no Slack/email integration configured here).
- The live `ite-calibration-api-1` container was docker-cp'd twice today
  (the `__main__` guard, then the email-validation fix) for verification
  — it now matches committed source for `cli.py`, but its `main.py`/image
  layer do NOT yet reflect the migration-hardening fix (`3a5c373`, which
  changes the Dockerfile/entrypoint) — that needs a real image rebuild
  (`docker compose build api && up -d api`) to take effect on the running
  dev stack, same as was done for `web` earlier today.

**The local Docker dev stack is still running**, real verified production
data still loaded from GH issue #2's 2026-09-15 snapshot. Not torn down —
the user hasn't said either way.

**New finding this session, not yet acted on**: audited the loaded historical
calibration data against the exact signature of the `matcher.py`
fabricated-reference-reading bug fixed on 2026-09-16 (`ref_c == target_c` in
`logger_results.per_setpoint` — a real reference instrument essentially never
reads exactly on the nominal setpoint). It's live in the data, not just a
theoretical risk:
- 428 of 1,125 setpoint records (38%) across 6 of 13 runs carry the
  fabrication signature, all at the ±40°C / 5°C setpoints.
- 396 of those are "pass" verdicts partly computed from a fake reading (32
  are "fail" and stay trustworthy — a fake perfect-match reading biases
  toward pass, so a fail despite it is real).
- Affected runs (all `status=complete`, June–August 2026): "Batch 1 · March
  4 2026" (104 results), "Batch 2 · March 12 2026" (110), "Batch 3 · April
  14 2026" (1), "July 8th 122 loggers" (17), "8th July 122 loggers 2nd"
  (122), "14th August 2026 74 loggers" (74).
- These are real production runs that predate the fix, so up to 396 "pass"
  verdicts may not reflect a genuine in-tolerance reading — potential
  wrong-certificate exposure for a calibration company.
- **Recoverable**: original reference CSVs for all 6 runs still exist in
  `run_reference_files` / on disk, so they can be reprocessed through the
  now-fixed `matcher.py` to get real verdicts before deciding what (if
  anything) needs correcting or re-issuing.

**Still-open finding from 2026-09-18's earlier check-in, not yet resolved**:
this repo's `.claude/settings.json` (checked into git) has accumulated
permission grants for PowerShell/Windows commands — `Get-CimInstance`
hardware queries (CPU/GPU/disk/OS), a WSL install flow, `docker
logs`/`docker exec` against `ite-calibration-api-1`, a `C:\Calibration`
path, and a reference to `info_ithrue.com` (matching the
`takahashi@ithrue.com` engineer account in the real production DB). Strong
evidence a separate Claude Code session has been running directly on a
Windows machine tied to this project — possibly the actual production PC,
possibly collaborator Reiko Takahashi's own machine. **Now possibly linked
to the deploy-runner-offline finding above** — worth checking whether that
machine is meant to be the self-hosted GitHub Actions runner and simply
isn't registered/running as one right now.

The implementation plan
(`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`)
remains the authoritative source for what's next on the engineering side.

## Next steps
- (since 2026-09-22) **Rebuild the local `api` container** so the running
  dev stack reflects the migration-hardening fix (`docker compose build
  api && up -d api` from `infra/`).
- (since 2026-09-22) **Investigate the deploy-runner-offline finding** —
  is a self-hosted runner supposed to be registered? Tied to the
  Windows-session mystery below?
- (since 2026-09-22) **Decide on a notification channel** for deploy-queue
  alerting (P0.4 from the original analysis), then implement it.
- (since 2026-09-22) **Fix the parked DESIGN.md/ConfirmDialog border
  mismatch** — one line, whenever someone next touches `DESIGN.md`.
- (since 2026-09-18) **Decide how to handle the 396 questionable "pass"
  verdicts** — reprocess the 6 affected runs' reference files through the
  fixed `matcher.py` to see which actually hold up, then decide whether any
  certificates need correction or re-issue. This needs the user's call
  before any code touches production data.
- (since 2026-09-18) **Ask the user about the Windows-session evidence in
  `.claude/settings.json`** — is this their own session on another machine,
  the collaborator's, or something to investigate? Could shortcut several
  of `docs/MIGRATION.md`'s open logistics questions.
- (since 2026-09-16) Ask whether to tear down the local Docker stack
  (running with real data loaded) once the user is done testing/auditing.
- (since 2026-09-16) When ready to continue: the fully-scoped Upcoming-bug
  fix (Phase 4 of the implementation plan) — Phase 1 (lint → CI green) is
  now done as of today.
- (since 2026-09-16) Figure out where `add-otel-instrumentation` came from
  before deciding whether to review or merge it.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access — the
  Windows-session finding above might resolve some of these directly.

## Open questions
- (since 2026-09-22) Is the deploy-runner-offline finding related to the
  Windows-session mystery? Not yet answered.
- (since 2026-09-22) What notification channel for deploy-queue alerting?
  Not yet answered.
- (since 2026-09-18) Do the 396 fabrication-tainted "pass" verdicts need
  correction, customer notification, or certificate re-issue? Blocked on
  reprocessing the 6 runs through the fixed matcher first.
- (since 2026-09-18) What is the Claude Code session evidenced in
  `.claude/settings.json` running on a Windows machine? Not yet answered.
- (since 2026-09-16) Leave the local Docker stack (real data loaded)
  running or tear it down? Not yet answered.
- (since 2026-09-15) See `docs/MIGRATION.md`'s own open-questions section
  (unrelated workstream).

## In flight
- **Local Docker dev stack running** on this Mac (`infra/` compose,
  containers `ite-calibration-{postgres,api,web,edge}-1`). `web` image
  rebuilt from merged `main`. `api` container's `cli.py` was docker-cp'd
  twice for live verification (now matches committed source) but its
  `main.py`/Dockerfile do NOT yet reflect the migration-hardening fix —
  needs a real rebuild (see Next steps). Real verified production dump
  still loaded.
- No open PRs; `add-otel-instrumentation` still unclaimed.
- No stale worktrees or branches — already cleaned up.
- No test accounts remain in the DB — all cleaned up after verification.
- CI's `e2e` job (`102dea3`) has never actually run on real GitHub Actions
  infra yet — only dry-run verified locally. Worth watching the first real
  CI run on the next push/PR to confirm it behaves as designed.
