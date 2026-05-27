# Design Spec: History Redesign + Batch Detail + Animation Polish
**Date:** 2026-05-26  
**Status:** Approved by user

---

## 1. Scope

Three interconnected changes to the web app:

1. **HistoryPage** — replace the current plain table/cards with a rich data table showing pass rate, max deviation, and logger count inline.
2. **RunDetailPage** — redesign from a tabbed layout into a batch detail page with a stat strip, live search, and a table/card view toggle for browsing individual certificates.
3. **Animation & interaction polish** — apply consistent, classy motion across the entire app (hover lifts, fade transitions, view toggle crossfade, page mount fade-in, processing pulse).

---

## 2. HistoryPage

### Layout
- Single-view: rich data table (no card toggle needed here — the per-batch card toggle lives inside RunDetailPage).
- Toolbar: search input (batch name) + status filter select + **"+ New calibration"** button.

### Table columns
| Column | Notes |
|--------|-------|
| Batch name | Bold, clickable — navigates to RunDetailPage |
| Status | `StatusPill` component |
| Loggers | Integer count |
| Pass rate | Percentage + mini horizontal sparkbar (green = pass portion, red = fail portion); shows "—" if no results |
| Max dev. | Worst-case deviation in °C across all loggers; shows "—" if unavailable |
| Date | Created date, formatted "12 Mar 2025" |

### Interactions
- Row hover: `background: var(--c-accent-50)` fade-in, `150ms ease-out`.
- Row click: navigate to `/calibrations/:id`.
- Failed rows: no special row colour — the StatusPill and red max-dev value are sufficient signal.

### Data source
The `RunSummary` type already has `logger_count`, `status`, `created_at`. Pass rate and max deviation are **not currently returned** by `/api/runs`. The API needs two new optional fields added to `RunSummary`:
- `pass_rate: number | null` — percentage of loggers with verdict "pass"
- `max_deviation_c: number | null` — worst max_deviation_c across all logger results

These can be `null` for runs with no results yet (draft / processing / failed).

---

## 3. RunDetailPage (Batch Detail)

### Layout — top to bottom

**Header row**
- Back link "← History" (navigates to `/calibrations`)
- Batch title (h2, Boardroom Navy)
- Status badge inline with title
- Batch meta: date · logger count
- "↓ Download all (.zip)" button — right-aligned, only shown when `status === "complete"`

**Stat strip** (always visible)
- Four tiles in a horizontal strip: Pass count · Fail count · Pass rate % · Max deviation °C
- Derived from `run.results` on the frontend — no new API field needed.

**Toolbar**
- Search input: filters by cert number (substring match on `cert_no`) OR logger serial (`sheet_name`). Placeholder: "Search cert no. or logger serial…"
- Filter pills: All · Pass · Fail (filters `verdict` field)
- View toggle (right-aligned): `≡ Table` / `⊞ Cards` — pill-shaped toggle, active state = Boardroom Navy background + white text.

**Table view** (default)

| Column | Notes |
|--------|-------|
| Cert no. | Bold, Boardroom Navy; red for fail |
| Logger serial | `sheet_name` from `LoggerResult`; muted grey |
| Verdict | `StatusPill` |
| −40°C dev | Inline deviation bar + value; red bar if `!within_tol` |
| +5°C dev | Same |
| +40°C dev | Same |
| Max dev. | Bold red if fail |
| ↓ | Download individual cert `.docx` via `GET /api/runs/:runId/results/:resultId/certificate`; only shown if `cert_no !== null` |

Deviation bar: `width = Math.min(deviation / 2.0 * 80, 80)px` — caps at 80px for deviations ≥ 2°C. Green if `within_tol`, red if not.

**Card view**

4-column grid. Each card:
- Cert number (prominent, top-left)
- Verdict badge (top-right)
- Logger serial (muted, second line)
- Max deviation (bottom-left, red if fail)
- ↓ download button (bottom-right)
- Failed cards: `border-color: #fca5a5`

**Secondary info (batch metadata)** — collapsible disclosure panel below the cert list, collapsed by default, titled "Batch configuration". Contains: test date, cert date, threshold, setpoints, reference files, calibration file. This replaces the old "setpoints / conditions / audit" tabs.

### Search behaviour
- Search is client-side, filtered on the already-loaded `run.results` array.
- Matches `cert_no` (contains) OR `sheet_name` (contains), case-insensitive.
- Search + verdict filter compose: both must match.

### View toggle persistence
- Store in `useState` (no localStorage needed — resets on page reload is fine).
- Default: table view.

---

## 4. Animation & Interaction Polish

All transitions use `ease-out` unless otherwise noted. No `width`/`height` animations (triggers reflow). Only `transform`, `opacity`, `box-shadow`, `background-color`, `border-color`.

### Global token additions (tokens.css)
```css
--transition-fast:   150ms ease-out;
--transition-base:   200ms ease-out;
--transition-slow:   300ms ease-out;
```

### Per-component rules

| Element | Animation |
|---------|-----------|
| **Sidebar nav items** | `background`, `color` — `150ms ease-out`. Already present; verify timing matches token. |
| **Stat tiles (StatTile)** | Hover: `transform: translateY(-2px)`, `box-shadow: var(--shadow-2)` — `200ms ease-out`. |
| **History table rows** | Hover: `background: var(--c-accent-50)` — `150ms ease-out`. |
| **Overview list items** | Hover: `background: var(--c-accent-50)`, extend padding — `150ms ease-out`. Already present; ensure timing. |
| **Batch detail cert cards** | Hover: `transform: translateY(-2px)`, `box-shadow: var(--shadow-2)`, `border-color: var(--c-accent-300)` — `200ms ease-out`. |
| **Buttons (primary pill)** | Hover: `background: var(--c-accent-700)` — `150ms ease-out`. Already present. |
| **View toggle switch** | Active pill slides: use background transition `200ms ease-out` on the active button. No JS needed — CSS handles it. |
| **Table/card view crossfade** | Outgoing view: `opacity: 0` over `150ms`. Incoming view: `opacity: 1` over `200ms` with `150ms` delay. Implemented via CSS class swap + `transition`. |
| **Page mount (all pages)** | `.page` gets `@keyframes fadeSlideUp`: `from { opacity:0; transform: translateY(8px) }` `to { opacity:1; transform: translateY(0) }` — `250ms ease-out`, `fill-mode: both`. Applied once on mount. |
| **StatusPill — processing** | Subtle `opacity` pulse: `@keyframes processingPulse` cycles `opacity: 1 → 0.6 → 1` over `1.8s infinite ease-in-out`. Applied only when `value === "processing"`. |
| **Download button (row/card)** | Hover: `background: var(--c-accent-50)`, `border-color: var(--color-brand-electric)` — `150ms ease-out`. |
| **Search input focus** | `border-bottom-color` transition to Electric Blue — `150ms ease-out`. Already present. |
| **Filter pills** | Hover on inactive: `border-color: var(--c-accent-300)`, `color: var(--c-accent-500)` — `150ms ease-out`. |

### What we are NOT doing
- No page-level route transitions (adds complexity, React Router v6 makes it awkward).
- No spring physics (overkill for this product type).
- No staggered list entrance animations (distracting for a data-dense tool).
- No parallax.

---

## 5. API changes required

`GET /api/runs` response — add to `RunSummary`:
```ts
pass_rate: number | null        // % loggers with verdict "pass"; null if no results
max_deviation_c: number | null  // max across all logger results; null if no results
```

Computed in the API query via a SQL join on `calibration_run_results`. If no results exist, both are `null`.

No other API changes. The RunDetailPage already receives full `LoggerResult[]` including `per_setpoint`, `verdict`, `cert_no`, `max_deviation_c`.

---

## 6. Files to create / modify

| File | Change |
|------|--------|
| `apps/web/src/theme/tokens.css` | Add `--transition-fast/base/slow` tokens |
| `apps/web/src/pages/HistoryPage.tsx` | Full redesign — rich table with pass rate sparkbar + max dev column |
| `apps/web/src/pages/HistoryPage.module.css` | Update styles; add row animation |
| `apps/web/src/pages/RunDetailPage.tsx` | Full redesign — stat strip, search, view toggle, table+card views, collapsible batch config |
| `apps/web/src/pages/RunDetailPage.module.css` | New styles for all new sections |
| `apps/web/src/components/StatTile.module.css` | Add hover lift animation |
| `apps/web/src/components/StatusPill.module.css` | Add processing pulse keyframe |
| `apps/web/src/components/StatusPill.tsx` | Apply pulse class conditionally |
| `apps/web/src/api/types.ts` | Add `pass_rate` and `max_deviation_c` to `RunSummary` |
| `apps/api/ite_api/routes/runs.py` | Compute and return new `RunSummary` fields |

---

## 7. Out of scope

- LoggersPage, NewCalibrationPage, AdminUsersPage, SettingsPage, CertificatePage — no changes.
- Mobile responsive layout — the app is used on desktop; no breakpoint work needed beyond what exists.
- Dark mode — not planned.
- Individual certificate preview (clicking a cert opens a preview modal) — future work.
