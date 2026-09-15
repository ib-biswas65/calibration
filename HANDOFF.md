# Handoff

## State
Repo is clean, HEAD `9cca1d6`. Current implementation is **ITE Calibration**
(FastAPI + React/Vite/TS, Docker-based, running on a Windows PC at the
calibration lab) — see `docs/ARCHITECTURE.md`. A migration runbook for moving
the whole prod stack (app + Postgres DB + certificate volume) to a **different
Windows PC, planned for next week**, is now written and committed at
`docs/MIGRATION.md`. No code was changed — this session was analysis/docs
only. No outstanding uncommitted work.

## Next steps
- (since 2026-09-15) Before running the migration for real, get the user's
  answers to the 7 open questions at the bottom of `docs/MIGRATION.md`:
  IP/hostname handling on the new PC, whether both PCs are online
  simultaneously during the move, the actual downtime window, whether
  `C:\Calibration` is confirmed to be the right/clean path on the old PC,
  whether new-PC test runs during the fallback period count as real data,
  whether to fix `backup-windows.ps1`'s PowerShell text-encoding risk now,
  and whether the dormant GitHub Actions self-hosted runner should ever be
  re-enabled on the new PC (recommended: no, not as part of this move).
- (since 2026-09-15) Optionally refresh the GitNexus index (`gitnexus
  analyze`) — it's one commit stale (last indexed `c08b1e3`, HEAD is now
  `9cca1d6`, docs-only diff).

## Open questions
- (since 2026-09-15) See `docs/MIGRATION.md` open-questions section — these
  are user decisions, not blocked-on-Claude items.

## In flight
(none — working tree clean, nothing mid-change)
