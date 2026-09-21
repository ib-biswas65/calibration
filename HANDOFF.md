# Handoff

## State
`main` is at `ba80c48`, clean, matches origin. Zero open PRs, zero unmerged
feature branches other than the still-unclaimed `origin/add-otel-instrumentation`.

**The local Docker dev stack is still running** (2+ days), still with the
real verified production data loaded from GH issue #2's 2026-09-15 snapshot.
Not torn down — the user hasn't said either way.

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
  containers `ite-calibration-{postgres,api,web,edge}-1`, up 2+ days) with
  the real verified production dump loaded.
- No open PRs, no unmerged feature branches (besides the untouched
  `add-otel-instrumentation`), no worktree agents running, no code changed
  this session.
