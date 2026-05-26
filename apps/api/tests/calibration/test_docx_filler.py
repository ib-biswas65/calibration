from docx import Document

from ite_api.calibration.docx_filler import replace_text_everywhere


def test_replace_text_everywhere_updates_cert_number(template_docx, tmp_path):
    doc = Document(str(template_docx))
    replace_text_everywhere(doc, {"0000001700": "0000001999"})
    out = tmp_path / "out.docx"
    doc.save(str(out))
    saved = Document(str(out))
    body_text = "\n".join(p.text for p in saved.paragraphs)
    assert "0000001999" in body_text
    assert "0000001700" not in body_text


def test_replace_text_everywhere_handles_serial_in_table(template_docx, tmp_path):
    doc = Document(str(template_docx))
    replace_text_everywhere(doc, {"190124110002417": "190124110099999"})
    out = tmp_path / "out.docx"
    doc.save(str(out))
    saved = Document(str(out))
    # Serial lives in table 0
    table_text = " ".join(
        c.text for t in saved.tables for r in t.rows for c in r.cells
    )
    assert "190124110099999" in table_text
    assert "190124110002417" not in table_text


def test_replace_text_everywhere_handles_dates(template_docx, tmp_path):
    doc = Document(str(template_docx))
    replace_text_everywhere(doc, {
        "2026年3月4日": "2026年4月14日",
        "2026年3月6日": "2026年4月15日",
    })
    out = tmp_path / "out.docx"
    doc.save(str(out))
    saved = Document(str(out))
    body_text = "\n".join(p.text for p in saved.paragraphs)
    assert "2026年4月14日" in body_text
    assert "2026年4月15日" in body_text
    assert "2026年3月4日" not in body_text
    assert "2026年3月6日" not in body_text
