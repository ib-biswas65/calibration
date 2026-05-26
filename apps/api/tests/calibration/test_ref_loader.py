from ite_api.calibration.ref_loader import _try_open, detect_format


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
