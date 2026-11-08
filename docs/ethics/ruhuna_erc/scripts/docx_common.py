#!/usr/bin/env python3
"""Shared academic formatting for the University of Ruhuna ERC drafts.

Visual target: the plain research-proposal layout used by the Faculty
(Version at the top left, date at the top right, page number at the foot).
A4. Times New Roman. No coloured panels.
"""

import os

import docx
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

FONT = "Times New Roman"
DRAFT_DATE = "08 November 2026"
STUDY_TITLE = (
    "Feasibility, usability and caregiver acceptability of a customised trilingual "
    "picture-based AAC mobile application for children with communication difficulties "
    "in Galle, Sri Lanka"
)
BLACK = RGBColor(0, 0, 0)
# Content width for A4 with 2.54 cm side margins: 210 mm - 50.8 mm.
RIGHT_TAB = 9072


def repo_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))


def erc_root():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def load_private_contacts():
    """Read telephone and email from a git-ignored local file, if present.

    The numbers are never stored in this module.
    """
    path = os.path.join(repo_root(), ".local_erc_private", "investigator_contacts.json")
    if not os.path.isfile(path):
        return None
    import json
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    phone = str(data.get("phone", "")).strip()
    email = str(data.get("email", "")).strip()
    if not phone or not email:
        return None
    contacts = {"phone": phone, "email": email}
    for key in ("fernando_phone", "fernando_email"):
        value = str(data.get(key, "")).strip()
        if value:
            contacts[key] = value
    return contacts


def is_private_output(path):
    return ".local_erc_private" in os.path.abspath(path)


def corresponding_contact_text(output_path):
    """Contact line for named private copies only."""
    if not is_private_output(output_path):
        return (
            "The corresponding telephone number and email address are printed only in the "
            "private submission copy. They are omitted from this tracked draft."
        )
    contacts = load_private_contacts()
    if not contacts:
        return (
            "The private contact file was not available when this copy was generated. "
            "Enter the confirmed applicant telephone and email before submission."
        )
    return (
        f"Telephone: {contacts['phone']}. Email: {contacts['email']}. "
        "The team asked that these be linked with J.G.D. Thamalka. "
        "This does not appoint that person as principal investigator."
    )


def _set_run_font(run, size=12, bold=False, italic=False):
    run.font.name = FONT
    run.bold = bold
    run.italic = italic
    run.font.size = Pt(size)
    run.font.color.rgb = BLACK
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), FONT)
    rfonts.set(qn("w:hAnsi"), FONT)
    rfonts.set(qn("w:cs"), FONT)
    rfonts.set(qn("w:eastAsia"), FONT)


def _set_style_font(style, size=12):
    style.font.name = FONT
    style.font.size = Pt(size)
    style.font.color.rgb = BLACK
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), FONT)
    rfonts.set(qn("w:hAnsi"), FONT)
    rfonts.set(qn("w:cs"), FONT)
    rfonts.set(qn("w:eastAsia"), FONT)


def create_styled_document():
    doc = docx.Document()
    for section in doc.sections:
        section.page_width = Cm(21.0)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(2.54)
        section.bottom_margin = Cm(2.54)
        section.left_margin = Cm(2.54)
        section.right_margin = Cm(2.54)
        section.header_distance = Cm(1.0)
        section.footer_distance = Cm(1.0)
        section.different_first_page_header_footer = False
    _set_style_font(doc.styles["Normal"], 12)
    normal = doc.styles["Normal"]
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.5
    _configure_heading_style(doc, "Heading 1", 14, 12, 6)
    _configure_heading_style(doc, "Heading 2", 12, 10, 4)
    props = doc.core_properties
    props.author = ""
    props.last_modified_by = ""
    props.category = ""
    props.comments = ""
    props.subject = ""
    return doc


def _add_page_field(paragraph):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.append(begin)
    run2 = paragraph.add_run()
    run2._r.append(instr)
    run3 = paragraph.add_run()
    run3._r.append(end)
    for item in (run, run2, run3):
        _set_run_font(item, 12, False, False)


def _right_tab(section):
    width = section.page_width or Cm(21.0)
    left = section.left_margin or Cm(2.54)
    right = section.right_margin or Cm(2.54)
    content = int(width) - int(left) - int(right)
    # Tab positions are in twips; EMU / 635 = twips.
    return str(max(content // 635, 7000))


def _nil_borders(table):
    tbl_pr = table._tbl.tblPr
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        element = OxmlElement(f"w:{edge}")
        element.set(qn("w:val"), "nil")
        element.set(qn("w:sz"), "0")
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), "auto")
        borders.append(element)
    tbl_pr.append(borders)


def setup_header_footer(doc):
    """Version 01 at the left, draft date at the right, page number at the foot."""
    for section in doc.sections:
        header = section.header
        header.is_linked_to_previous = False
        paragraph = header.paragraphs[0]
        paragraph.clear()
        paragraph.paragraph_format.space_before = Pt(0)
        paragraph.paragraph_format.space_after = Pt(0)
        usable = int(section.page_width - section.left_margin - section.right_margin)
        table = doc.add_table(rows=1, cols=2)
        table.autofit = False
        _nil_borders(table)
        table.columns[0].width = usable // 2
        table.columns[1].width = usable // 2
        left_cell = table.cell(0, 0)
        right_cell = table.cell(0, 1)
        left_cell.width = usable // 2
        right_cell.width = usable // 2
        left_para = left_cell.paragraphs[0]
        left_para.alignment = WD_ALIGN_PARAGRAPH.LEFT
        left_para.paragraph_format.space_before = Pt(0)
        left_para.paragraph_format.space_after = Pt(0)
        add_text(left_para, "Version 01", 11, False, False)
        right_para = right_cell.paragraphs[0]
        right_para.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        right_para.paragraph_format.space_before = Pt(0)
        right_para.paragraph_format.space_after = Pt(0)
        add_text(right_para, DRAFT_DATE, 11, False, False)
        # add_table places the table in the body. Move it into this header.
        header._element.append(table._tbl)
        if not paragraph.text and paragraph._p.getparent() is not None:
            paragraph._p.getparent().remove(paragraph._p)

        footer = section.footer
        footer.is_linked_to_previous = False
        foot = footer.paragraphs[0]
        foot.clear()
        foot.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        foot.paragraph_format.space_before = Pt(0)
        foot.paragraph_format.space_after = Pt(0)
        _add_page_field(foot)
    return doc


def add_text(paragraph, text, size=12, bold=False, italic=False):
    run = paragraph.add_run(text)
    _set_run_font(run, size, bold, italic)
    return run


def _configure_heading_style(doc, style_name, size, before, after):
    style = doc.styles[style_name]
    _set_style_font(style, size)
    style.font.bold = True
    style.font.italic = False
    style.font.color.rgb = BLACK
    rpr = style.element.get_or_add_rPr()
    color = rpr.find(qn("w:color"))
    if color is None:
        color = OxmlElement("w:color")
        rpr.append(color)
    color.set(qn("w:val"), "000000")
    if qn("w:themeColor") in color.attrib:
        del color.attrib[qn("w:themeColor")]
    style.paragraph_format.space_before = Pt(before)
    style.paragraph_format.space_after = Pt(after)
    style.paragraph_format.line_spacing = 1.5
    style.paragraph_format.keep_with_next = True


def add_heading(doc, text, level=1):
    paragraph = doc.add_paragraph(style="Heading 1" if level == 1 else "Heading 2")
    paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
    paragraph.paragraph_format.space_before = Pt(12 if level == 1 else 10)
    paragraph.paragraph_format.space_after = Pt(4)
    paragraph.paragraph_format.line_spacing = 1.5
    paragraph.paragraph_format.keep_with_next = True
    add_text(paragraph, text, 14 if level == 1 else 12, bold=True)
    return paragraph


def add_body(doc, text, *, bold=False, italic=False, center=False, justify=True, space_after=6, line_spacing=1.5, first_indent=None):
    paragraph = doc.add_paragraph()
    if center:
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    elif justify:
        paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    else:
        paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(space_after)
    paragraph.paragraph_format.line_spacing = line_spacing
    if first_indent:
        paragraph.paragraph_format.first_line_indent = first_indent
    add_text(paragraph, text, 12, bold, italic)
    return paragraph


def add_mixed_body(doc, parts, *, center=False, space_after=6):
    """parts: list of (text, bold)."""
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER if center else WD_ALIGN_PARAGRAPH.JUSTIFY
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(space_after)
    paragraph.paragraph_format.line_spacing = 1.5
    for text, bold in parts:
        add_text(paragraph, text, 12, bold, False)
    return paragraph


def add_bullet(doc, text, *, level=0):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    paragraph.paragraph_format.left_indent = Cm(1.0 + 0.5 * level)
    paragraph.paragraph_format.first_line_indent = Cm(-0.4)
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(2)
    paragraph.paragraph_format.line_spacing = 1.5
    add_text(paragraph, "•  " + text, 12, False, False)
    return paragraph


def add_numbered_item(doc, number, text, *, justify=True):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY if justify else WD_ALIGN_PARAGRAPH.LEFT
    paragraph.paragraph_format.left_indent = Cm(1.0)
    paragraph.paragraph_format.first_line_indent = Cm(-0.5)
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(3)
    paragraph.paragraph_format.line_spacing = 1.5
    add_text(paragraph, f"{number}.  {text}", 12, False, False)
    return paragraph


def add_toc_line(doc, title, page, level=0):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
    paragraph.paragraph_format.left_indent = Cm(0.75 * level)
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(1)
    paragraph.paragraph_format.line_spacing = 1.0
    ppr = paragraph._p.get_or_add_pPr()
    tabs = OxmlElement("w:tabs")
    tab = OxmlElement("w:tab")
    tab.set(qn("w:val"), "right")
    tab.set(qn("w:leader"), "dot")
    tab.set(qn("w:pos"), str(RIGHT_TAB - int(0.75 * level * 567)))
    tabs.append(tab)
    ppr.append(tabs)
    page_text = "" if page in (None, "") else str(page)
    add_text(paragraph, f"{title}\t{page_text}", 12, bold=(level == 0))
    return paragraph


def add_page_break(doc):
    paragraph = doc.add_paragraph()
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.space_after = Pt(0)
    run = paragraph.add_run()
    _set_run_font(run, 12)
    break_el = OxmlElement("w:br")
    break_el.set(qn("w:type"), "page")
    run._r.append(break_el)


def set_cell_text(cell, text, size=11, bold=False):
    cell.text = ""
    paragraph = cell.paragraphs[0]
    paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
    paragraph.paragraph_format.space_after = Pt(2)
    paragraph.paragraph_format.space_before = Pt(0)
    paragraph.paragraph_format.line_spacing = 1.15
    add_text(paragraph, text, size, bold, False)


def shade_cell(cell, fill):
    tc = cell._tc
    tcpr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    shd.set(qn("w:val"), "clear")
    tcpr.append(shd)


def set_table_borders(table):
    tbl = table._tbl
    tblpr = tbl.tblPr if tbl.tblPr is not None else OxmlElement("w:tblPr")
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        element = OxmlElement(f"w:{edge}")
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), "4")
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), "000000")
        borders.append(element)
    existing = tblpr.find(qn("w:tblBorders"))
    if existing is not None:
        tblpr.remove(existing)
    tblpr.append(borders)


def _keep_row_together(row):
    tr = row._tr
    trpr = tr.get_or_add_trPr()
    cant = OxmlElement("w:cantSplit")
    trpr.append(cant)


def add_plain_table(doc, headers, rows, col_widths=None):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.autofit = True
    set_table_borders(table)
    for row in table.rows:
        _keep_row_together(row)
    for index, header in enumerate(headers):
        set_cell_text(table.rows[0].cells[index], header, 11, True)
    for r_index, row in enumerate(rows):
        for c_index, value in enumerate(row):
            set_cell_text(table.rows[r_index + 1].cells[c_index], value, 11, False)
    if col_widths:
        for row in table.rows:
            for index, width in enumerate(col_widths):
                row.cells[index].width = Cm(width)
    return table


def clear_metadata(doc, title):
    props = doc.core_properties
    props.author = ""
    props.last_modified_by = ""
    props.title = title
    props.subject = ""
    props.comments = ""
    props.category = ""
    props.keywords = ""


def save_doc(doc, path, title):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    clear_metadata(doc, title)
    doc.save(path)
