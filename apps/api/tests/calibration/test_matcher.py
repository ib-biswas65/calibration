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
    # 5.2 and 5.3 are equidistant from 5.25; idxmin returns the first occurrence (5.2 at i=2).
    assert val == pytest.approx(5.2)
    assert ts == base + timedelta(minutes=2)


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
