# Handoff

## State
`main` is at `276bd26` (config files + implementation plan committed and
pushed). Two feature branches are rebased on top of it and **each has an
independent subagent verifying it and opening a PR right now** (not merged —
see In flight): `fix/migration-0008-revision-length` (the critical fresh-DB
migration bootstrap fix) and `feat/ite-brand-redesign` (the full ITE brand
redesign + WCAG contrast fix). The implementation plan at
`docs/superpowers/plans/2026-09-16-post-redesign-implementation-plan.md`
has all 10 of its original open questions resolved and recorded in its own
"resolved" section — read that before re-asking any of them.

**Mid-execution, a real discovery changed the plan**: the "Upcoming
calibrations shows nothing" bug the user reported has a confirmed root
cause, found in an unmerged prior planning doc
(`origin/claude/calibration-ui-overhaul-plan-6uo67q`, dated 2026-08-17) —
`Logger.next_due_at` is never written by any automated code path, so the
column is NULL fleet-wide. That same doc also covers cert_no uniqueness
(overlaps this session's Phase 2.1) and other unscoped work. A second
unmerged branch, `origin/add-otel-instrumentation` (committed *today* under
the user's own identity), explains the "opentelemetry undeclared dependency"
item from earlier in the day — it's not a bug on `main`, just unmerged.
**Two questions were posed to the user about these and are unanswered as of
this handoff** — see Open questions.

## Next steps
- (since 2026-09-16) Check on the two in-flight subagents (migration-fix PR,
  redesign PR) — they were dispatched with `isolation: worktree`, each
  independently re-verifying (contrast ratios recomputed from scratch,
  fresh Postgres migration run, full test/build) before opening its PR.
  Review both PRs once open; do not self-merge without a gap, per this
  session's own dev-pipeline findings about direct-push habits.
- (since 2026-09-16) Once Phase 0 lands: re-run `/handoff` to fold the PR
  outcomes in, then move to Phase 1 (lint fix → app-boots-outside-Docker →
  fixture collision → CI green → branch protection), per the plan doc.
- (since 2026-09-16) Reconcile the old UI-overhaul plan
  (`claude/calibration-ui-overhaul-plan-6uo67q`) into the current plan doc
  once the user answers whether to — the Upcoming fix and cert_no design
  already exist there in detail, don't re-derive them.
- (since 2026-09-15) Windows PC migration (`docs/MIGRATION.md`): GH issue #4
  (certificate-volume dry-run) still awaiting the collaborator; 8 logistics
  questions remain, most load-bearing is new-PC internet access.

## Open questions
- (since 2026-09-16) **Reconcile plans?** Merge the old UI-overhaul plan's
  Upcoming/cert_no design into today's implementation plan, or keep them
  separate? Asked, not yet answered.
- (since 2026-09-16) **`add-otel-instrumentation` branch** — is this the
  user's own in-progress work (leave alone), or ready for review/merge?
  Asked, not yet answered.
- (since 2026-09-15) See `docs/MIGRATION.md`'s own open-questions section
  (unrelated workstream).

## In flight
- Branch `fix/migration-0008-revision-length` — 1 commit, rebased on
  `main`, being independently verified + PR'd by a worktree-isolated
  subagent. Not pushed by the time of this handoff (agent does that itself
  once it independently confirms the fix).
- Branch `feat/ite-brand-redesign` — 1 commit, rebased on `main`, same
  treatment, separate subagent.
- A stray `.claude/worktrees/` directory may appear/disappear as these
  agents run — that's the harness's own workspace for them, not something
  to commit or clean up manually.
