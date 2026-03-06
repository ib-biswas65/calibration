"""Reference logger CSV loading — preserves original Shift-JIS parsing logic."""

from datetime import datetime
from pathlib import Path

import pandas as pd


def load_ref1(path: Path) -> pd.DataFrame:
    """
    Reference logger 1: simple CSV with columns: index, datetime, temp, --
    Encoding: Shift-JIS. Filters lines starting with '2026/'.
    """
    data = []
    with open(path, "r", encoding="shift_jis") as f:
        for line in f:
            parts = line.strip().split(",")
            if len(parts) >= 3 and parts[1].strip().startswith("2026/"):
                ts = datetime.strptime(parts[1].strip(), "%Y/%m/%d %H:%M:%S")
                try:
                    temp = float(parts[2].strip())
                    data.append((ts, temp))
                except ValueError:
                    pass
    return pd.DataFrame(data, columns=["timestamp", "temp"])


def load_ref2(path: Path) -> pd.DataFrame:
    """
    Reference logger 2: MC3000 format with header rows, then data.
    Encoding: Shift-JIS. Data lines start with '2026/'.
    """
    data = []
    with open(path, "r", encoding="shift_jis") as f:
        lines = f.readlines()
    for line in lines:
        line = line.strip()
        if line.startswith("2026/"):
            parts = line.split(",")
            ts = datetime.strptime(parts[0], "%Y/%m/%d %H:%M:%S")
            try:
                temp = float(parts[1])
                data.append((ts, temp))
            except ValueError:
                pass
    return pd.DataFrame(data, columns=["timestamp", "temp"])


def combine_refs(ref1_df: pd.DataFrame, ref2_df: pd.DataFrame) -> pd.DataFrame:
    """Combine both reference loggers into one sorted dataframe."""
    combined = pd.concat([ref1_df, ref2_df], ignore_index=True)
    return combined.sort_values("timestamp").reset_index(drop=True)
