"""Word template filling — placeholder text replacement + results table writing."""

from docx.document import Document as _DocType
from docx.oxml.ns import qn
from docx.table import _Cell, Table
from docx.text.paragraph import Paragraph


def _iter_block_items(parent):
    if isinstance(parent, _DocType):
        parent_elm = parent.element.body
    elif isinstance(parent, _Cell):
        parent_elm = parent._tc
    else:
        return
    for child in parent_elm.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, parent)
        elif child.tag == qn("w:tbl"):
            yield Table(child, parent)


def _replace_in_paragraph(paragraph: Paragraph, mapping: dict[str, str]) -> None:
    if not paragraph.runs:
        return
    full_text = "".join(r.text or "" for r in paragraph.runs)
    if not any(k in full_text for k in mapping):
        return
    new_text = full_text
    for old, new in mapping.items():
        new_text = new_text.replace(old, new)
    paragraph.runs[0].text = new_text
    for r in paragraph.runs[1:]:
        r.text = ""


def _replace_in_blocks(parent, mapping: dict[str, str]) -> None:
    for block in _iter_block_items(parent):
        if isinstance(block, Paragraph):
            _replace_in_paragraph(block, mapping)
        elif isinstance(block, Table):
            for row in block.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)


def replace_text_everywhere(doc, mapping: dict[str, str]) -> None:
    """Replace placeholder text in body, headers, and footers of `doc`."""
    _replace_in_blocks(doc, mapping)
    for section in doc.sections:
        for p in section.header.paragraphs:
            _replace_in_paragraph(p, mapping)
        for table in section.header.tables:
            for row in table.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)
        for p in section.footer.paragraphs:
            _replace_in_paragraph(p, mapping)
        for table in section.footer.tables:
            for row in table.rows:
                for cell in row.cells:
                    for p in cell.paragraphs:
                        _replace_in_paragraph(p, mapping)
