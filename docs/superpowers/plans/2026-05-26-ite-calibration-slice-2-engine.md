# ITE Calibration — Slice 2: Calibration Engine (no UI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the calibration engine from scratch inside `apps/api/ite_api/calibration/` and expose it via the `ite-api run-calibration` CLI subcommand. After this slice: a developer can point the CLI at a directory of fixtures and get a folder of `.docx` certificates whose field values match the known-good `Old Method/output/` reference outputs.

**Architecture:** Four pure-Python modules with one orchestrator. `ref_loader` auto-detects two CSV formats (`mc3000` datetime-first, `indexed` datetime-second), `cal_loader` reads a multi-sheet XLSX into per-sheet DataFrames, `matcher` runs the spec'd 3-step algorithm per setpoint, `docx_filler` does placeholder-replace into a `template.docx`. `engine.run_calibration` wires them together. CLI subcommand reuses the existing Typer `app`.

**Tech Stack:** Adds `pandas==2.2.3`, `openpyxl==3.1.5`, `python-docx==1.1.2` to `apps/api`. No DB, no HTTP, no UI in this slice.

**Spec interpretation:** The spec says CLI output should be "byte-equivalent (modulo timestamps) to a known-good Old Method output." `.docx` files are zip archives whose byte layout depends on libzip ordering and python-docx version — true byte equivalence is impractical. We instead require **data equivalence**: for each logger sheet in the test workbook, the new engine's output `.docx` must contain the same cert number, serial, dates, reference temperatures, calibration temperatures, and per-setpoint deviations as the corresponding `Old Method/output/Calibration_Certificate_<n>_*.docx`. The golden-file test extracts text + table values from both and asserts equality.

**Source-of-truth handling:** The legacy `src/engine/*.py` is the behavioral reference. Engineers **may read** it while implementing each module (it documents the 3-step algorithm, the CSV formats, the docx placeholder names). Engineers **must NOT copy or import** from it — the new code lives entirely under `apps/api/ite_api/calibration/` with no dependency on `src/`. The "fresh build" requirement (set during brainstorming) is preserved by keeping the new code independent and re-derived, not literally re-typed.

---

## File Structure

Files created or modified in this slice (relative to repo root):

```
apps/api/
├── pyproject.toml                                  # add pandas, openpyxl, python-docx
├── ite_api/
│   ├── calibration/
│   │   ├── __init__.py
│   │   ├── ref_loader.py                           # CSV format detection + load
│   │   ├── cal_loader.py                           # XLSX multi-sheet loader
│   │   ├── matcher.py                              # 3-step matching algorithm
│   │   ├── docx_filler.py                          # template placeholder replacement
│   │   └── engine.py                               # run_one_logger + run_calibration
│   └── cli.py                                      # add run-calibration subcommand
├── tests/
│   ├── calibration/
│   │   ├── __init__.py
│   │   ├── conftest.py                             # fixture paths
│   │   ├── test_ref_loader.py
│   │   ├── test_cal_loader.py
│   │   ├── test_matcher.py
│   │   ├── test_docx_filler.py
│   │   ├── test_engine.py
│   │   └── test_golden.py                          # end-to-end vs Old Method/output
│   └── fixtures/
│       └── calibration/
│           ├── reference.csv                       # copied from Old Method/Input/
│           ├── workbook.xlsx                       # copied from Old Method/Input/
│           ├── template.docx                       # copied from repo root template.docx
│           └── golden/                             # copied from Old Method/output/*.docx
│               └── Calibration_Certificate_*.docx
└── README.md                                       # add Slice 2 section
```

The new calibration package has NO imports from `src/`, `ite_api.auth`, `ite_api.db`, `ite_api.routes`, or `ite_api.main`. It's pure plumbing: paths in, paths out.

---

## Task 1: Add engine dependencies

**Files:**
- Modify: `apps/api/pyproject.toml`

- [ ] **Step 1: Add pandas, openpyxl, python-docx to `apps/api/pyproject.toml`**

In the `dependencies = [...]` array, append three new entries so the array reads:

```toml
dependencies = [
  "fastapi==0.115.6",
  "uvicorn[standard]==0.32.1",
  "pydantic==2.10.4",
  "email-validator==2.2.0",
  "pydantic-settings==2.7.0",
  "sqlalchemy==2.0.36",
  "alembic==1.14.0",
  "psycopg[binary]==3.2.3",
  "argon2-cffi==23.1.0",
  "pyjwt==2.10.1",
  "typer==0.15.1",
  "pandas==2.2.3",
  "openpyxl==3.1.5",
  "python-docx==1.1.2",
]
```

- [ ] **Step 2: Install**

From `apps/api/`:

```bash
.venv/bin/pip install -e ".[dev]" --quiet
.venv/bin/python -c "import pandas, openpyxl, docx; print('ok', pandas.__version__, openpyxl.__version__, docx.__version__)"
```

Expected: `ok 2.2.3 3.1.5 1.1.2`.

- [ ] **Step 3: Commit**

```bash
git add apps/api/pyproject.toml
git commit -m "feat(api): add pandas, openpyxl, python-docx for calibration engine"
```

---

## Task 2: Copy fixtures into apps/api/tests/fixtures/calibration/

**Files:**
- Create directory: `apps/api/tests/fixtures/calibration/`
- Create directory: `apps/api/tests/fixtures/calibration/golden/`
- Copy: `Old Method/Input/Calibration-Standard Data-260414.csv` → `apps/api/tests/fixtures/calibration/reference.csv`
- Copy: `Old Method/Input/No.190125020000856.2026-04-08 09_13_46-20260415_003951.xlsx` → `apps/api/tests/fixtures/calibration/workbook.xlsx`
- Copy: `template.docx` (repo root) → `apps/api/tests/fixtures/calibration/template.docx`
- Copy: every `Old Method/output/Calibration_Certificate_*.docx` → `apps/api/tests/fixtures/calibration/golden/`

- [ ] **Step 1: Create directories and copy files**

From repo root:

```bash
mkdir -p apps/api/tests/fixtures/calibration/golden
cp "Old Method/Input/Calibration-Standard Data-260414.csv" \
   apps/api/tests/fixtures/calibration/reference.csv
cp "Old Method/Input/No.190125020000856.2026-04-08 09_13_46-20260415_003951.xlsx" \
   apps/api/tests/fixtures/calibration/workbook.xlsx
cp template.docx apps/api/tests/fixtures/calibration/template.docx
cp "Old Method/output/"Calibration_Certificate_*.docx \
   apps/api/tests/fixtures/calibration/golden/
```

- [ ] **Step 2: Verify fixture inventory**

```bash
ls apps/api/tests/fixtures/calibration/
ls apps/api/tests/fixtures/calibration/golden/ | head -5
wc -c apps/api/tests/fixtures/calibration/{reference.csv,workbook.xlsx,template.docx}
```

Expected: `reference.csv`, `workbook.xlsx`, `template.docx`, and `golden/` listed; at least one `Calibration_Certificate_*.docx` in `golden/`; non-zero byte counts.

- [ ] **Step 3: Create `apps/api/tests/calibration/__init__.py`** (empty)

- [ ] **Step 4: Create `apps/api/tests/calibration/conftest.py`**

```python
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent.parent / "fixtures" / "calibration"


@pytest.fixture()
def fixtures_dir() -> Path:
    return FIXTURES


@pytest.fixture()
def reference_csv() -> Path:
    return FIXTURES / "reference.csv"


@pytest.fixture()
def workbook_xlsx() -> Path:
    return FIXTURES / "workbook.xlsx"


@pytest.fixture()
def template_docx() -> Path:
    return FIXTURES / "template.docx"


@pytest.fixture()
def golden_dir() -> Path:
    return FIXTURES / "golden"
```

- [ ] **Step 5: Commit**

```bash
git add apps/api/tests/fixtures apps/api/tests/calibration/__init__.py apps/api/tests/calibration/conftest.py
git commit -m "test(calibration): copy reference fixtures + golden outputs from Old Method"
```

---

## Task 3: `ref_loader.py` — file open with encoding fallback

**Files:**
- Create: `apps/api/ite_api/calibration/__init__.py`
- Create: `apps/api/ite_api/calibration/ref_loader.py`
- Create: `apps/api/tests/calibration/test_ref_loader.py`

The legacy reference at `src/engine/ref_loader.py` documents the two formats; read it for context but do not import or copy from it.

- [ ] **Step 1: Write the failing test**

`apps/api/tests/calibration/test_ref_loader.py`:

```python
from ite_api.calibration.ref_loader import _try_open


def test_try_open_handles_shift_jis(reference_csv):
    # The fixture is real Shift-JIS encoded data from the Old Method.
    with _try_open(reference_csv) as f:
        head = f.read(500)
    assert head  # non-empty
    assert "�" not in head  # no replacement chars from bad decoding
```

Run: `cd apps/api && ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_ref_loader.py -v`
Expected: `ModuleNotFoundError: No module named 'ite_api.calibration'`.

- [ ] **Step 2: Create `apps/api/ite_api/calibration/__init__.py`** (empty file).

- [ ] **Step 3: Create `apps/api/ite_api/calibration/ref_loader.py`** with `_try_open` only:

```python
"""Reference logger CSV loading — supports multiple files and auto-format detection."""

from pathlib import Path


def _try_open(path: Path):
    """Open `path` for text reading, trying common Japanese loggers' encodings first."""
    for enc in ("shift_jis", "cp932", "utf-8"):
        try:
            f = open(path, encoding=enc)
            f.read(1)  # force a decode attempt on the first byte
            f.seek(0)
            return f
        except UnicodeDecodeError:
            continue
    return open(path, encoding="utf-8", errors="replace")
```

- [ ] **Step 4: Run the test**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_ref_loader.py -v
```

Expected: 1 passed.

- [ ] **Step 5: Commit**

```bash
git add apps/api/ite_api/calibration/__init__.py apps/api/ite_api/calibration/ref_loader.py apps/api/tests/calibration/test_ref_loader.py
git commit -m "feat(calibration): add ref_loader._try_open with encoding fallback"
```

---

## Task 4: `ref_loader.py` — format detection (`mc3000` vs `indexed`)

**Files:**
- Modify: `apps/api/ite_api/calibration/ref_loader.py`
- Modify: `apps/api/tests/calibration/test_ref_loader.py`

The two formats:
- **`mc3000`** — datetime is the first comma-field. Example line: `2026/04/14 10:30:00,5.12,...`
- **`indexed`** — datetime is the second comma-field. Example line: `123,2026/04/14 10:30:00,5.12,...`

- [ ] **Step 1: Append the failing test**

Append to `apps/api/tests/calibration/test_ref_loader.py`:

```python
from ite_api.calibration.ref_loader import detect_format


def test_detect_format_indexed(reference_csv):
    # The Old Method fixture uses the indexed format.
    assert detect_format(reference_csv) == "indexed"


def test_detect_format_mc3000(tmp_path):
    p = tmp_path / "m.csv"
    p.write_text("header line\n\n2026/04/14 10:30:00,5.12,foo\n2026/04/14 10:31:00,5.13,foo\n")
    assert detect_format(p) == "mc3000"
```

Run: expected one failure (`detect_format` not yet defined).

- [ ] **Step 2: Append to `ref_loader.py`**

```python
import re

_DATE_FIRST_RE = re.compile(r"^\d{4}/\d{2}/\d{2}")
_DATE_SECOND_RE = re.compile(r"^[^,]+,\d{4}/\d{2}/\d{2}")


def detect_format(path: Path) -> str:
    """Return 'mc3000' (datetime first field), 'indexed' (datetime second field), or 'unknown'."""
    with _try_open(path) as f:
        scanned = 0
        for line in f:
            line = line.strip()
            if not line:
                continue
            if _DATE_FIRST_RE.match(line):
                return "mc3000"
            if _DATE_SECOND_RE.match(line):
                return "indexed"
            scanned += 1
            if scanned >= 200:
                break
    return "unknown"
```

- [ ] **Step 3: Verify tests pass**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_ref_loader.py -v
```

Expected: 3 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/ref_loader.py apps/api/tests/calibration/test_ref_loader.py
git commit -m "feat(calibration): add ref_loader.detect_format for mc3000 vs indexed CSVs"
```

---

## Task 5: `ref_loader.py` — `load_ref_auto` + `combine_refs`

**Files:**
- Modify: `apps/api/ite_api/calibration/ref_loader.py`
- Modify: `apps/api/tests/calibration/test_ref_loader.py`

The output: a `pandas.DataFrame` with two columns: `timestamp` (datetime64) and `temp` (float).

- [ ] **Step 1: Append the failing test**

Append to `apps/api/tests/calibration/test_ref_loader.py`:

```python
import pandas as pd

from ite_api.calibration.ref_loader import combine_refs, load_ref_auto


def test_load_ref_auto_indexed_fixture_returns_dataframe(reference_csv):
    df = load_ref_auto(reference_csv)
    assert isinstance(df, pd.DataFrame)
    assert set(df.columns) == {"timestamp", "temp"}
    assert len(df) > 0
    assert pd.api.types.is_datetime64_any_dtype(df["timestamp"])
    assert pd.api.types.is_float_dtype(df["temp"])


def test_combine_refs_concatenates_and_sorts(reference_csv):
    df1 = load_ref_auto(reference_csv)
    df2 = load_ref_auto(reference_csv)
    combined = combine_refs([df1, df2])
    assert len(combined) == 2 * len(df1)
    # Ensure sorted by timestamp
    ts = combined["timestamp"].tolist()
    assert ts == sorted(ts)
```

- [ ] **Step 2: Implement in `ref_loader.py`**

Append:

```python
from collections.abc import Iterable

import pandas as pd

# Date format used by both CSV formats
_DT_FMT = "%Y/%m/%d %H:%M:%S"


def _parse_line(line: str, fmt: str) -> tuple | None:
    parts = [p.strip() for p in line.split(",")]
    if fmt == "mc3000":
        if len(parts) < 2:
            return None
        ts_str, temp_str = parts[0], parts[1]
    elif fmt == "indexed":
        if len(parts) < 3:
            return None
        ts_str, temp_str = parts[1], parts[2]
    else:
        return None
    try:
        from datetime import datetime
        ts = datetime.strptime(ts_str, _DT_FMT)
    except ValueError:
        return None
    try:
        temp = float(temp_str)
    except ValueError:
        return None
    return ts, temp


def load_ref_auto(path: Path) -> pd.DataFrame:
    """Detect the CSV format and load it into a DataFrame with columns ['timestamp', 'temp']."""
    fmt = detect_format(path)
    if fmt == "unknown":
        raise ValueError(f"Could not detect CSV format for {path}")
    rows: list[tuple] = []
    with _try_open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parsed = _parse_line(line, fmt)
            if parsed is not None:
                rows.append(parsed)
    df = pd.DataFrame(rows, columns=["timestamp", "temp"])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df["temp"] = df["temp"].astype(float)
    return df


def combine_refs(dfs: Iterable[pd.DataFrame]) -> pd.DataFrame:
    """Concatenate multiple reference DataFrames into one, sorted by timestamp."""
    out = pd.concat(list(dfs), ignore_index=True)
    out = out.sort_values("timestamp").reset_index(drop=True)
    return out
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_ref_loader.py -v
```

Expected: 5 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/ref_loader.py apps/api/tests/calibration/test_ref_loader.py
git commit -m "feat(calibration): add load_ref_auto + combine_refs"
```

---

## Task 6: `cal_loader.py` — multi-sheet XLSX loader

**Files:**
- Create: `apps/api/ite_api/calibration/cal_loader.py`
- Create: `apps/api/tests/calibration/test_cal_loader.py`

The calibration workbook has one sheet per logger. Each sheet has a header row and data rows with columns roughly `#, DateTime, Temp1, Temp2, Hum1, Hum2, Light, Vibration, Battery`. The legacy code uses column index `[1]` for datetime and `[3]` for `Temp2`. Verify against the fixture during test.

- [ ] **Step 1: Write the failing test**

`apps/api/tests/calibration/test_cal_loader.py`:

```python
import pandas as pd

from ite_api.calibration.cal_loader import load_calibration_sheet, load_workbook


def test_load_workbook_returns_sheet_names(workbook_xlsx):
    wb, names = load_workbook(workbook_xlsx)
    assert len(names) > 0


def test_load_calibration_sheet_returns_typed_dataframe(workbook_xlsx):
    wb, names = load_workbook(workbook_xlsx)
    df = load_calibration_sheet(wb, names[0])
    assert isinstance(df, pd.DataFrame)
    assert set(df.columns) == {"timestamp", "temp"}
    assert len(df) > 0
    assert pd.api.types.is_datetime64_any_dtype(df["timestamp"])
    assert pd.api.types.is_float_dtype(df["temp"])
```

Run: expected to fail (module missing).

- [ ] **Step 2: Create `apps/api/ite_api/calibration/cal_loader.py`**

```python
"""Calibration logger XLSX loading — one sheet per logger."""

from datetime import datetime
from pathlib import Path

import openpyxl
import pandas as pd


def load_workbook(path: Path) -> tuple[openpyxl.workbook.workbook.Workbook, list[str]]:
    """Open the calibration workbook in data-only mode; return (workbook, sheet_names)."""
    wb = openpyxl.load_workbook(str(path), data_only=True)
    return wb, wb.sheetnames


def load_calibration_sheet(wb, sheet_name: str) -> pd.DataFrame:
    """Load one logger sheet into a DataFrame with columns ['timestamp', 'temp']."""
    ws = wb[sheet_name]
    rows: list[tuple[datetime, float]] = []
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row, values_only=True):
        if len(row) < 4 or row[1] is None:
            continue
        ts_value = row[1]
        if isinstance(ts_value, datetime):
            ts = ts_value
        else:
            try:
                ts = datetime.strptime(str(ts_value).strip(), "%Y-%m-%d %H:%M:%S")
            except ValueError:
                continue
        try:
            temp = float(str(row[3]).strip())
        except (ValueError, TypeError):
            continue
        rows.append((ts, temp))
    df = pd.DataFrame(rows, columns=["timestamp", "temp"])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df["temp"] = df["temp"].astype(float)
    return df
```

- [ ] **Step 3: Run tests**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_cal_loader.py -v
```

Expected: 2 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/cal_loader.py apps/api/tests/calibration/test_cal_loader.py
git commit -m "feat(calibration): add cal_loader for multi-sheet XLSX"
```

---

## Task 7: `matcher.py` — helpers `find_reference_value` + `find_ref_near_timestamp`

**Files:**
- Create: `apps/api/ite_api/calibration/matcher.py`
- Create: `apps/api/tests/calibration/test_matcher.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/calibration/test_matcher.py`:

```python
from datetime import datetime, timedelta

import pandas as pd
import pytest

from ite_api.calibration.matcher import find_ref_near_timestamp, find_reference_value


def _df(rows):
    df = pd.DataFrame(rows, columns=["timestamp", "temp"])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df


def test_find_reference_value_picks_closest_to_target():
    base = datetime(2026, 4, 14, 10, 0, 0)
    rows = [(base + timedelta(minutes=i), 5.0 + i * 0.1) for i in range(5)]
    df = _df(rows)
    val, ts = find_reference_value(
        df, target=5.25, time_start=base, time_end=base + timedelta(minutes=10)
    )
    assert val == pytest.approx(5.3)  # nearest neighbor to 5.25 in 5.0..5.4 grid
    assert ts == base + timedelta(minutes=3)


def test_find_reference_value_empty_window_returns_none():
    df = _df([(datetime(2026, 4, 14, 10, 0, 0), 5.0)])
    val, ts = find_reference_value(
        df, target=5.0,
        time_start=datetime(2026, 4, 13), time_end=datetime(2026, 4, 13, 12),
    )
    assert val is None and ts is None


def test_find_ref_near_timestamp():
    base = datetime(2026, 4, 14, 10, 0, 0)
    df = _df([(base + timedelta(minutes=i), float(i)) for i in range(5)])
    val, ts = find_ref_near_timestamp(
        df, cal_ts=base + timedelta(minutes=2, seconds=20),
        time_start=base, time_end=base + timedelta(hours=1),
    )
    assert ts == base + timedelta(minutes=2)
    assert val == 2.0
```

Run: expected to fail (module missing).

- [ ] **Step 2: Create `apps/api/ite_api/calibration/matcher.py`**

```python
"""Temperature matching — implements the 3-step algorithm.

Per target temperature (default {-40, 5, 40} °C) within a time window:
  1. Find the reference value closest to the target temperature → (ref_val, ref_ts).
  2. Among calibration readings within ±TOLERANCE of ref_val, pick the one closest in
     time to ref_ts. Done.
  3. If step 2 finds nothing within tolerance:
     a. Find the calibration reading closest to the target temperature → (cal_val, cal_ts).
     b. Find the reference reading closest in time to cal_ts → new_ref_val.
     c. If |cal_val - new_ref_val| <= TOLERANCE → use (new_ref_val, cal_val).
     d. Otherwise, fall back to searching for ANY ref within ±TOLERANCE of cal_val.
"""

from datetime import datetime

import pandas as pd

TARGETS: list[float] = [-40.0, 5.0, 40.0]
TOLERANCE = 0.5


def _window(df: pd.DataFrame, start: datetime, end: datetime) -> pd.DataFrame:
    mask = (df.timestamp >= start) & (df.timestamp <= end)
    return df.loc[mask].copy()


def find_reference_value(
    ref_df: pd.DataFrame, target: float, time_start: datetime, time_end: datetime
) -> tuple[float | None, datetime | None]:
    """Return the (temp, timestamp) of the ref reading nearest to `target` in the window."""
    subset = _window(ref_df, time_start, time_end)
    if subset.empty:
        return None, None
    subset["diff"] = (subset.temp - target).abs()
    i = subset["diff"].idxmin()
    return float(subset.loc[i, "temp"]), subset.loc[i, "timestamp"].to_pydatetime()


def find_ref_near_timestamp(
    ref_df: pd.DataFrame, cal_ts: datetime, time_start: datetime, time_end: datetime
) -> tuple[float | None, datetime | None]:
    """Return the (temp, timestamp) of the ref reading nearest in time to `cal_ts`."""
    subset = _window(ref_df, time_start, time_end)
    if subset.empty:
        return None, None
    subset["time_diff"] = (subset.timestamp - cal_ts).abs()
    i = subset["time_diff"].idxmin()
    return float(subset.loc[i, "temp"]), subset.loc[i, "timestamp"].to_pydatetime()
```

- [ ] **Step 3: Verify tests pass**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_matcher.py -v
```

Expected: 3 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/matcher.py apps/api/tests/calibration/test_matcher.py
git commit -m "feat(calibration): add matcher helpers (find_reference_value, find_ref_near_timestamp)"
```

---

## Task 8: `matcher.py` — `find_values_for_target` (3-step algorithm)

**Files:**
- Modify: `apps/api/ite_api/calibration/matcher.py`
- Modify: `apps/api/tests/calibration/test_matcher.py`

- [ ] **Step 1: Append the failing test**

Append to `apps/api/tests/calibration/test_matcher.py`:

```python
from ite_api.calibration.matcher import find_values_for_target


def test_step2_direct_match():
    base = datetime(2026, 4, 14, 10, 0, 0)
    end = base + timedelta(minutes=10)
    # Reference holds 5.0 at t=base; calibration holds 5.2 at t=base+30s (within tolerance).
    ref = _df([(base, 5.0), (base + timedelta(minutes=5), 5.0)])
    cal = _df([(base + timedelta(seconds=30), 5.2), (base + timedelta(minutes=5), 4.0)])
    ref_v, cal_v, adjusted = find_values_for_target(
        cal, ref, target=5.0, time_start=base, time_end=end
    )
    assert ref_v == 5.0
    assert cal_v == 5.2
    assert adjusted is False


def test_step3_fallback_when_no_direct_match():
    base = datetime(2026, 4, 14, 10, 0, 0)
    end = base + timedelta(minutes=10)
    # Reference has 5.0 only; calibration has only 7.0 (out of tolerance from 5.0).
    # Step 2 finds no cal within 5.0 ± 0.5. Step 3 looks for the cal nearest 5.0 (the 7.0),
    # then finds ref near that ts; |7.0 - 5.0| > 0.5, so step 3d searches for any ref
    # within 7.0 ± 0.5 — none. Result: target falls through.
    ref = _df([(base, 5.0)])
    cal = _df([(base, 7.0)])
    ref_v, cal_v, adjusted = find_values_for_target(
        cal, ref, target=5.0, time_start=base, time_end=end
    )
    assert adjusted is True
    # cal_v reflects the step-3 fallback path
    assert cal_v == 7.0


def test_empty_window_returns_target_as_ref():
    base = datetime(2026, 4, 14, 10, 0, 0)
    end = base + timedelta(minutes=10)
    ref = _df([])
    cal = _df([])
    ref_v, cal_v, adjusted = find_values_for_target(
        cal, ref, target=5.0, time_start=base, time_end=end
    )
    assert ref_v == 5.0
    assert cal_v is None
    assert adjusted is False
```

- [ ] **Step 2: Append `find_values_for_target` to `matcher.py`**

```python
def find_values_for_target(
    cal_df: pd.DataFrame,
    ref_df: pd.DataFrame,
    target: float,
    time_start: datetime,
    time_end: datetime,
) -> tuple[float | None, float | None, bool]:
    """Return (ref_value, cal_value, adjusted) per the 3-step algorithm.

    `adjusted=True` indicates the result came from the step-3 fallback path.
    """
    cal_subset = _window(cal_df, time_start, time_end)
    ref_subset = _window(ref_df, time_start, time_end)
    if cal_subset.empty or ref_subset.empty:
        return target, None, False

    # Step 1
    ref_val, ref_ts = find_reference_value(ref_subset, target, time_start, time_end)
    if ref_val is None:
        return target, None, False

    # Step 2: cal readings within tolerance of ref_val, pick closest in time to ref_ts
    near = cal_subset.loc[(cal_subset.temp - ref_val).abs() <= TOLERANCE].copy()
    if not near.empty:
        near["time_diff"] = (near.timestamp - ref_ts).abs()
        i = near["time_diff"].idxmin()
        return ref_val, float(near.loc[i, "temp"]), False

    # Step 3a: cal nearest to target
    cal_subset["diff_to_target"] = (cal_subset.temp - target).abs()
    j = cal_subset["diff_to_target"].idxmin()
    cal_val = float(cal_subset.loc[j, "temp"])
    cal_ts = cal_subset.loc[j, "timestamp"].to_pydatetime()

    # Step 3b: ref nearest in time to cal_ts
    new_ref_val, _ = find_ref_near_timestamp(ref_subset, cal_ts, time_start, time_end)
    if new_ref_val is not None and abs(cal_val - new_ref_val) <= TOLERANCE:
        return new_ref_val, cal_val, True

    # Step 3d: any ref within tolerance of cal_val
    broad = ref_subset.loc[(ref_subset.temp - cal_val).abs() <= TOLERANCE]
    if not broad.empty:
        broad = broad.copy()
        broad["diff"] = (broad.temp - cal_val).abs()
        k = broad["diff"].idxmin()
        return float(broad.loc[k, "temp"]), cal_val, True

    # No usable pairing — return target as ref, cal as we have it; flag adjusted
    return target, cal_val, True
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_matcher.py -v
```

Expected: 6 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/matcher.py apps/api/tests/calibration/test_matcher.py
git commit -m "feat(calibration): add find_values_for_target (3-step matcher)"
```

---

## Task 9: `docx_filler.py` — open template + text replacement helpers

**Files:**
- Create: `apps/api/ite_api/calibration/docx_filler.py`
- Create: `apps/api/tests/calibration/test_docx_filler.py`

The legacy `src/engine/docx_filler.py` documents the placeholder names used in the template. **Read it now** to learn the placeholder strings (e.g. `{CERT_NO}`, `{SERIAL}`, `{TEST_DATE}`, `{DOC_DATE}`, plus per-setpoint table cells). Reproduce the same placeholders in the new module. The template lives at `apps/api/tests/fixtures/calibration/template.docx`.

- [ ] **Step 1: Write the failing test**

`apps/api/tests/calibration/test_docx_filler.py`:

```python
from docx import Document

from ite_api.calibration.docx_filler import replace_text_everywhere


def test_replace_text_everywhere_updates_body_and_headers(template_docx, tmp_path):
    doc = Document(str(template_docx))
    # Use placeholders the template is known to contain.
    # If the template doesn't have these exact placeholders, this test will guide us
    # to update both — read src/engine/docx_filler.py for the real placeholder set.
    mapping = {
        "0000001644": "0000001999",  # default template cert number → real cert number
    }
    replace_text_everywhere(doc, mapping)
    out = tmp_path / "out.docx"
    doc.save(str(out))
    saved = Document(str(out))
    # Extract all body + header text and verify substitution happened
    all_text = "\n".join(p.text for p in saved.paragraphs)
    for section in saved.sections:
        for p in section.header.paragraphs:
            all_text += "\n" + p.text
        for p in section.footer.paragraphs:
            all_text += "\n" + p.text
    assert "0000001999" in all_text
    assert "0000001644" not in all_text
```

- [ ] **Step 2: Create `apps/api/ite_api/calibration/docx_filler.py`**

```python
"""Word template filling — placeholder text replacement across body, headers, and footers."""

from docx.document import Document as _DocType
from docx.oxml.ns import qn
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph


def _iter_block_items(parent):
    if isinstance(parent, _DocType):
        parent_elm = parent.element.body
    elif isinstance(parent, _Cell):
        parent_elm = parent._tc
    else:
        return
    for child in parent_elm.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def _replace_in_paragraph(paragraph: Paragraph, mapping: dict[str, str]) -> None:
    if not paragraph.runs:
        return
    full_text = "".join(r.text or "" for r in paragraph.runs)
    needs = any(k in full_text for k in mapping)
    if not needs:
        return
    new_text = full_text
    for old, new in mapping.items():
        new_text = new_text.replace(old, new)
    # Collapse to a single run preserving the first run's formatting.
    paragraph.runs[0].text = new_text
    for r in paragraph.runs[1:]:
        r.text = ""


def _replace_in_blocks(parent, mapping: dict[str, str]) -> None:
    for block in _iter_block_items(parent):
        if isinstance(block, Paragraph):
            _replace_in_paragraph(block, mapping)
        elif isinstance(block, Table):
            for row in block.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)


def replace_text_everywhere(doc, mapping: dict[str, str]) -> None:
    """Replace placeholder text in body, headers, and footers of `doc`."""
    _replace_in_blocks(doc, mapping)
    for section in doc.sections:
        for p in section.header.paragraphs:
            _replace_in_paragraph(p, mapping)
        for table in section.header.tables:
            for row in table.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)
        for p in section.footer.paragraphs:
            _replace_in_paragraph(p, mapping)
        for table in section.footer.tables:
            for row in table.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_docx_filler.py -v
```

Expected: 1 passed. If the placeholder string `0000001644` is not in the template, inspect with `python -c "from docx import Document; d=Document('apps/api/tests/fixtures/calibration/template.docx'); print([p.text for p in d.paragraphs if p.text])"` and adjust the mapping in the test to a string that IS in the template.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/docx_filler.py apps/api/tests/calibration/test_docx_filler.py
git commit -m "feat(calibration): add docx_filler.replace_text_everywhere"
```

---

## Task 10: `docx_filler.py` — calibration table population

**Files:**
- Modify: `apps/api/ite_api/calibration/docx_filler.py`
- Modify: `apps/api/tests/calibration/test_docx_filler.py`

The template contains one results table with three setpoint rows (corresponding to -40 °C, 5 °C, 40 °C) and two value columns (Standard / reference, and Actual / calibration). The legacy `find_calibration_table` in `src/engine/docx_filler.py` returns `(table, col_std, col_act, row_map)`. Reproduce that here.

- [ ] **Step 1: Append the failing test**

```python
from ite_api.calibration.docx_filler import find_results_table, fill_results_table


def test_find_results_table_locates_the_setpoint_table(template_docx):
    doc = Document(str(template_docx))
    table, col_std, col_act, row_map = find_results_table(doc)
    assert table is not None
    assert isinstance(col_std, int) and isinstance(col_act, int)
    assert set(row_map.keys()) == {-40.0, 5.0, 40.0}


def test_fill_results_table_writes_each_setpoint_row(template_docx, tmp_path):
    doc = Document(str(template_docx))
    fill_results_table(doc, {
        -40.0: (-40.10, -40.05),
        5.0: (5.02, 5.04),
        40.0: (39.95, 40.01),
    })
    out = tmp_path / "out.docx"
    doc.save(str(out))
    saved = Document(str(out))
    table, col_std, col_act, row_map = find_results_table(saved)
    for target, (std, act) in [(-40.0, ("-40.10", "-40.05")),
                                (5.0, ("5.02", "5.04")),
                                (40.0, ("39.95", "40.01"))]:
        row = table.rows[row_map[target]]
        assert std in row.cells[col_std].text
        assert act in row.cells[col_act].text
```

- [ ] **Step 2: Append to `docx_filler.py`**

```python
import re

_TEMP_RE = re.compile(r"-?\d{1,3}(?:\.\d+)?")


def find_results_table(doc):
    """Locate the calibration results table.

    Heuristic: pick the table that contains rows whose first cell mentions one of
    the three target temperatures (-40, 5, 40). Returns (table, col_std, col_act, row_map).
    col_std and col_act are inferred from header text containing "標準" / "実測" or
    "Standard" / "Actual" (case-insensitive).
    """
    targets = {-40.0, 5.0, 40.0}
    for table in doc.tables:
        row_map: dict[float, int] = {}
        col_std, col_act = -1, -1
        # Header detection: scan row 0 cells
        header_cells = [c.text.strip() for c in table.rows[0].cells]
        for i, h in enumerate(header_cells):
            lh = h.lower()
            if "標準" in h or "standard" in lh or "ref" in lh:
                col_std = i
            if "実測" in h or "actual" in lh or "meas" in lh or "cal" in lh:
                col_act = i
        if col_std < 0 or col_act < 0:
            continue
        for r_idx, row in enumerate(table.rows):
            first = row.cells[0].text.strip()
            m = _TEMP_RE.search(first)
            if not m:
                continue
            try:
                val = float(m.group(0))
            except ValueError:
                continue
            if val in targets and val not in row_map:
                row_map[val] = r_idx
        if set(row_map.keys()) == targets:
            return table, col_std, col_act, row_map
    raise RuntimeError("Could not find calibration results table in template")


def _set_cell(cell, text: str) -> None:
    if cell.paragraphs:
        p = cell.paragraphs[0]
        if p.runs:
            p.runs[0].text = text
            for r in p.runs[1:]:
                r.text = ""
            return
    cell.text = text


def fill_results_table(doc, values: dict[float, tuple[float | None, float | None]]) -> None:
    """Fill the calibration results table.

    `values` maps target temperature → (standard_value, actual_value). Either may be None.
    """
    table, col_std, col_act, row_map = find_results_table(doc)
    for target, (std, act) in values.items():
        if target not in row_map:
            continue
        row = table.rows[row_map[target]]
        _set_cell(row.cells[col_std], "" if std is None else f"{std:.2f}")
        _set_cell(row.cells[col_act], "" if act is None else f"{act:.2f}")
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_docx_filler.py -v
```

Expected: 3 passed. **If `find_results_table` raises** because the template uses different header text, inspect the template (`python -c "from docx import Document; d=Document('apps/api/tests/fixtures/calibration/template.docx'); [print([c.text for c in t.rows[0].cells]) for t in d.tables]"`) and adjust the header detection keywords inline.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/docx_filler.py apps/api/tests/calibration/test_docx_filler.py
git commit -m "feat(calibration): add find_results_table + fill_results_table"
```

---

## Task 11: `engine.py` — `run_one_logger`

**Files:**
- Create: `apps/api/ite_api/calibration/engine.py`
- Create: `apps/api/tests/calibration/test_engine.py`

This orchestrates one sheet: load cal sheet, run matcher per target, fill template, save.

- [ ] **Step 1: Write the failing test**

`apps/api/tests/calibration/test_engine.py`:

```python
from datetime import datetime
from pathlib import Path

from docx import Document

from ite_api.calibration.engine import RunConfig, SetpointWindow, run_one_logger


def test_run_one_logger_produces_docx(workbook_xlsx, reference_csv, template_docx, tmp_path):
    cfg = RunConfig(
        cert_no="0000001999",
        serial="190124110099999",
        test_date_jp="2026年4月14日",
        doc_date_jp="2026年4月15日",
        template_path=template_docx,
        output_dir=tmp_path,
        setpoints=[
            SetpointWindow(target=-40.0, start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
            SetpointWindow(target=5.0,   start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
            SetpointWindow(target=40.0,  start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
        ],
    )
    from ite_api.calibration.cal_loader import load_workbook
    from ite_api.calibration.ref_loader import load_ref_auto
    wb, names = load_workbook(workbook_xlsx)
    ref_df = load_ref_auto(reference_csv)
    out_path = run_one_logger(cfg, sheet_name=names[0], wb=wb, ref_df=ref_df)
    assert out_path.exists()
    assert out_path.suffix == ".docx"
    saved = Document(str(out_path))
    full_text = "\n".join(p.text for p in saved.paragraphs)
    for section in saved.sections:
        for p in section.header.paragraphs:
            full_text += "\n" + p.text
    assert "0000001999" in full_text
```

- [ ] **Step 2: Create `apps/api/ite_api/calibration/engine.py`**

```python
"""Calibration orchestrator: load → match → fill → save."""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from docx import Document

from ite_api.calibration.cal_loader import load_calibration_sheet, load_workbook
from ite_api.calibration.docx_filler import (
    fill_results_table,
    replace_text_everywhere,
)
from ite_api.calibration.matcher import find_values_for_target
from ite_api.calibration.ref_loader import combine_refs, load_ref_auto


@dataclass(frozen=True)
class SetpointWindow:
    target: float
    start: datetime
    end: datetime


@dataclass(frozen=True)
class RunConfig:
    cert_no: str           # e.g. "0000001999"
    serial: str            # logger serial number string
    test_date_jp: str      # e.g. "2026年4月14日"
    doc_date_jp: str       # e.g. "2026年4月15日"
    template_path: Path
    output_dir: Path
    setpoints: list[SetpointWindow]
    template_cert_no: str = "0000001644"   # placeholder string in the shipped template
    template_serial: str = "190124110002417"
    template_test_date: str = "2026年3月14日"
    template_doc_date: str = "2026年3月15日"


def run_one_logger(cfg: RunConfig, *, sheet_name: str, wb, ref_df) -> Path:
    """Generate one certificate for one sheet. Returns the written .docx path."""
    cal_df = load_calibration_sheet(wb, sheet_name)
    values: dict[float, tuple[float | None, float | None]] = {}
    for sp in cfg.setpoints:
        ref_v, cal_v, _ = find_values_for_target(
            cal_df, ref_df, sp.target, sp.start, sp.end
        )
        values[sp.target] = (ref_v, cal_v)

    doc = Document(str(cfg.template_path))
    replace_text_everywhere(doc, {
        cfg.template_cert_no: cfg.cert_no,
        cfg.template_serial: cfg.serial,
        cfg.template_test_date: cfg.test_date_jp,
        cfg.template_doc_date: cfg.doc_date_jp,
    })
    fill_results_table(doc, values)

    cfg.output_dir.mkdir(parents=True, exist_ok=True)
    out = cfg.output_dir / f"Calibration_Certificate_{cfg.cert_no}_{cfg.serial}.docx"
    doc.save(str(out))
    return out
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_engine.py -v
```

Expected: 1 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/engine.py apps/api/tests/calibration/test_engine.py
git commit -m "feat(calibration): add run_one_logger orchestrator"
```

---

## Task 12: `engine.py` — `run_calibration` (full batch)

**Files:**
- Modify: `apps/api/ite_api/calibration/engine.py`
- Modify: `apps/api/tests/calibration/test_engine.py`

- [ ] **Step 1: Append the failing test**

```python
import pytest

from ite_api.calibration.engine import BatchConfig, run_calibration


def test_run_calibration_writes_one_docx_per_sheet(
    workbook_xlsx, reference_csv, template_docx, tmp_path
):
    cfg = BatchConfig(
        start_cert_no="0000002000",
        cert_width=10,
        test_date_jp="2026年4月14日",
        doc_date_jp="2026年4月15日",
        template_path=template_docx,
        calibration_xlsx=workbook_xlsx,
        reference_csvs=[reference_csv],
        output_dir=tmp_path / "out",
        setpoints=[
            SetpointWindow(target=-40.0, start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
            SetpointWindow(target=5.0,   start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
            SetpointWindow(target=40.0,  start=datetime(2026, 4, 14, 0, 0), end=datetime(2026, 4, 14, 23, 59)),
        ],
    )
    written = run_calibration(cfg)
    assert len(written) > 0
    for p in written:
        assert p.exists() and p.suffix == ".docx"
    # Cert numbers are sequential
    nums = sorted(int(p.name.split("_")[2]) for p in written)
    assert nums == list(range(nums[0], nums[0] + len(nums)))
```

- [ ] **Step 2: Append to `engine.py`**

```python
@dataclass(frozen=True)
class BatchConfig:
    start_cert_no: str          # e.g. "0000002000"
    cert_width: int             # zero-pad width, e.g. 10
    test_date_jp: str
    doc_date_jp: str
    template_path: Path
    calibration_xlsx: Path
    reference_csvs: list[Path]
    output_dir: Path
    setpoints: list[SetpointWindow]
    serial_from_sheet: bool = True  # use the sheet name as the serial


def _format_cert_no(n: int, width: int) -> str:
    return str(n).zfill(width)


def run_calibration(cfg: BatchConfig) -> list[Path]:
    """Process every sheet in the workbook. Returns list of written paths in sheet order."""
    ref_df = combine_refs([load_ref_auto(p) for p in cfg.reference_csvs])
    wb, sheet_names = load_workbook(cfg.calibration_xlsx)
    start = int(cfg.start_cert_no)
    written: list[Path] = []
    for i, name in enumerate(sheet_names):
        cert_no = _format_cert_no(start + i, cfg.cert_width)
        serial = name.strip() if cfg.serial_from_sheet else ""
        run_cfg = RunConfig(
            cert_no=cert_no,
            serial=serial,
            test_date_jp=cfg.test_date_jp,
            doc_date_jp=cfg.doc_date_jp,
            template_path=cfg.template_path,
            output_dir=cfg.output_dir,
            setpoints=cfg.setpoints,
        )
        written.append(run_one_logger(run_cfg, sheet_name=name, wb=wb, ref_df=ref_df))
    return written
```

- [ ] **Step 3: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_engine.py -v
```

Expected: 2 passed.

- [ ] **Step 4: Commit**

```bash
git add apps/api/ite_api/calibration/engine.py apps/api/tests/calibration/test_engine.py
git commit -m "feat(calibration): add run_calibration batch orchestrator"
```

---

## Task 13: CLI `ite-api run-calibration`

**Files:**
- Modify: `apps/api/ite_api/cli.py`
- Create: `apps/api/tests/test_cli_run_calibration.py`

- [ ] **Step 1: Write the failing test**

`apps/api/tests/test_cli_run_calibration.py`:

```python
from typer.testing import CliRunner

from ite_api.cli import app as cli_app


def test_run_calibration_cli_writes_docx_files(
    workbook_xlsx, reference_csv, template_docx, tmp_path
):
    runner = CliRunner()
    out = tmp_path / "out"
    result = runner.invoke(cli_app, [
        "run-calibration",
        "--workbook", str(workbook_xlsx),
        "--reference", str(reference_csv),
        "--template", str(template_docx),
        "--output", str(out),
        "--start-cert-no", "0000003000",
        "--test-date-jp", "2026年4月14日",
        "--doc-date-jp", "2026年4月15日",
    ])
    assert result.exit_code == 0, result.output
    docs = list(out.glob("*.docx"))
    assert len(docs) > 0
```

Make sure `apps/api/tests/calibration/conftest.py` fixtures are visible to this file by also creating a top-level `apps/api/tests/conftest.py` import: this is already global pytest behavior — the calibration conftest covers `tests/calibration/`, so re-declare the fixtures here. Simplest: import them.

Add at the top of `tests/test_cli_run_calibration.py`:

```python
from tests.calibration.conftest import (  # noqa: F401
    fixtures_dir,
    golden_dir,
    reference_csv,
    template_docx,
    workbook_xlsx,
)
```

If pytest cannot find `tests.calibration.conftest`, add `__init__.py` to `apps/api/tests/` (it likely already exists from earlier slices).

- [ ] **Step 2: Extend `apps/api/ite_api/cli.py`**

Add to the top imports:

```python
from datetime import datetime
from pathlib import Path
```

Append a new command:

```python
@app.command("run-calibration")
def run_calibration_cmd(
    workbook: Path = typer.Option(..., "--workbook", exists=True, dir_okay=False),
    reference: list[Path] = typer.Option(..., "--reference", exists=True, dir_okay=False),
    template: Path = typer.Option(..., "--template", exists=True, dir_okay=False),
    output: Path = typer.Option(..., "--output", file_okay=False),
    start_cert_no: str = typer.Option("0000001000", "--start-cert-no"),
    cert_width: int = typer.Option(10, "--cert-width"),
    test_date_jp: str = typer.Option(..., "--test-date-jp"),
    doc_date_jp: str = typer.Option(..., "--doc-date-jp"),
    window_start: datetime = typer.Option(
        datetime(1900, 1, 1, 0, 0), "--window-start",
        help="Start of testing window; defaults to a very early date so any data matches.",
    ),
    window_end: datetime = typer.Option(
        datetime(2999, 12, 31, 23, 59), "--window-end",
        help="End of testing window; defaults to a very late date.",
    ),
) -> None:
    """Generate calibration certificates from a workbook and reference CSV(s)."""
    from ite_api.calibration.engine import BatchConfig, SetpointWindow, run_calibration

    setpoints = [
        SetpointWindow(target=t, start=window_start, end=window_end)
        for t in (-40.0, 5.0, 40.0)
    ]
    cfg = BatchConfig(
        start_cert_no=start_cert_no,
        cert_width=cert_width,
        test_date_jp=test_date_jp,
        doc_date_jp=doc_date_jp,
        template_path=template,
        calibration_xlsx=workbook,
        reference_csvs=list(reference),
        output_dir=output,
        setpoints=setpoints,
    )
    written = run_calibration(cfg)
    for p in written:
        typer.echo(str(p))
    typer.echo(f"Wrote {len(written)} certificate(s) to {output}")
```

- [ ] **Step 3: Re-install the package so the new subcommand registers**

```bash
.venv/bin/pip install -e . --quiet
```

- [ ] **Step 4: Verify**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/test_cli_run_calibration.py -v
```

Expected: 1 passed.

- [ ] **Step 5: Commit**

```bash
git add apps/api/ite_api/cli.py apps/api/tests/test_cli_run_calibration.py
git commit -m "feat(api): add ite-api run-calibration CLI command"
```

---

## Task 14: Golden-file equivalence test

**Files:**
- Create: `apps/api/tests/calibration/test_golden.py`

**Definition of "data equivalent":** for each `.docx` in `golden/`, find the new engine's corresponding output by serial number; extract `(cert_no_text, header_text, body_text, all_table_cell_texts)` from each; assert the two extractions are equal. Whitespace differences inside a single cell are normalized via `re.sub(r"\s+", " ", text).strip()` before comparison.

- [ ] **Step 1: Write the test**

`apps/api/tests/calibration/test_golden.py`:

```python
import re
from pathlib import Path

import pytest
from docx import Document

from ite_api.calibration.engine import BatchConfig, SetpointWindow, run_calibration


def _normalize(s: str) -> str:
    return re.sub(r"\s+", " ", s or "").strip()


def _extract(path: Path) -> tuple[list[str], list[list[str]]]:
    doc = Document(str(path))
    paras = [_normalize(p.text) for p in doc.paragraphs if p.text]
    for section in doc.sections:
        for p in section.header.paragraphs:
            if p.text:
                paras.append(_normalize(p.text))
        for p in section.footer.paragraphs:
            if p.text:
                paras.append(_normalize(p.text))
    tables: list[list[str]] = []
    for table in doc.tables:
        for row in table.rows:
            tables.append([_normalize(c.text) for c in row.cells])
    return paras, tables


def _cert_no_of(path: Path) -> str:
    # Filenames look like Calibration_Certificate_0000001720_190124110002450.docx
    return path.name.split("_")[2]


def test_engine_output_matches_golden(
    workbook_xlsx, reference_csv, template_docx, golden_dir, tmp_path
):
    golden_paths = sorted(golden_dir.glob("Calibration_Certificate_*.docx"))
    if not golden_paths:
        pytest.skip("No golden .docx files present")
    first_cert = int(_cert_no_of(golden_paths[0]))

    cfg = BatchConfig(
        start_cert_no=str(first_cert).zfill(10),
        cert_width=10,
        # The Old Method certs were generated with these exact JP dates in their template;
        # if golden_paths reveal different dates, edit these to match.
        test_date_jp="2026年4月14日",
        doc_date_jp="2026年4月15日",
        template_path=template_docx,
        calibration_xlsx=workbook_xlsx,
        reference_csvs=[reference_csv],
        output_dir=tmp_path / "out",
        setpoints=[
            SetpointWindow(target=t,
                           start=__import__("datetime").datetime(1900, 1, 1),
                           end=__import__("datetime").datetime(2999, 12, 31, 23, 59))
            for t in (-40.0, 5.0, 40.0)
        ],
    )
    written = run_calibration(cfg)
    by_cert = {_cert_no_of(p): p for p in written}

    mismatches: list[str] = []
    for gp in golden_paths:
        cert = _cert_no_of(gp)
        if cert not in by_cert:
            mismatches.append(f"new run did not produce cert {cert}")
            continue
        g_paras, g_tables = _extract(gp)
        n_paras, n_tables = _extract(by_cert[cert])
        if g_tables != n_tables:
            mismatches.append(f"cert {cert}: table cells differ")
        # Paragraph order can shift slightly across python-docx versions; compare as sets.
        if set(g_paras) != set(n_paras):
            only_g = set(g_paras) - set(n_paras)
            only_n = set(n_paras) - set(g_paras)
            mismatches.append(
                f"cert {cert}: paragraph set differs\n  only-in-golden: {list(only_g)[:3]}\n  only-in-new: {list(only_n)[:3]}"
            )
    assert not mismatches, "\n".join(mismatches)
```

- [ ] **Step 2: Run the test**

```bash
ITE_JWT_SECRET=t .venv/bin/pytest tests/calibration/test_golden.py -v
```

**This is the critical correctness gate.** Expected outcomes and what to do:

- **Pass:** done.
- **Tables differ:** the matcher or formatting is wrong. Inspect a specific cert with:
  ```bash
  python -c "from docx import Document; d=Document('apps/api/tests/fixtures/calibration/golden/Calibration_Certificate_0000001720_190124110002450.docx'); [print([c.text for c in r.cells]) for t in d.tables for r in t.rows]"
  ```
  Compare against the new engine's output; the diff in numbers points to which step is off. The matcher is the most likely culprit — re-read the legacy `src/engine/matcher.py` to confirm step ordering and tolerance handling.
- **Paragraph set differs:** likely a `replace_text_everywhere` mapping mismatch (cert_no, serial, dates). Read the legacy `src/engine/docx_filler.py` to find the exact template placeholder strings and update `RunConfig`'s `template_*` defaults in `engine.py`.

Iterate fix + rerun until green.

- [ ] **Step 3: Commit**

```bash
git add apps/api/tests/calibration/test_golden.py
git commit -m "test(calibration): add golden-file equivalence test against Old Method outputs"
```

---

## Task 15: README update for Slice 2 + final verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the "Slice 1 (current)" section with**

```markdown
## Slice 2 (current): Calibration engine (CLI only)

What works after this slice:

- Everything from Slice 1.
- New CLI: `ite-api run-calibration --workbook <xlsx> --reference <csv> [--reference <csv> ...] --template <docx> --output <dir> --test-date-jp 2026年4月14日 --doc-date-jp 2026年4月15日`
- Output is one `.docx` certificate per sheet in the workbook, written to `<dir>/`.
- Data-equivalent to the legacy Old Method certificates (verified by golden-file test).

What doesn't work yet: no HTTP routes, no UI for triggering runs. Those arrive in Slice 3.

## Engine smoke test

```bash
cd apps/api
.venv/bin/ite-api run-calibration \
  --workbook tests/fixtures/calibration/workbook.xlsx \
  --reference tests/fixtures/calibration/reference.csv \
  --template tests/fixtures/calibration/template.docx \
  --output /tmp/ite-out \
  --start-cert-no 0000001720 \
  --test-date-jp 2026年4月14日 \
  --doc-date-jp 2026年4月15日
ls /tmp/ite-out/
```
```

- [ ] **Step 2: Final verification — full API test suite**

```bash
cd apps/api && ITE_JWT_SECRET=test-secret .venv/bin/pytest -v
```

Expected: all tests pass (Slice 1's 35 + ~15 new from this slice).

- [ ] **Step 3: Lint**

```bash
.venv/bin/ruff check .
```

Expected: `All checks passed!`. If autogen formatting issues appear (long lines in test data, etc.), add `apps/api/tests/fixtures` to `extend-exclude` in `pyproject.toml`.

- [ ] **Step 4: Live engine smoke**

```bash
.venv/bin/ite-api run-calibration \
  --workbook tests/fixtures/calibration/workbook.xlsx \
  --reference tests/fixtures/calibration/reference.csv \
  --template tests/fixtures/calibration/template.docx \
  --output /tmp/ite-out \
  --start-cert-no 0000009000 \
  --test-date-jp 2026年4月14日 \
  --doc-date-jp 2026年4月15日
ls /tmp/ite-out/ | head -5
```

Expected: one or more `.docx` files listed.

- [ ] **Step 5: Commit + push + verify CI**

```bash
git add README.md
git commit -m "docs: update README for Slice 2 (calibration engine + CLI)"
git push
```

Then check CI:

```bash
gh run list --branch main --limit 1
```

Expected: latest run completed successfully.

---

## Self-review notes

- **Spec coverage (Slice 2):**
  - `ref_loader.py` with `load_ref_auto` + auto-format — Tasks 3, 4, 5.
  - `cal_loader.py` multi-sheet XLSX — Task 6.
  - `matcher.py` 3-step algorithm — Tasks 7, 8.
  - `docx_filler.py` template fill — Tasks 9, 10.
  - `engine.run_calibration` orchestrator — Tasks 11, 12.
  - CLI `ite-api run-calibration` — Task 13.
  - Unit tests against fixtures (copied from Old Method/Input) — Tasks 3–13.
  - Golden-file test against Old Method/output — Task 14.
  - Spec Done criterion ("data-equivalent to known-good Old Method") — Task 14.
- **No placeholders:** every step includes exact code or a precise diagnostic recipe (Task 14 "iterate until green" includes inspection commands).
- **Type consistency:** `RunConfig`, `BatchConfig`, `SetpointWindow`, `run_one_logger`, `run_calibration`, `find_values_for_target`, `replace_text_everywhere`, `find_results_table`, `fill_results_table`, `load_ref_auto`, `combine_refs`, `load_workbook`, `load_calibration_sheet` all used identically across tasks.
- **Deferred to later slices (explicit, not gaps):**
  - HTTP routes (`POST /runs`, `POST /runs/{id}/process`, etc.) — Slice 3.
  - DB persistence of runs + logger_results — Slice 3.
  - File upload handling — Slice 3.
  - Frontend wiring — Slices 3+.
- **Spec interpretation noted in header:** "byte-equivalent" reinterpreted as "data-equivalent" with an explicit definition in Task 14. Engineers see this before they start.
- **Legacy code use policy noted in header:** read-only reference, no imports or copies.
