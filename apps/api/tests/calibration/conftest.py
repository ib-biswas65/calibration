from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent.parent / "fixtures" / "calibration"


@pytest.fixture()
def fixtures_dir() -> Path:
    return FIXTURES


@pytest.fixture()
def reference_csv() -> Path:
    return FIXTURES / "reference.csv"


@pytest.fixture()
def workbook_xlsx() -> Path:
    return FIXTURES / "workbook.xlsx"


@pytest.fixture()
def template_docx() -> Path:
    return FIXTURES / "template.docx"


@pytest.fixture()
def golden_dir() -> Path:
    return FIXTURES / "golden"
