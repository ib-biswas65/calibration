# Handoff

## State
Repo is clean locally, HEAD `f538bd1`, rebased cleanly onto the latest
`origin/main` (which had moved 3 commits ahead — certificate template fixes
and a new `docs/CHANGE_LOG.md`, unrelated to this session's work). **8 local
commits are not yet pushed** — push was held pending explicit user
confirmation, last asked and not yet answered as of this handoff.

Current implementation is **ITE Calibration** (FastAPI + React/Vite/TS,
Docker-based, on a Windows PC at the calibration lab) — see
`docs/ARCHITECTURE.md`. Migration plan for a **different Windows PC next
week** is at `docs/MIGRATION.md` (simplified: only DB + certificate volume
are irreplaceable data; app rebuilt fresh from a tagged git commit; dry run
runs on this Mac).

**Live production issue found and fixed this session:** the nightly
`backup-windows.ps1` had two real bugs, both hit for real on the production
PC and reported by a collaborator in GitHub issue #3 — (1) the Docker-down
preflight check never fired in PowerShell 5.1, so a stopped Docker Desktop
produced a silent empty backup; (2) the `pg_dump > file` redirect corrupted
Japanese text via UTF-16 re-encoding, so **every nightly backup before
2026-09-16 has broken data**. Both are fixed in the pending commit
`f538bd1` — not yet on the production PC until it's pushed and someone pulls
it there.

## Next steps
- (since 2026-09-15) **Push to `origin/main`** — get explicit confirmation
  from the user (asked, unanswered as of this handoff), then `git push`. The
  collaborator on GitHub issue #2/#3 is blocked on this: they explicitly
  asked for `docs/MIGRATION.md` to be pushed, and the backup-script fix
  needs to reach the production PC.
- (since 2026-09-15) After pushing, tell the collaborator (via issue
  comments) that the backup fix landed, and ask them to pull it onto the
  production PC — the broken nightly backup (issue #3) is still live until
  then.
- (since 2026-09-15) Restore-verify the DB dump from issue #2 on this Mac (or
  wherever it landed) to independently confirm the collaborator's numbers —
  this was the planned "Part C" step, not yet done from this side.
- (since 2026-09-15) **Scope "refine the application"** (bug fixes, features,
  ops cleanup, UI redesign) before touching any of that code — still not
  scoped, see prior open question.
- (since 2026-09-15) Get answers to the 8 open questions in
  `docs/MIGRATION.md` (internet access on new PC is the most load-bearing).
- (since 2026-09-15) Optionally refresh the GitNexus index (`gitnexus
  analyze`) — several commits stale.

## Open questions
- (since 2026-09-15) Push confirmation — asked, awaiting user response.
- (since 2026-09-15) See `docs/MIGRATION.md` open-questions section.
- (since 2026-09-15) "Refine the application" scope — needs a conversation.

## In flight
- `f538bd1` and 7 commits before it (session's doc/migration/backup-fix work)
  — committed locally, rebased onto current `origin/main`, **not pushed**.
