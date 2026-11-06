#!/usr/bin/env python3
"""Fill the official human-research application without rebuilding its tables.

The blank file is the form downloaded from the Faculty site on 6 November 2026.
Answers that are not yet known are marked as pending. They are not guessed.
"""

import os

import docx
from docx.shared import Pt

from docx_common import (
    corresponding_contact_text,
    erc_root,
    is_private_output,
    load_private_contacts,
    setup_header_footer,
)

TITLE = (
    "Usability and caregiver acceptability of an offline picture-based "
    "communication application for children with communication difficulties in Galle"
)


def _font(paragraph, size=11, bold=False):
    for run in paragraph.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(size)
        run.bold = bold


def _set_paragraph(paragraph, text, size=11, bold=False):
    paragraph.text = text
    _font(paragraph, size, bold)


def _set_cell(cell, text):
    cell.text = text
    for paragraph in cell.paragraphs:
        _font(paragraph, 10, False)


def _replace_starting(doc, prefix, text):
    found = False
    for paragraph in doc.paragraphs:
        if paragraph.text.strip().startswith(prefix):
            _set_paragraph(paragraph, text)
            found = True
    return found


def _mark(table, row_index, yes, note):
    row = table.rows[row_index]
    row.cells[-1].text = note
    for paragraph in row.cells[-1].paragraphs:
        _font(paragraph, 9)
    if yes is None or len(row.cells) < 5:
        return
    # Standard five-column checklist: Yes, No, then the protocol note.
    yes_cell = row.cells[-3]
    no_cell = row.cells[-2]
    if yes_cell._tc is no_cell._tc:
        return
    yes_cell.text = "Yes" if yes else ""
    no_cell.text = "" if yes else "No"


def _contact_pair(output_path):
    if not is_private_output(output_path):
        return (
            "Omitted from this tracked draft.",
            "Omitted from this tracked draft.",
        )
    contacts = load_private_contacts()
    if not contacts:
        return ("Private contact file was not found.", "Private contact file was not found.")
    return (contacts["phone"], contacts["email"])


def populate_application_form(template_path, output_path):
    doc = docx.Document(template_path)
    phone, email = _contact_pair(output_path)

    _replace_starting(
        doc,
        "Version:",
        "Version: 01     Date: 06 November 2026     Draft for supervisor review. Not signed.",
    )
    _replace_starting(
        doc,
        "Name of Applicant:",
        "Name of Applicant: Pending confirmation. Do not read Yasas Pasindu Fernando as the applicant. "
        "The three investigators are named below until Dr Gayani Punchihewa and the medical students agree who will sign.",
    )
    _replace_starting(doc, "1. Title of Research Project:", "1. Title of Research Project: " + TITLE)

    applicant = doc.tables[1]
    _set_cell(applicant.cell(0, 0), "Title(Prof./Dr./Mr/Ms): Pending confirmation")
    _set_cell(
        applicant.cell(0, 1),
        "Name: Pending confirmation. The applicant will be one of J.G.D. Thamalka, "
        "D.V.W. Gunawardana, or, if the Faculty requires a staff applicant, Dr Gayani Punchihewa. "
        "Yasas Pasindu Fernando is not entered in this box.",
    )
    _set_cell(
        applicant.cell(1, 0),
        "Current designation and institution: Not confirmed, because the applicant is not confirmed. "
        "The medical students are students of the Faculty of Medicine, University of Ruhuna. "
        "Dr Punchihewa is a senior lecturer and psychiatrist in the Department of Psychiatry.",
    )
    _set_cell(
        applicant.cell(2, 0),
        "Highest educational qualification of applicant: Not entered until the applicant is named. "
        "Student qualifications have not been supplied. Dr Punchihewa’s public staff entry is MBBS, MD Psych.",
    )
    _set_cell(
        applicant.cell(3, 0),
        "Mailing address: Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle. "
        "A personal postal address has not been supplied.",
    )
    _set_cell(
        applicant.cell(4, 0),
        "Phone no for contact: " + phone + " Pending confirmation that this is J.G.D. Thamalka’s number and that this person will be the applicant.",
    )
    _set_cell(applicant.cell(4, 2), "e-mail: " + email)

    _replace_starting(
        doc,
        "3. Is this study a requirement",
        "3. Is this study a requirement for a postgraduate degree/requirement by PGIM for Board "
        "Certification, Faculty of Graduate studies (FGS)?    No. "
        "It is not a Kingston University dissertation and it is not a postgraduate registration. "
        "Whether it is required by the undergraduate medical curriculum has not been confirmed.",
    )
    _replace_starting(
        doc,
        "4. Are there supervisors",
        "4. Are there supervisors for this project?    Yes. Dr Gayani Punchihewa is proposed. She has not signed.",
    )

    supervisor = doc.tables[3]
    _set_cell(supervisor.cell(0, 0), "Title: Dr")
    _set_cell(supervisor.cell(0, 1), "Name: Gayani D. Punchihewa")
    _set_cell(
        supervisor.cell(1, 0),
        "Institutional affiliation: Senior Lecturer and Psychiatrist, Department of Psychiatry, "
        "Faculty of Medicine, University of Ruhuna. Taken from the Faculty staff page on 6 November 2026. "
        "She is not described here as Head of Department.",
    )
    _set_cell(supervisor.cell(2, 0), "Highest educational qualification: MBBS, MD Psych, as stated on that staff page.")
    _set_cell(
        supervisor.cell(3, 0),
        "Mailing address: Department of Psychiatry, Faculty of Medicine, P.O. Box 70, Galle.",
    )
    _set_cell(
        supervisor.cell(4, 0),
        "Phone: Not confirmed for this application. The departmental intercom on the staff page is not entered as a personal mobile.",
    )
    _set_cell(
        supervisor.cell(4, 2),
        "e-mail: Not copied into this draft. She should enter the address she wants the committee to use.",
    )

    _replace_starting(
        doc,
        "5.  Are there Co-investigators",
        "5. Are there Co-investigators for this project?    Yes. Three people are named. "
        "The formal applicant among them is still to be agreed.",
    )

    first = doc.tables[4]
    _set_cell(first.cell(0, 0), "Title: To be confirmed")
    _set_cell(first.cell(0, 1), "Name: J.G.D. Thamalka")
    _set_cell(
        first.cell(1, 0),
        "Institutional affiliation: Medical student researcher, Faculty of Medicine, University of Ruhuna. "
        "The project note lists Thamalka D. J. G. The name order should be confirmed before signature.",
    )
    _set_cell(first.cell(2, 0), "Highest educational qualification: Not supplied. Not guessed.")
    _set_cell(first.cell(3, 0), "Mailing address: Faculty of Medicine, University of Ruhuna, Galle.")
    _set_cell(first.cell(4, 0), "Phone: " + phone)
    _set_cell(first.cell(4, 2), "e-mail: " + email)

    second = doc.tables[5]
    _set_cell(second.cell(0, 0), "Title: To be confirmed")
    _set_cell(second.cell(0, 1), "Name: D.V.W. Gunawardana")
    _set_cell(
        second.cell(1, 0),
        "Institutional affiliation: Medical student researcher, Faculty of Medicine, University of Ruhuna.",
    )
    _set_cell(second.cell(2, 0), "Highest educational qualification: Not supplied. Not guessed.")
    _set_cell(second.cell(3, 0), "Mailing address: Faculty of Medicine, University of Ruhuna, Galle.")
    _set_cell(second.cell(4, 0), "Phone: Not supplied.")
    _set_cell(second.cell(4, 2), "e-mail: Not supplied.")

    third = doc.tables[6]
    _set_cell(third.cell(0, 0), "Title: To be confirmed")
    _set_cell(third.cell(0, 1), "Name: Yasas Pasindu Fernando")
    _set_cell(
        third.cell(1, 0),
        "Role: Researcher, technical research collaborator and developer of the application. "
        "No University of Ruhuna appointment has been confirmed. "
        "Kingston University and London Metropolitan University are the places of his degrees, not sponsors of this study.",
    )
    _set_cell(
        third.cell(2, 0),
        "Qualifications supplied by him: MSc Artificial Intelligence, Kingston University, ongoing; "
        "BEng (Hons) Software Engineering, London Metropolitan University, completed.",
    )
    _set_cell(third.cell(3, 0), "Mailing address: Not supplied.")
    _set_cell(third.cell(4, 0), "Phone: Not supplied for this form.")
    _set_cell(third.cell(4, 2), "e-mail: Not supplied for this form.")

    _replace_starting(
        doc,
        "Has any other ERC approved",
        "6. Has any other ERC approved this project?    No. This is a first application. No approval is claimed.",
    )

    sites = doc.tables[7]
    _set_cell(sites.cell(1, 0), "Child intervention centre (proposed)")
    _set_cell(
        sites.cell(1, 1),
        "PRAGATHI Child Intervention Centre, Galle. Permission has not been received. See proposal Annex E.",
    )
    _set_cell(sites.cell(2, 0), "Not a study site in this draft")
    _set_cell(
        sites.cell(2, 1),
        "No hospital ward or clinic is included. A second site would need an amendment before submission.",
    )

    _replace_starting(
        doc,
        "Is this a multi-site study?",
        "Is this a multi-site study?    No, on the present draft. Only one centre is proposed, and it has not yet agreed.",
    )

    funding = doc.tables[8]
    _set_cell(funding.cell(1, 0), "Funded: No")
    _set_cell(funding.cell(1, 1), "No agency and no amount.")
    _set_cell(funding.cell(2, 0), "Applied for funding: No")
    _set_cell(funding.cell(2, 1), "No application has been made.")
    _set_cell(
        funding.cell(3, 0),
        "Unfunded. No grant has been identified. Amounts for printing, travel and a device have not been costed. "
        "No sponsor is named. Participants will not be paid. The software already exists. "
        "That is not the same as a statement that the Faculty or the centre has agreed to provide a room or a device.",
    )

    _replace_starting(
        doc,
        "For Clinical Trials only",
        "For Clinical Trials only: Not applicable. This is not a clinical trial.",
    )
    _replace_starting(doc, "9.2 Is it a multi-centre trial?", "9.2 Is it a multi-centre trial? Not applicable.")
    _replace_starting(
        doc,
        "9.3 Is the clinical trial registered",
        "9.3 Is the clinical trial registered with a clinical trials registry? Not applicable.",
    )
    _replace_starting(
        doc,
        "9.4",
        "9.4 Has this study been approved by the SCOCT at the Ministry of Health? Not applicable. This is not a clinical trial.",
    )
    _replace_starting(doc, "9.5", "9.5 Data Safety Monitoring Board: Not applicable.")
    _replace_starting(
        doc,
        "9.6",
        "9.6 Indemnity and insurance: Not applicable to a clinical-trial policy. The study has no medicine and no invasive procedure. "
        "Ordinary responsibility for a distressed child is described in proposal section 5.10.",
    )

    _replace_starting(
        doc,
        "Estimated start date",
        "Estimated start date that involves human participants or data: Not fixed. "
        "No participant will be approached before ethics approval and written permission from the centre.",
    )
    _replace_starting(
        doc,
        "Estimated completion date",
        "Estimated completion date of involvement of human participants or data: Not fixed. "
        "A relative timetable is in proposal section 7. It is not an agreed calendar.",
    )
    # Leftover prompts from questions that are not applicable. They must not stay as blank Yes/No lines.
    for prefix, answer in (
        ("Certification, Faculty of Graduate", "Not applicable. Question 3 is No, so no Board of Study letter is attached."),
        ("3.1 Have you already registered", "3.1 Have you already registered for this degree? Not applicable."),
        ("Please append letter of approval", "Board of Study approval letter: Not applicable."),
        ("What is the phase of the clinical trial", "Phase of the clinical trial: Not applicable."),
        ("If OTHER specify", "Other phase: Not applicable."),
        ("If yes, list the other trial sites", "Other trial sites: Not applicable."),
        ("Please attach ethics approval from the sponsoring", "Ethics approval from a sponsoring country: Not applicable."),
        ("If yes, give details (name of register", "Trial registry: Not applicable."),
        ("If No, give reasons", "Not applicable."),
        ("the Ministry of Health", "Not applicable."),
        ("If yes, give details of Approval Number", "SCOCT approval number: Not applicable."),
        ("* Please attach the curriculum vitae of all members of the DSMB", "DSMB curriculum vitae: Not applicable."),
        ("ethics committee", "Not applicable."),
        ("If Yes, please attach a copy of the approval letter.", "Other ethics approval letter: Not applicable. No other committee has approved this study."),
    ):
        _replace_starting(doc, prefix, answer)

    _mark(doc.tables[21], 2, True, "Proposed only. The centre has not agreed. Proposal sections 5.2 and 5.9.")
    _mark(doc.tables[21], 3, False, "No community organisation has been consulted for this draft. Not claimed.")
    _mark(
        doc.tables[21],
        4,
        True,
        "The benefit, if any, is information about whether one sitting is practical. No promise of better speech. Section 2.",
    )

    _mark(
        doc.tables[22],
        2,
        True,
        "Children with communication difficulties who already attend the centre, and their caregivers. Section 5.3.",
    )
    _mark(
        doc.tables[22],
        3,
        True,
        "A short description of the counts would be offered to the centre and the committee. No journal is promised. Section 5.10.",
    )

    _mark(
        doc.tables[23],
        2,
        True,
        "The application exists, but it has not been observed with participants. Sections 1 and 2.",
    )
    _mark(doc.tables[23], 3, False, "Not a replication study.")
    _mark(
        doc.tables[23],
        4,
        False,
        "No sample size is stated. A calculation has not been done. Section 5.5. This must be completed before submission.",
    )

    _mark(doc.tables[24], 2, True, "Observer record and five caregiver questions. No biological samples. Section 5.6 and Annex D.")
    _mark(doc.tables[24], 3, None, "Retention period not yet agreed. It will follow the Faculty requirement. Section 5.10.")
    _mark(doc.tables[24], 4, True, "A name is needed on the consent form. The session record uses a code. Section 5.10.")
    _mark(doc.tables[24], 5, True, "Student researchers and the supervisor. The developer does not need the name list. Section 5.10.")
    _mark(doc.tables[24], 6, True, "Code on the session form. Consent kept apart. Section 5.10.")
    _mark(doc.tables[24], 7, None, "The locked place has not been named. Recruitment waits on that decision. Section 5.10.")
    _mark(doc.tables[24], 8, None, "Destruction after the Faculty retention period. Method not yet specified. Section 5.10.")

    _mark(doc.tables[25], 2, True, "The parent may stop by saying so. The child may refuse. Section 5.10 and Annex B.")
    _mark(doc.tables[25], 3, True, "Questions to the student researchers, and complaints to ethics@med.ruh.ac.lk. Annex A.")
    _mark(doc.tables[25], 4, None, "Applicant not confirmed. " + corresponding_contact_text(output_path))
    _mark(doc.tables[25], 5, True, "The centre can be told the grouped counts. Families are not promised an individual report. Section 5.10.")
    _mark(doc.tables[25], 6, False, "The application is not promised as a product to keep. Section 5.8.")

    _mark(
        doc.tables[26],
        2,
        True,
        "The question can only be answered with children who have communication difficulties and their caregivers. Section 5.3.",
    )
    _mark(doc.tables[26], 3, True, "Section 5.4.")

    # Wider table. Put the answer in the protocol column rather than guessing merged tick-boxes.
    responsibilities = doc.tables[27]
    notes = {
        2: "Yes, in the limited sense that the sitting stops if the child is distressed and usual care is not withheld. No research injury procedure beyond that. Section 5.10.",
        3: "Yes. Usual care at the centre continues. This study does not provide a course of therapy. Section 5.10.",
        4: "An intellectual interest is declared: the developer is an investigator. No financial sponsor was identified. Section 5.10. The signed declaration is still required.",
        5: "Children cannot protect their own interests. Consent, assent and the right to stop are in section 5.10.",
        8: "Yes. The users of a picture board are children with communication difficulties. Adults without that difficulty could not answer the question. Section 5.3.",
    }
    for index, note in notes.items():
        responsibilities.rows[index].cells[-1].text = note

    foreign = doc.tables[28]
    foreign.rows[2].cells[-1].text = (
        "Not applicable as a foreign-funded project. There is no foreign sponsor. "
        "Two degrees of the technical collaborator were taken in the United Kingdom. "
        "Those universities are not funders, sites, or owners of this study."
    )
    for index in range(3, len(foreign.rows)):
        foreign.rows[index].cells[-1].text = "Not applicable. No foreign funder and no transfer of samples."

    _mark(doc.tables[29], 2, True, "One proposed centre in Galle. Permission not yet given. Section 5.2.")
    _mark(doc.tables[29], 3, False, "The community has not been consulted beyond the intention to ask the centre. Not claimed.")
    _mark(doc.tables[29], 4, True, "Parent consent and the centre’s written permission. No separate community consent. Section 5.10.")
    _mark(doc.tables[29], 5, False, "No training programme is offered as part of this study.")
    _mark(doc.tables[29], 6, True, "Grouped counts can be shared with the centre. Section 5.10.")

    trial = doc.tables[30]
    for index in range(2, len(trial.rows)):
        trial.rows[index].cells[-1].text = "Not applicable. This is not a clinical trial."

    sheets = doc.tables[31]
    sheet_notes = {
        2: "Annex A, purpose.",
        3: "Annex A, voluntary participation, and Annex B.",
        4: "Annex A, what will happen.",
        5: "Annex A, benefits.",
        6: "Annex A, risks.",
        7: "Annex A, no payment.",
        8: "Annex A and section 5.10.",
        9: "Annex A and Annex B.",
    }
    for index, note in sheet_notes.items():
        if index < len(sheets.rows):
            sheets.rows[index].cells[-1].text = note

    consent_notes = {
        2: "A clinician at the centre introduces the study. A student researcher explains it. Section 5.8.",
        3: "Written consent. Annex B.",
        6: "Annex A in English. Sinhala and Tamil are not yet prepared. Annex F.",
        7: "The researcher asks the parent to say back what the sitting involves. Section 5.8.",
        8: "Written consent of a parent or guardian for every child. Annex B.",
        9: "The parent may withdraw by saying so. Section 5.10.",
        10: "No payment and no gift. Section 5.8.",
        11: "Any change to the sitting will be sent to the committee before it is used, and parents will be asked again if the change matters.",
        12: "Parent consent for every child. A child who does not want to continue is not made to continue. Section 5.10.",
        13: "The upper age in this draft is about 12 years. A child who can read Annex C will be asked to sign it. Others are not asked to sign a form they cannot read.",
    }
    consent = doc.tables[32]
    for index, note in consent_notes.items():
        if index < len(consent.rows):
            consent.rows[index].cells[-1].text = note
            if len(consent.rows[index].cells) >= 5 and index in (3, 8):
                consent.rows[index].cells[-3].text = "Yes"

    _replace_starting(
        doc,
        "12.1 What is the procedure",
        "12.1 What is the procedure to be carried out on these subjects?\n"
        "One sitting of about twenty minutes with the caregiver present. The device is offline. "
        "The caregiver is asked to open the picture categories. The child may select a picture. "
        "The observer completes Annex D. The caregiver answers five yes, no, or not-sure questions. "
        "There is no blood sample, medicine, or diagnostic test. "
        "No child has undergone this procedure. Proposal sections 5.6 and 5.8.",
    )
    _replace_starting(
        doc,
        "13.1 Please provide a brief description",
        "13.1 Experience of the investigators.\n"
        "J.G.D. Thamalka and D.V.W. Gunawardana are medical students. Previous research experience has not been supplied. "
        "They will be shown by the supervisor how to explain the study and how to stop a sitting before anyone is invited.\n"
        "Dr Gayani Punchihewa is proposed as supervisor. Her public appointment is summarised in the curriculum-vitae note. "
        "This form does not invent a list of her research.\n"
        "Yasas Pasindu Fernando developed the application. Other research experience has not been supplied. "
        "He will not take consent.",
    )
    _replace_starting(
        doc,
        "(i) Physical risks",
        "(i) Physical risks: No.\n"
        "(ii) Psychological or emotional risks: Yes. A child may become tired or frustrated.\n"
        "(iii) Social risks: Yes, if a name were linked publicly to a communication difficulty.\n"
        "(iv) Legal risks: No.",
    )
    _replace_starting(
        doc,
        "14.2",
        "14.2 The sitting can frustrate a child who cannot find a picture. A named form could disclose that the child attends the centre for communication support.",
    )
    _replace_starting(
        doc,
        "14.3",
        "14.3 The parent stays. The sitting stops if the child is distressed. The session record uses a code. "
        "The place where consent forms will be locked has not yet been agreed. Section 5.10.",
    )
    _replace_starting(
        doc,
        "Describe any potential direct benefits to participants",
        "Direct benefit to participants: there may be none. The family sees the application once. No improvement in speech is promised.",
    )
    _replace_starting(
        doc,
        "Describe any potential direct benefits to the community",
        "The centre would learn whether this application can be operated in one sitting. That information is useful only if the sittings actually take place under approval.",
    )
    _replace_starting(
        doc,
        "Comment on the potential benefits to the scientific",
        "A later reader would have a description of one local application used once, not a trial of treatment.",
    )
    _replace_starting(
        doc,
        "16.1",
        "16.1 Will participants receive compensation? Financial: No. In-kind: No. Other: No.",
    )
    _replace_starting(
        doc,
        "16.2",
        "16.2 Not applicable. Nothing of value is offered for taking part.",
    )
    _replace_starting(
        doc,
        "16.3",
        "16.3 Payment is not planned. Offering the application as a gift would make refusal harder, so installation on a family telephone is not part of the study.",
    )
    _replace_starting(
        doc,
        "16.4",
        "16.4 There is no payment to withdraw. A parent who stops loses nothing that the study had given.",
    )
    _replace_starting(
        doc,
        "17. Feedback",
        "17. After the sitting the parent may ask what was written on the code-numbered form. "
        "Usual care at the centre continues. No extra clinic is created by this study.",
    )
    _replace_starting(
        doc,
        "18. Do you have any conflict",
        "18. Do you have any conflict of interests? Yes, an intellectual one, described below. No financial conflict has been identified. The investigators must still sign.",
    )
    _replace_starting(doc, "18.1", "18.1 Commercially: none identified. No sale of the application is part of this study.")
    _replace_starting(doc, "18.2", "18.2 Financially: none identified. No grant and no sponsor.")
    _replace_starting(
        doc,
        "18.3",
        "18.3 Intellectually: Yasas Pasindu Fernando developed the application that the sitting will use. "
        "The students will complete the forms. The supervisor will review them. He will not take consent.",
    )
    _replace_starting(doc, "18.4", "18.4 Other: none identified.")
    _replace_starting(
        doc,
        "19. Does any member",
        "19. Does any member have an affiliation with a funder? No funder has been identified.",
    )
    _replace_starting(
        doc,
        "20. If there is a duality",
        "20. The developer’s role is declared in 18.3. It is not a financial interest on the information supplied. "
        "The team must correct this answer if any person expects payment or control of the software.",
    )
    _replace_starting(
        doc,
        "Full name of Principal Investigator:",
        "Full name of Principal Investigator: Pending confirmation. Not signed. "
        "Signature and date remain blank.",
    )

    signatures = doc.tables[37]
    rows = [
        (
            "Applicant: name pending confirmation",
            "Not entered until the applicant is agreed",
            "Faculty of Medicine, University of Ruhuna, if a student or Dr Punchihewa is appointed",
            "Signature not made",
        ),
        (
            "J.G.D. Thamalka",
            "Not supplied",
            "Medical student researcher, Faculty of Medicine, University of Ruhuna",
            "Signature not made",
        ),
        (
            "D.V.W. Gunawardana",
            "Not supplied",
            "Medical student researcher, Faculty of Medicine, University of Ruhuna",
            "Signature not made",
        ),
        (
            "Dr Gayani Punchihewa",
            "MBBS, MD Psych, from the Faculty staff page",
            "Senior Lecturer and Psychiatrist, Department of Psychiatry. Proposed supervisor. Consent not yet given.",
            "Signature not made",
        ),
        (
            "Yasas Pasindu Fernando",
            "MSc Artificial Intelligence, Kingston University, ongoing; BEng (Hons) Software Engineering, London Metropolitan University, completed",
            "Researcher, technical research collaborator and application developer. Not the applicant on this draft.",
            "Signature not made",
        ),
    ]
    for index, values in enumerate(rows, start=1):
        for column, value in enumerate(values):
            _set_cell(signatures.cell(index, column), value)
    for index in range(6, len(signatures.rows)):
        for column in range(4):
            _set_cell(signatures.cell(index, column), "Not applicable")

    setup_header_footer(doc)
    props = doc.core_properties
    props.author = ""
    props.last_modified_by = ""
    props.title = "Human research application draft"
    props.subject = ""
    props.comments = ""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Wrote {output_path}")
    return output_path


def main():
    root = erc_root()
    template = os.path.join(root, "scripts", "templates", "Application_for_Human_Research_OFFICIAL_BLANK.docx")
    output = os.path.join(root, "forms", "02_Human_Research_Application_DRAFT.docx")
    populate_application_form(template, output)


if __name__ == "__main__":
    main()
