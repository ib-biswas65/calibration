# Handoff

## State
Repo is clean, HEAD `4911ab5`, pushed to `origin/main`. The critical
certificate-correctness bug (fabricated reference readings feeding pass/fail
verdicts) is fixed and shipped with a full TDD validation feature (invalid
results, partial run status) — see `docs/ARCHITECTURE.md` for the app shape
and this session's commit message for the fix's detail. Migration planning
for the new Windows PC (`docs/MIGRATION.md`) is separately in progress — DB
dry-run already validated (GitHub issues #2/#3), certificate-volume dry-run
(#4) still pending a collaborator response.

Of the four "refine the application" buckets the user set up on 2026-09-15
(bug fixes, features, ops cleanup, UI redesign), only the highest-priority
bug fix has been actioned. **Next session should open by discussing the
other three** — that's what the user asked for going into this handoff.

## Next steps
- (since 2026-09-16) **Discuss and scope the remaining three buckets** with
  the user: new features (they wanted to brainstorm, not yet started), ops
  cleanup (auto-deploy runner review + general deploy-package audit already
  ran on 2026-09-15 — findings never actioned, see that day's log), and the
  UI full visual refresh (not scoped at all yet).
- (since 2026-09-16) Four test/CI infrastructure bugs were found while
  building the fix above and were deliberately NOT touched (out of scope,
  per an advisor consult mid-task) — these are strong ops-cleanup candidates:
  1. CI has been red on the lint step on every push since 2026-08-14; the
     Test step has never actually run.
  2. `ite_api/main.py:50` hardcodes `/app/alembic.ini` — only works inside
     Docker, breaks local/CI test runs that boot the real app.
  3. `tests/conftest.py`'s `engine` fixture (`Base.metadata.create_all`) and
     the app's real Alembic migrations collide when both run in one test
     session — route tests using the `client` fixture have likely never
     passed.
  4. `tests/test_telemetry.py` fails — `opentelemetry` isn't a declared
     dependency.
- (since 2026-09-15) Migration: GitHub issue #4 (certificate-volume dry-run)
  is filed and awaiting the collaborator's run on the production PC.
- (since 2026-09-15) Migration: 8 open questions remain in
  `docs/MIGRATION.md` before the real one-shot capture can be scheduled —
  most load-bearing: does the new PC have internet access for `docker build`.
- (since 2026-09-15) Optionally refresh the GitNexus index (`gitnexus
  analyze`) — several commits stale.

## Open questions
- (since 2026-09-16) Which of features / ops cleanup / UI redesign to scope
  next, and in what order — user said "let's discuss in detail" going into
  this handoff.
- (since 2026-09-15) See `docs/MIGRATION.md` open-questions section.

## In flight
(none — working tree clean, nothing mid-change; all work this session is
committed and pushed)
