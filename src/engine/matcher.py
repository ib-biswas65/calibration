"""
Temperature matching logic — preserves the exact 3-step strategy from calibration.py.

Strategy per target temperature (-40.0, 5.0, 40.0):
1. Find the reference value closest to the target temperature → ref_val, ref_ts
2. Among calibration readings within ±0.5°C of ref_val, pick the one closest in time
   to ref_ts → done.
3. If NO calibration reading is within ±0.5 of ref_val:
   a. Find the calibration reading closest to the target temperature → cal_val, cal_ts
   b. Find the reference reading closest in time to cal_ts → new_ref_val
   c. If |cal_val - new_ref_val| <= 0.5 → use (new_ref_val, cal_val)
   d. Otherwise, search broadly for ANY ref within ±0.5 of cal_val

Tolerance: ±0.5°C
"""

from datetime import datetime

import pandas as pd

# Temperature targets
TARGETS = [-40.0, 5.0, 40.0]

# Tolerance for matching reference and calibration values
TOLERANCE = 0.5


def find_reference_value(
    ref_df: pd.DataFrame, target: float, time_start: datetime, time_end: datetime
):
    """Find the reference reading closest to the target temperature within the time range."""
    mask = (ref_df.timestamp >= time_start) & (ref_df.timestamp <= time_end)
    subset = ref_df[mask].copy()
    if subset.empty:
        return None, None
    subset["diff"] = (subset.temp - target).abs()
    best_idx = subset["diff"].idxmin()
    return subset.loc[best_idx, "temp"], subset.loc[best_idx, "timestamp"]


def find_ref_near_timestamp(
    ref_df: pd.DataFrame, cal_ts: datetime, time_start: datetime, time_end: datetime
):
    """Find the reference reading closest in time to a given calibration timestamp."""
    mask = (ref_df.timestamp >= time_start) & (ref_df.timestamp <= time_end)
    subset = ref_df[mask].copy()
    if subset.empty:
        return None, None
    subset["time_diff"] = (subset.timestamp - cal_ts).abs()
    best_idx = subset["time_diff"].idxmin()
    return subset.loc[best_idx, "temp"], subset.loc[best_idx, "timestamp"]


def find_values_for_target(
    cal_df: pd.DataFrame,
    ref_df: pd.DataFrame,
    target: float,
    time_start: datetime,
    time_end: datetime,
):
    """
    Main matching function. Returns: (ref_value, cal_value, adjusted: bool)

    'adjusted' is True when the algorithm had to use the fallback path
    (step 3) instead of the direct match (step 2).
    """
    cal_mask = (cal_df.timestamp >= time_start) & (cal_df.timestamp <= time_end)
    cal_subset = cal_df[cal_mask].copy()
    if cal_subset.empty:
        return target, None, False

    ref_mask = (ref_df.timestamp >= time_start) & (ref_df.timestamp <= time_end)
    ref_subset = ref_df[ref_mask].copy()
    if ref_subset.empty:
        return target, None, False

    # Step 1: Find best reference value (closest to target temp)
    ref_subset_t = ref_subset.copy()
    ref_subset_t["diff"] = (ref_subset_t.temp - target).abs()
    best_ref_idx = ref_subset_t["diff"].idxmin()
    ref_val = ref_subset_t.loc[best_ref_idx, "temp"]
    ref_ts = ref_subset_t.loc[best_ref_idx, "timestamp"]

    # Step 2: Among cal readings within ±0.5 of ref_val, pick closest in time to ref_ts
    cal_within = cal_subset[(cal_subset.temp - ref_val).abs() <= TOLERANCE].copy()
    if not cal_within.empty:
        cal_within["time_diff"] = (cal_within.timestamp - ref_ts).abs()
        best_cal_idx = cal_within["time_diff"].idxmin()
        cal_val = cal_within.loc[best_cal_idx, "temp"]
        return ref_val, cal_val, False

    # Step 3: No cal reading within ±0.5 of ref_val
    # Find cal reading closest to TARGET temperature
    cal_subset_t = cal_subset.copy()
    cal_subset_t["diff"] = (cal_subset_t.temp - target).abs()
    best_cal_idx = cal_subset_t["diff"].idxmin()
    cal_val = cal_subset_t.loc[best_cal_idx, "temp"]
    cal_ts = cal_subset_t.loc[best_cal_idx, "timestamp"]

    # Find reference reading closest in TIME to that calibration reading
    ref_subset_time = ref_subset.copy()
    ref_subset_time["time_diff"] = (ref_subset_time.timestamp - cal_ts).abs()

    # Among reference readings near cal_ts, find one within ±0.5 of cal_val
    ref_near = ref_subset_time.sort_values("time_diff")
    ref_candidates = ref_near[(ref_near.temp - cal_val).abs() <= TOLERANCE]

    if not ref_candidates.empty:
        # Use the closest-in-time ref that's within ±0.5 of cal_val
        new_ref_val = ref_candidates.iloc[0]["temp"]
        return new_ref_val, cal_val, True

    # Last resort: pick the ref reading closest in time to cal_ts
    new_ref_val = ref_near.iloc[0]["temp"]
    # If still > 0.5, search more broadly for ANY ref within ±0.5 of cal_val
    all_within = ref_subset[(ref_subset.temp - cal_val).abs() <= TOLERANCE].copy()
    if not all_within.empty:
        all_within["time_diff"] = (all_within.timestamp - cal_ts).abs()
        new_ref_val = all_within.sort_values("time_diff").iloc[0]["temp"]
        return new_ref_val, cal_val, True

    return new_ref_val, cal_val, True
