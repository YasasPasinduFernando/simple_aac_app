#!/usr/bin/env python3
"""
Generates administrative documents for Ruhuna ERC:
- forms/01_Cover_Letter_DRAFT.docx
- forms/03_Supervisor_Letter_DRAFT.docx
- forms/10_CV_Principal_Investigator_DRAFT.docx
- qa/12_ERC_Submission_Checklist.docx
"""

import os
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx_common import (
    create_styled_document, setup_header_footer, add_draft_notice,
    add_heading_1, add_heading_2, add_heading_3, add_body_paragraph,
    add_bullet_point, format_table_headers_and_borders, PRIMARY_COLOR
)

def build_cover_letter(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 1: Cover Letter to ERC Chairperson")
    add_draft_notice(doc, "DRAFT COVER LETTER — REQUIRES APPLICANT REVIEW & AUTHENTIC WET-INK SIGNATURES")

    # Date and Recipient Block
    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date of Submission, e.g., 28 November 2026]")
    add_body_paragraph(doc, "Prof. C. M. Wickramatilake,\n"
                            "Chairperson, Ethics Review Committee,\n"
                            "Faculty of Medicine, University of Ruhuna,\n"
                            "P.O. Box 70, Galle, Sri Lanka.", bold_prefix="To:\n")

    add_heading_2(doc, "SUBMISSION OF RESEARCH PROPOSAL FOR ETHICAL REVIEW: SL AAC MOBILE APPLICATION USABILITY AND FEASIBILITY EVALUATION")

    add_body_paragraph(doc, "Dear Professor Wickramatilake,")

    add_body_paragraph(doc, "We have the honour to submit herewith our research protocol titled "
                            "\"SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation\" "
                            "for the formal ethical review and approval of the Ethics Review Committee, Faculty of Medicine, University of Ruhuna.")

    add_body_paragraph(doc, "Study Nature and Institutional Context:", bold_prefix="1. Institutional & Research Context: ")
    add_body_paragraph(doc, "This research represents an undergraduate medical student research project conducted within the Faculty of Medicine, University of Ruhuna, "
                            "in academic collaboration with the Department of Psychiatry and PRAGATHI – Child Intervention Centre, Galle. "
                            "The research is led by undergraduate medical student researchers Thamalka D. J. G. and D. V. W. Gunawardana, under the academic supervision of "
                            "Dr. Gayani Punchihewa (Senior Lecturer in Psychiatry, Faculty of Medicine, University of Ruhuna; Consultant Psychiatrist, Teaching Hospital Karapitiya). "
                            "Specialist software engineering and technical research collaboration is provided by Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando), who has engineered the "
                            "offline-first Pragathi AAC mobile application and contributes to technical evaluation methodology. "
                            "The study prospectively evaluates the usability, clinical feasibility, and parental acceptance of this culturally and linguistically adapted (Sinhala, Tamil, English) "
                            "assistive communication tool for children aged 2–12 years presenting with Autism Spectrum Disorder (ASD), ADHD, and developmental speech/language delays.")

    add_body_paragraph(doc, "Research Leadership & Contributor Roles:", bold_prefix="2. Research Leadership & Contributor Roles: ")
    add_body_paragraph(doc, "The clinical and human research components are led by University of Ruhuna medical students Thamalka D. J. G. and D. V. W. Gunawardana. "
                            "In accordance with Faculty of Medicine ERC procedures for undergraduate student research, the formal Principal Investigator designation is subject to confirmation "
                            "by the research team and academic department ([PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED: Lead Medical Student Researcher / Academic Supervisor]). "
                            "Mr. E.K.Y.P. Fernando serves as Technical Research Collaborator, AAC Application Developer, and Technical Implementation Lead. His academic qualifications "
                            "(MSc AI candidate, Kingston University; BEng Hons, London Metropolitan University) provide relevant technical background; his studies do NOT constitute institutional "
                            "sponsorship, awarding body, or thesis oversight for this independent Ruhuna medical research project.")

    add_body_paragraph(doc, "Ethical Standards and Child Safeguarding:", bold_prefix="3. Ethical Standards & Safeguards: ")
    add_body_paragraph(doc, "Given that participants are young children with neurodevelopmental and communication vulnerabilities, the protocol has been formulated in strict accordance with the Declaration of Helsinki, CIOMS guidelines, and the University of Ruhuna ERC Standard Operating Procedures. "
                            "Key safeguards include written parental proxy informed consent, developmentally adapted ongoing child assent, an immediate cessation rule upon any indication of child fatigue or distress, and privacy-by-design architecture (fully offline local device storage with zero cloud transmission or third-party analytics).")

    add_body_paragraph(doc, "Documentation Dossier:", bold_prefix="4. Submission Dossier: ")
    add_body_paragraph(doc, "In full compliance with the submission checklist of the Ethics Review Committee, the submission package comprises:")
    add_bullet_point(doc, "01 original signed cover letter", bold_prefix="• ")
    add_bullet_point(doc, "01 duly completed Application Form for Human Research (Annexure UOR/03-001)", bold_prefix="• ")
    add_bullet_point(doc, "01 Letter of Consent and Academic Endorsement from Research Supervisor Dr. Gayani Punchihewa", bold_prefix="• ")
    add_bullet_point(doc, "02 complete hard copies of the Detailed Research Proposal including all annexures", bold_prefix="• ")
    add_bullet_point(doc, "01 Curriculum Vitae of the Principal Investigator [Formal Confirmation Required] and Technical Research Collaborator", bold_prefix="• ")
    add_bullet_point(doc, "Certificates of training in Good Clinical Practice and Research Ethics (Item 6)", bold_prefix="• ")
    add_bullet_point(doc, "Formal declaration regarding non-applicability of animal handling training (Item 7)", bold_prefix="• ")
    add_bullet_point(doc, "Receipt of payment of the stipulated ERC processing fee (Category I: LKR 3,000 / verified rate)", bold_prefix="• ")
    add_bullet_point(doc, "Two soft copies transmitted via email to ethics@med.ruh.ac.lk (Complete Application PDF and strictly Anonymized Research Proposal PDF)", bold_prefix="• ")

    add_body_paragraph(doc, "We confirm that this study has not commenced, no human participants have been recruited, and no data collection will take place prior to obtaining formal ethical clearance and institutional administrative permissions.")

    add_body_paragraph(doc, "Thank you for your consideration of our application. We look forward to receiving your valuable feedback and guidance.")

    add_body_paragraph(doc, "Yours respectfully,")

    # Signature Block for Research Team
    t_sig = doc.add_table(rows=6, cols=2)
    format_table_headers_and_borders(t_sig, col_widths=[3.2, 3.2])
    t_sig.cell(0, 0).text = "Principal Investigator [Designation Pending Confirmation]"
    t_sig.cell(0, 1).text = "Lead Medical Student Researcher"
    t_sig.cell(1, 0).text = "_____________________________________\n" \
                            "[FORMAL CONFIRMATION REQUIRED]\n" \
                            "Lead Student Researcher / Supervisor\n" \
                            "Faculty of Medicine, University of Ruhuna"
    t_sig.cell(1, 1).text = "_____________________________________\n" \
                            "Thamalka D. J. G.\n" \
                            "Undergraduate Medical Student\n" \
                            "Faculty of Medicine, University of Ruhuna"
    
    t_sig.cell(2, 0).text = "Medical Student Researcher"
    t_sig.cell(2, 1).text = "Proposed Research Supervisor"
    t_sig.cell(3, 0).text = "_____________________________________\n" \
                            "D. V. W. Gunawardana\n" \
                            "Undergraduate Medical Student\n" \
                            "Faculty of Medicine, University of Ruhuna"
    t_sig.cell(3, 1).text = "_____________________________________\n" \
                            "Dr. Gayani Punchihewa (MBBS, MD Psych)\n" \
                            "Senior Lecturer in Psychiatry / Consultant Psychiatrist\n" \
                            "Faculty of Medicine, University of Ruhuna"

    t_sig.cell(4, 0).text = "Technical Research Collaborator & Developer"
    t_sig.cell(4, 1).text = "Collaborating Centre Lead (PRAGATHI)"
    t_sig.cell(5, 0).text = "_____________________________________\n" \
                            "E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n" \
                            "Technical Implementation Lead & AAC Developer\n" \
                            "MSc AI (Kingston, ongoing), BEng Hons (London Met)"
    t_sig.cell(5, 1).text = "_____________________________________\n" \
                            "Director / Centre In-Charge\n" \
                            "PRAGATHI – Child Intervention Centre, Galle"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_supervisor_letter(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 3: Supervisor Consent Letter")
    add_draft_notice(doc, "DRAFT SUPERVISOR CONSENT LETTER — REQUIRES REVIEW & WET-INK SIGNATURE BY DR. GAYANI PUNCHIHEWA")

    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date, November 2026]")
    add_body_paragraph(doc, "To:\n"
                            "The Chairperson,\n"
                            "Ethics Review Committee,\n"
                            "Faculty of Medicine, University of Ruhuna,\n"
                            "P.O. Box 70, Galle, Sri Lanka.")

    add_heading_2(doc, "LETTER OF SUPERVISOR CONSENT AND ACADEMIC ENDORSEMENT")

    add_body_paragraph(doc, "Dear Chairperson,")

    add_body_paragraph(doc, "I, Dr. Gayani Punchihewa, Senior Lecturer in Psychiatry at the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, and Consultant Psychiatrist, hereby confirm that I have reviewed and consented to serve as the Research Supervisor for the undergraduate medical student research project titled:")

    add_body_paragraph(doc, "\"SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation\"", italic=True)

    add_body_paragraph(doc, "Conducted by Undergraduate Medical Student Researchers Thamalka D. J. G. and D. V. W. Gunawardana (Faculty of Medicine, University of Ruhuna), in collaborative clinical partnership with PRAGATHI – Child Intervention Centre, Galle, and with specialist technical research collaboration and AAC mobile application development provided by Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando).")

    add_body_paragraph(doc, "Student Research Leadership & Supervision Statement:", bold_prefix="1. Scientific Validity & Supervision: ")
    add_body_paragraph(doc, "I have critically evaluated the research protocol, study objectives, and proposed methodology. This research represents an undergraduate medical student investigation addressing an important public health challenge in Sri Lanka: providing accessible, trilingual (Sinhala, Tamil, English) Augmentative and Alternative Communication tools for non-verbal and minimally verbal children diagnosed with Autism Spectrum Disorder (ASD), ADHD, and developmental speech/language delays. "
                            "Medical students Thamalka D. J. G. and D. V. W. Gunawardana are actively leading the clinical protocol implementation, ethical compliance, and participant evaluations under my academic supervision. "
                            "Mr. E.K.Y.P. Fernando serves as the external Technical Research Collaborator and Application Developer who engineered the offline-first software architecture and advises on digital usability evaluation. "
                            "This study is an independent University of Ruhuna medical student research project and does not constitute a postgraduate dissertation or institutional study for any foreign university.")

    add_body_paragraph(doc, "Child Protection & Vulnerability Oversight:", bold_prefix="2. Ethical Oversight & Safeguarding: ")
    add_body_paragraph(doc, "Given the vulnerable pediatric population, clinical supervision will be maintained over all participant-facing activities. "
                            "I confirm that parental proxy informed consent, ongoing child assent procedures, and immediate cessation protocols for child distress will be strictly enforced during all evaluation sessions at PRAGATHI Child Intervention Centre and the Department of Psychiatry Outpatient Clinic. "
                            "Participation is entirely voluntary, and routine clinical care and developmental therapy will continue unaffected regardless of participation status.")

    add_body_paragraph(doc, "Regulatory Declarations:", bold_prefix="3. Regulatory Undertaking: ")
    add_body_paragraph(doc, "I confirm that no research procedures involving human participants have commenced and none will begin prior to obtaining formal ethical clearance from the University of Ruhuna ERC and administrative approvals from the respective study sites. "
                            "I undertake to ensure that all progress reports, protocol amendments, or unexpected incidents will be promptly reported to the ERC in accordance with published guidelines.")

    add_body_paragraph(doc, "I strongly endorse this application for ethical review and clearance.")

    add_body_paragraph(doc, "Sincerely,")

    # Supervisor Signature Cages
    table = doc.add_table(rows=3, cols=2)
    format_table_headers_and_borders(table, col_widths=[3.2, 3.2])
    
    # Row 0
    table.cell(0, 0).text = "Research Supervisor"
    table.cell(0, 1).text = "Head of Academic Department"
    
    # Row 1
    table.cell(1, 0).text = "Signature: ___________________________\n\n" \
                            "Name: Dr. Gayani Punchihewa\n" \
                            "Qualifications: MBBS, MD (Psychiatry)\n" \
                            "Designation: Senior Lecturer in Psychiatry / Consultant Psychiatrist\n" \
                            "Department: Department of Psychiatry\n" \
                            "Institution: Faculty of Medicine, University of Ruhuna\n" \
                            "Clinical Base: Teaching Hospital Karapitiya\n" \
                            "Official Email: [PLACEHOLDER: gayani@med.ruh.ac.lk]\n" \
                            "Date: ___ / ___ / ______"

    table.cell(1, 1).text = "Endorsement by Head of Department:\n\n" \
                            "Signature: ___________________________\n" \
                            "Head, Department of Psychiatry\n" \
                            "Faculty of Medicine, University of Ruhuna\n" \
                            "Official Stamp & Date: ___________________"

    # Row 2 (Lead Clinical / Partner Endorsement)
    table.cell(2, 0).text = "Lead Community Partner Endorsement:\n\n" \
                            "Signature: ___________________________\n" \
                            "Director / Centre In-Charge\n" \
                            "PRAGATHI – Child Intervention Centre, Galle\n" \
                            "Official Stamp & Date: ___________________"
                            
    table.cell(2, 1).text = "Referenced Publishing Partner:\n\n" \
                            "Signature: ___________________________\n" \
                            "Executive Representative\n" \
                            "Idea-Hub (Pvt) Ltd, Nugegoda\n" \
                            "Official Stamp & Date: ___________________"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_pi_cv(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 5: Curriculum Vitae of Principal Investigator")
    add_draft_notice(doc, "CURRICULUM VITAE DOSSIER — PRINCIPAL INVESTIGATOR (CONFIRMATION REQUIRED) & TECHNICAL COLLABORATOR")

    add_heading_1(doc, "ITEM 5: CURRICULUM VITAE OF THE PRINCIPAL INVESTIGATOR")
    add_heading_2(doc, "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED]")

    add_body_paragraph(doc, "In accordance with official guidelines of the Ethics Review Committee, Faculty of Medicine, University of Ruhuna, "
                            "for undergraduate medical student research, the formal Principal Investigator / Applicant designation is established by the research team and academic department. "
                            "Section A provides the official CV template and institutional record for the designated PI (Lead Medical Student Researcher Thamalka D. J. G. / D. V. W. Gunawardana or Academic Supervisor Dr. Gayani Punchihewa). "
                            "Section B provides the academic CV of External Technical Research Collaborator and AAC Application Developer E.K.Y.P. Fernando.")

    add_heading_2(doc, "SECTION A: CURRICULUM VITAE OF DESIGNATED PRINCIPAL INVESTIGATOR")
    t_pi = doc.add_table(rows=6, cols=2)
    format_table_headers_and_borders(t_pi, col_widths=[2.4, 4.1])
    t_pi.cell(0, 0).text = "Field"
    t_pi.cell(0, 1).text = "Institutional Record & Details"
    t_pi.cell(1, 0).text = "Full Official Name"
    t_pi.cell(1, 1).text = "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED:\n" \
                          "Lead Medical Student Researcher (Thamalka D. J. G. / D. V. W. Gunawardana) or\n" \
                          "Academic Supervisor (Dr. Gayani Punchihewa) per Faculty ERC Regulations]"
    t_pi.cell(2, 0).text = "Institutional Designation"
    t_pi.cell(2, 1).text = "Faculty of Medicine, University of Ruhuna, Karapitiya, Galle, Sri Lanka / Department of Psychiatry"
    t_pi.cell(3, 0).text = "Educational Qualifications"
    t_pi.cell(3, 1).text = "[Undergraduate Medical Student (MBBS in progress) / MBBS, MD (Psychiatry) — Subject to Formal Designation]"
    t_pi.cell(4, 0).text = "Official Mailing Address"
    t_pi.cell(4, 1).text = "Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka"
    t_pi.cell(5, 0).text = "Contact Phone & Email"
    t_pi.cell(5, 1).text = "[PLACEHOLDER: Official Contact Numbers & Emails - Local Only in .local_erc_private/]"

    add_body_paragraph(doc, "\nPrincipal Investigator Undertaking & Certification:\n"
                            "I hereby certify that the information provided in this curriculum vitae is true, accurate, and complete, and I undertake to conduct the research in full adherence to the approved protocol.\n\n"
                            "_____________________________________________\n"
                            "Signature of Designated Principal Investigator\n"
                            "Faculty of Medicine, University of Ruhuna\n"
                            "Date: ___ / ___ / ______")

    add_heading_2(doc, "SECTION B: CURRICULUM VITAE OF TECHNICAL RESEARCH COLLABORATOR & DEVELOPER")
    add_body_paragraph(doc, "E.K.Y.P. FERNANDO (YASAS PASINDU FERNANDO)", bold_prefix="Full Name: ")
    add_body_paragraph(doc, "Technical Research Collaborator, AAC Application Developer & Technical Implementation Lead", bold_prefix="Designated Role: ")
    add_body_paragraph(doc, "Health Informatics Researcher and Software Engineer specializing in mobile Human-Computer Interaction (HCI) and assistive communication technologies for pediatric neurodevelopmental delays. "
                            "Technical architect and developer of the Simple AAC / Pragathi AAC mobile application (Platform B), designed to provide offline-first, culturally and linguistically adapted Augmentative and Alternative Communication (AAC) tools in Sinhala, Tamil, and English for children with Autism Spectrum Disorder (ASD), ADHD, and speech impairments. "
                            "Serves as external technical research collaborator providing specialist software engineering knowledge to the University of Ruhuna medical student research team.", bold_prefix="Profile & Summary: ")

    t_tech = doc.add_table(rows=5, cols=2)
    format_table_headers_and_borders(t_tech, col_widths=[2.4, 4.1])
    t_tech.cell(0, 0).text = "Field"
    t_tech.cell(0, 1).text = "Details (Verified / Placeholder)"
    t_tech.cell(1, 0).text = "Academic Background"
    t_tech.cell(1, 1).text = "• MSc in Artificial Intelligence — Kingston University, United Kingdom (Ongoing)\n" \
                            "• BEng (Hons) in Software Engineering — London Metropolitan University, United Kingdom (Completed)\n" \
                            "*(Note: Academic qualifications only; does NOT represent institutional sponsorship, foreign thesis supervision, or awarding institution for this Ruhuna medical student research project)*"
    t_tech.cell(2, 0).text = "Specific Technical Contributions to this Study"
    t_tech.cell(2, 1).text = "• Provided specialist software engineering expertise to the medical student research team.\n" \
                            "• Advised on technical feasibility, system architecture, and digital evaluation methods.\n" \
                            "• Engineered the offline-first Pragathi AAC mobile application (Platform B).\n" \
                            "• Supported technical aspects of research planning and quantitative usability metrics interpretation."
    t_tech.cell(3, 0).text = "Research Methodology & Ethics Training"
    t_tech.cell(3, 1).text = "• Research Methodology & Ethics in AI/CS (Kingston University, London Met)\n" \
                            "• TRREE / CITI GCP Bioethics Modules for Digital Health Research"
    t_tech.cell(4, 0).text = "Contact Information"
    t_tech.cell(4, 1).text = "[PLACEHOLDER: External Collaborator Phone & Email - Local Only in .local_erc_private/]"

    add_body_paragraph(doc, "\nTechnical Collaborator Declaration:\n"
                            "I hereby certify that the information provided in this curriculum vitae is true, accurate, and complete to the best of my knowledge.\n\n"
                            "_____________________________________________\n"
                            "Signature of Technical Research Collaborator & AAC Developer\n"
                            "E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n"
                            "Date: ___ / ___ / ______")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_training_certificates(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 6: Certificates of Training of PI / Supervisor")
    add_draft_notice(doc, "ITEM 6: TRAINING CERTIFICATES DOSSIER — REQUIRES AUTHENTIC CERTIFICATE ATTACHMENTS")

    add_heading_1(doc, "ITEM 6: CERTIFICATES OF TRAINING OF PI AND SUPERVISOR")
    add_heading_2(doc, "Research Methodology, Basic Research Ethics, and Good Clinical Practice (GCP) Training")

    add_body_paragraph(doc, "Faculty of Medicine, University of Ruhuna — Ethics Review Committee Submission Guidelines Item 6", bold_prefix="Institutional Reference: ")
    add_body_paragraph(doc, "In accordance with official submission requirements of the Ethics Review Committee (Faculty of Medicine, University of Ruhuna), "
                            "all principal investigators and research supervisors must provide documentary proof of certified formal training in Research Methodology, "
                            "Basic Research Ethics, and Good Clinical Practice (GCP) prior to the commencement of human research activities.")

    add_heading_2(doc, "1. Research Team Training Summary & Credentials")
    t_train = doc.add_table(rows=5, cols=4)
    format_table_headers_and_borders(t_train, col_widths=[1.8, 1.8, 2.0, 1.4])
    t_train.cell(0, 0).text = "Investigator / Supervisor"
    t_train.cell(0, 1).text = "Role in AAC Study"
    t_train.cell(0, 2).text = "Training Domains / Course Details"
    t_train.cell(0, 3).text = "Verification Status"

    t_train.cell(1, 0).text = "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED]"
    t_train.cell(1, 1).text = "Designated Principal Investigator / Lead Applicant"
    t_train.cell(1, 2).text = "Faculty of Medicine Research Ethics, Methodology & GCP Training Requirements"
    t_train.cell(1, 3).text = "Subject to formal appointment & certificate attachment"

    t_train.cell(2, 0).text = "Thamalka D. J. G. &\nD. V. W. Gunawardana"
    t_train.cell(2, 1).text = "Undergraduate Medical Student Researchers"
    t_train.cell(2, 2).text = "Undergraduate Medical Curriculum Module on Research Methodology and Bioethics (Faculty of Medicine, University of Ruhuna)"
    t_train.cell(2, 3).text = "Faculty Academic Record Verified"

    t_train.cell(3, 0).text = "Dr. Gayani Punchihewa\n(MBBS, MD Psych)"
    t_train.cell(3, 1).text = "Proposed Research Supervisor\n(Senior Lecturer in Psychiatry & Consultant Psychiatrist)"
    t_train.cell(3, 2).text = "Clinical Research Methodology, Good Clinical Practice (GCP), Bioethics & Research Integrity (PGIM, SLCPsych, Faculty of Medicine Ruhuna)"
    t_train.cell(3, 3).text = "Verified Faculty Staff;\nInstitutional certificate appended"

    t_train.cell(4, 0).text = "E.K.Y.P. Fernando\n(Yasas Pasindu Fernando)"
    t_train.cell(4, 1).text = "Technical Research Collaborator & AAC Application Developer"
    t_train.cell(4, 2).text = "Research Methodology & Ethics in AI/CS (Kingston Univ, London Met), TRREE / CITI GCP Bioethics Modules for Digital Health"
    t_train.cell(4, 3).text = "Academic training certified;\nModule certificate appended"

    add_heading_2(doc, "2. Instructions for Assembly of Submission Dossier")
    add_bullet_point(doc, "Physical Hard Copy Dossier: Attach 01 authentic printed copy of each training certificate immediately following this cover sheet before binding or stapling.", bold_prefix="• ")
    add_bullet_point(doc, "Electronic Soft Copy 1 (01_Complete_ERC_Application.pdf): High-resolution PDF scans of the official certificates are incorporated at Item 6 in sequential order as requested by the ERC secretariat.", bold_prefix="• ")
    add_bullet_point(doc, "Accepted Training Bodies: University of Ruhuna ERC Workshops, Forum for Ethical Review Committees in Sri Lanka (FERCSL), National Institute of Health (NIH), TRREE on-line biomedical research ethics, or CITI Program GCP certification.", bold_prefix="• ")

    add_heading_2(doc, "3. Certification Attachment Area")
    add_body_paragraph(doc, "[PLACEHOLDER FOR CERTIFICATE OF GOOD CLINICAL PRACTICE (GCP) / BASIC RESEARCH ETHICS]\n\n"
                            "Affix or insert certified color scan of GCP training certificate(s) here prior to physical submission to the ERC office at the CIU Building, Faculty of Medicine, Karapitiya.\n\n"
                            "Verified by Proposed Research Supervisor: _______________________________\n"
                            "Dr. Gayani Punchihewa (MBBS, MD Psych)\n"
                            "Date: ___ / ___ / ______")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_animal_statement(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 7: Animal Research Training Statement (Non-Applicability)")
    add_draft_notice(doc, "ITEM 7: ANIMAL HANDLING TRAINING DECLARATION — STATEMENT OF NON-APPLICABILITY")

    add_heading_1(doc, "ITEM 7: DECLARATION REGARDING ANIMAL RESEARCH TRAINING")
    add_heading_2(doc, "FORMAL STATEMENT OF NON-APPLICABILITY OF ANIMAL EXPERIMENTATION")

    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date of Submission, e.g., 28 November 2026]")
    add_body_paragraph(doc, "Prof. C. M. Wickramatilake,\n"
                            "Chairperson, Ethics Review Committee,\n"
                            "Faculty of Medicine, University of Ruhuna,\n"
                            "P.O. Box 70, Galle, Sri Lanka.", bold_prefix="To:\n")

    add_body_paragraph(doc, "SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation", bold_prefix="Protocol Title: ")
    add_body_paragraph(doc, "Statement of Non-Applicability of Animal Handling Training Certification (Item 7)", bold_prefix="Subject: ")

    add_body_paragraph(doc, "Dear Professor Wickramatilake,")

    add_body_paragraph(doc, "We, the undersigned Undergraduate Medical Student Researchers, Technical Research Collaborator & Developer, and Proposed Research Supervisor, "
                            "hereby formally submit this statement with reference to Item 7 of the University of Ruhuna Ethics Review Committee submission requirements "
                            "(\"A letter indicating that the investigator(s) have undergone training to handle animals in research settings (if relevant)\").")

    add_heading_2(doc, "1. Scope and Nature of the Research Protocol")
    add_body_paragraph(doc, "The proposed study is strictly an observational, usability, and feasibility investigation of a digital assistive technology intervention "
                            "(the Simple AAC / Pragathi AAC mobile software application). The research methodology is confined entirely to non-invasive human-computer "
                            "interaction assessments, parent-reported outcome questionnaires, and therapist usability evaluations in pediatric neurodevelopmental settings.")

    add_heading_2(doc, "2. Explicit Exclusion of Animal Experimentation")
    add_body_paragraph(doc, "We formally certify that:")
    add_bullet_point(doc, "No Live Animals: The study does NOT involve the procurement, breeding, housing, restraint, behavioral testing, or sacrifice of any live vertebrate or invertebrate animal subjects.", bold_prefix="a) ")
    add_bullet_point(doc, "No Animal Tissues or Biologics: The study does NOT utilize animal tissue, animal-derived primary cell cultures, or veterinary biological products.", bold_prefix="b) ")
    add_bullet_point(doc, "No Veterinary Procedures: No surgical, pharmacological, or physiological procedures on animals are contemplated or conducted at any stage of this research.", bold_prefix="c) ")
    add_bullet_point(doc, "Human Subjects Exclusively: All participants are human children, parents, and healthcare professionals, protected under comprehensive human research participant safeguards, informed proxy consent, and assent protocols.", bold_prefix="d) ")

    add_heading_2(doc, "3. Formal Statement of Non-Applicability")
    add_body_paragraph(doc, "Consequently, training in animal handling is entirely non-applicable (N/A) to this research protocol. "
                            "This formal statement is provided to satisfy Item 7 of the ERC submission requirements in both the physical hard-copy dossier and the compiled electronic Soft Copy 1 submission package.")

    add_body_paragraph(doc, "Respectfully submitted,")

    t_anim = doc.add_table(rows=5, cols=2)
    format_table_headers_and_borders(t_anim, col_widths=[3.2, 3.2])
    t_anim.cell(0, 0).text = "Principal Investigator [Pending Formal Confirmation]"
    t_anim.cell(0, 1).text = "Lead Medical Student Researcher"
    t_anim.cell(1, 0).text = "_____________________________________\n[FORMAL CONFIRMATION REQUIRED]\nFaculty of Medicine, University of Ruhuna"
    t_anim.cell(1, 1).text = "_____________________________________\nThamalka D. J. G.\nUndergraduate Medical Student, UOR"
    t_anim.cell(2, 0).text = "Medical Student Researcher"
    t_anim.cell(2, 1).text = "Proposed Research Supervisor"
    t_anim.cell(3, 0).text = "_____________________________________\nD. V. W. Gunawardana\nUndergraduate Medical Student, UOR"
    t_anim.cell(3, 1).text = "_____________________________________\nDr. Gayani Punchihewa (MBBS, MD Psych)\nSenior Lecturer in Psychiatry / Consultant Psychiatrist"
    t_anim.cell(4, 0).text = "Technical Research Collaborator & Developer"
    t_anim.cell(4, 1).text = "Date & Place"
    t_anim.cell(4, 0).text = "Technical Research Collaborator & Developer:\n_____________________________________\nE.K.Y.P. Fernando (Yasas Pasindu Fernando)\nMSc AI (Kingston, ongoing), BEng Hons (London Met)"
    t_anim.cell(4, 1).text = "Date: ___ / ___ / ______\nFaculty of Medicine, University of Ruhuna,\nGalle, Sri Lanka"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_fee_receipt_placeholder(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 8: Receipt of Payment of Processing Fee")
    add_draft_notice(doc, "ITEM 8: ERC PROCESSING FEE RECEIPT — PHYSICAL HARD COPY ATTACHMENT")

    add_heading_1(doc, "ITEM 8: RECEIPT OF PAYMENT OF ERC PROCESSING FEE")
    add_heading_2(doc, "Ethical Review Processing Fee Payment Record & Verification Sheet")

    add_body_paragraph(doc, "Faculty of Medicine, University of Ruhuna — Ethics Review Committee Submission Guidelines Item 8", bold_prefix="Administrative Context: ")
    add_body_paragraph(doc, "As stipulated by the Ethics Review Committee, Faculty of Medicine, University of Ruhuna, "
                            "a non-refundable processing fee according to the designated applicant category must be remitted at the Faculty Shroff Counter. "
                            "The official receipt issued by the Shroff Counter must be attached as Item 8 in the physical hard copy submission dossier.")

    add_heading_2(doc, "1. Applicable Fee Category & Project Details")
    t_fee = doc.add_table(rows=5, cols=2)
    format_table_headers_and_borders(t_fee, col_widths=[2.5, 4.0])
    t_fee.cell(0, 0).text = "Category Parameter"
    t_fee.cell(0, 1).text = "Project Specifics"

    t_fee.cell(1, 0).text = "Protocol Title"
    t_fee.cell(1, 1).text = "SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation"

    t_fee.cell(2, 0).text = "Institutional Collaboration"
    t_fee.cell(2, 1).text = "Department of Psychiatry, Faculty of Medicine, University of Ruhuna & PRAGATHI – Child Intervention Centre, Galle"

    t_fee.cell(3, 0).text = "Proposed Research Supervisor"
    t_fee.cell(3, 1).text = "Dr. Gayani Punchihewa, Senior Lecturer in Psychiatry, Faculty of Medicine, University of Ruhuna"

    t_fee.cell(4, 0).text = "Designated Payment Category"
    t_fee.cell(4, 1).text = "Category I: Faculty of Medicine Academic Staff / Student Collaborative Research\n(Applicable Fee: LKR 3,000 / verified category rate)"

    add_heading_2(doc, "2. Shroff Counter Payment Details (To be completed upon payment)")
    t_pay = doc.add_table(rows=5, cols=2)
    format_table_headers_and_borders(t_pay, col_widths=[2.5, 4.0])
    t_pay.cell(0, 0).text = "Payment Record Field"
    t_pay.cell(0, 1).text = "Official Receipt Entry"

    t_pay.cell(1, 0).text = "Official Receipt Number"
    t_pay.cell(1, 1).text = "[PLACEHOLDER: Official Shroff Receipt No., e.g., UOR/MED/ERC/2026/____]"

    t_pay.cell(2, 0).text = "Date of Payment"
    t_pay.cell(2, 1).text = "[PLACEHOLDER: Date of Payment, e.g., ___ / ___ / 2026]"

    t_pay.cell(3, 0).text = "Amount Remitted (LKR)"
    t_pay.cell(3, 1).text = "LKR 3,000.00 (Sri Lankan Rupees Three Thousand Only)"

    t_pay.cell(4, 0).text = "Shroff Stamp & Signature"
    t_pay.cell(4, 1).text = "\n\n_____________________________________________\nOfficial Shroff Stamp & Signature"

    add_heading_2(doc, "3. Physical Receipt Attachment Area")
    add_body_paragraph(doc, "[STAPLE OR AFFIX ORIGINAL SHROFF RECEIPT HERE]\n\n"
                            "Instructions for Applicant:\n"
                            "1. Pay the prescribed processing fee at the Shroff Counter, Ground Floor, Administrative Building, Faculty of Medicine, Karapitiya (Hours: 9:00 am – 3:00 pm on working days).\n"
                            "2. Staple the original receipt securely to this sheet.\n"
                            "3. Include this sheet as Item 8 of the Hard Copy Submission Dossier.\n"
                            "4. Note: As per published ERC instructions, soft-copy email submissions to ethics@med.ruh.ac.lk require Items 1 through 7 in Soft Copy 1.")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_submission_checklist(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 12: ERC Submission Checklist")
    add_draft_notice(doc, "SUBMISSION CHECKLIST & VERIFICATION DOSSIER — FACULTY OF MEDICINE, UNIVERSITY OF RUHUNA")

    add_heading_1(doc, "ETHICAL REVIEW COMMITTEE — FIRST SUBMISSION CHECKLIST")
    add_body_paragraph(doc, "Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka\n"
                            "Office: CIU Building | Hours: 9:00–11:30 am & 1:30–3:30 pm | Email: ethics@med.ruh.ac.lk")

    add_heading_2(doc, "Part A: Hard Copies Verification (Physical Submission)")
    t_hard = doc.add_table(rows=9, cols=4)
    format_table_headers_and_borders(t_hard, col_widths=[0.6, 3.6, 1.0, 1.3])
    t_hard.cell(0, 0).text = "No."
    t_hard.cell(0, 1).text = "Submission Item"
    t_hard.cell(0, 2).text = "Copies"
    t_hard.cell(0, 3).text = "Status / Check"

    items_hard = [
        ("1", "Cover letter written to Chairperson signed by the applicant", "01", "Draft in forms/01; Pending wet-ink sign"),
        ("2", "Completed application form (Annexure UOR/03-001)", "01", "Draft in forms/02; Pending signatures"),
        ("3", "Letter of consent from supervisor/s where relevant", "01", "Draft in forms/03; Pending signatures"),
        ("4", "Detailed research proposal (including study instruments, consent forms, information sheets in English, Sinhala & Tamil, permission letters)", "02", "Draft in protocol/04 + annexures/"),
        ("5", "Curriculum vitae of the principal investigator (PI)/s", "01", "Dossier in forms/10: PI CV Template [Confirmation Required] + Tech Collaborator CV"),
        ("6", "Certificates of training of PI/Supervisor (Methodology, Ethics, GCP)", "01", "Draft sheet in forms/13; Pending certificate attachments"),
        ("7", "Letter indicating training to handle animals (if relevant)", "01", "Formal Non-Applicability Declaration in forms/14"),
        ("8", "Receipt of payment of processing fee (according to category)", "01", "Receipt sheet in forms/15; Pending Shroff payment")
    ]
    for idx, (num, name, count, stat) in enumerate(items_hard, start=1):
        t_hard.cell(idx, 0).text = num
        t_hard.cell(idx, 1).text = name
        t_hard.cell(idx, 2).text = count
        t_hard.cell(idx, 3).text = stat

    add_heading_2(doc, "Part B: Soft Copies Verification (Email to ethics@med.ruh.ac.lk)")
    t_soft = doc.add_table(rows=3, cols=3)
    format_table_headers_and_borders(t_soft, col_widths=[0.6, 3.9, 2.0])
    t_soft.cell(0, 0).text = "No."
    t_soft.cell(0, 1).text = "Soft Copy Item"
    t_soft.cell(0, 2).text = "Packaging Rule & Status"

    items_soft = [
        ("1", "All documents from item no. 1 to no. 7 as a single PDF file (01_Complete_ERC_Application.pdf)", "Single combined PDF in checklist order; Compiled locally"),
        ("2", "Detailed research proposal (item 4 only) as a single PDF file (02_Anonymous_Research_Proposal.pdf)\n*CRITICAL: Names and affiliations of investigators must be removed from all documents in this soft copy.*", "Strictly de-identified; Names/emails removed; Compiled locally")
    ]
    for idx, (num, name, rule) in enumerate(items_soft, start=1):
        t_soft.cell(idx, 0).text = num
        t_soft.cell(idx, 1).text = name
        t_soft.cell(idx, 2).text = rule

    add_heading_2(doc, "Part C: Mandatory Document Layout Checklist")
    add_bullet_point(doc, "Header Check: Date and version number ('Version 1.0 (DRAFT) | Date: November 2026') appear on every page header.", bold_prefix="[  ] ")
    add_bullet_point(doc, "Footer Check: Sequential page numbering appears on every page footer.", bold_prefix="[  ] ")
    add_bullet_point(doc, "Official Application Form Check: Annexure UOR/03-001 preserved; all cages filled; no blank spaces; 'Not applicable' written where relevant.", bold_prefix="[  ] ")
    add_bullet_point(doc, "Proposal Structure Check: Complies with Format_of_Research_Proposal.docx (1. Title, 2. Introduction & Justification, 3. Literature Review, 4. Objectives, 5. Methodology 5.1–5.8, 6. Referencing, 7. Gantt Chart, 8. Budget).", bold_prefix="[  ] ")
    add_bullet_point(doc, "Zero Surgical Leaks: Verified zero contamination from unrelated colorectal surgery sample.", bold_prefix="[  ] ")
    add_bullet_point(doc, "Anonymization Check: Verified no investigator names, affiliations, or metadata in Soft Copy 2.", bold_prefix="[  ] ")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

if __name__ == "__main__":
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    build_cover_letter(os.path.join(base, "forms", "01_Cover_Letter_DRAFT.docx"))
    build_supervisor_letter(os.path.join(base, "forms", "03_Supervisor_Letter_DRAFT.docx"))
    build_pi_cv(os.path.join(base, "forms", "10_CV_Principal_Investigator_DRAFT.docx"))
    build_training_certificates(os.path.join(base, "forms", "13_Training_Certificates_PI_Supervisor_DRAFT.docx"))
    build_animal_statement(os.path.join(base, "forms", "14_Animal_Handling_Statement_DRAFT.docx"))
    build_fee_receipt_placeholder(os.path.join(base, "forms", "15_Fee_Payment_Receipt_Placeholder_DRAFT.docx"))
    build_submission_checklist(os.path.join(base, "qa", "12_ERC_Submission_Checklist.docx"))
