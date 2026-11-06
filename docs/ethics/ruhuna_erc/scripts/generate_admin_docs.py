#!/usr/bin/env python3
"""Cover letter, supervisor draft, curriculum vitae notes, and status sheets.

Training certificates, animal-handling letters and fee receipts are not invented.
Those sheets say what is missing. They are not part of the electronic submission file.
"""

import os

from docx_common import (
    add_body,
    add_bullet,
    add_heading,
    add_plain_table,
    corresponding_contact_text,
    create_styled_document,
    erc_root,
    save_doc,
    setup_header_footer,
)

TITLE = (
    "Usability and caregiver acceptability of an offline picture-based communication "
    "application for children with communication difficulties in Galle"
)


def _doc(path):
    doc = create_styled_document()
    doc._output_path = path
    setup_header_footer(doc)
    return doc


def build_cover_letter(output_path):
    doc = _doc(output_path)
    add_body(doc, "The Chairperson")
    add_body(doc, "Ethics Review Committee", space_after=0)
    add_body(doc, "Faculty of Medicine", space_after=0)
    add_body(doc, "University of Ruhuna", space_after=0)
    add_body(doc, "Galle, Sri Lanka")
    add_body(doc, "Dear Chairperson,")
    add_body(
        doc,
        "We submit a draft application for ethical review of the study entitled “"
        + TITLE
        + "”. The study would describe one supervised sitting with an existing picture-based "
        "communication application. No participant has been recruited. The application has not "
        "been shown to improve communication, and this draft does not claim that it has.",
    )
    add_body(
        doc,
        "The medical student researchers are J.G.D. Thamalka and D.V.W. Gunawardana, Faculty of "
        "Medicine, University of Ruhuna. They lead the clinical planning and this application. "
        "Yasas Pasindu Fernando is a researcher, technical research collaborator and the developer "
        "of the application. He is not proposed as the sole principal investigator. "
        "Dr Gayani Punchihewa is the proposed supervisor. She has not yet signed.",
    )
    add_body(
        doc,
        "The person who will sign as the applicant has not been confirmed with Dr Punchihewa. "
        "Until that is agreed, all three investigators are named and the applicant line is left "
        "open. " + corresponding_contact_text(output_path),
    )
    add_body(
        doc,
        "Hard-copy items that are not enclosed with this electronic file are the training "
        "certificates (none have been supplied), the animal-handling letter (not applicable, "
        "because the study involves no animals), and the fee receipt (the fee category cannot "
        "be chosen until the applicant and the curriculum status are confirmed). Sinhala and "
        "Tamil parent forms are still to be prepared. We ask the committee to treat this package "
        "as a draft for review by the supervisor, not as a signed submission.",
    )
    add_body(doc, "Yours faithfully,")
    add_plain_table(
        doc,
        ["Signatory", "Signature", "Date"],
        [
            ["Applicant (name to be confirmed)", "", ""],
            ["J.G.D. Thamalka", "", ""],
            ["D.V.W. Gunawardana", "", ""],
            ["Yasas Pasindu Fernando", "", ""],
            ["Dr Gayani Punchihewa, supervisor", "", ""],
        ],
    )
    add_body(doc, "The signature cells are blank. No signature is represented by this draft.", italic=True, space_after=2)
    save_doc(doc, output_path, "Cover letter draft")
    return output_path


def build_supervisor_letter(output_path):
    doc = _doc(output_path)
    add_body(doc, "The Chairperson")
    add_body(doc, "Ethics Review Committee", space_after=0)
    add_body(doc, "Faculty of Medicine", space_after=0)
    add_body(doc, "University of Ruhuna", space_after=0)
    add_body(doc, "Galle, Sri Lanka")
    add_body(doc, "Dear Chairperson,")
    add_body(
        doc,
        "This letter is a draft for Dr Gayani Punchihewa to accept, amend or decline. It is not "
        "her consent, and it does not say that she has read or approved the proposal.",
    )
    add_body(
        doc,
        "If she agrees to supervise, the letter she signs would need to say that she is willing "
        "to supervise J.G.D. Thamalka and D.V.W. Gunawardana, medical student researchers of the "
        "Faculty of Medicine, University of Ruhuna, in the study entitled “" + TITLE + "”, and "
        "that Yasas Pasindu Fernando will take part as a researcher and as the technical "
        "collaborator who developed the application. The students would be responsible for "
        "explaining the study, taking consent, and completing the session forms. The technical "
        "collaborator would be responsible for the version of the application used in the sitting "
        "and for dealing with faults. He would not take consent.",
    )
    add_body(
        doc,
        "Before the letter is signed, the team needs her decision on four points: who will be "
        "named as the applicant; whether the project is a requirement of the undergraduate "
        "curriculum; what sample size she will accept; and whether PRAGATHI Child Intervention "
        "Centre is an appropriate and available site. The Faculty staff page lists her as "
        "Dr Gayani D. Punchihewa, MBBS, MD Psych, Senior Lecturer and Psychiatrist. This draft "
        "uses only that public description. It does not add posts, training certificates, or "
        "clinical duties she has not confirmed.",
    )
    add_body(doc, "Signature of supervisor: ___________________________")
    add_body(doc, "Name: Dr Gayani Punchihewa")
    add_body(doc, "Date: ______________")
    add_body(
        doc,
        "The signature line is blank. Nothing on this page should be read as an endorsement already given.",
        italic=True,
    )
    save_doc(doc, output_path, "Supervisor letter draft")
    return output_path


def build_cv(output_path):
    doc = _doc(output_path)
    add_heading(doc, "Curriculum vitae material for this application")
    add_body(
        doc,
        "The principal investigator has not been confirmed, so a single curriculum vitae cannot "
        "yet be offered as the investigator’s own document. The notes below contain only facts "
        "the team supplied or facts taken from the Faculty’s public staff page. Blank lines are "
        "for the person concerned to complete. Nothing here is a claim of research-ethics training.",
        italic=True,
    )
    add_heading(doc, "A. J.G.D. Thamalka", 2)
    add_body(doc, "Role in this study: medical student researcher, Faculty of Medicine, University of Ruhuna.")
    add_body(doc, "The project note gives the same person as Thamalka D. J. G. The order of the name should be confirmed before the form is signed.")
    add_body(doc, "Student registration number: to be entered by the student.")
    add_body(doc, "Qualifications, posts and previous research: not supplied. Not invented in this draft.")
    add_body(doc, "Research ethics or methods certificates: none supplied.")
    add_heading(doc, "B. D.V.W. Gunawardana", 2)
    add_body(doc, "Role in this study: medical student researcher, Faculty of Medicine, University of Ruhuna.")
    add_body(doc, "Student registration number: to be entered by the student.")
    add_body(doc, "Qualifications, posts and previous research: not supplied. Not invented in this draft.")
    add_body(doc, "Research ethics or methods certificates: none supplied.")
    add_heading(doc, "C. Yasas Pasindu Fernando", 2)
    add_body(
        doc,
        "Role in this study: researcher, technical research collaborator and developer of the "
        "communication application. He is not described as the principal investigator.",
    )
    add_body(doc, "Qualifications supplied by him: Master of Science in Artificial Intelligence, Kingston University, ongoing; Bachelor of Engineering with Honours in Software Engineering, London Metropolitan University, completed.")
    add_body(
        doc,
        "Those degrees are his education. Kingston University and London Metropolitan University "
        "are not sponsors or sites of this study, and the study is not his dissertation.",
    )
    add_body(doc, "Other posts, publications and training certificates: not supplied. Not invented in this draft.")
    add_body(doc, "If the form requires initials, the legal name must be confirmed. Initials are not guessed here.")
    add_heading(doc, "D. Dr Gayani Punchihewa — public summary, not a curriculum vitae she has supplied", 2)
    add_body(
        doc,
        "Faculty of Medicine staff page, Department of Psychiatry, read on 6 November 2026: "
        "Dr Gayani D. Punchihewa, MBBS, MD Psych, Senior Lecturer and Psychiatrist. Special "
        "interests stated there: general adult psychiatry and maternal mental health.",
    )
    add_body(
        doc,
        "The departmental services page lists her as the consultant in charge of the maternal "
        "mental health clinic at Teaching Hospital Mahamodara and the adult psychiatry clinic at "
        "Teaching Hospital Karapitiya. The child and adolescent clinic on that page is listed "
        "under another consultant. This summary does not call her Head of Department, because the "
        "staff page names Dr S.A.C. Senadheera as Head, while another Faculty page has used a "
        "different description. She should confirm her designation before the letter is signed.",
    )
    add_body(doc, "Ethics training certificates: none have been placed in this file. Completion is not claimed.")
    save_doc(doc, output_path, "Curriculum vitae notes")
    return output_path


def build_training_status(output_path):
    doc = _doc(output_path)
    add_heading(doc, "Item 6. Training certificates — not enclosed")
    add_body(
        doc,
        "This page is not a certificate. No person is described as having completed Good Clinical "
        "Practice, research methods, or basic research ethics training, because no certificate has "
        "been given to the person preparing these drafts.",
    )
    add_plain_table(
        doc,
        ["Person", "Certificate in this file"],
        [
            ["J.G.D. Thamalka", "None supplied"],
            ["D.V.W. Gunawardana", "None supplied"],
            ["Yasas Pasindu Fernando", "None supplied"],
            ["Dr Gayani Punchihewa", "None supplied"],
        ],
    )
    add_body(
        doc,
        "For an observational study the committee asks for research methods and basic research "
        "ethics training of the principal investigator or, in undergraduate research, the supervisor. "
        "Copies of real certificates should be added when the holders provide them. This sheet must "
        "not be placed in the submission file in place of those copies.",
    )
    save_doc(doc, output_path, "Training evidence status")
    return output_path


def build_animal_statement(output_path):
    doc = _doc(output_path)
    add_heading(doc, "Item 7. Animals")
    add_body(
        doc,
        "The study does not use animals. The committee’s checklist asks for animal-handling "
        "training only where it is relevant. No animal-handling letter is prepared, and no training "
        "is claimed.",
    )
    save_doc(doc, output_path, "Animal research not applicable")
    return output_path


def build_fee_status(output_path):
    doc = _doc(output_path)
    add_heading(doc, "Item 8. Fee receipt — not enclosed")
    add_body(
        doc,
        "This page is not a receipt. No payment has been made, and no payment is simulated.",
    )
    add_body(
        doc,
        "The Faculty instructions distinguish a fee of LKR 3,000 when the principal investigator "
        "is a staff member of the University of Ruhuna or the extended faculty, LKR 5,000 when the "
        "principal investigator is not in that category, no fee when the principal investigator is "
        "an undergraduate and the project is required by the curriculum, and a separate fee for an "
        "industry-sponsored clinical trial. This study is not an industry-sponsored trial. The "
        "other categories cannot be chosen until the applicant is named and the students confirm "
        "whether the project is required by the curriculum.",
    )
    add_body(
        doc,
        "The instructions do not ask for the receipt inside the electronic file of items 1 to 7. "
        "The receipt, once a real one exists, is a hard-copy item.",
    )
    save_doc(doc, output_path, "Fee status")
    return output_path


def build_submission_checklist(output_path):
    doc = _doc(output_path)
    add_heading(doc, "Initial submission checklist")
    add_body(
        doc,
        "Taken from the Faculty instructions page as read on 6 November 2026. The older downloadable "
        "checklist file does not match that page. The website list is the one used here. This sheet "
        "is a working record for the team. It is not one of the two electronic files.",
        italic=True,
    )
    add_plain_table(
        doc,
        ["Hard copy", "What is ready in this draft", "Still required"],
        [
            ["1. Cover letter, signed", "Unsigned draft", "Applicant confirmed, then signatures"],
            ["2. Application form", "Official form filled as a draft", "Signatures and registration numbers"],
            ["3. Supervisor’s consent", "Unsigned draft for her to edit", "Her decision and signature"],
            ["4. Proposal, tools, consent, information, permission drafts", "English drafts", "Checked Sinhala and Tamil, or a justified limit"],
            ["5. Curriculum vitae of the principal investigator", "Notes only", "The confirmed investigator’s own curriculum vitae"],
            ["6. Training certificates", "None", "Real certificates. Not claimed"],
            ["7. Animal handling", "Not applicable", "No letter, because there are no animals"],
            ["8. Fee receipt", "None", "After the fee category is known. Hard copy only"],
        ],
    )
    add_body(doc, "Electronic files, when the team decides to send them:", bold=True, space_after=4)
    add_bullet(doc, "01_Complete_ERC_Application.pdf — items 1 to 7 that actually exist. Certificates and the fee receipt are not inserted.")
    add_bullet(doc, "02_Anonymous_Research_Proposal.pdf — item 4 only, without investigator names.")
    save_doc(doc, output_path, "Submission checklist")
    return output_path


def main():
    root = erc_root()
    pairs = [
        (build_cover_letter, os.path.join(root, "forms", "01_Cover_Letter_DRAFT.docx")),
        (build_supervisor_letter, os.path.join(root, "forms", "03_Supervisor_Letter_DRAFT.docx")),
        (build_cv, os.path.join(root, "forms", "10_CV_Principal_Investigator_DRAFT.docx")),
        (build_training_status, os.path.join(root, "forms", "13_Training_Certificates_PI_Supervisor_DRAFT.docx")),
        (build_animal_statement, os.path.join(root, "forms", "14_Animal_Handling_Statement_DRAFT.docx")),
        (build_fee_status, os.path.join(root, "forms", "15_Fee_Payment_Receipt_Placeholder_DRAFT.docx")),
        (build_submission_checklist, os.path.join(root, "qa", "12_ERC_Submission_Checklist.docx")),
    ]
    for builder, path in pairs:
        builder(path)
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
