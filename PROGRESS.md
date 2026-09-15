# Calibration
Calibration project.

## Log
- 2026-08-14 — recovered codebase after broken 2026-07-09 merge lost code, re-derived date parsing fix, removed legacy Flet app, added architecture docs — outcome: HEAD (`c08b1e3`) clean and documented in `docs/ARCHITECTURE.md`
- 2026-08-22 — restored onto new machine (cloned fresh from remote)
- 2026-09-15 — reviewed current implemented state of the app for the user, no code changes — outcome: confirmed ITE Calibration dashboard (FastAPI+React) generating Japanese calibration certs is the current, working implementation ([details](logs/DAILY-2026-09-15.md))
- 2026-09-15 — wrote Windows PC migration runbook (app + DB + certificate volume) ahead of a planned move next week — outcome: `docs/MIGRATION.md` committed (`9cca1d6`), 7 open questions left for the user before running it for real ([details](logs/DAILY-2026-09-15.md))
- 2026-09-15 — reworked migration runbook after user confirmed old PC will be unreachable post-move with a multi-day capture-to-setup gap — outcome: added mandatory pre-departure dry-run restore step, two-copy bundle redundancy, rewrote rollback as "there isn't one" (`371bff2`) ([details](logs/DAILY-2026-09-15.md))
- 2026-09-15 — simplified migration plan to fresh app build + DB/certs-only data transfer, after user confirmed only the DB needs migrating live and the app will be refined (bugs/features/ops/UI) before the move — outcome: `docs/MIGRATION.md` rewritten, dry run now runs on this Mac (`0db5054`); "refine the application" scoping deliberately deferred, not started ([details](logs/DAILY-2026-09-15.md))
- 2026-09-15 — filed GH issue #2 for a DB dry-run capture; collaborator ran it successfully on the production PC (restore-verified, all row counts/checksums match) and separately found a real broken-backup bug (GH issue #3: silent Docker-down preflight failure + UTF-16-corrupted nightly dumps) — outcome: applied their tested fix to `backup-windows.ps1`, rebased onto origin/main (which had moved), push held pending explicit user confirmation ([details](logs/DAILY-2026-09-15.md))
