#!/usr/bin/env python3
"""
Common formatting and styling utilities for University of Ruhuna ERC documents.
Adheres strictly to the formatting rules:
- Margin: 1 inch (72 pt) all around
- Header: Version 1.0 (DRAFT) | Date: November 2026
- Footer: Page numbers
- Typography: Calibri / Arial, clean line spacing and paragraph margins
- Table styling: professional shading, borders, and cell padding
"""

import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

PRIMARY_HEX = "1A365D"  # Deep Navy
SECONDARY_HEX = "2B6CB0" # Slate Blue
NEUTRAL_BG = "F7FAFC"   # Light Gray-Blue
BORDER_HEX = "CBD5E0"   # Subtle Border Gray

PRIMARY_COLOR = RGBColor(26, 54, 93)
SECONDARY_COLOR = RGBColor(43, 108, 176)
TEXT_COLOR = RGBColor(45, 55, 72)
MUTED_COLOR = RGBColor(113, 128, 150)
ALERT_BG_HEX = "FFF5F5"
ALERT_BORDER_HEX = "E53E3E"

def create_styled_document():
    """Initializes a document with 1-inch margins and default styles."""
    doc = docx.Document()
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.header_distance = Inches(0.5)
        section.footer_distance = Inches(0.5)
    return doc

def setup_header_footer(doc, doc_title, is_anonymous=False, version_str="Version 1.0 (DRAFT) | November 2026"):
    """Configures official header and footer for Ruhuna ERC submissions."""
    for section in doc.sections:
        # Header
        header = section.header
        p_hdr = header.paragraphs[0]
        p_hdr.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p_hdr.text = ""
        r_hdr = p_hdr.add_run(f"Ethics Review Committee, Faculty of Medicine, University of Ruhuna\n{doc_title} — {version_str}")
        r_hdr.font.name = "Calibri"
        r_hdr.font.size = Pt(8.5)
        r_hdr.font.italic = True
        r_hdr.font.color.rgb = MUTED_COLOR

        # Footer
        footer = section.footer
        p_ftr = footer.paragraphs[0]
        p_ftr.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_ftr.text = ""
        if is_anonymous:
            r_ftr = p_ftr.add_run("[ANONYMIZED SUBMISSION COPY FOR PEER REVIEW]   |   Page ")
        else:
            r_ftr = p_ftr.add_run("Simple AAC Application Research Protocol   |   Page ")
        r_ftr.font.name = "Calibri"
        r_ftr.font.size = Pt(9.0)
        r_ftr.font.color.rgb = MUTED_COLOR

        # Add page number XML field
        fldSimple = OxmlElement('w:fldSimple')
        fldSimple.set(qn('w:instr'), 'PAGE')
        p_ftr._p.append(fldSimple)

def add_draft_notice(doc, note="DRAFT — PENDING SUPERVISOR REVIEW AND AUTHENTIC APPLICANT SIGNATURES"):
    """Adds a standardized callout notice indicating draft status."""
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)
    
    set_cell_background(cell, "FEFCBF") # Light yellow/amber
    set_cell_padding(cell, top=120, bottom=120, left=180, right=180)
    
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_tag = p.add_run("ETHICS SUBMISSION WORKING DRAFT\n")
    r_tag.bold = True
    r_tag.font.name = "Calibri"
    r_tag.font.size = Pt(10)
    r_tag.font.color.rgb = RGBColor(146, 64, 14)
    
    r_txt = p.add_run(note)
    r_txt.font.name = "Calibri"
    r_txt.font.size = Pt(9.5)
    r_txt.font.color.rgb = RGBColor(116, 42, 6)
    
    doc.add_paragraph() # Spacer

def add_heading_1(doc, text):
    """Adds a standardized primary heading."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(14)
    run.font.bold = True
    run.font.color.rgb = PRIMARY_COLOR
    return p

def add_heading_2(doc, text):
    """Adds a standardized secondary heading."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(12)
    run.font.bold = True
    run.font.color.rgb = SECONDARY_COLOR
    return p

def add_heading_3(doc, text):
    """Adds a tertiary heading."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(11)
    run.font.bold = True
    run.font.italic = True
    run.font.color.rgb = PRIMARY_COLOR
    return p

def add_body_paragraph(doc, text, bold_prefix=None, space_after=6, italic=False):
    """Adds a clean body paragraph with 1.15 line spacing."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_prefix = p.add_run(bold_prefix)
        r_prefix.font.name = "Calibri"
        r_prefix.font.size = Pt(11)
        r_prefix.font.bold = True
        r_prefix.font.color.rgb = PRIMARY_COLOR
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(11)
    run.font.italic = italic
    run.font.color.rgb = TEXT_COLOR
    return p

def add_bullet_point(doc, text, bold_prefix=None):
    """Adds a styled bullet list item."""
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Calibri"
        r_pre.font.size = Pt(11)
        r_pre.font.bold = True
        r_pre.font.color.rgb = PRIMARY_COLOR
    run = p.add_run(text)
    run.font.name = "Calibri"
    run.font.size = Pt(11)
    run.font.color.rgb = TEXT_COLOR
    return p

def set_cell_background(cell, fill_hex):
    """Sets background shading of a table cell via XML."""
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_padding(cell, top=100, bottom=100, left=140, right=140):
    """Sets cell padding in dxa (1 pt = 20 dxa)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def format_table_headers_and_borders(table, col_widths=None, header_bg=PRIMARY_HEX):
    """Applies standardized styling to tables."""
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    # Format header row
    if len(table.rows) > 0:
        for idx, cell in enumerate(table.rows[0].cells):
            set_cell_background(cell, header_bg)
            set_cell_padding(cell, top=140, bottom=140, left=140, right=140)
            for p in cell.paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in p.runs:
                    run.font.name = "Calibri"
                    run.font.size = Pt(9.5)
                    run.font.bold = True
                    run.font.color.rgb = RGBColor(255, 255, 255)

    # Format data rows
    for r_idx, row in enumerate(table.rows[1:], start=1):
        bg = NEUTRAL_BG if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, cell in enumerate(row.cells):
            set_cell_background(cell, bg)
            set_cell_padding(cell, top=100, bottom=100, left=120, right=120)
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.name = "Calibri"
                    run.font.size = Pt(9.5)
                    run.font.color.rgb = TEXT_COLOR

    # Set column widths if provided
    if col_widths:
        for row in table.rows:
            for idx, width in enumerate(col_widths):
                if idx < len(row.cells):
                    row.cells[idx].width = Inches(width)
