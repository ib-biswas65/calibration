from ite_api.calibration.ref_loader import _try_open


def test_try_open_handles_shift_jis(reference_csv):
    with _try_open(reference_csv) as f:
        head = f.read(500)
    assert head
    assert "�" not in head  # no Unicode replacement char from bad decoding
