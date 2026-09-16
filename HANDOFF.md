# Handoff

## State
`main` is at `3b62e3e`, clean, pushed. The implementation plan
(`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`)
is now the single authoritative source for what's next — it has all 10
original open questions resolved, plus the reconciled "Upcoming
calibrations" fix design (root cause: `Logger.next_due_at` is never written
by any automated code path, confirmed and fully designed, not just
diagnosed) and a new Phase 6 tracking carried-over scope from an older
unmerged plan (archive/restore, admin audit trail, New Calibration UX,
Overview overhaul, Loggers page, PDF export — lower priority, not yet
scheduled).

**Two PRs are open and independently verified, awaiting user review/merge**:
- [PR #5](https://github.com/ib-biswas65/calibration/pull/5) — the critical
  migration-0008 fix (fresh-DB bootstrap bug). Re-verified from scratch
  against a real Postgres by the agent that opened it: all 8 migrations
  apply in one transaction, all 10 tables present, `alembic_version` correct,
  29/29 tests pass.
- [PR #6](https://github.com/ib-biswas65/calibration/pull/6) — the ITE brand
  redesign + WCAG contrast fix. Every contrast ratio independently
  recomputed (not trusted from the original claim): 4.34–17.02:1, all pass.
  Two non-blocking nits noted in the PR body (dead CSS in
  `AdminUsersPage.module.css`, a `DESIGN.md`/token-name mismatch).

This is the first work done under the session's newly-adopted PR-per-change
policy for `apps/` — neither PR was self-merged, both are waiting on a real
review after a gap, per the `dev-pipeline` skill's own guidance.

**An unclaimed branch exists and must NOT be touched without the user's
say-so**: `origin/add-otel-instrumentation`, committed today under the
user's own git identity (adds opt-in OpenTelemetry tracing), but the user
said "I don't know about that branch" when asked. Do not merge, review, or
build on it until the user identifies where it came from.

## Next steps
- (since 2026-09-16) **Review and merge PR #5 first** (it's small, critical,
  and next week's Windows PC migration depends on it being on `main` before
  then).
- (since 2026-09-16) **Review and merge PR #6** — read its two noted nits
  before merging; neither blocks, but confirm you agree.
- (since 2026-09-16) Once both land, start Phase 1 of the implementation
  plan (pay down the 22 ruff lint errors → make the app boot outside Docker
  → fix the `conftest.py`/Alembic test collision → confirm CI green → branch
  protection + secrets-scan + style-check + Dependabot). User already
  decided: fix lint now, don't defer.
- (since 2026-09-16) The Upcoming-bug fix (Phase 4) is now fully scoped and
  ready to implement — no longer blocked on investigation.
- (since 2026-09-16) Figure out where `add-otel-instrumentation` came from
  (check other Claude sessions/devices) before deciding whether to review
  or merge it.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access.

## Open questions
- (since 2026-09-16) None blocking — both prior open questions (plan
  reconciliation, otel branch) were answered this session. Next real
  decision point is simply "review and merge PR #5/#6."
- (since 2026-09-15) See `docs/MIGRATION.md`'s own open-questions section
  (unrelated workstream).

## In flight
(none — working tree clean, `main` matches `origin/main`, no worktree
agents currently running)
