#!/usr/bin/env python3
"""Supervisor review pack for the Galle AAC feasibility pilot.

Writes only under the git-ignored private directory. It does not submit
anything to the Ethics Review Committee or the Ministry of Health.
"""

import os
import shutil

import docx
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm

from build_erc_package import convert_docx_to_pdf
from docx_common import (
    STUDY_TITLE,
    add_body,
    add_bullet,
    add_heading,
    add_page_break,
    add_plain_table,
    create_styled_document,
    repo_root,
    save_doc,
    setup_header_footer,
)
from generate_protocol_and_annexures import (
    add_annex_assent,
    add_annex_consent,
    add_annex_info,
    add_annex_tools,
    build_research_protocol,
)

PACK_NAME = "Supervisor_Review_Pack"
PROPOSAL_NAME = "Research_Proposal_EDITABLE.docx"


def pack_dir():
    path = os.path.join(repo_root(), ".local_erc_private", "supervisor_review_pack")
    os.makedirs(path, exist_ok=True)
    return path


def proposal_source():
    return os.path.join(
        repo_root(), ".local_erc_private", "review_word", "04_Research_Proposal.docx"
    )


def _set_widths(table, widths):
    """Lock column widths in twips so a blank column stays wide enough to write in."""
    table.autofit = False
    table.allow_autofit = False
    tbl = table._tbl
    tbl_pr = tbl.tblPr
    total = str(int(sum(widths) * 567))
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), total)
    tbl_w.set(qn("w:type"), "dxa")
    grid = tbl.find(qn("w:tblGrid"))
    if grid is None:
        grid = OxmlElement("w:tblGrid")
        tbl_pr.addnext(grid)
    for child in list(grid):
        grid.remove(child)
    for width in widths:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(int(width * 567)))
        grid.append(col)
    for row in table.rows:
        for index, width in enumerate(widths):
            row.cells[index].width = Cm(width)


def _tight(doc, text, *, bold=False, center=False, space_after=3):
    return add_body(
        doc,
        text,
        bold=bold,
        center=center,
        justify=not center,
        space_after=space_after,
        line_spacing=1.08,
    )


def add_summary(doc):
    _tight(doc, "SUPERVISOR REVIEW PACK", bold=True, center=True, space_after=2)
    _tight(
        doc,
        "For Dr Gayani Punchihewa, J.G.D. Thamalka and D.V.W. Gunawardana",
        center=True,
        space_after=2,
    )
    _tight(
        doc,
        "Unsigned internal draft for discussion. It has not been sent to the Ethics Review "
        "Committee or to the Ministry of Health. It is not an approval.",
        center=True,
        space_after=6,
    )
    _tight(doc, "Proposed title", bold=True, space_after=2)
    _tight(doc, STUDY_TITLE, bold=True, space_after=2)
    _tight(doc, "The title is provisional until the supervisor agrees the wording.", space_after=6)
    _tight(doc, "Study in one page", bold=True, space_after=2)
    _tight(
        doc,
        "The study would be a prospective descriptive feasibility and usability pilot. Each "
        "child–caregiver pair would be invited to one supervised sitting of about twenty minutes "
        "at PRAGATHI Child Intervention Centre, Galle. The application would be used offline. "
        "The sitting would record whether the procedure can be completed, whether a willing child "
        "selects a picture, whether the caregiver can open the categories, and whether the "
        "caregiver finds the screen and the language acceptable.",
    )
    _tight(
        doc,
        "“Not attempted” would be kept separate from “attempted but unsuccessful”. There is no "
        "control group, no random allocation, and no change to medicine or usual therapy. The "
        "study does not estimate whether communication or speech improves. No family has been "
        "recruited, and the application has not been tried with participants for this study.",
    )
    _tight(
        doc,
        "J.G.D. Thamalka and D.V.W. Gunawardana lead the research under faculty supervision. "
        "Dr Gayani Punchihewa is the proposed supervisor and has not signed. E.K.Y.P. Fernando "
        "(Yasas Pasindu Fernando) is a researcher, the technical collaborator and the developer "
        "of the application. He is not proposed as the sole principal investigator. He would not "
        "take consent and would not decide who is eligible.",
        space_after=4,
    )


def add_decisions(doc):
    add_page_break(doc)
    add_heading(doc, "Decisions required before the draft can proceed")
    add_body(
        doc,
        "Please mark each row. A blank is not an acceptance. None of these points has been agreed.",
        space_after=4,
        line_spacing=1.08,
    )
    decision_table = add_plain_table(
        doc,
        ["Decision", "Position in this draft", "Supervisor"],
        [
            [
                "Title",
                "Provisional, as printed above.",
                "",
            ],
            [
                "Applicant who will sign",
                "Not named. The students lead the research. E.K.Y.P. Fernando is not proposed as the sole principal investigator.",
                "",
            ],
            [
                "Supervisor designation on the letters",
                "The letters say Senior Lecturer in Psychiatry. The staff page says Senior Lecturer and Psychiatrist. Please confirm the wording.",
                "",
            ],
            [
                "Sample size",
                "No number is in force. See the next section. Option B (12 pairs) is not selected.",
                "",
            ],
            [
                "Age rule",
                "About 2 to 12 years. The exact date-of-birth rule is not set.",
                "",
            ],
            [
                "Design of the sitting",
                "One sitting, about 20 minutes, offline, at PRAGATHI only. No second site.",
                "",
            ],
            [
                "Forms in this pack",
                "English parent sheet, consent, assent, session record and five caregiver questions are drafts.",
                "",
            ],
            [
                "Technical collaborator’s role",
                "He maintains the build and may see a fault note with no name. He does not take consent.",
                "",
            ],
        ],
        col_widths=[4.2, 7.6, 4.7],
    )
    _set_widths(decision_table, [4.2, 7.6, 4.7])


def add_sample_size(doc):
    add_page_break(doc)
    add_heading(doc, "Sample size: for discussion, not yet chosen")
    add_body(
        doc,
        "No target number has been selected, and this pack does not treat any number as approved. "
        "The study would describe one sitting. It would not compare groups and it would not test "
        "whether communication improves, so a power calculation for a treatment effect is not the "
        "right calculation. The number of eligible children who attend the centre has not been counted.",
    )
    add_body(
        doc,
        "Recruitment, if it is later allowed, would be consecutive. A clinician or therapist who "
        "already knows the child would mention the study. A student researcher would then explain "
        "it to families who wish to hear more. Families could decide on a later visit. Recruitment "
        "would stop when an agreed number is reached or when an agreed period ends, whichever comes first.",
    )
    add_body(doc, "Two options are written for a decision. Neither is in force.", bold=True, space_after=4)
    add_body(
        doc,
        "Option A. Invite every eligible pair who attends during a period agreed with the centre. "
        "The number would be whatever that period yields. Because attendance is unknown, Option A "
        "does not state a target. It also cannot promise that the period will be long enough to "
        "see rare practical problems.",
    )
    add_body(
        doc,
        "Option B. A fixed group of 12 pairs, suggested only as a way to see whether the sitting, "
        "the forms and the offline setup can be completed. Twelve is not a power calculation. It "
        "is not based on a count of eligible families. It is not the sample size of this study "
        "unless the supervisor accepts it in writing and states the reason. Accepting 12 would "
        "not allow a claim of clinical effectiveness.",
    )
    add_body(
        doc,
        "A third course is open: the supervisor may set a different number, or a different period, "
        "and write the reason. Until one course is accepted and copied into section 5.5 of the "
        "proposal, no family will be recruited.",
    )
    add_body(doc, "Please record the decision here.", bold=True, space_after=4)
    choice = add_plain_table(
        doc,
        ["Choice", "Write one option, or another number", "Reason, in the supervisor’s words"],
        [["Sample size", "", ""]],
        col_widths=[3.2, 6.6, 6.7],
    )
    _set_widths(choice, [3.2, 6.6, 6.7])


def add_technical_checklist(doc):
    add_page_break(doc)
    add_heading(doc, "Technical checks still required on the pilot handset")
    add_body(
        doc,
        "The notes below come from reading the application source on 8 November 2026, version "
        "1.0.2+3 in pubspec.yaml. That reading is not a test of an installed handset, and it is "
        "not evidence that a family has used the application. The result column is blank because "
        "these checks have not been done on the device that would be used.",
    )
    add_plain_table(
        doc,
        ["Check", "What the source shows", "Still to do before recruitment", "Result"],
        [
            [
                "Name the build",
                "Source version 1.0.2+3. No handset build has been frozen.",
                "Write the file name, version and date of the one device build that will be used.",
                "",
            ],
            [
                "Languages on screen",
                "Cards can store English, Sinhala and Tamil. An empty Sinhala or Tamil label falls back to English. The seed list translates only hello, happy, sad, angry, more, good and play.",
                "On that device, open each language and record which words are still English.",
                "",
            ],
            [
                "Spoken output",
                "The home screen asks for si-LK, ta-IN or en-US. Speech starts on en-US. Sinhala and Tamil speech has not been heard.",
                "Listen on the pilot device. A competent speaker checks the wording.",
                "",
            ],
            [
                "Offline sitting",
                "Online features start off, and the gated client used by the application throws while they are off. This was not shown on a handset. The Android package still requests internet access.",
                "Start the sitting with online features off and confirm that the sitting does not need a connection.",
                "",
            ],
            [
                "Camera and microphone",
                "The package can photograph a card and record a voice. Those permissions stay in the installed package.",
                "Make no new photograph and no new voice recording. If either happens, stop the sitting.",
                "",
            ],
            [
                "Storage",
                "Cards are stored in the application documents folder, with a local backup file. No encryption of that file was identified. A local backup is not proof that cloud backup is impossible.",
                "Switch off device cloud backup for the sitting. Do not copy study forms to a cloud drive.",
                "",
            ],
            [
                "Later changes",
                "A different build is a different intervention.",
                "Do not replace the named build after recruitment starts unless the proposal is amended.",
                "",
            ],
        ],
    )
    add_body(
        doc,
        "E.K.Y.P. Fernando would be responsible for the named build and for dealing with a technical "
        "fault. The student researchers would complete the session forms. The supervisor would review them.",
        space_after=4,
    )


def add_permissions(doc):
    add_page_break(doc)
    add_heading(doc, "Ethics and administrative permissions still outstanding")
    add_body(
        doc,
        "Nothing in this list has been granted. The drafts are ready for the supervisor to read. "
        "They are not ready to send.",
        space_after=4,
    )
    add_plain_table(
        doc,
        ["Item", "Present position"],
        [
            ["Supervisor’s signature", "Not signed. The endorsement letter is a draft in her name."],
            ["Applicant / principal investigator", "Not confirmed."],
            ["Faculty ethics review", "Not submitted. No approval has been given."],
            ["Fee category and receipt", "Cannot be chosen until the applicant and the curriculum status are confirmed. No receipt is enclosed."],
            ["Training certificates", "Not supplied."],
            ["PRAGATHI Child Intervention Centre", "Proposed site only. The permission letter has not been sent and has not been signed."],
            ["Ministry or provincial route", "Not known. A separate advice letter exists and has not been sent. It is not part of the ethics file, and it is not a clearance."],
            ["Sinhala and Tamil parent forms", "Not written. A competent speaker has not checked them. English-only explanation limits who can be invited."],
            ["Consent storage and retention", "Coded study forms would be kept apart from named consent. The lock, the place and the retention period are not agreed."],
            ["Handset build", "Not frozen, and the language and speech checks above are not done."],
        ],
    )
    add_body(
        doc,
        "No child will be recruited until the supervisor has accepted the design, the site has given "
        "written permission, and the Ethics Review Committee has approved the study.",
    )


def add_forms(doc, output_path):
    add_page_break(doc)
    add_heading(doc, "Draft forms for review")
    add_body(
        doc,
        "The same drafts sit in the editable proposal in this folder. They are not signed consent, "
        "and they are not evidence that anyone has taken part. Please mark changes on either copy. "
        "The proposal file is the detailed methods, literature and reference list.",
        italic=True,
    )
    doc._output_path = output_path
    add_annex_info(doc, anonymous=False)
    add_annex_consent(doc, anonymous=False)
    add_annex_assent(doc)
    add_annex_tools(doc)


def ensure_proposal(destination):
    source = proposal_source()
    if not os.path.isfile(source):
        build_research_protocol(destination, anonymous=False)
        return destination
    shutil.copy2(source, destination)
    return destination


def build_pack():
    folder = pack_dir()
    briefing_path = os.path.join(folder, PACK_NAME + ".docx")
    proposal_path = os.path.join(folder, PROPOSAL_NAME)
    ensure_proposal(proposal_path)

    doc = create_styled_document()
    doc._output_path = briefing_path
    setup_header_footer(doc)
    add_summary(doc)
    add_decisions(doc)
    add_sample_size(doc)
    add_technical_checklist(doc)
    add_permissions(doc)
    add_forms(doc, briefing_path)
    save_doc(doc, briefing_path, "Supervisor review pack")

    # Confirm the saved file opens and still has no author metadata.
    check = docx.Document(briefing_path)
    if check.core_properties.author:
        raise RuntimeError("Author metadata was not cleared")
    pdf_path = convert_docx_to_pdf(briefing_path, folder)
    print(briefing_path)
    print(proposal_path)
    print(pdf_path)
    return briefing_path, proposal_path, pdf_path


if __name__ == "__main__":
    build_pack()
