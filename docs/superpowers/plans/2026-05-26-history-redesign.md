# History Redesign + Batch Detail + Animation Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the HistoryPage into a rich data table, replace the RunDetailPage with a stat-strip + searchable cert browser (table/card toggle), and add consistent classy animations across the app.

**Architecture:** API layer adds `pass_rate` and `max_deviation_c` to `RunSummary`. Frontend redesigns two pages in-place (no new routes needed). Animation is pure CSS — transition tokens in `tokens.css`, keyframes in component CSS modules, no JS animation libraries.

**Tech Stack:** React 18, TypeScript, CSS Modules, React Query, React Router v6, FastAPI/SQLAlchemy (Python)

---

## File Map

| File | Change |
|------|--------|
| `apps/api/ite_api/routes/runs.py` | Add `pass_rate` + `max_deviation_c` to `RunSummary` model and `list_runs` query |
| `apps/api/tests/routes/test_runs.py` | Add test asserting new fields appear in list response |
| `apps/web/src/api/types.ts` | Add `pass_rate: number \| null` and `max_deviation_c: number \| null` to `RunSummary` |
| `apps/web/src/theme/tokens.css` | Add `--transition-fast`, `--transition-base`, `--transition-slow` + `@keyframes fadeSlideUp` + `@keyframes processingPulse` |
| `apps/web/src/components/StatusPill.module.css` | Add processing pulse animation |
| `apps/web/src/components/StatusPill.tsx` | Apply pulse class when `value === "processing"` |
| `apps/web/src/components/StatTile.module.css` | Add hover lift transition |
| `apps/web/src/pages/HistoryPage.tsx` | Full redesign — rich data table with sparkbar + new columns |
| `apps/web/src/pages/HistoryPage.module.css` | New styles for rich table, sparkbar, row hover |
| `apps/web/src/pages/RunDetailPage.tsx` | Full redesign — stat strip, search, view toggle, table+card views, collapsible config |
| `apps/web/src/pages/RunDetailPage.module.css` | New styles for all new sections |

---

## Task 1: API — Add pass_rate and max_deviation_c to RunSummary

**Files:**
- Modify: `apps/api/ite_api/routes/runs.py`
- Test: `apps/api/tests/routes/test_runs.py`

**Context:** `RunSummary` is the Pydantic model returned by `GET /api/runs`. Currently it has `logger_count` but no aggregated result fields. `LoggerResult` rows have `verdict` (string: "pass"/"fail"/"adjusted") and `max_deviation_c` (Decimal|None). We need to aggregate these per-run in `list_runs`.

- [ ] **Step 1: Write the failing test**

Add to `apps/api/tests/routes/test_runs.py` after the existing `test_create_and_list_runs` test:

```python
def test_list_runs_includes_pass_rate_and_max_deviation(authed_client, db_session):
    """RunSummary must include pass_rate and max_deviation_c (null when no results)."""
    authed_client.post("/api/runs", json=_RUN_BODY)
    lst = authed_client.get("/api/runs")
    assert lst.status_code == 200
    run = lst.json()[0]
    # No results yet → both fields are null
    assert "pass_rate" in run
    assert "max_deviation_c" in run
    assert run["pass_rate"] is None
    assert run["max_deviation_c"] is None
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd apps/api
.venv/bin/pytest tests/routes/test_runs.py::test_list_runs_includes_pass_rate_and_max_deviation -v
```

Expected: `FAILED` — `KeyError: 'pass_rate'` or assertion error.

- [ ] **Step 3: Add fields to RunSummary model**

In `apps/api/ite_api/routes/runs.py`, change the `RunSummary` class (currently at line ~74):

```python
class RunSummary(BaseModel):
    id: uuid.UUID
    batch_name: str
    status: str
    created_at: datetime
    completed_at: datetime | None
    logger_count: int | None = None
    pass_rate: float | None = None
    max_deviation_c: float | None = None

    model_config = {"from_attributes": True}
```

- [ ] **Step 4: Compute fields in list_runs**

In `apps/api/ite_api/routes/runs.py`, replace the `list_runs` for-loop body (currently at line ~164):

```python
    result = []
    for run in runs:
        results = db.scalars(select(LoggerResult).where(LoggerResult.run_id == run.id)).all()
        count = len(results)
        pass_rate: float | None = None
        max_dev: float | None = None
        if results:
            passed = sum(1 for r in results if r.verdict == "pass")
            pass_rate = round(passed / count * 100, 1)
            devs = [float(r.max_deviation_c) for r in results if r.max_deviation_c is not None]
            max_dev = max(devs) if devs else None
        result.append(RunSummary(
            id=run.id,
            batch_name=run.batch_name,
            status=run.status,
            created_at=run.created_at,
            completed_at=run.completed_at,
            logger_count=count if run.status == "complete" else None,
            pass_rate=pass_rate if run.status == "complete" else None,
            max_deviation_c=max_dev if run.status == "complete" else None,
        ))
    return result
```

- [ ] **Step 5: Run the test to confirm it passes**

```bash
cd apps/api
.venv/bin/pytest tests/routes/test_runs.py::test_list_runs_includes_pass_rate_and_max_deviation -v
```

Expected: `PASSED`

- [ ] **Step 6: Run full test suite to check for regressions**

```bash
cd apps/api
.venv/bin/pytest tests/ -v
```

Expected: all previously-passing tests still pass.

- [ ] **Step 7: Commit**

```bash
git add apps/api/ite_api/routes/runs.py apps/api/tests/routes/test_runs.py
git commit -m "feat(api): add pass_rate and max_deviation_c to RunSummary"
```

---

## Task 2: Frontend types update

**Files:**
- Modify: `apps/web/src/api/types.ts`

- [ ] **Step 1: Add new fields to RunSummary**

In `apps/web/src/api/types.ts`, find the `RunSummary` interface and add two fields:

```ts
export interface RunSummary {
  id: string;
  batch_name: string;
  status: RunStatus;
  created_at: string;
  completed_at: string | null;
  logger_count: number | null;
  pass_rate: number | null;
  max_deviation_c: number | null;
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd apps/web
npm run build 2>&1 | tail -20
```

Expected: build succeeds (exit 0), no type errors.

- [ ] **Step 3: Commit**

```bash
git add apps/web/src/api/types.ts
git commit -m "feat(web): add pass_rate and max_deviation_c to RunSummary type"
```

---

## Task 3: Animation tokens and global keyframes

**Files:**
- Modify: `apps/web/src/theme/tokens.css`

- [ ] **Step 1: Add transition tokens and keyframes**

Open `apps/web/src/theme/tokens.css`. After the `/* ── Shadows */` block at the bottom, append:

```css
  /* ── Transitions ─────────────────────────────────────────────────── */
  --transition-fast: 150ms ease-out;
  --transition-base: 200ms ease-out;
  --transition-slow: 300ms ease-out;
}

/* ── Global keyframes ─────────────────────────────────────────────── */
@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

@keyframes processingPulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.55; }
}
```

Note: The transition tokens go **inside** the `:root {}` block (before the closing `}`). The `@keyframes` rules go **outside** `:root`, after the closing brace.

- [ ] **Step 2: Verify the dev server still compiles**

```bash
cd apps/web
npm run dev &
sleep 4
curl -s http://localhost:5173 | grep -q "<!doctype" && echo "OK" || echo "FAIL"
kill %1
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add apps/web/src/theme/tokens.css
git commit -m "feat(web): add animation tokens and global keyframes"
```

---

## Task 4: StatusPill — processing pulse + page mount animation

**Files:**
- Modify: `apps/web/src/components/StatusPill.tsx`
- Modify: `apps/web/src/components/StatusPill.module.css`

- [ ] **Step 1: Add pulse class to StatusPill CSS**

In `apps/web/src/components/StatusPill.module.css`, append after the last existing rule:

```css
.pulsing {
  animation: processingPulse 1.8s ease-in-out infinite;
}
```

- [ ] **Step 2: Apply pulse class conditionally in StatusPill.tsx**

Replace the entire content of `apps/web/src/components/StatusPill.tsx`:

```tsx
import styles from "./StatusPill.module.css";
import type { RunStatus, Verdict } from "../api/types";

const LABELS: Record<string, string> = {
  draft: "Draft",
  processing: "Processing",
  complete: "Complete",
  failed: "Failed",
  pass: "Pass",
  fail: "Fail",
  adjusted: "Adjusted",
};

interface Props {
  value: RunStatus | Verdict | string;
}

export function StatusPill({ value }: Props) {
  const cls = [styles.pill, styles[value] ?? "", value === "processing" ? styles.pulsing : ""]
    .filter(Boolean)
    .join(" ");
  return <span className={cls}>{LABELS[value] ?? value}</span>;
}
```

- [ ] **Step 3: Add page mount animation to all .page classes**

In each of the following files, find the `.page` rule and add `animation: fadeSlideUp var(--transition-slow) both;` to it:

- `apps/web/src/pages/HistoryPage.module.css` — `.page { ... }` 
- `apps/web/src/pages/OverviewPage.module.css` — `.page { ... }`
- `apps/web/src/pages/RunDetailPage.module.css` — `.page { ... }`
- `apps/web/src/pages/LoggersPage.module.css` — `.page { ... }`
- `apps/web/src/pages/NewCalibrationPage.module.css` — `.page { ... }`

For each file, add the animation line so the rule looks like:

```css
.page {
  padding: var(--s-6);
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--s-5);  /* or whatever gap value is already there */
  animation: fadeSlideUp var(--transition-slow) both;
}
```

- [ ] **Step 4: Commit**

```bash
git add apps/web/src/components/StatusPill.tsx apps/web/src/components/StatusPill.module.css
git add apps/web/src/pages/HistoryPage.module.css apps/web/src/pages/OverviewPage.module.css
git add apps/web/src/pages/RunDetailPage.module.css apps/web/src/pages/LoggersPage.module.css
git add apps/web/src/pages/NewCalibrationPage.module.css
git commit -m "feat(web): add processing pulse, page mount fade-slide animation"
```

---

## Task 5: StatTile hover lift

**Files:**
- Modify: `apps/web/src/components/StatTile.module.css`

- [ ] **Step 1: Add hover transition to StatTile**

In `apps/web/src/components/StatTile.module.css`, update the `.tile` rule and add a hover rule:

```css
.tile {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  padding: var(--s-5) var(--s-6);
  display: flex;
  flex-direction: column;
  gap: var(--s-2);
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}
.tile:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-2);
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/web/src/components/StatTile.module.css
git commit -m "feat(web): add hover lift to StatTile"
```

---

## Task 6: HistoryPage — rich data table redesign

**Files:**
- Modify: `apps/web/src/pages/HistoryPage.tsx`
- Modify: `apps/web/src/pages/HistoryPage.module.css`

**Context:** The current HistoryPage has a table/cards toggle. We're replacing it with a single rich data table that shows pass rate (with a sparkbar) and max deviation inline. No card view on this page — card view lives inside the batch detail (RunDetailPage).

- [ ] **Step 1: Replace HistoryPage.tsx**

Write the entire file `apps/web/src/pages/HistoryPage.tsx`:

```tsx
import { useQuery } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { RunSummary } from "../api/types";
import { StatusPill } from "../components/StatusPill";
import styles from "./HistoryPage.module.css";

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function PassRateBar({ rate }: { rate: number | null }) {
  if (rate === null) return <span className={styles.muted}>—</span>;
  const pass = Math.round(rate);
  const fail = 100 - pass;
  return (
    <div className={styles.rateWrap}>
      <div className={styles.sparkBar}>
        <div className={styles.sparkPass} style={{ width: `${pass}%` }} />
        <div className={styles.sparkFail} style={{ width: `${fail}%` }} />
      </div>
      <span className={styles.rateVal}>{rate.toFixed(1)}%</span>
    </div>
  );
}

export function HistoryPage() {
  const nav = useNavigate();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  const { data = [], isLoading } = useQuery<RunSummary[]>({
    queryKey: ["runs", search, statusFilter],
    queryFn: () => {
      const params = new URLSearchParams();
      if (search) params.set("q", search);
      if (statusFilter) params.set("status", statusFilter);
      return apiFetch<RunSummary[]>(`/api/runs?${params}`);
    },
    refetchInterval: 10_000,
  });

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <h2 className={styles.heading}>Calibration History</h2>
        <button className={styles.btnPrimary} onClick={() => nav("/new")}>+ New calibration</button>
      </div>

      <div className={styles.toolbar}>
        <input
          className={styles.search}
          placeholder="Search batch name…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select className={styles.select} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          <option value="">All statuses</option>
          <option value="draft">Draft</option>
          <option value="processing">Processing</option>
          <option value="complete">Complete</option>
          <option value="failed">Failed</option>
        </select>
      </div>

      {isLoading ? (
        <p className={styles.empty}>Loading…</p>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Batch name</th>
                <th>Status</th>
                <th className={styles.colNum}>Loggers</th>
                <th className={styles.colWide}>Pass rate</th>
                <th className={styles.colNum}>Max dev.</th>
                <th className={styles.colNum}>Date</th>
              </tr>
            </thead>
            <tbody>
              {data.length === 0 ? (
                <tr>
                  <td colSpan={6} className={styles.empty}>No calibration runs found</td>
                </tr>
              ) : (
                data.map((run) => (
                  <tr key={run.id} className={styles.row} onClick={() => nav(`/calibrations/${run.id}`)}>
                    <td className={styles.nameCell}>{run.batch_name}</td>
                    <td><StatusPill value={run.status} /></td>
                    <td className={styles.numCell}>{run.logger_count ?? "—"}</td>
                    <td><PassRateBar rate={run.pass_rate} /></td>
                    <td className={styles.numCell}>
                      {run.max_deviation_c !== null && run.max_deviation_c !== undefined
                        ? <span className={run.max_deviation_c > 0.5 ? styles.devFail : styles.devOk}>
                            {run.max_deviation_c.toFixed(1)}°C
                          </span>
                        : <span className={styles.muted}>—</span>}
                    </td>
                    <td className={styles.numCell}>{fmt(run.created_at)}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

Note: add `import { useState } from "react";` at the top with the other imports.

- [ ] **Step 2: Replace HistoryPage.module.css**

Write the entire file `apps/web/src/pages/HistoryPage.module.css`:

```css
.page {
  padding: var(--s-6);
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--s-5);
  animation: fadeSlideUp var(--transition-slow) both;
}

.header { display: flex; align-items: center; justify-content: space-between; }

.heading {
  font-family: var(--font-heading);
  font-size: 28px;
  font-weight: 500;
  letter-spacing: -0.03em;
  color: var(--color-boardroom-navy);
  margin: 0;
}

.btnPrimary {
  background: var(--color-brand-electric);
  color: #fff;
  border: none;
  border-radius: var(--radius-pill);
  padding: 10px var(--s-5);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background var(--transition-fast);
}
.btnPrimary:hover { background: var(--c-accent-700); }

.toolbar { display: flex; gap: var(--s-3); align-items: center; flex-wrap: wrap; }

.search {
  flex: 1;
  min-width: 200px;
  padding: 9px 12px;
  border: none;
  border-bottom: 1.5px solid var(--color-input-border);
  font-size: 14px;
  background: transparent;
  color: var(--c-text);
  outline: none;
  transition: border-bottom-color var(--transition-fast);
}
.search:focus { border-bottom-color: var(--color-brand-electric); }

.select {
  padding: 9px 12px;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-badge);
  font-size: 14px;
  background: var(--c-surface);
  color: var(--c-text);
}

/* ── Table ───────────────────────────────────────────────────────── */
.tableWrap {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  overflow: hidden;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

.table thead tr {
  border-bottom: 1px solid var(--c-border);
}

.table th {
  text-align: left;
  padding: var(--s-3) var(--s-4);
  font-size: 11px;
  font-weight: 600;
  color: var(--c-text-mute);
  text-transform: uppercase;
  letter-spacing: 0.07em;
  white-space: nowrap;
}

.table td {
  padding: var(--s-3) var(--s-4);
  border-bottom: 1px solid var(--c-border);
  color: var(--c-text);
  vertical-align: middle;
}

.table tbody tr:last-child td { border-bottom: none; }

.row {
  cursor: pointer;
  transition: background var(--transition-fast);
}
.row:hover td { background: var(--c-accent-50); }

.nameCell { font-weight: 600; }
.numCell  { color: var(--c-text-mute); white-space: nowrap; }
.colNum   { width: 100px; }
.colWide  { width: 180px; }

/* ── Pass rate sparkbar ──────────────────────────────────────────── */
.rateWrap { display: flex; align-items: center; gap: var(--s-2); }

.sparkBar {
  width: 80px;
  height: 6px;
  border-radius: 3px;
  overflow: hidden;
  display: flex;
  background: var(--c-border);
}

.sparkPass { background: var(--c-pass); height: 100%; }
.sparkFail { background: var(--c-fail); height: 100%; }

.rateVal { font-size: 13px; color: var(--c-text); white-space: nowrap; }

/* ── Deviation colours ───────────────────────────────────────────── */
.devOk   { color: var(--c-pass); font-weight: 500; }
.devFail { color: var(--c-fail); font-weight: 600; }

.muted { color: var(--c-text-mute); }
.empty { padding: var(--s-6); text-align: center; color: var(--c-text-mute); font-size: 14px; }
```

- [ ] **Step 3: Start the dev server and visually verify the History page**

```bash
cd /Users/subhanshubiswas/Projects/Calibration/apps/web
npm run dev
```

Open `http://localhost:5173/calibrations` and check:
- Table shows Batch name, Status, Loggers, Pass rate (sparkbar + %), Max dev., Date columns
- Hovering a row produces a pale blue background transition
- Clicking a row navigates to the batch detail page
- "Processing" status pills pulse

- [ ] **Step 4: Commit**

```bash
git add apps/web/src/pages/HistoryPage.tsx apps/web/src/pages/HistoryPage.module.css
git commit -m "feat(web): redesign HistoryPage with rich data table, sparkbar, and hover animations"
```

---

## Task 7: RunDetailPage — stat strip, search, view toggle, table+card

**Files:**
- Modify: `apps/web/src/pages/RunDetailPage.tsx`
- Modify: `apps/web/src/pages/RunDetailPage.module.css`

**Context:** The current page has a tabs UI (loggers / setpoints / conditions / audit). We're replacing it with: a stat strip derived from `run.results`, a toolbar with live search + verdict filter + view toggle, and the cert table/card grid. Batch configuration (setpoints, dates, files) moves into a `<details>` disclosure element below the certs.

The `run.results` array (type `LoggerResult[]`) already has: `id`, `sheet_name`, `verdict`, `max_deviation_c`, `cert_no`, `per_setpoint` (array of `PerSetpoint` with `target_c`, `ref_c`, `cal_c`, `dev_c`, `within_tol`).

Individual cert download URL: `GET /api/runs/:runId/results/:resultId/certificate`

- [ ] **Step 1: Replace RunDetailPage.tsx**

Write the entire file `apps/web/src/pages/RunDetailPage.tsx`:

```tsx
import { useQuery } from "@tanstack/react-query";
import { useState, useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiFetch } from "../api/client";
import type { LoggerResult, RunDetail } from "../api/types";
import { StatusPill } from "../components/StatusPill";
import styles from "./RunDetailPage.module.css";

type ViewMode = "table" | "cards";

function fmt(dt: string) {
  return new Date(dt).toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function DevBar({ value, withinTol }: { value: number | null; withinTol: boolean }) {
  if (value === null) return <span className={styles.muted}>—</span>;
  const w = Math.min(Math.abs(value) / 2.0 * 80, 80);
  return (
    <div className={styles.devWrap}>
      <div
        className={withinTol ? styles.devBarPass : styles.devBarFail}
        style={{ width: `${w}px` }}
      />
      <span className={withinTol ? styles.devValPass : styles.devValFail}>
        {value.toFixed(2)}
      </span>
    </div>
  );
}

function CertCard({ result, runId }: { result: LoggerResult; runId: string }) {
  const isFail = result.verdict === "fail";
  return (
    <div className={`${styles.card} ${isFail ? styles.cardFail : ""}`}>
      <div className={styles.cardTop}>
        <span className={`${styles.certNo} ${isFail ? styles.certNoFail : ""}`}>
          {result.cert_no ? `No. ${result.cert_no}` : "No cert"}
        </span>
        <StatusPill value={result.verdict} />
      </div>
      <div className={styles.cardLogger}>{result.sheet_name}</div>
      <div className={styles.cardBottom}>
        <span className={`${styles.cardDev} ${isFail ? styles.cardDevFail : ""}`}>
          {result.max_deviation_c !== null ? `${result.max_deviation_c.toFixed(2)}°C max` : "—"}
        </span>
        {result.cert_no && (
          <a
            href={`/api/runs/${runId}/results/${result.id}/certificate`}
            download
            className={styles.dlBtn}
            onClick={(e) => e.stopPropagation()}
          >
            ↓
          </a>
        )}
      </div>
    </div>
  );
}

export function RunDetailPage() {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const [view, setView] = useState<ViewMode>("table");
  const [search, setSearch] = useState("");
  const [verdictFilter, setVerdictFilter] = useState<"" | "pass" | "fail">("");

  const { data: run, isLoading, error } = useQuery<RunDetail>({
    queryKey: ["run", id],
    queryFn: () => apiFetch<RunDetail>(`/api/runs/${id}`),
    refetchInterval: (query) => {
      const d = query.state.data as RunDetail | undefined;
      return d?.status === "processing" ? 3000 : false;
    },
  });

  const filtered = useMemo(() => {
    if (!run) return [];
    const q = search.toLowerCase();
    return run.results.filter((r) => {
      const matchSearch =
        !q ||
        (r.cert_no?.toLowerCase().includes(q) ?? false) ||
        r.sheet_name.toLowerCase().includes(q);
      const matchVerdict = !verdictFilter || r.verdict === verdictFilter;
      return matchSearch && matchVerdict;
    });
  }, [run, search, verdictFilter]);

  const stats = useMemo(() => {
    if (!run || run.results.length === 0) return null;
    const passed = run.results.filter((r) => r.verdict === "pass").length;
    const failed = run.results.filter((r) => r.verdict === "fail").length;
    const total = run.results.length;
    const devs = run.results
      .map((r) => r.max_deviation_c)
      .filter((d): d is number => d !== null);
    return {
      passed,
      failed,
      passRate: total > 0 ? ((passed / total) * 100).toFixed(1) : null,
      maxDev: devs.length > 0 ? Math.max(...devs).toFixed(2) : null,
    };
  }, [run]);

  if (isLoading) return <div className={styles.loading}>Loading…</div>;
  if (error || !run) return <div className={styles.loading}>Run not found.</div>;

  return (
    <div className={styles.page}>
      {/* ── Header ── */}
      <div className={styles.header}>
        <button className={styles.back} onClick={() => nav("/calibrations")}>← History</button>
        <div className={styles.headerRow}>
          <div className={styles.headerLeft}>
            <h2 className={styles.heading}>{run.batch_name}</h2>
            <div className={styles.headMeta}>
              <StatusPill value={run.status} />
              <span className={styles.metaDot}>·</span>
              <span className={styles.metaText}>{fmt(run.created_at)}</span>
              {run.results.length > 0 && (
                <>
                  <span className={styles.metaDot}>·</span>
                  <span className={styles.metaText}>{run.results.length} loggers</span>
                </>
              )}
            </div>
          </div>
          {run.status === "complete" && (
            <a href={`/api/runs/${id}/results.zip`} download className={styles.btnPrimary}>
              ↓ Download all (.zip)
            </a>
          )}
        </div>
      </div>

      {run.failure_reason && (
        <div className={styles.errorBanner}>
          {run.failure_reason.message ?? "Processing failed"}
        </div>
      )}

      {/* ── Stat strip ── */}
      {stats && (
        <div className={styles.statStrip}>
          <div className={styles.statItem}>
            <span className={`${styles.statVal} ${styles.statPass}`}>{stats.passed}</span>
            <span className={styles.statLbl}>Pass</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={`${styles.statVal} ${stats.failed > 0 ? styles.statFail : ""}`}>{stats.failed}</span>
            <span className={styles.statLbl}>Fail</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={styles.statVal}>{stats.passRate ?? "—"}%</span>
            <span className={styles.statLbl}>Pass rate</span>
          </div>
          <div className={styles.statDivider} />
          <div className={styles.statItem}>
            <span className={styles.statVal}>{stats.maxDev ? `${stats.maxDev}°C` : "—"}</span>
            <span className={styles.statLbl}>Max dev.</span>
          </div>
        </div>
      )}

      {/* ── Toolbar ── */}
      <div className={styles.toolbar}>
        <input
          className={styles.search}
          placeholder="Search cert no. or logger serial…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button
          className={`${styles.filterPill} ${verdictFilter === "" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("")}
        >All</button>
        <button
          className={`${styles.filterPill} ${verdictFilter === "pass" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("pass")}
        >Pass</button>
        <button
          className={`${styles.filterPill} ${verdictFilter === "fail" ? styles.filterActive : ""}`}
          onClick={() => setVerdictFilter("fail")}
        >Fail</button>
        <div className={styles.viewToggle}>
          <button
            className={`${styles.vtBtn} ${view === "table" ? styles.vtActive : ""}`}
            onClick={() => setView("table")}
          >≡ Table</button>
          <button
            className={`${styles.vtBtn} ${view === "cards" ? styles.vtActive : ""}`}
            onClick={() => setView("cards")}
          >⊞ Cards</button>
        </div>
      </div>

      {/* ── Content: table or cards ── */}
      <div className={styles.viewArea}>
        {run.results.length === 0 ? (
          <p className={styles.empty}>No results yet.</p>
        ) : view === "table" ? (
          <div className={`${styles.tableWrap} ${styles.viewIn}`}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Cert no.</th>
                  <th>Logger serial</th>
                  <th>Verdict</th>
                  {run.results[0]?.per_setpoint.map((sp) => (
                    <th key={sp.target_c}>{sp.target_c > 0 ? "+" : ""}{sp.target_c}°C</th>
                  ))}
                  <th>Max dev.</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr><td colSpan={5 + (run.results[0]?.per_setpoint.length ?? 0)} className={styles.empty}>No results match</td></tr>
                ) : (
                  filtered.map((r) => (
                    <tr key={r.id} className={r.verdict === "fail" ? styles.rowFail : styles.rowPass}>
                      <td className={`${styles.certNoCell} ${r.verdict === "fail" ? styles.certNoFail : ""}`}>
                        {r.cert_no ?? "—"}
                      </td>
                      <td className={styles.serialCell}>{r.sheet_name}</td>
                      <td><StatusPill value={r.verdict} /></td>
                      {r.per_setpoint.map((sp) => (
                        <td key={sp.target_c}>
                          <DevBar value={sp.dev_c} withinTol={sp.within_tol} />
                        </td>
                      ))}
                      <td className={r.verdict === "fail" ? styles.devValFail : styles.devValPass}>
                        {r.max_deviation_c !== null ? `${r.max_deviation_c.toFixed(2)}°C` : "—"}
                      </td>
                      <td>
                        {r.cert_no && (
                          <a
                            href={`/api/runs/${id}/results/${r.id}/certificate`}
                            download
                            className={styles.dlBtn}
                          >↓</a>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        ) : (
          <div className={`${styles.cardGrid} ${styles.viewIn}`}>
            {filtered.length === 0 ? (
              <p className={styles.empty}>No results match</p>
            ) : (
              filtered.map((r) => <CertCard key={r.id} result={r} runId={id!} />)
            )}
          </div>
        )}
      </div>

      {/* ── Batch configuration (collapsible) ── */}
      <details className={styles.batchConfig}>
        <summary className={styles.batchConfigSummary}>Batch configuration</summary>
        <div className={styles.batchConfigBody}>
          <div className={styles.cfgGrid}>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Test date</span><span>{run.test_date_jp}</span></div>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Cert date</span><span>{run.doc_date_jp}</span></div>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Threshold</span><span>±{run.threshold_c}°C</span></div>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Start cert no.</span><span>{run.start_cert_no}</span></div>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Reference files</span>
              <span>{run.reference_files.map((f) => f.original_name).join(", ") || "—"}</span>
            </div>
            <div className={styles.cfgItem}><span className={styles.cfgLabel}>Calibration file</span>
              <span>{run.calibration_file?.original_name ?? "—"}</span>
            </div>
          </div>
          <div className={styles.cfgSetpoints}>
            <span className={styles.cfgLabel}>Setpoints</span>
            <div className={styles.setpointList}>
              {run.setpoints.map((sp: { target_c: number; start_at: string; end_at: string }) => (
                <span key={sp.target_c} className={styles.setpointChip}>
                  {sp.target_c > 0 ? "+" : ""}{sp.target_c}°C
                </span>
              ))}
            </div>
          </div>
        </div>
      </details>
    </div>
  );
}
```

- [ ] **Step 2: Replace RunDetailPage.module.css**

Write the entire file `apps/web/src/pages/RunDetailPage.module.css`:

```css
.page {
  padding: var(--s-6);
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: var(--s-5);
  animation: fadeSlideUp var(--transition-slow) both;
}

.loading { padding: var(--s-6); color: var(--c-text-mute); }

/* ── Header ───────────────────────────────────────────────────────── */
.header { display: flex; flex-direction: column; gap: var(--s-2); }

.back {
  background: none;
  border: none;
  cursor: pointer;
  color: var(--color-brand-electric);
  font-size: 13px;
  font-weight: 500;
  padding: 0;
  align-self: flex-start;
  transition: opacity var(--transition-fast);
}
.back:hover { opacity: 0.7; }

.headerRow { display: flex; align-items: flex-start; justify-content: space-between; gap: var(--s-4); }
.headerLeft { display: flex; flex-direction: column; gap: var(--s-2); }

.heading {
  font-family: var(--font-heading);
  font-size: 28px;
  font-weight: 500;
  letter-spacing: -0.03em;
  color: var(--color-boardroom-navy);
  margin: 0;
}

.headMeta { display: flex; align-items: center; gap: var(--s-2); flex-wrap: wrap; }
.metaDot  { color: var(--c-text-mute); }
.metaText { font-size: 13px; color: var(--c-text-mute); }

.btnPrimary {
  background: var(--color-brand-electric);
  color: #fff;
  border: none;
  border-radius: var(--radius-pill);
  padding: 10px var(--s-5);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
  display: inline-block;
  white-space: nowrap;
  flex-shrink: 0;
  transition: background var(--transition-fast);
}
.btnPrimary:hover { background: var(--c-accent-700); }

.errorBanner {
  background: #fee2e2;
  border: 1px solid var(--c-fail);
  border-radius: var(--radius-card);
  padding: var(--s-3) var(--s-4);
  color: var(--c-fail);
  font-size: 14px;
}

/* ── Stat strip ───────────────────────────────────────────────────── */
.statStrip {
  display: flex;
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  overflow: hidden;
}

.statItem {
  flex: 1;
  padding: var(--s-4) var(--s-5);
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.statDivider { width: 1px; background: var(--c-border); flex-shrink: 0; }

.statVal {
  font-family: var(--font-heading);
  font-size: 22px;
  font-weight: 600;
  color: var(--color-boardroom-navy);
  line-height: 1;
  letter-spacing: -0.02em;
}
.statPass { color: var(--c-pass); }
.statFail { color: var(--c-fail); }

.statLbl {
  font-size: 10px;
  font-weight: 600;
  color: var(--c-text-mute);
  text-transform: uppercase;
  letter-spacing: 0.07em;
}

/* ── Toolbar ──────────────────────────────────────────────────────── */
.toolbar { display: flex; gap: var(--s-2); align-items: center; flex-wrap: wrap; }

.search {
  flex: 1;
  min-width: 200px;
  padding: 9px 12px;
  border: none;
  border-bottom: 1.5px solid var(--color-input-border);
  font-size: 14px;
  background: transparent;
  color: var(--c-text);
  outline: none;
  transition: border-bottom-color var(--transition-fast);
}
.search:focus { border-bottom-color: var(--color-brand-electric); }

.filterPill {
  border: 1px solid var(--c-border);
  border-radius: var(--radius-pill);
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 500;
  background: var(--c-surface);
  color: var(--c-text-mute);
  cursor: pointer;
  transition: border-color var(--transition-fast), color var(--transition-fast), background var(--transition-fast);
}
.filterPill:hover { border-color: var(--c-accent-300); color: var(--c-accent-500); }
.filterActive {
  border-color: var(--color-brand-electric);
  color: var(--color-brand-electric);
  background: var(--c-accent-50);
}

.viewToggle {
  display: flex;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-pill);
  overflow: hidden;
  margin-left: auto;
}
.vtBtn {
  background: var(--c-surface);
  border: none;
  padding: 7px 14px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  color: var(--c-text-mute);
  transition: background var(--transition-fast), color var(--transition-fast);
}
.vtActive { background: var(--color-boardroom-navy); color: #fff; }

/* ── View area (crossfade) ────────────────────────────────────────── */
.viewArea { min-height: 200px; }

.viewIn {
  animation: fadeSlideUp var(--transition-base) both;
}

/* ── Table view ───────────────────────────────────────────────────── */
.tableWrap {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  overflow: hidden;
}

.table { width: 100%; border-collapse: collapse; font-size: 13px; }

.table th {
  text-align: left;
  padding: var(--s-3) var(--s-4);
  font-size: 10px;
  font-weight: 600;
  color: var(--c-text-mute);
  text-transform: uppercase;
  letter-spacing: 0.07em;
  border-bottom: 1px solid var(--c-border);
  white-space: nowrap;
}

.table td {
  padding: var(--s-3) var(--s-4);
  border-bottom: 1px solid var(--c-border);
  vertical-align: middle;
}
.table tbody tr:last-child td { border-bottom: none; }

.rowPass { transition: background var(--transition-fast); }
.rowPass:hover td { background: var(--c-accent-50); }
.rowFail { background: #fff8f8; transition: background var(--transition-fast); }
.rowFail:hover td { background: #fee2e2; }

.certNoCell { font-weight: 700; color: var(--color-boardroom-navy); font-size: 12px; }
.certNoFail { color: var(--c-fail) !important; }
.serialCell { color: var(--c-text-mute); font-size: 12px; }

/* ── Deviation bar ────────────────────────────────────────────────── */
.devWrap { display: flex; align-items: center; gap: 6px; }
.devBarPass { height: 4px; border-radius: 2px; background: var(--c-pass); min-width: 2px; }
.devBarFail { height: 4px; border-radius: 2px; background: var(--c-fail); min-width: 2px; }
.devValPass { font-size: 11px; color: var(--c-pass); white-space: nowrap; }
.devValFail { font-size: 11px; color: var(--c-fail); font-weight: 600; white-space: nowrap; }

/* ── Download button ──────────────────────────────────────────────── */
.dlBtn {
  display: inline-block;
  border: 1px solid var(--c-border);
  border-radius: var(--radius-pill);
  padding: 4px 10px;
  font-size: 12px;
  color: var(--color-brand-electric);
  text-decoration: none;
  transition: background var(--transition-fast), border-color var(--transition-fast);
}
.dlBtn:hover { background: var(--c-accent-50); border-color: var(--color-brand-electric); }

/* ── Card grid view ───────────────────────────────────────────────── */
.cardGrid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: var(--s-4);
}

.card {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  padding: var(--s-4);
  display: flex;
  flex-direction: column;
  gap: var(--s-2);
  transition: transform var(--transition-base), box-shadow var(--transition-base), border-color var(--transition-base);
}
.card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-2);
  border-color: var(--c-accent-300);
}
.cardFail { border-color: #fca5a5; }
.cardFail:hover { border-color: var(--c-fail); }

.cardTop { display: flex; justify-content: space-between; align-items: flex-start; gap: var(--s-2); }
.certNo { font-size: 12px; font-weight: 700; color: var(--color-boardroom-navy); }
.certNoFail { color: var(--c-fail); }

.cardLogger { font-size: 11px; color: var(--c-text-mute); }

.cardBottom { display: flex; justify-content: space-between; align-items: center; margin-top: var(--s-1); }
.cardDev { font-size: 11px; color: var(--c-text-mute); }
.cardDevFail { color: var(--c-fail); font-weight: 600; }

/* ── Batch config (collapsible) ───────────────────────────────────── */
.batchConfig {
  background: var(--c-surface);
  border: 1px solid var(--c-border);
  border-radius: var(--radius-card);
  overflow: hidden;
}

.batchConfigSummary {
  padding: var(--s-4) var(--s-5);
  font-size: 13px;
  font-weight: 500;
  color: var(--c-text-mute);
  cursor: pointer;
  user-select: none;
  list-style: none;
  display: flex;
  align-items: center;
  gap: var(--s-2);
}
.batchConfigSummary::before { content: "›"; transition: transform var(--transition-fast); }
details[open] .batchConfigSummary::before { transform: rotate(90deg); }

.batchConfigBody { padding: var(--s-4) var(--s-5) var(--s-5); border-top: 1px solid var(--c-border); display: flex; flex-direction: column; gap: var(--s-4); }

.cfgGrid { display: grid; grid-template-columns: repeat(3, 1fr); gap: var(--s-3) var(--s-5); }
.cfgItem { display: flex; flex-direction: column; gap: 2px; }
.cfgLabel { font-size: 10px; font-weight: 600; color: var(--c-text-mute); text-transform: uppercase; letter-spacing: 0.07em; }

.cfgSetpoints { display: flex; flex-direction: column; gap: var(--s-2); }
.setpointList { display: flex; gap: var(--s-2); flex-wrap: wrap; }
.setpointChip {
  background: var(--c-accent-50);
  color: var(--color-brand-electric);
  border-radius: var(--radius-badge);
  padding: 3px 10px;
  font-size: 12px;
  font-weight: 500;
}

.muted { color: var(--c-text-mute); }
.empty { padding: var(--s-6); text-align: center; color: var(--c-text-mute); font-size: 14px; }
```

- [ ] **Step 3: Start the dev server and visually verify**

```bash
cd /Users/subhanshubiswas/Projects/Calibration/apps/web
npm run dev
```

Open `http://localhost:5173/calibrations` and click into any complete batch. Verify:
- Stat strip shows pass/fail counts, pass rate, max deviation
- Search input filters by cert number and logger serial in real time
- All/Pass/Fail filter pills compose correctly with search
- "≡ Table" / "⊞ Cards" toggle switches views with a fade animation
- Table: deviation bars are green (pass) or red (fail), failed rows have a red tint
- Cards: failed cards have a red border, cards lift on hover
- "↓" download links work for certs that have `cert_no`
- "Batch configuration" disclosure panel expands/collapses
- "← History" navigates back correctly

- [ ] **Step 4: Commit**

```bash
git add apps/web/src/pages/RunDetailPage.tsx apps/web/src/pages/RunDetailPage.module.css
git commit -m "feat(web): redesign RunDetailPage with stat strip, search, view toggle, and certificate browser"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ HistoryPage rich data table with pass rate sparkbar and max deviation — Task 6
- ✅ `pass_rate` and `max_deviation_c` added to API RunSummary — Task 1
- ✅ Frontend type update — Task 2
- ✅ RunDetailPage stat strip derived from results — Task 7
- ✅ Live search by cert no. and logger serial — Task 7
- ✅ All/Pass/Fail filter pills — Task 7
- ✅ Table/card view toggle — Task 7
- ✅ Table: deviation bars per setpoint, fail row highlight — Task 7
- ✅ Cards: cert no. prominent, logger serial, verdict, max dev, download — Task 7
- ✅ Individual cert download via existing endpoint — Task 7
- ✅ Batch config collapsible panel replacing old tabs — Task 7
- ✅ Animation tokens + page mount fade — Tasks 3, 4
- ✅ Processing pulse on StatusPill — Task 4
- ✅ StatTile hover lift — Task 5
- ✅ Row hover on history table — Task 6
- ✅ Card hover lift on cert cards — Task 7
- ✅ View toggle crossfade — Task 7 (`viewIn` animation on re-mount)
- ✅ Button/pill/search focus hover transitions — Tasks 6, 7

**Type consistency check:**
- `LoggerResult` in `types.ts` already has `id`, `sheet_name`, `verdict`, `max_deviation_c`, `cert_no`, `per_setpoint` — all accessed consistently across Task 7.
- `PerSetpoint` has `target_c`, `dev_c`, `within_tol` — used correctly in `DevBar` and column headers.
- `RunDetail.setpoints` typed as `SetpointConfig[]` in `types.ts` (`{ target_c, start_at, end_at }`) — Task 7 uses same shape with explicit type annotation.
