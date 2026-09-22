# Handoff

## State
`main` is at `53267f8`, clean. Zero open PRs, zero unmerged feature
branches other than the still-unclaimed `origin/add-otel-instrumentation`.
**Not yet pushed to origin.**

**The Direction C dense redesign is merged into `main` and live-tested.**
All 12 plan tasks complete and reviewed clean (see
[logs/DAILY-2026-09-21.md](logs/DAILY-2026-09-21.md)); a final whole-branch
review's 6 Important + 4 Minor findings were fixed in one consolidated
pass and re-reviewed clean. `tsc`, `vitest` (15/15), and `vite build` are
green. The local Docker `web` image was rebuilt from the merged code and
the app was driven live with Playwright (login desktop+mobile, Overview,
History, Run Detail table+cards, ConfirmDialog) — all confirmed correct
(see [logs/DAILY-2026-09-22.md](logs/DAILY-2026-09-22.md)). **One parked,
non-blocking item remains**: `DESIGN.md` still describes `ConfirmDialog` as
losing its border entirely, but the shipped CSS deliberately keeps a 2px
border — a one-line doc/code mismatch, not a functional defect.

**Live testing today surfaced real, pre-existing bugs unrelated to the
redesign** (full detail in
[logs/DAILY-2026-09-22.md](logs/DAILY-2026-09-22.md)), now being triaged
with the user:
1. **Fixed operationally**: DB migration `0008_add_failure_reason` had
   never actually applied to this container's Postgres despite
   `alembic_version` implying otherwise — every request touching
   `logger_results` (Overview/History/Run Detail) 500'd. Ran `alembic
   upgrade head` directly against the container to fix; not a code change.
2. **Fixed and committed** (`53267f8`): the existing e2e suite
   (`apps/web/e2e/*.spec.ts`) had an ambiguous `getByLabel(/password/i)`
   locator matching both the password field and the "Show password"
   toggle, failing all 9 specs before login could even run.
3. **Not yet fixed**, found today, awaiting triage:
   - `apps/api/ite_api/cli.py`'s `create-admin` silently no-ops under
     `python -m ite_api.cli` (no `__main__` guard) — the real entry point
     is the installed `ite-api` console script.
   - Backend `EmailStr` validation rejects reserved TLDs (`.local`,
     `.invalid`), including the e2e suite's own baked-in seed credential
     `boss@ite.local`.
   - `admin.spec.ts`: heading assertion (`/users/i`) doesn't match the
     real "User Management" heading.
   - `admin.spec.ts`: invite-user test never opens the invite form.
   - `history.spec.ts`: empty-state text assertion (`/no runs/i`) doesn't
     match the real "No calibration runs found."
   - `history.spec.ts`: expects a Table/Cards toggle on History that only
     exists on Run Detail.

**The local Docker dev stack is still running** (rebuilt `web` image
today), still with the real verified production data loaded from GH issue
#2's 2026-09-15 snapshot. Not torn down — the user hasn't said either way.

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
possibly collaborator Reiko Takahashi's own machine. Potentially directly
relevant to the pending Windows PC migration.

The implementation plan
(`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`)
remains the authoritative source for what's next on the engineering side.

## Next steps
- (since 2026-09-22) **Triage and fix the 5 not-yet-fixed bugs listed
  above** (CLI `__main__` guard, reserved-TLD email validation, 3 e2e
  spec/app mismatches) — in progress with the user right now.
- (since 2026-09-22) **Push the merged `main` to origin** (currently local
  only) once the user confirms.
- (since 2026-09-22) **Fix the parked DESIGN.md/ConfirmDialog border
  mismatch** — one line, whenever someone next touches `DESIGN.md` (either
  remove ConfirmDialog from the "loses its border" example list, or add an
  explicit exception clause with the overlay-visibility reasoning).
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
- (since 2026-09-16) When ready to continue: Phase 1 of the implementation
  plan (lint → app-boots-outside-Docker → fixture collision → CI green →
  branch protection/secrets-scan/style-check/Dependabot — lint count has
  drifted, 22→23, re-check before starting), or the fully-scoped Upcoming-bug
  fix (Phase 4) — either can go first.
- (since 2026-09-16) Figure out where `add-otel-instrumentation` came from
  before deciding whether to review or merge it.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access — the
  Windows-session finding above might resolve some of these directly.

## Open questions
- (since 2026-09-22) Push the merged redesign to origin now, or wait for
  the user to review it locally first? Not yet answered.
- (since 2026-09-22) Should migration `0008` failing to apply silently (no
  traceback in `docker logs`) be investigated as a deeper reliability
  issue, or was this a one-off from how the container was originally
  brought up? Not yet answered.
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
  containers `ite-calibration-{postgres,api,web,edge}-1`), `web` image
  rebuilt today from merged `main`, `api`/`postgres` migrated to head.
  Real verified production dump still loaded.
- No open PRs; `add-otel-instrumentation` still unclaimed.
- Merged `main` (`53267f8`) is local-only, not yet pushed to origin.
- Worktree/branch from the redesign already cleaned up (merged and
  removed) — no stale worktrees remain.
- Currently analyzing the 5 not-yet-fixed bugs found during today's live
  testing, with the user, one at a time.
