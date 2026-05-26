"""Temperature matching — implements the 3-step algorithm.

Per target temperature (default {-40, 5, 40} °C) within a time window:
  1. Find the reference value closest to the target temperature → (ref_val, ref_ts).
  2. Among calibration readings within ±TOLERANCE of ref_val, pick the one closest
     in time to ref_ts. Done.
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
    """(temp, timestamp) of the ref reading nearest to `target` in the window."""
    subset = _window(ref_df, time_start, time_end)
    if subset.empty:
        return None, None
    subset["diff"] = (subset.temp - target).abs()
    i = subset["diff"].idxmin()
    return float(subset.loc[i, "temp"]), subset.loc[i, "timestamp"].to_pydatetime()


def find_ref_near_timestamp(
    ref_df: pd.DataFrame, cal_ts: datetime, time_start: datetime, time_end: datetime
) -> tuple[float | None, datetime | None]:
    """(temp, timestamp) of the ref reading nearest in time to `cal_ts`."""
    subset = _window(ref_df, time_start, time_end)
    if subset.empty:
        return None, None
    subset["time_diff"] = (subset.timestamp - cal_ts).abs()
    i = subset["time_diff"].idxmin()
    return float(subset.loc[i, "temp"]), subset.loc[i, "timestamp"].to_pydatetime()
