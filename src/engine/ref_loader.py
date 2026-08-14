"""Reference logger CSV loading — supports any number of reference files with auto-format detection."""

import re
from datetime import datetime
from pathlib import Path
from typing import List

import pandas as pd

# Regex to detect lines that begin with a datetime in YYYY/MM/DD format
_DATE_PREFIX_RE = re.compile(r"^\d{4}/\d{2}/\d{2}")

# Regex to detect lines where the SECOND comma-field is a datetime (index,datetime,...)
_DATE_SECOND_FIELD_RE = re.compile(r"^[^,]+,\d{4}/\d{2}/\d{2}")


def _try_open(path: Path):
    """Open path trying Shift-JIS first, falling back to UTF-8."""
    for enc in ("shift_jis", "utf-8", "cp932"):
        try:
            return open(path, "r", encoding=enc)
        except UnicodeDecodeError:
            continue
    # Last resort: ignore errors
    return open(path, "r", encoding="utf-8", errors="ignore")


def _detect_format(path: Path) -> str:
    """
    Auto-detect CSV format by scanning the first 50 non-empty lines.

    Returns:
        "mc3000"  — datetime is the FIRST field (MC3000 style: datetime,temp,...)
        "indexed" — datetime is the SECOND field (index style: index,datetime,temp,--)
        "unknown" — could not detect
    """
    with _try_open(path) as f:
        for _ in range(200):  # scan up to 200 lines to find data rows
            line = f.readline()
            if not line:
                break
            line = line.strip()
            if not line:
                continue
            if _DATE_PREFIX_RE.match(line):
                return "mc3000"
            if _DATE_SECOND_FIELD_RE.match(line):
                return "indexed"
    return "unknown"


def load_ref_auto(path: Path) -> pd.DataFrame:
    """
    Load a reference logger CSV with automatic format detection.

    Supports:
      - MC3000 style: datetime,temp[,...] — datetime is the first field
      - Indexed style: index,datetime,temp[,--] — datetime is the second field

    Encoding: Tries Shift-JIS, then UTF-8, then cp932.

    Returns:
        DataFrame with columns ["timestamp", "temp"]
    """
    fmt = _detect_format(path)
    data = []

    with _try_open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split(",")

            if fmt == "mc3000":
                # First field is datetime: YYYY/MM/DD HH:MM:SS
                if not _DATE_PREFIX_RE.match(line):
                    continue
                if len(parts) < 2:
                    continue
                try:
                    ts = datetime.strptime(parts[0].strip(), "%Y/%m/%d %H:%M:%S")
                    temp = float(parts[1].strip())
                    data.append((ts, temp))
                except (ValueError, IndexError):
                    continue

            elif fmt == "indexed":
                # Second field is datetime: index,YYYY/MM/DD HH:MM:SS,temp,--
                if len(parts) < 3:
                    continue
                if not re.match(r"^\d{4}/\d{2}/\d{2}", parts[1].strip()):
                    continue
                try:
                    ts = datetime.strptime(parts[1].strip(), "%Y/%m/%d %H:%M:%S")
                    temp = float(parts[2].strip())
                    data.append((ts, temp))
                except (ValueError, IndexError):
                    continue

            else:
                # Unknown format: try both positions
                if _DATE_PREFIX_RE.match(line) and len(parts) >= 2:
                    try:
                        ts = datetime.strptime(parts[0].strip(), "%Y/%m/%d %H:%M:%S")
                        temp = float(parts[1].strip())
                        data.append((ts, temp))
                        continue
                    except (ValueError, IndexError):
                        pass
                if len(parts) >= 3 and re.match(r"^\d{4}/\d{2}/\d{2}", parts[1].strip()):
                    try:
                        ts = datetime.strptime(parts[1].strip(), "%Y/%m/%d %H:%M:%S")
                        temp = float(parts[2].strip())
                        data.append((ts, temp))
                    except (ValueError, IndexError):
                        pass

    df = pd.DataFrame(data, columns=["timestamp", "temp"])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df


def combine_refs(ref_dfs: List[pd.DataFrame]) -> pd.DataFrame:
    """Combine any number of reference DataFrames into one sorted DataFrame."""
    if not ref_dfs:
        return pd.DataFrame(columns=["timestamp", "temp"])
    combined = pd.concat(ref_dfs, ignore_index=True)
    return combined.sort_values("timestamp").reset_index(drop=True)


# ---------------------------------------------------------------------------
# Legacy helpers kept for backward compatibility (not used internally anymore)
# ---------------------------------------------------------------------------

def load_ref1(path: Path) -> pd.DataFrame:
    """Legacy: load reference logger 1 (indexed CSV format)."""
    return load_ref_auto(path)


def load_ref2(path: Path) -> pd.DataFrame:
    """Legacy: load reference logger 2 (MC3000 format)."""
    return load_ref_auto(path)
