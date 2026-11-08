#!/usr/bin/env python3
"""Separate request for advice. Not part of the ERC submission PDF.

The correct administrative route has not been confirmed. This letter does not
say that Ministry permission is mandatory or that it has been granted.
"""

from docx_common import (
    STUDY_TITLE,
    add_body,
    create_styled_document,
    save_doc,
    setup_header_footer,
)


def build_ministry_brief(output_path):
    doc = create_styled_document()
    doc._output_path = output_path
    setup_header_footer(doc)
    add_body(doc, "From", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "J.G.D. Thamalka and D.V.W. Gunawardana", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Medical student researchers", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Faculty of Medicine, University of Ruhuna", justify=False, space_after=6, line_spacing=1.0)
    add_body(doc, "Through", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Dr Gayani Punchihewa", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Senior Lecturer in Psychiatry", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Department of Psychiatry, Faculty of Medicine, University of Ruhuna", justify=False, space_after=6, line_spacing=1.0)
    add_body(doc, "To", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "The Secretary", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Ministry of Health", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Sri Lanka", justify=False, space_after=8, line_spacing=1.0)
    add_body(doc, "Dear Sir or Madam,", justify=False, space_after=6, line_spacing=1.0)
    add_body(
        doc,
        "We ask for advice, not for a decision that this letter can itself grant. The study "
        "title proposed for our supervisor is “" + STUDY_TITLE + "”. It would be one supervised "
        "sitting with each child and caregiver at PRAGATHI Child Intervention Centre, Galle. "
        "It would not test whether communication improves. No child has been recruited.",
        space_after=6,
        line_spacing=1.0,
    )
    add_body(
        doc,
        "We do not yet know whether a study at that single centre needs clearance from the "
        "Ministry of Health, from the provincial or regional health authority, from the centre "
        "alone, or from more than one of these. Please tell us which route applies. Ethics "
        "approval from the Faculty of Medicine, University of Ruhuna, and written permission "
        "from the centre, are separate. Neither has been given. This letter has not been sent.",
        space_after=6,
        line_spacing=1.0,
    )
    add_body(
        doc,
        "E.K.Y.P. Fernando is a researcher and the developer of the application. He is not the "
        "applicant. Dr Gayani Punchihewa has not signed as supervisor. The number of children "
        "has not been chosen.",
        space_after=6,
        line_spacing=1.0,
    )
    add_body(doc, "Yours faithfully,", justify=False, space_after=4, line_spacing=1.0)
    add_body(doc, "J.G.D. Thamalka", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "D.V.W. Gunawardana", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "E.K.Y.P. Fernando", justify=False, space_after=0, line_spacing=1.0)
    add_body(doc, "Dr Gayani Punchihewa, proposed supervisor", justify=False, space_after=2, line_spacing=1.0)
    add_body(
        doc,
        "The signature lines are blank. This page is not included in the ethics submission file.",
        italic=True,
        space_after=2,
        line_spacing=1.0,
    )
    save_doc(doc, output_path, "Request for administrative advice")
    return output_path
