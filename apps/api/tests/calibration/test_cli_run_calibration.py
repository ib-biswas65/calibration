from typer.testing import CliRunner

from ite_api.cli import app as cli_app


def test_run_calibration_cli_writes_docx_files(
    workbook_xlsx, reference_csv, template_docx, tmp_path
):
    runner = CliRunner()
    out = tmp_path / "out"
    result = runner.invoke(cli_app, [
        "run-calibration",
        "--workbook", str(workbook_xlsx),
        "--reference", str(reference_csv),
        "--template", str(template_docx),
        "--output", str(out),
        "--start-cert-no", "0000003000",
        "--test-date-jp", "2026年4月14日",
        "--doc-date-jp", "2026年4月15日",
    ])
    assert result.exit_code == 0, result.output
    docs = list(out.glob("*.docx"))
    assert len(docs) > 0
