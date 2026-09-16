# Handoff

## State
`main` is at `051c9fd`, clean. PRs #5 (migration fix) and #6 (redesign) are
merged and were live-tested on a fresh Docker stack. **PR #7 is open,
unmerged** — a thermo-nuclear code-quality review (user-invoked, explicit
skill) of this session's app-code diff found 3 duplication issues (repeated
`LoggerResult` construction, hand-threaded status flags instead of deriving
status from data, a duplicated verdict predicate in the frontend); all 3
fixed via TDD with zero behavior change (same 33 backend + 15 frontend
tests pass before/after). Awaiting review per the session's adopted
PR-per-change policy.

**A local Docker dev stack is currently running** on this Mac
(`infra/docker-compose.yml`) with the **real, verified production database**
loaded — not test data. This was requested by the user after they noticed
historical data missing on `localhost` (turned out to be fake seed data I'd
put in for redesign verification, deliberately wiped afterward — clarified
and resolved). The loaded data is a point-in-time snapshot from 2026-09-15
(GH issue #2's verified dump) and will drift from real production over time
— don't treat it as live. Real accounts are in it
(`biswas.sub65@icebattery.jp` admin, `takahashi@ithrue.com` engineer); their
real production passwords are what's needed to log in, nothing I can reset.

The implementation plan
(`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`)
remains the authoritative source for what's next — all open questions
resolved, Upcoming bug fully scoped, Phase 6 tracking lower-priority
carried-over scope.

**An unclaimed branch still needs the user's attention, not touched**:
`origin/add-otel-instrumentation` — user said "I don't know about that
branch." Do not merge, review, or build on it until they identify its
origin.

## Next steps
- (since 2026-09-16) **Review and merge PR #7** (the cleanup refactor).
- (since 2026-09-16) Ask the user whether to tear down the local Docker
  stack (currently running with real data loaded) or leave it — they hadn't
  said either way as of this handoff.
- (since 2026-09-16) Start Phase 1 of the implementation plan: pay down the
  22 ruff lint errors → make the app boot outside Docker → fix the
  `conftest.py`/Alembic test-fixture collision → confirm CI green → branch
  protection + secrets-scan + style-check + Dependabot.
- (since 2026-09-16) Alternatively: the Upcoming-bug fix (Phase 4) is fully
  scoped and ready to implement independently of Phase 1.
- (since 2026-09-16) Figure out where `add-otel-instrumentation` came from
  before deciding whether to review or merge it.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access.

## Open questions
- (since 2026-09-16) Leave the local Docker stack (real data loaded) running
  or tear it down? Not yet answered.
- (since 2026-09-15) See `docs/MIGRATION.md`'s own open-questions section
  (unrelated workstream).

## In flight
- **Local Docker dev stack is running** on this Mac (`infra/` compose,
  containers `ite-calibration-{postgres,api,web,edge}-1`) with the real
  verified production dump loaded — not test data, not torn down as of this
  handoff.
- Branch `refactor/cleanup-duplication-thermonuclear-review` — pushed, PR #7
  open against `main`, not merged.
