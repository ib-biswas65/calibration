# Handoff

## State
Repo is clean, HEAD `0db5054`. Current implementation is **ITE Calibration**
(FastAPI + React/Vite/TS, Docker-based, running on a Windows PC at the
calibration lab) — see `docs/ARCHITECTURE.md`. The migration plan for moving
to a **different Windows PC, planned for next week**, is written and
committed at `docs/MIGRATION.md`, now in its simplified form: only the live
Postgres database and the certificate volume are treated as irreplaceable
data; the app itself is rebuilt fresh on the new PC from a tagged, reviewed
git commit rather than shipped as exact baked images. The mandatory
pre-departure dry-run restore (section 2a) runs on this Mac (Docker via
Colima) rather than needing a spare Windows machine. No code was changed this
session — analysis/docs only. No outstanding uncommitted work.

## Next steps
- (since 2026-09-15) **Scope "refine the application" before touching any
  code.** The user wants bug fixes, new features, deployment/ops cleanup, and
  a UI redesign done before the migration, but none of it is scoped yet —
  which bugs, which features, what specifically for ops cleanup (the
  `backup-windows.ps1` encoding fix is one known candidate), and what
  direction for the redesign. This is a big enough initiative to need its own
  scoping/brainstorming pass, not ad-hoc implementation.
- (since 2026-09-15) Before migration day, get the user's answers to the 8
  open questions at the bottom of `docs/MIGRATION.md`. Most load-bearing:
  **will the new PC have internet access** for `docker build`/`pip`/`npm`
  during setup (default path assumes yes; fallback documented if not).
- (since 2026-09-15) Also confirm: exact timing of old-PC unavailability vs.
  final capture, whether the old PC sees real work between rehearsal and
  final capture, and the IP/hostname plan for the new PC.
- (since 2026-09-15) Optionally refresh the GitNexus index (`gitnexus
  analyze`) — it's several commits stale (last indexed `c08b1e3`, HEAD is now
  `0db5054`, all docs-only diffs so far).

## Open questions
- (since 2026-09-15) See `docs/MIGRATION.md` open-questions section — these
  are user/logistics decisions, not blocked-on-Claude items.
- (since 2026-09-15) What specifically does "refine the application" include?
  Needs a scoping conversation with the user (see Next steps).

## In flight
(none — working tree clean, nothing mid-change)
