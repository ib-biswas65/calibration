"""Reference logger CSV loading — supports multiple files and auto-format detection."""

import re
from collections.abc import Iterable
from datetime import datetime
from pathlib import Path

import pandas as pd

_DT_FORMATS = ("%Y/%m/%d %H:%M:%S", "%Y-%m-%d %H:%M:%S")

_DATE_FIRST_RE = re.compile(r"^\d{4}[/-]\d{2}[/-]\d{2}")
_DATE_SECOND_RE = re.compile(r"^[^,]+,\d{4}[/-]\d{2}[/-]\d{2}")


def _try_open(path: Path):
    """Open `path` for text reading, trying common Japanese loggers' encodings first."""
    for enc in ("shift_jis", "cp932", "utf-8"):
        try:
            f = open(path, encoding=enc)
            f.read(1)
            f.seek(0)
            return f
        except UnicodeDecodeError:
            continue
    return open(path, encoding="utf-8", errors="replace")


def detect_format(path: Path) -> str:
    """Return 'mc3000' (datetime first field), 'indexed' (datetime second), or 'unknown'."""
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


def _parse_dt(s: str) -> datetime | None:
    for fmt in _DT_FORMATS:
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    return None


def _parse_line(line: str, fmt: str) -> tuple[datetime, float] | None:
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
    ts = _parse_dt(ts_str)
    if ts is None:
        return None
    try:
        temp = float(temp_str)
    except ValueError:
        return None
    return ts, temp


def load_ref_auto(path: Path) -> pd.DataFrame:
    """Detect format and load into DataFrame with columns ['timestamp', 'temp']."""
    fmt = detect_format(path)
    if fmt == "unknown":
        raise ValueError(f"Could not detect CSV format for {path}")
    rows: list[tuple[datetime, float]] = []
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
    return out.sort_values("timestamp").reset_index(drop=True)
