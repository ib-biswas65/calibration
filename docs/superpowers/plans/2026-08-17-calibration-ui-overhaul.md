# Calibration Dashboard — Focused Overhaul Plan (August 2026)

**Status:** Plan only — no implementation in this change. Written against `main` @ `c08b1e3`.

**Scope:** Five pages, in the order the request listed them: Overview, Calibrations,
New Calibration, Upcoming, Loggers. Each section states what is actually in the code
today, the root cause where something is broken, the proposed change, and the files
involved.

**Development target:** all work is done on a **Windows machine** (Docker Desktop +
PowerShell). See [Windows-specific notes](#windows-specific-notes) — one item (PDF
export) has a real Windows/Docker constraint that needs a decision before it can be built.

---

## Contents

1. [Overview page — UI overhaul](#1-overview-page--ui-overhaul)
2. [Calibrations page — delete a run](#2-calibrations-page--delete-a-run)
3. [New Calibration page — dates, draft persistence, cert numbers, PDF export](#3-new-calibration-page)
4. [Upcoming page — fix the due-date logic](#4-upcoming-page--fix-the-due-date-logic)
5. [Loggers page — completeness, freshness, sorting](#5-loggers-page--completeness-freshness-sorting)
6. [Cross-cutting: the logger scheduling model](#cross-cutting-the-logger-scheduling-model)
7. [Suggested build order](#suggested-build-order)
8. [Windows-specific notes](#windows-specific-notes)
9. [Open decisions for the user](#open-decisions-for-the-user)

---

## 1. Overview page — UI overhaul

**Files:** `apps/web/src/pages/OverviewPage.tsx`, `OverviewPage.module.css`,
`components/StatTile.tsx`. Read-only against `GET /api/overview`
(`apps/api/ite_api/routes/overview.py`).

### What's there today

Four stat tiles (total loggers, runs in 30 d, pass rate, overdue), two rails
(recent runs ×5, due soon ×5), and a pass/fail bar chart over the last 10 runs.

### What's wrong

The page under-uses the data it already receives, and the tiles it does show are the
least actionable ones.

- **Already returned by the API and never rendered:** `fleet.due_30d`,
  `last_30d.fail_count`, `last_30d.adjusted_count`. `recent_runs[].verdict_mix` is
  used only to feed the chart, not the run rows.
- **Nothing on the page is a link except the recent-run rows.** "Overdue: 7" is a
  dead number — there is no way to get from it to the seven loggers.
- **Failures are invisible.** A run with `status: "failed"` shows only a status pill;
  `failure_reason` (which the run detail page does surface) never reaches the operator
  who needs to retry it.
- **Pass rate has no reference point** — 94.2% with no prior-period comparison and no
  denominator ("of 312 results") is not decision-useful.
- **Empty-state trap:** `recent_runs` is filtered server-side to the last 30 days
  (`overview.py:79`). With no runs this month the page says *"No runs yet — Start a new
  calibration to see results here"* even when the system holds years of history. That
  reads as data loss to a user. This is the one item that cannot be fully fixed in the
  UI alone — see the note below.

### Proposed UI

Keep the existing visual language (tokens, StatTile, StatusPill, skeletons) and rebuild
the composition:

- [ ] **KPI row, re-picked and made clickable.** Fleet compliance (`overdue` /
      `due_30d` in one tile, deep-linking to `/upcoming`), runs in the last 30 days
      (→ `/calibrations`), pass rate with the result denominator and fail/adjusted
      counts as a sub-line, total loggers (→ `/loggers`).
- [ ] **Attention rail** — a new first rail listing runs needing action: `failed` and
      `processing` runs, with the failure message inline and a direct link to the run.
      Rendered only when non-empty, so the page stays calm on a good day.
- [ ] **Recent runs rail, enriched.** Per row: batch name, status pill, logger count,
      pass/fail split from `verdict_mix` as a mini bar (reuse the `PassRateBar` pattern
      from `HistoryPage.tsx`), relative date ("2 days ago") with the absolute date on
      hover.
- [ ] **Due soon rail** — rows become links to the logger; show the day count
      ("in 12 d") rather than a raw ISO date, matching `UpcomingPage`'s vocabulary.
- [ ] **Chart** — keep the pass/fail bars; add a legend, stack the bars so the
      per-run total is readable, and fix the label truncation (currently slices at 10
      chars mid-word, which mangles the Japanese batch names).
- [ ] **Empty and error states** per section rather than one page-level
      "Failed to load overview."
- [ ] **Responsive pass** — tiles wrap to 2×2 and rails stack on narrow windows; the
      lab PC runs a single browser window that is often not maximised.

### Note on "UI-only"

Everything above is achievable without touching the API **except** the 30-day cutoff on
`recent_runs`. Making "Recent runs" honest needs a one-line change in `overview.py`
(drop the `created_at >= cutoff_30d` filter for the recent-runs query only, keeping it
for the 30-day stats). Two options:

- **(a)** Strictly UI-only: keep the cutoff, and change the empty-state copy to
  "No runs in the last 30 days" with a link to full history. Honest, zero backend risk.
- **(b)** One-line API change so the rail always shows the five most recent runs.

Recommendation: **(b)** — it is a smaller change than the copy workaround and gives the
right answer. Flagged here because it crosses the stated UI-only boundary.

---

## 2. Calibrations page — delete a run

**Files:** `apps/web/src/pages/HistoryPage.tsx`, `HistoryPage.module.css`,
`components/ConfirmDialog.tsx`; backend `apps/api/ite_api/routes/runs.py`.

### What's already done

The backend endpoint **exists and already meets both requirements**:
`DELETE /api/runs/{run_id}` (`runs.py:317`) is gated by `require_role("admin")`, writes
an audit row (`action="run.deleted"`), deletes the DB rows by cascade, and removes the
reference CSVs, workbook, certificates and the run directory from the data volume.

So this item is mostly frontend, plus four small backend hardening fixes.

### Frontend

- [ ] Add a trailing actions column to the history table with a delete (trash) button,
      rendered only when `useAuth().user?.role === "admin"`.
- [ ] `e.stopPropagation()` on the button — the whole row is a navigation target
      (`HistoryPage.tsx:189`), so without it the click also opens the run.
- [ ] Confirmation via the existing `ConfirmDialog`, requiring the batch name to be
      typed to confirm. Deletion destroys issued certificates; a one-click
      "Are you sure?" is not enough friction for that.
- [ ] `useMutation` → invalidate `["runs"]` and `["overview"]`, success/failure toast,
      and explicit handling of `403` ("admin role required") and `409` (see below).
- [ ] Disable the button while `status === "processing"`.

### Backend hardening

- [ ] **Block deleting a run that is `processing`** → `409`. The generation background
      task holds the run in another session; deleting mid-flight lets the task write
      results back and re-create certificate files under a directory that was just
      removed.
- [ ] **Record what was deleted.** `write_audit(...)` at `runs.py:330` passes no
      `detail`. After the cascade the run row is gone, so the audit entry as written
      cannot answer "what was deleted?". Add `detail={batch_name, status,
      certificate_date, logger_count, cert_no_range, file_count}`.
- [ ] **Make the record reachable.** `audit_log.run_id` is deliberately *not* a foreign
      key (`db/models/audit_log.py:21`), so the row survives the delete — good. But the
      only way to read audit rows is `GET /api/runs/{run_id}/audit`, which 404s once the
      run is gone. The deletion log is therefore currently write-only. Add
      `GET /api/audit` (admin, paginated, filterable by action/user/date) and a small
      admin-only audit view, or at minimum surface `run.deleted` entries there. Without
      this, "logged properly" is only half true.
- [ ] **Recompute logger due dates after deletion** — see
      [cross-cutting](#cross-cutting-the-logger-scheduling-model). If the deleted run
      was a logger's most recent calibration, its due date must roll back.

### Tests

- [ ] API: admin deletes → 204 + audit row with detail; engineer → 403; processing run
      → 409; files removed from disk.
- [ ] E2E (`apps/web/e2e/history.spec.ts`): button hidden for non-admin, visible and
      functional for admin.

---

## 3. New Calibration page

**Files:** `apps/web/src/pages/NewCalibrationPage.tsx`,
`components/SetpointWindowRow.tsx`; backend `routes/runs.py`,
`db/models/calibration.py`, new alembic migration.

Four sub-items, listed in request order.

### 3a. Dates default to today

**Root cause:** `NewCalibrationPage.tsx:11-15` hardcodes
`DEFAULT_SETPOINTS` with `1900-01-01T00:00:00Z` → `2999-12-31T23:59:00Z`. Those
sentinels mean "match anything", so the matcher picks readings from the whole file
instead of the intended setpoint window.

- [ ] Default each setpoint window to today, staggered by target so the three windows
      don't overlap (e.g. −40 °C 09:00–11:00, +5 °C 11:00–13:00, +40 °C 13:00–15:00) —
      the operator adjusts rather than retypes.
- [ ] Default **Testing start** to today 00:00 and **Testing end** to today 23:59
      (both are `required` and currently start empty).
- [ ] Add a "reset windows to today" control for reuse of an open form.
- [ ] **Timezone consistency check while in here.** The form appends `":00Z"` to
      `datetime-local` values (`NewCalibrationPage.tsx:85-86`,
      `SetpointWindowRow.tsx:36`), i.e. local wall-clock time is labelled UTC, while
      `jpDate()` re-parses with local semantics. It happens to work because the matcher
      strips tzinfo and logger timestamps are naive (`docs/ARCHITECTURE.md`, matcher
      section), but generated defaults must follow the same convention or windows will
      silently shift by the UTC offset (9 h in JST). Generate defaults from local
      Y-M-D components, not `toISOString()`.

### 3b. Persist in-progress form data

**Root cause:** all form state is `useState` (`NewCalibrationPage.tsx:32-45`); there is
no persistence anywhere in the app — `grep -rn "localStorage" apps/web/src` returns
nothing. Navigating away loses everything.

- [ ] Persist the form to `localStorage` under a versioned, per-user key
      (`ite:new-cal-draft:v1:<user_id>`), debounced ~500 ms.
- [ ] Restore on mount, with a dismissible "Restored your unsaved draft — Discard"
      banner so a stale draft is never silently submitted.
- [ ] Clear on successful run creation, and on explicit discard.
- [ ] Persist `runId` and `phase` too, so a user who leaves after the upload step
      returns to the upload step rather than a blank form. Uploaded-file names are then
      re-read from `GET /api/runs/{id}` (which returns `reference_files` and
      `calibration_file`) rather than from storage — **never** attempt to store `File`
      objects.
- [ ] Guard against schema drift: store a version field and drop drafts that don't match.
- [ ] While here: the setpoint list uses `key={sp.target_c}` (`:291`); if target
      temperatures ever become editable this key breaks. Use a stable id.

### 3c. Auto-fill the certificate number

**Today:** `startCertNo` is hardcoded to `"0000001000"` (`:37`), and
`_do_process` assigns `cert_no = str(start + idx).zfill(cert_width)` sequentially
(`runs.py:743-747`). Every run starts from 1000 unless the operator remembers to type
the right number.

- [ ] New endpoint `GET /api/runs/next-cert-no` → `{next_cert_no, width, source}`:
      `MAX(logger_results.cert_no) + 1` compared numerically (cast to `bigint`, ignoring
      any non-numeric value), padded to the width of the most recent run. All existing
      data is numeric zero-padded (`scripts/migrate_historical.py:213`), so the cast is
      safe, but the query must not blow up if that ever changes.
- [ ] Prefill the form field from it, keep it editable, and show where it came from
      ("next after 0000001042").
- [ ] Once the workbook is uploaded and the sheet count is known, show the block that
      will be consumed: "certificates 0000001043–0000001057 (15 loggers)".

### 3d. No duplicate certificate numbers

**Root cause:** `logger_results.cert_no` is indexed but **not unique**
(`db/models/calibration.py:95`), and nothing validates the requested block against
existing numbers. Two runs started with the same `start_cert_no` silently issue
duplicate certificates — the worst failure mode in the system, since the certificate
number is the customer-facing identifier and `GET /api/runs/by-cert-no/{cert_no}`
returns `.first()` of an ambiguous match.

Defence in depth, all three layers:

- [ ] **Database** — alembic `0008`: partial unique index on `logger_results (cert_no)
      WHERE cert_no IS NOT NULL`. **Prerequisite:** run a duplicate audit against
      production data first (`SELECT cert_no, COUNT(*) … HAVING COUNT(*) > 1`) — if the
      historical import created any, the migration will fail on a live database. Ship a
      read-only check script alongside the migration and resolve any hits before
      deploying.
- [ ] **API, at run creation and at process time** — validate the requested block
      `[start, start + n_sheets)` against existing numbers; on collision return `409`
      with the offending numbers and the next free block. The check must be repeated at
      process time: the sheet count is unknown at creation, and two operators can hold
      two drafts at once.
- [ ] **Engine** — wrap the per-logger insert so an `IntegrityError` marks the run
      `failed` with a readable `failure_reason` instead of a raw traceback.
- [ ] **UI** — inline validation on the cert-number field (debounced check against the
      next-cert-no endpoint) and a clear collision message on the process step.

### 3e. Word **or** PDF certificate download

**Today:** certificates are generated as `.docx` only
(`calibration/docx_filler.py`, `python-docx`), served by
`GET /api/runs/{run_id}/results/{result_id}/certificate` (`runs.py:544`) and the zip at
`/results.zip`. There is no PDF path anywhere in the codebase.

**This is the one item with a real infrastructure constraint.** The API runs in a
*Linux* container on the Windows PC (`deploy-package/docker-compose.yml`), so
Windows-native conversion (`docx2pdf`, Word COM automation) is **not** available to it.
Options:

| Option | How | Cost / risk |
|---|---|---|
| **LibreOffice in the API image** (recommended) | `soffice --headless --convert-to pdf` invoked from the API | +400–600 MB image; needs `fonts-noto-cjk` or the Japanese certificate renders as tofu; deploy tarball grows accordingly; **fidelity of the JP template under LibreOffice must be verified before committing** |
| Word COM on the Windows host | A small helper service outside Docker | Requires MS Word licensed on the lab PC; new out-of-container moving part; contradicts the current single-stack deployment |
| Client-side conversion | JS docx→PDF in the browser | Poor fidelity on a template-driven JP document; not viable for a customer deliverable |

Proposed (assuming LibreOffice):

- [ ] Add LibreOffice + Noto CJK fonts to `apps/api/Dockerfile`; pin the package
      versions and re-measure image size for the deploy tarball.
- [ ] **Fidelity spike first** — convert one real certificate and compare against the
      Word rendering (fonts, table borders, JP date line, page breaks). If it fails,
      stop and re-decide; everything below depends on it.
- [ ] `GET …/certificate?format=docx|pdf` (default `docx`, so existing links keep
      working); convert on demand and cache the PDF next to the `.docx`, invalidated
      whenever the certificate is regenerated (`_regenerate_certificate`,
      `_regenerate_all_certificates`).
- [ ] `GET …/results.zip?format=docx|pdf|both`.
- [ ] UI: a format choice on the per-certificate download in `RunDetailPage.tsx`
      (lines 52, 481), on the zip download (line 286), on `CertificatePage.tsx` (line 91),
      and on the "Certificates ready" screen in `NewCalibrationPage.tsx:173`.
- [ ] Conversion is slow (~1–3 s per document, single-threaded per `soffice`
      instance). Bulk PDF zips for a 50-logger run need to run as a background task with
      progress, not a blocking request — reuse the existing run-status polling pattern.

---

## 4. Upcoming page — fix the due-date logic

**Files:** `apps/web/src/pages/UpcomingPage.tsx`; backend `routes/loggers.py`,
`db/models/calibration.py`, `routes/runs.py`, new migration + backfill script.

### Root cause (confirmed)

`UpcomingPage.tsx:24-25` filters on `next_due_at != null`. **`Logger.next_due_at` is
never written by any automated path in the system:**

- `_do_process` creates loggers with `Logger(serial_no=name.strip())` and nothing else
  (`runs.py:759-763`);
- the historical import does the same (`scripts/migrate_historical.py:225`);
- the only writer is the manual `PATCH /api/loggers/{id}` (`loggers.py:72`).

So the column is NULL fleet-wide and the page is permanently empty. This is not a UI
bug — the scheduling data does not exist. It needs the model change described in
[the cross-cutting section](#cross-cutting-the-logger-scheduling-model), which is the
prerequisite for this page.

### Once due dates exist

- [ ] Move bucketing server-side: `GET /api/loggers/upcoming?within_days=90` returning
      pre-bucketed, sorted rows. Today the page fetches `?limit=200` and buckets in the
      browser — with the 200-row cap being a hard limit in `list_loggers`
      (`loggers.py:38`), a larger fleet silently truncates.
- [ ] Add a **"Never calibrated"** bucket — loggers with no completed result at all.
      They are the most overdue thing in the system and currently invisible.
- [ ] Show per row: last calibrated date, the interval used, the source of the due date
      (derived vs manually overridden), and last verdict.
- [ ] Fix the off-by-one in `daysUntil` (`UpcomingPage.tsx:9`): `new Date("2026-08-17")`
      parses as UTC midnight, then gets compared to a local `Date.now()`. Compare
      date-only values in local time.
- [ ] Allow an engineer to adjust a logger's next-due date inline (the `PATCH` endpoint
      already exists) and mark it as a manual override so recomputation doesn't stomp it.
- [ ] CSV export, matching the History page's export affordance.

---

## 5. Loggers page — completeness, freshness, sorting

**Files:** `apps/web/src/pages/LoggersPage.tsx`, `LoggersPage.module.css`,
`routes/loggers.py`, `components/DataTable.tsx`.

### "All loggers that have gone through the test are present"

Loggers are created only inside `_do_process` (`runs.py:759`) and the historical import,
keyed on the trimmed sheet name. Gaps to verify and close:

- [ ] **Data audit first** (read-only queries): distinct `logger_results.sheet_name`
      with `logger_id IS NULL`, and distinct sheet names with no matching
      `loggers.serial_no`. This says how big the problem actually is before any code is
      written.
- [ ] **Normalise serials on match.** Sheet names are only `.strip()`-ed. Unicode
      normalisation (the codebase already uses NFC for batch names —
      `NewCalibrationPage.tsx:84`), full-width vs half-width digits, and case
      differences will each create a *second* logger row for the same physical device.
      Normalise on lookup and insert, and add a one-off merge script for existing splits.
- [ ] **Reconciliation task** — a CLI command that walks `logger_results`, creates any
      missing `loggers` row, links orphaned results, and reports what it changed. Run
      once as a backfill; keep it available for repair.

### "Regularly updated"

- [ ] Update the logger row on every successful run rather than only creating it:
      `last_calibrated_at`, `next_due_at`, and last-known model. Currently a logger
      created in 2026-05 is never touched again.
- [ ] Surface derived state on the list: last calibration date, last verdict, last
      max deviation, last certificate number, run count. All of it is already in
      `logger_results` — it just needs one aggregate query rather than N+1.

### "Proper sorting"

- [ ] **Server-side sort + pagination** in `list_loggers`: `sort` (serial, model,
      next_due_at, last_calibrated_at, last verdict) + `dir`, with `limit`/`offset`.
      Today it is `ORDER BY serial_no` with `limit ≤ 200` and no sort parameter at all
      (`loggers.py:42`), so the UI cannot sort beyond what one page returned.
- [ ] **Natural (numeric-aware) ordering** for serial numbers so `A-9` sorts before
      `A-10`. Plain lexicographic ordering on the serial column is the specific thing
      that reads as "sorting is broken".
- [ ] Sortable headers in the UI. `DataTable` has no sort support
      (`components/DataTable.tsx`), while `HistoryPage` implements its own with
      `SortIcon`. Lift that into `DataTable` so Loggers, Upcoming and History share one
      implementation instead of a third copy.
- [ ] Keep sort/search/page state in the URL query string so a browser back-navigation
      returns to the same view.
- [ ] Filters: due status (overdue / due 30 d / ok / never), and verdict of last run.
- [ ] Decide the fate of `LoggerProfilePage.tsx` — it is a two-line `ComingSoon` stub
      and no route points at it (`App.tsx`). Either wire `/loggers/:id` to a real
      profile page (the inline expanding panel already shows most of it) or delete it.

---

## Cross-cutting: the logger scheduling model

Items 2 (delete), 4 (Upcoming) and 5 (Loggers) all depend on one piece of missing
backend state. Build this once, first.

- [ ] **Schema** (alembic `0009`): add to `loggers` — `last_calibrated_at DATE NULL`,
      `cal_interval_months INT NULL` (per-logger override), `due_override BOOLEAN NOT
      NULL DEFAULT false`. Add `ITE_DEFAULT_CAL_INTERVAL_MONTHS` (default 12) to
      `config.py`.
- [ ] **One helper**, `recompute_logger_schedule(db, logger_id)`:
      `last_calibrated_at` = the `certificate_date` of the most recent **complete** run
      containing a result for that logger; `next_due_at` = that date +
      interval — skipped entirely when `due_override` is set.
- [ ] **Call it from every path that changes history:** after `_do_process` completes,
      after a run is deleted, after `PATCH /runs/{id}/dates`, and after a manual
      deviation correction changes a verdict.
- [ ] **Backfill script** in `scripts/` (the repo has precedent for one-shot migrations)
      that recomputes the whole fleet from existing `logger_results`, with a `--dry-run`
      that prints what it would set. This is what makes the Upcoming page light up for
      the first time.
- [ ] Use `certificate_date`, not `created_at`, as the calibration date — the historical
      import backdates certificates, so `created_at` would schedule those loggers years late.

---

## Suggested build order

The user's ordering is by page; this is the dependency-safe ordering to actually build in.
Each phase is independently shippable.

| Phase | Contents | Why here |
|---|---|---|
| 1 | Logger scheduling model + backfill (cross-cutting) | Unblocks Upcoming and Loggers |
| 2 | Cert-number uniqueness (3c + 3d) | Highest-risk correctness gap; guards the customer-facing identifier |
| 3 | New Calibration UX: date defaults + draft persistence (3a + 3b) | Pure frontend, immediate daily relief, no dependencies |
| 4 | Delete run (item 2) — frontend + backend hardening + audit view | Small, self-contained; the endpoint already exists |
| 5 | Upcoming page (item 4) | Consumes phase 1 |
| 6 | Loggers page (item 5) | Consumes phase 1; largest backend surface |
| 7 | Overview overhaul (item 1) | Presentation of everything above; best done once the data underneath is correct |
| 8 | PDF export (3e) | Gated on the LibreOffice fidelity spike; largest infrastructure risk; ship last |

---

## Windows-specific notes

- **Everything runs in Linux containers** on Docker Desktop for Windows. Python file
  handling in the API is already `pathlib`-based, so no path work is needed — but it
  also means **Windows-only libraries (`docx2pdf`, Word COM) are unavailable to the
  API**. This is the constraint behind the PDF decision in §3e.
- **Line endings.** The repo has no `.gitattributes`. Git for Windows defaults to
  `core.autocrlf=true`, which will rewrite `.sh` scripts and `.ps1`/Dockerfile content
  on checkout. Add a `.gitattributes` (`* text=auto`, `*.sh text eol=lf`,
  `*.ps1 text eol=crlf`) before starting — a CRLF-mangled `backup.sh` or Dockerfile
  `CMD` fails in confusing ways inside the container.
- **File deletion** (used by the run-delete path) behaves differently on Windows: an
  open handle blocks `unlink`. Files live inside the container's volume so this mostly
  doesn't apply, but any host-side cleanup script must tolerate `PermissionError`,
  not just `OSError`.
- **Commands in the README are bash** (`cp .env.example .env`). PowerShell equivalents
  (`Copy-Item`) are needed, or run them from Git Bash. Worth fixing the README while in
  there.
- **Image rebuild is mandatory after any change.** Production runs pre-baked images with
  no source bind-mount — editing `apps/api` on disk changes nothing until
  `docker build` + `docker compose up -d --no-deps api`. See `docs/DEPLOYMENT.md`; this
  has bitten this project before.
- **Deploy tarball size.** `deploy-package/images/api.tar.gz` is copied to the lab PC by
  hand. Adding LibreOffice roughly doubles it — worth confirming how that package
  reaches the machine before committing to it.
- **Playwright e2e** needs the Docker stack running locally; on Windows use
  `npx playwright install` once per machine.

---

## Open decisions for the user

1. **Overview scope** — strictly UI-only (accept that "Recent runs" stays limited to the
   last 30 days), or allow the one-line API change so it always shows the five most
   recent runs? *(Recommend: allow it.)*
2. **PDF conversion** — approve LibreOffice inside the API image (bigger image, needs a
   fidelity check on the Japanese template), or keep `.docx`-only until a Windows-side
   converter can be arranged? *(Recommend: LibreOffice, gated on the spike.)*
3. **Calibration interval** — is 12 months the correct default, and does it vary by
   logger model or by customer? This sets the default for the whole scheduling model.
4. **Delete semantics** — hard delete (current behaviour: run, results and certificate
   files are destroyed) or soft delete / archive, so an issued certificate can still be
   looked up by number after the run is removed? *(This is the one decision with
   compliance implications; worth an explicit answer.)*
5. **Audit visibility** — is an admin-facing audit page in scope? Without it, the
   deletion log exists in the database but cannot be read from the application.
</content>
</invoke>
