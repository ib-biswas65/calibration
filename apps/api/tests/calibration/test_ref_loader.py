import pandas as pd

from ite_api.calibration.ref_loader import (
    _try_open,
    combine_refs,
    detect_format,
    load_ref_auto,
)


def test_try_open_handles_shift_jis(reference_csv):
    with _try_open(reference_csv) as f:
        head = f.read(500)
    assert head
    assert "�" not in head


def test_detect_format_indexed(reference_csv):
    assert detect_format(reference_csv) == "indexed"


def test_detect_format_mc3000(tmp_path):
    p = tmp_path / "m.csv"
    p.write_text("header line\n\n2026/04/14 10:30:00,5.12,foo\n2026/04/14 10:31:00,5.13,foo\n")
    assert detect_format(p) == "mc3000"


def test_load_ref_auto_returns_typed_dataframe(reference_csv):
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
    ts = combined["timestamp"].tolist()
    assert ts == sorted(ts)
