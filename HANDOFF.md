# Handoff

## State
`main` is at `eba071a`, clean, pushed. All 3 PRs from 2026-09-16 are merged
(migration fix, brand redesign + contrast fix, thermo-nuclear cleanup
refactor) — zero open PRs. This check-in found and closed a real gap: a
"format-on-edit" whitespace-only reformatting commit had been made locally
on this machine by a different session on 2026-09-16 and never pushed —
verified safe (33/33 backend tests, pure formatting, no logic change) and
pushed.

**The local Docker dev stack is still running** (47 hours), still with the
real verified production data loaded from GH issue #2's 2026-09-15
snapshot. Not torn down — the user hasn't said either way.

**New finding, not investigated, needs the user's input**: this repo's
`.claude/settings.json` (checked into git) has accumulated permission
grants for PowerShell/Windows commands — `Get-CimInstance` hardware queries
(CPU/GPU/disk/OS), a WSL install flow, `docker logs`/`docker exec` against
`ite-calibration-api-1`, a `C:\Calibration` path, and a reference to
`info_ithrue.com` (matching the `takahashi@ithrue.com` engineer account in
the real production DB). This is strong evidence a separate Claude Code
session has been running directly on a Windows machine tied to this project
— possibly the actual production PC, possibly collaborator Reiko Takahashi's
own machine. **Potentially directly relevant to the pending Windows PC
migration** (some of those hardware queries could already answer open
migration questions about the new PC's specs/internet access) — worth
asking the user about before the migration proceeds further.

The implementation plan
(`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`)
remains the authoritative source for what's next. `origin/add-otel-instrumentation`
remains untouched/unclaimed, unresolved.

## Next steps
- (since 2026-09-18) **Ask the user about the Windows-session evidence in
  `.claude/settings.json`** — is this their own session on another machine,
  the collaborator's, or something to investigate? This could shortcut
  several of `docs/MIGRATION.md`'s open logistics questions if it's a
  session that's already been probing the target hardware.
- (since 2026-09-16) Ask whether to tear down the local Docker stack
  (running 47+ hours now with real data loaded) once the user is done
  testing.
- (since 2026-09-16) When ready to continue: Phase 1 of the implementation
  plan (lint → app-boots-outside-Docker → fixture collision → CI green →
  branch protection/secrets-scan/style-check/Dependabot — lint count has
  drifted slightly, 22→23, re-check before starting), or the fully-scoped
  Upcoming-bug fix (Phase 4) — either can go first.
- (since 2026-09-16) Figure out where `add-otel-instrumentation` came from
  before deciding whether to review or merge it.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access — the
  Windows-session finding above might resolve some of these directly.

## Open questions
- (since 2026-09-18) What is the Claude Code session evidenced in
  `.claude/settings.json` running on a Windows machine? Not yet answered.
- (since 2026-09-16) Leave the local Docker stack (real data loaded)
  running or tear it down? Not yet answered.
- (since 2026-09-15) See `docs/MIGRATION.md`'s own open-questions section
  (unrelated workstream).

## In flight
- **Local Docker dev stack running** on this Mac (`infra/` compose,
  containers `ite-calibration-{postgres,api,web,edge}-1`, up 47+ hours)
  with the real verified production dump loaded.
- No open PRs, no unmerged feature branches, no worktree agents running.
