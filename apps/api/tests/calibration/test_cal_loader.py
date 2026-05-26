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
