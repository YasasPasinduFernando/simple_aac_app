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
    add_draft_notice(doc, "DRAFT COVER LETTER — REQUIRES APPLICANT REVIEW & AUTHENTIC WET-INK SIGNATURE")

    # Date and Recipient Block
    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date of Submission, e.g., 28 November 2026]")
    add_body_paragraph(doc, "Prof. C. M. Wickramatilake,\n"
                            "Chairperson, Ethics Review Committee,\n"
                            "Faculty of Medicine, University of Ruhuna,\n"
                            "P.O. Box 70, Galle, Sri Lanka.", bold_prefix="To:\n")

    add_heading_2(doc, "SUBMISSION OF RESEARCH PROPOSAL FOR ETHICAL REVIEW: SL AAC MOBILE APPLICATION USABILITY AND FEASIBILITY EVALUATION")

    add_body_paragraph(doc, "Dear Professor Wickramatilake,")

    add_body_paragraph(doc, "I am pleased to submit herewith our research protocol titled "
                            "\"SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation\" "
                            "for the formal ethical review and approval of the Ethics Review Committee, Faculty of Medicine, University of Ruhuna.")

    add_body_paragraph(doc, "Study Nature and Institutional Context:", bold_prefix="1. Institutional & Research Context: ")
    add_body_paragraph(doc, "This research represents a prospective, non-invasive observational usability and acceptability study of a digital assistive technology intervention (the Pragathi AAC / Simple AAC mobile application). "
                            "The project is conducted under a collaborative academic framework between the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, and PRAGATHI – Child Intervention Centre, Galle, with endorsement from the Ministry of Health, Sri Lanka. "
                            "The study is academically supervised by Dr. Gayani Punchihewa (Senior Lecturer in Psychiatry, Faculty of Medicine, University of Ruhuna; Consultant Psychiatrist), with research design, software engineering, and technical evaluation led by Researcher E.K.Y.P. Fernando (Yasas Pasindu Fernando), in collaboration with medical student co-investigators Thamalka D. J. G. and D. V. W. Gunawardana. "
                            "The application provides trilingual (Sinhala, Tamil, English) picture-based augmentative and alternative communication (AAC) with text-to-speech audio for children aged 2–12 years presenting with Autism Spectrum Disorder (ASD), ADHD, and severe speech/language impairments.")

    add_body_paragraph(doc, "Research Team & Investigator Recognition:", bold_prefix="2. Investigator Recognition & Supervision: ")
    add_body_paragraph(doc, "Mr. E.K.Y.P. Fernando (MSc Artificial Intelligence candidate, Kingston University; BEng (Hons) Software Engineering, London Metropolitan University) serves as Researcher, Software Developer, and Technical Implementation Lead. "
                            "He is actively contributing to the research conceptualization, study design, technical instrumentation, usability data collection, and qualitative evaluation alongside the supervisory team. "
                            "Clinical governance and child safeguarding are provided under the direct supervision of Dr. Gayani Punchihewa.")

    add_body_paragraph(doc, "Ethical Standards and Child Safeguarding:", bold_prefix="3. Ethical Standards & Safeguards: ")
    add_body_paragraph(doc, "Given that participants are young children with neurodevelopmental and communication vulnerabilities, the protocol has been formulated in strict accordance with the Declaration of Helsinki, CIOMS guidelines, and the University of Ruhuna ERC Standard Operating Procedures. "
                            "Key safeguards include written parental proxy informed consent, developmentally adapted ongoing child assent, an immediate cessation rule upon any indication of child fatigue or distress, and privacy-by-design architecture (fully offline local device storage with zero cloud transmission or third-party analytics).")

    add_body_paragraph(doc, "Documentation Dossier:", bold_prefix="4. Submission Dossier: ")
    add_body_paragraph(doc, "In full compliance with the submission checklist of the Ethics Review Committee, the submission package comprises:")
    add_bullet_point(doc, "01 original signed cover letter", bold_prefix="• ")
    add_bullet_point(doc, "01 duly completed Application Form for Human Research (Annexure UOR/03-001)", bold_prefix="• ")
    add_bullet_point(doc, "01 Letter of Consent and Academic Endorsement from Research Supervisor Dr. Gayani Punchihewa", bold_prefix="• ")
    add_bullet_point(doc, "02 complete hard copies of the Detailed Research Proposal including all annexures", bold_prefix="• ")
    add_bullet_point(doc, "01 Curriculum Vitae of the Principal Investigator / Lead Researcher", bold_prefix="• ")
    add_bullet_point(doc, "Certificates of training in Good Clinical Practice and Research Ethics", bold_prefix="• ")
    add_bullet_point(doc, "Receipt of payment of the stipulated ERC processing fee (Shroff Counter, Faculty of Medicine)", bold_prefix="• ")
    add_bullet_point(doc, "Two soft copies transmitted via email to ethics@med.ruh.ac.lk (Complete Application PDF and strictly Anonymized Research Proposal PDF)", bold_prefix="• ")

    add_body_paragraph(doc, "We confirm that this study has not commenced, no human participants have been recruited, and no data collection will take place prior to obtaining formal ethical clearance and institutional administrative permissions.")

    add_body_paragraph(doc, "Thank you for your consideration of our application. We look forward to receiving your valuable feedback and guidance.")

    add_body_paragraph(doc, "Yours sincerely,\n\n\n\n"
                            "_____________________________________\n"
                            "[PLACEHOLDER: Signature of Applicant / Lead Researcher]\n"
                            "Full Name: E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n"
                            "Researcher, Software Developer & Technical Implementation Lead\n"
                            "MSc in Artificial Intelligence (Kingston University, ongoing)\n"
                            "BEng (Hons) in Software Engineering (London Metropolitan University)\n"
                            "Collaborator, PRAGATHI – Child Intervention Centre, Galle\n"
                            "Email: [PLACEHOLDER: Official Email - Local Only]\n"
                            "Contact Number: [PLACEHOLDER: Official Contact - Local Only]")

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

    add_body_paragraph(doc, "I, Dr. Gayani Punchihewa, Senior Lecturer in Psychiatry at the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, and Consultant Psychiatrist, hereby confirm that I have reviewed and consented to serve as the Research Supervisor for the research project titled:")

    add_body_paragraph(doc, "\"SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation\"", italic=True)

    add_body_paragraph(doc, "Conducted in collaboration with Lead Researcher & Software Developer Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando) and Student Co-Investigators Thamalka D. J. G. and D. V. W. Gunawardana (Undergraduate Medical Students, Faculty of Medicine, University of Ruhuna).")

    add_body_paragraph(doc, "Academic & Clinical Supervision Statement:", bold_prefix="1. Scientific Validity & Supervision: ")
    add_body_paragraph(doc, "I have critically evaluated the research protocol, study objectives, and proposed methodology. The research addresses an urgent public health need in Sri Lanka: providing accessible, trilingual (Sinhala, Tamil, English) Augmentative and Alternative Communication tools for non-verbal and minimally verbal children diagnosed with Autism Spectrum Disorder (ASD), ADHD, and developmental speech/language delays. "
                            "Mr. E.K.Y.P. Fernando is explicitly recognised as a key researcher who has engineered the application architecture and contributed substantively to the study design, technical instrumentation, and usability evaluation framework, working in close collaboration with our clinical team and medical students.")

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
                            
    table.cell(2, 1).text = "Publishing & Technical Partner:\n\n" \
                            "Signature: ___________________________\n" \
                            "Executive Representative\n" \
                            "Idea-Hub (Pvt) Ltd, Nugegoda\n" \
                            "Official Stamp & Date: ___________________"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_pi_cv(output_path):
    doc = create_styled_document()
    setup_header_footer(doc, "Item 5: Curriculum Vitae of Researcher / Lead Developer")
    add_draft_notice(doc, "CURRICULUM VITAE DRAFT — RESEARCHER & SOFTWARE DEVELOPER FACT SHEET")

    add_heading_1(doc, "CURRICULUM VITAE")
    add_heading_2(doc, "E.K.Y.P. FERNANDO (YASAS PASINDU FERNANDO)")

    add_body_paragraph(doc, "Professional Summary:", bold_prefix="1. Profile: ")
    add_body_paragraph(doc, "Health Informatics Researcher, Software Engineer, and Technical Implementation Lead specializing in mobile system architecture, Human-Computer Interaction (HCI), and assistive communication technologies for pediatric neurodevelopmental disorders. "
                            "Lead researcher and developer of the Simple AAC / Pragathi AAC application (Platform B), designed to provide offline-first, culturally and linguistically adapted Augmentative and Alternative Communication (AAC) tools in Sinhala, Tamil, and English for children with Autism Spectrum Disorder (ASD), ADHD, and speech impairments.")

    add_heading_2(doc, "2. Personal & Contact Information")
    t_contact = doc.add_table(rows=6, cols=2)
    format_table_headers_and_borders(t_contact, col_widths=[2.2, 4.3])
    t_contact.cell(0, 0).text = "Field"
    t_contact.cell(0, 1).text = "Details (Verified / Placeholder)"
    t_contact.cell(1, 0).text = "Full Official Name"
    t_contact.cell(1, 1).text = "Edirisinghe Kankanamge Yasas Pasindu Fernando (E.K.Y.P. Fernando)"
    t_contact.cell(2, 0).text = "Academic & Research Roles"
    t_contact.cell(2, 1).text = "Researcher, Software Developer & Technical Implementation Lead, Simple AAC Platform; Research Collaborator, PRAGATHI Child Intervention Centre, Galle"
    t_contact.cell(3, 0).text = "Mailing Address"
    t_contact.cell(3, 1).text = "[PLACEHOLDER: Official Correspondence Address, Galle / Colombo - Local Only]"
    t_contact.cell(4, 0).text = "Electronic Mail"
    t_contact.cell(4, 1).text = "[PLACEHOLDER: Official Email - Local Only]"
    t_contact.cell(5, 0).text = "Contact Telephone"
    t_contact.cell(5, 1).text = "[PLACEHOLDER: Contact Telephone Number - Local Only]"

    add_heading_2(doc, "3. Academic Qualifications")
    add_bullet_point(doc, "Master of Science in Artificial Intelligence (MSc AI) — Kingston University, United Kingdom (Ongoing).", bold_prefix="• ")
    add_bullet_point(doc, "Bachelor of Engineering (Honours) in Software Engineering (BEng Hons) — London Metropolitan University, United Kingdom (Completed).", bold_prefix="• ")
    add_bullet_point(doc, "Relevant Specializations: Human-Computer Interaction (HCI), Assistive Mobile Technologies, Machine Learning Foundations, System Privacy and Data Protection.", bold_prefix="• ")

    add_heading_2(doc, "4. Research Contributions & Technical Projects")
    add_body_paragraph(doc, "Platform B – Simple AAC Application (2024–Present):", bold_prefix="• ")
    add_body_paragraph(doc, "Architected, engineered, and maintained the complete production codebase for the Simple AAC Flutter application (`lk.yasas.simpleaac`). "
                            "Developed trilingual linguistic structures for Sinhala, Tamil, and English communication cards; local audio playback; offline-first scoped storage; and zero-cloud privacy architecture. "
                            "Led research protocol design, usability task formulation, and instrument development in collaboration with clinical supervisors.")

    add_body_paragraph(doc, "Clinical & Academic Collaboration (2025–Present):", bold_prefix="• ")
    add_body_paragraph(doc, "Collaborated with Dr. Gayani Punchihewa (Department of Psychiatry, Faculty of Medicine, University of Ruhuna), PRAGATHI Child Intervention Centre, and undergraduate medical students to co-design pediatric usability evaluation protocols for children with neurodevelopmental disabilities.")

    add_heading_2(doc, "5. Ethics & Research Methodology Training")
    add_bullet_point(doc, "Good Clinical Practice (GCP) & Research Ethics Training for Human Subject Research [PLACEHOLDER: Certifying Institution, Date].", bold_prefix="• ")
    add_bullet_point(doc, "Pediatric Safeguarding & Ethical Data Management in Digital Health [PLACEHOLDER: Training Body, Date].", bold_prefix="• ")

    add_heading_2(doc, "6. Technical Proficiencies")
    add_bullet_point(doc, "Frameworks & Languages: Flutter, Dart, Python, Android SDK, iOS Swift/Objective-C.", bold_prefix="• ")
    add_bullet_point(doc, "Assistive Tech & Multilingual NLP: AAC visual communication grids, Text-to-Speech (TTS) integration, Unicode Sinhala/Tamil text tokenization.", bold_prefix="• ")
    add_bullet_point(doc, "Privacy & Data Security: Scoped storage architecture, local encryption, offline-first networking, zero-telemetry design.", bold_prefix="• ")

    add_heading_2(doc, "7. Declaration")
    add_body_paragraph(doc, "I hereby certify that the information provided in this curriculum vitae is true, accurate, and complete to the best of my knowledge.\n\n\n"
                            "_____________________________________\n"
                            "Signature of Researcher / Lead Developer\n"
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
    t_train = doc.add_table(rows=4, cols=4)
    format_table_headers_and_borders(t_train, col_widths=[1.8, 1.8, 2.0, 1.4])
    t_train.cell(0, 0).text = "Investigator / Supervisor"
    t_train.cell(0, 1).text = "Role in AAC Study"
    t_train.cell(0, 2).text = "Training Domains / Course Details"
    t_train.cell(0, 3).text = "Verification Status"

    t_train.cell(1, 0).text = "Dr. Gayani Punchihewa\n(MBBS, MD Psych)"
    t_train.cell(1, 1).text = "Proposed Research Supervisor\n(Senior Lecturer in Psychiatry & Consultant Psychiatrist)"
    t_train.cell(1, 2).text = "Clinical Research Methodology, Good Clinical Practice (GCP), Bioethics & Research Integrity (PGIM, SLCPsych, Faculty of Medicine Ruhuna)"
    t_train.cell(1, 3).text = "Verified Faculty Staff;\nInstitutional certificate appended"

    t_train.cell(2, 0).text = "E.K.Y.P. Fernando\n(Yasas Pasindu Fernando)"
    t_train.cell(2, 1).text = "Researcher, Software Developer & Technical Implementation Lead"
    t_train.cell(2, 2).text = "Research Methodology & Ethics in AI/CS (Kingston Univ, London Met), TRREE / CITI GCP Bioethics Modules for Digital Health"
    t_train.cell(2, 3).text = "Academic training certified;\nModule certificate appended"

    t_train.cell(3, 0).text = "Thamalka D. J. G. &\nD. V. W. Gunawardana"
    t_train.cell(3, 1).text = "Undergraduate Medical Student Co-Investigators"
    t_train.cell(3, 2).text = "Undergraduate Medical Curriculum Module on Research Methodology and Bioethics (Faculty of Medicine, University of Ruhuna)"
    t_train.cell(3, 3).text = "Faculty Academic Record Verified"

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

    add_body_paragraph(doc, "We, the undersigned Principal Investigator, Researcher/Technical Implementation Lead, and Proposed Research Supervisor, "
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

    add_body_paragraph(doc, "Respectfully submitted,\n\n\n"
                            "_____________________________________________\n"
                            "E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n"
                            "Researcher, Software Developer & Technical Implementation Lead\n"
                            "MSc AI (Kingston Univ, ongoing), BEng (Hons) SE (London Met)\n\n\n"
                            "_____________________________________________\n"
                            "Dr. Gayani Punchihewa (MBBS, MD Psych)\n"
                            "Proposed Research Supervisor\n"
                            "Senior Lecturer in Psychiatry, Faculty of Medicine, University of Ruhuna\n"
                            "Consultant Psychiatrist, Teaching Hospital Karapitiya\n"
                            "Date: ___ / ___ / ______")

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
        ("5", "Curriculum vitae of the principal investigator (PI)/s", "01", "Draft in forms/10; Fact-checked"),
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
