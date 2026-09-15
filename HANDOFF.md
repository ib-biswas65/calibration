# Handoff

## State
Repo is clean, HEAD `371bff2`. Current implementation is **ITE Calibration**
(FastAPI + React/Vite/TS, Docker-based, running on a Windows PC at the
calibration lab) — see `docs/ARCHITECTURE.md`. The migration runbook for
moving the whole prod stack (app + Postgres DB + certificate volume) to a
**different Windows PC, planned for next week**, is written and committed at
`docs/MIGRATION.md`. It has been reworked around a hard constraint the user
confirmed: the old PC will be **completely unreachable** once the new one
arrives (no remote access, no on-site presence), and there's a **multi-day
gap** between capturing the backup and setting up the new PC — so there is no
rollback and no re-capture once the old PC is gone. No code was changed —
this session was analysis/docs only. No outstanding uncommitted work.

## Next steps
- (since 2026-09-15) Before migration day, get the user's answers to the 7
  open questions at the bottom of `docs/MIGRATION.md`. The most load-bearing
  one: **is a spare Windows machine with Docker Desktop available** for the
  mandatory dry-run restore (section 2a) that must happen *before* the old PC
  leaves? Without it, the plan has no safe validation step before the point
  of no return.
- (since 2026-09-15) Also confirm: exact timing of when the old PC becomes
  unreachable relative to when the final capture can happen (decides how much
  of the capture-timing guidance in section 0.7 is actually followable), and
  whether the old PC will still be used for real calibration work between a
  rehearsal capture and the final one.
- (since 2026-09-15) Optionally refresh the GitNexus index (`gitnexus
  analyze`) — it's a few commits stale (last indexed `c08b1e3`, HEAD is now
  `371bff2`, docs-only diffs).

## Open questions
- (since 2026-09-15) See `docs/MIGRATION.md` open-questions section — these
  are user/logistics decisions, not blocked-on-Claude items.

## In flight
(none — working tree clean, nothing mid-change)
