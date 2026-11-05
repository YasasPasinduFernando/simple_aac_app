#!/usr/bin/env python3
"""
Populates the official blank University of Ruhuna ERC Application Form
(Annexure UOR/03-001) for the Simple AAC Application study.
Preserves all official tables, checkboxes, borders, and declaration blocks.
"""

import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

def populate_application_form(template_path, output_path):
    doc = docx.Document(template_path)

    # 1. Top matter / Applicant Name / Version
    # P7: Version, P8: Name of Applicant
    for p in doc.paragraphs[:15]:
        if "Version:" in p.text:
            p.text = "Version: Version 1.0 (DRAFT - November 2026)"
            for run in p.runs:
                run.font.name = "Calibri"
                run.font.size = Pt(10)
                run.font.bold = True
        elif "Name of Applicant:" in p.text:
            p.text = "Name of Applicant: Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando) [Technical Research Collaborator & AAC Application Developer]"
            for run in p.runs:
                run.font.name = "Calibri"
                run.font.size = Pt(10)
                run.font.bold = True

    # 2. Title of Research Project (P16)
    for p in doc.paragraphs[14:20]:
        if "1. Title of Research Project:" in p.text:
            p.text = "1. Title of Research Project:  SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation"
            for run in p.runs:
                run.font.name = "Calibri"
                run.font.size = Pt(10.5)
                run.font.bold = True

    # 3. Details of Principal Investigator / Applicant (Table 1)
    # CRITICAL: Under Ruhuna ERC rules for undergraduate student projects, the PI is formally designated
    # by the department/team (either the lead medical student researcher or academic supervisor).
    t1 = doc.tables[1]
    t1.cell(0, 0).text = "Title(Prof./Dr./Mr/Ms): [FORMAL CONFIRMATION REQUIRED]"
    t1.cell(0, 1).text = "Name: [PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED:\n" \
                         "Lead Medical Student Researcher (Thamalka D. J. G. / D. V. W. Gunawardana) or\n" \
                         "Academic Supervisor (Dr. Gayani Punchihewa) per Faculty ERC Regulations]"
    t1.cell(1, 0).text = "Current designation and name and address of institution where the applicant is attached:\n" \
                         "Faculty of Medicine, University of Ruhuna, Karapitiya, Galle, Sri Lanka / Department of Psychiatry."
    t1.cell(2, 0).text = "Highest educational qualification of applicant:\n" \
                         "[Undergraduate Medical Student (MBBS in progress) / MBBS, MD (Psychiatry) — Pending Formal Team Confirmation]"
    t1.cell(3, 0).text = "Mailing address:\n" \
                         "Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka."
    t1.cell(4, 0).text = "Phone no for contact: [PLACEHOLDER: Official Faculty/Student Contact - Local Only]"
    t1.cell(4, 2).text = "e-mail: [PLACEHOLDER: Official Email - Local Only]"

    # 4. Question 3: Postgraduate degree requirement (No)
    for p in doc.paragraphs[20:25]:
        if "3. Is this study a requirement" in p.text or "Yes" in p.text:
            p.text = "3. Is this study a requirement for a postgraduate degree/requirement by PGIM for Board\n" \
                     "    Certification, Faculty of Graduate studies (FGS)?    Yes [  ]      No [ X ]\n" \
                     "    (Faculty of Medicine Undergraduate Medical Student Research Project / Academic Department Collaboration)"

    # 5. Question 4: Supervisors (Yes)
    for p in doc.paragraphs[24:28]:
        if "4. Are there supervisors" in p.text:
            p.text = "4. Are there supervisors for this project?    Yes [ X ]    No [  ]"

    # Table 3: Supervisor Details (Dr. Gayani Punchihewa)
    t3 = doc.tables[3]
    t3.cell(0, 0).text = "Title: Dr."
    t3.cell(0, 1).text = "Name: Dr. Gayani Punchihewa"
    t3.cell(1, 0).text = "Institutional affiliations:\n" \
                         "Senior Lecturer in Psychiatry, Department of Psychiatry, Faculty of Medicine, University of Ruhuna;\n" \
                         "Consultant Psychiatrist, Teaching Hospital Karapitiya, Galle, Sri Lanka."
    t3.cell(2, 0).text = "Highest educational qualification :\n" \
                         "MBBS, MD (Psychiatry)"
    t3.cell(3, 0).text = "Mailing address:\n" \
                         "Department of Psychiatry, Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka."
    t3.cell(4, 0).text = "Phone: +94 91 2234801 / Ext 161"
    t3.cell(4, 2).text = "e-mail: [PLACEHOLDER: gayani@med.ruh.ac.lk - Local Only]"

    # 6. Question 5: Co-investigators (Yes)
    for p in doc.paragraphs[28:34]:
        if "5.  Are there Co-investigators" in p.text:
            p.text = "5.  Are there Co-investigators for this project?    Yes [ X ]    No [  ]"

    # Table 4: Co-investigator 1 (Thamalka D. J. G. - Lead Medical Student Researcher)
    t4 = doc.tables[4]
    t4.cell(0, 0).text = "Title: Ms."
    t4.cell(0, 1).text = "Name: Thamalka D. J. G."
    t4.cell(1, 0).text = "Institutional affiliations:\n" \
                         "Lead Medical Student Researcher, Faculty of Medicine, University of Ruhuna, Karapitiya, Galle."
    t4.cell(2, 0).text = "Highest educational qualification :\n" \
                         "Undergraduate Medical Student (MBBS in progress)"
    t4.cell(3, 0).text = "Mailing address:\n" \
                         "Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka."
    t4.cell(4, 0).text = "Phone: [PLACEHOLDER: Student Mobile - Local Only]"
    t4.cell(4, 2).text = "e-mail: [PLACEHOLDER: Student Faculty Email - Local Only]"

    # Table 5: Co-investigator 2 (D. V. W. Gunawardana - Medical Student Researcher)
    t5 = doc.tables[5]
    t5.cell(0, 0).text = "Title: Mr."
    t5.cell(0, 1).text = "Name: D. V. W. Gunawardana"
    t5.cell(1, 0).text = "Institutional affiliations:\n" \
                         "Medical Student Researcher, Faculty of Medicine, University of Ruhuna, Karapitiya, Galle."
    t5.cell(2, 0).text = "Highest educational qualification :\n" \
                         "Undergraduate Medical Student (MBBS in progress)"
    t5.cell(3, 0).text = "Mailing address:\n" \
                         "Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka."
    t5.cell(4, 0).text = "Phone: [PLACEHOLDER: Student Mobile - Local Only]"
    t5.cell(4, 2).text = "e-mail: [PLACEHOLDER: Student Email - Local Only]"

    # Table 6: Co-investigator 3 (E.K.Y.P. Fernando - Technical Research Collaborator & Developer)
    t6 = doc.tables[6]
    t6.cell(0, 0).text = "Title: Mr."
    t6.cell(0, 1).text = "Name: E.K.Y.P. Fernando (Yasas Pasindu Fernando)"
    t6.cell(1, 0).text = "Institutional affiliations & Research Role:\n" \
                         "Technical Research Collaborator & AAC Application Developer;\n" \
                         "External Technical Collaborator with Department of Psychiatry & PRAGATHI Child Intervention Centre.\n" \
                         "(Role: Specialist software engineering guidance, AAC mobile app architecture, technical instrumentation, usability data interpretation)."
    t6.cell(2, 0).text = "Highest educational qualification :\n" \
                         "MSc in Artificial Intelligence (Kingston University, UK - Ongoing);\n" \
                         "BEng (Hons) in Software Engineering (London Metropolitan University, UK - Completed)"
    t6.cell(3, 0).text = "Mailing address:\n" \
                         "[PLACEHOLDER: External Collaborator Address - Local Only]"
    t6.cell(4, 0).text = "Phone: [PLACEHOLDER: External Collaborator Contact - Local Only]"
    t6.cell(4, 2).text = "e-mail: [PLACEHOLDER: External Collaborator Email - Local Only]"

    # 7. Question 6: Has any other ERC approved? (No)
    for p in doc.paragraphs[48:54]:
        if "Has any other ERC approved" in p.text:
            p.text = "6. Has any other ERC approved this project?    Yes [  ]    No [ X ]  (Initial submission)"

    # 8. Question 7: Research sites (Table 7)
    t7 = doc.tables[7]
    t7.cell(1, 0).text = "Child Intervention & Developmental Therapy Centre"
    t7.cell(1, 1).text = "PRAGATHI – Child Intervention Centre, Galle, Southern Province, Sri Lanka"
    t7.cell(2, 0).text = "Child & Adolescent Psychiatric Outpatient Clinic"
    t7.cell(2, 1).text = "Department of Psychiatry Outpatient Clinic, Faculty of Medicine, University of Ruhuna / National Hospital Galle"

    # 9. Question 8: Funding (Table 8)
    t8 = doc.tables[8]
    t8.cell(3, 0).text = "Unfunded. If unfunded, please explain why no funding is needed:\n" \
                         "This research is conducted voluntarily using existing departmental and institutional resources of the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, and PRAGATHI – Child Intervention Centre, Galle. The Simple AAC mobile application has been developed and is distributed completely free of charge with no commercial sponsors, advertisements, or external financial grants."

    # 10. Question 9: Clinical Trials (9.1 to 9.6)
    for p in doc.paragraphs[58:84]:
        if "For Clinical Trials only" in p.text:
            p.text = "For Clinical Trials only:   [ NOT APPLICABLE ]\n" \
                     "This research is an observational usability, acceptability, and feasibility evaluation of an assistive communication software tool, not a clinical trial of a pharmaceutical compound, biological agent, vaccine, or invasive medical device."
        elif "9.2 Is it a multi-centre trial?" in p.text:
            p.text = "9.2 Is it a multi-centre trial?    Not applicable."
        elif "9.3 Is the clinical trial registered" in p.text:
            p.text = "9.3 Is the clinical trial registered with a clinical trials registry?    Not applicable."
        elif "9.4    Has this study been approved by the SCOCT" in p.text:
            p.text = "9.4 Has this study been approved by the SCOCT at the Ministry of Health?    Not applicable."
        elif "9.5   Data Safety Monitoring Board" in p.text:
            p.text = "9.5 Data Safety Monitoring Board (DSMB):    Not applicable."
        elif "9.6 Details of Indemnity and Insurance" in p.text:
            p.text = "9.6 Details of Indemnity and Insurance coverage:    Not applicable (Low-risk non-invasive observational software study)."

    # 11. Part II: 10. Start and end dates (P85-87)
    for p in doc.paragraphs[84:90]:
        if "Estimated start date" in p.text:
            p.text = "Estimated start date that involves human participants or data: 01 February 2027 (Following formal ERC approval)"
        elif "Estimated completion date" in p.text:
            p.text = "Estimated completion date of involvement of human participants or data: 31 July 2027 (6-month evaluation period)"

    # 12. Checklist Tables (Tables 21 to 32)
    def fill_checklist_table(table, answers):
        # answers is a list of tuples: (row_idx, is_applicable, is_yes, description_text)
        for r_idx, is_app, is_yes, desc in answers:
            if r_idx < len(table.rows):
                row = table.rows[r_idx]
                # Last cell is always Section in Protocol & page
                row.cells[-1].text = desc
                # If row has Yes/No columns (cells count >= 4)
                if len(row.cells) >= 4:
                    if is_yes is True:
                        row.cells[-3].text = "[ X ]"
                        row.cells[-2].text = "[  ]"
                    elif is_yes is False:
                        row.cells[-3].text = "[  ]"
                        row.cells[-2].text = "[ X ]"

    # Table 21: Collaborative partnership
    fill_checklist_table(doc.tables[21], [
        (2, True, True, "Collaborative partnership between PRAGATHI Child Intervention Centre and Dept of Psychiatry, Faculty of Medicine, University of Ruhuna. (Protocol Section 1 & 5.2, p. 2, 7)"),
        (3, True, True, "Engagement with local parent associations, speech therapists, and educators in Galle. (Protocol Section 5.2, p. 7)"),
        (4, True, True, "Children gain free localized digital AAC tool; therapists/parents gain clinical communication aids. (Protocol Section 2.2 & 5.8, p. 3, 11)")
    ])

    # Table 22: Social Value
    fill_checklist_table(doc.tables[22], [
        (2, True, True, "Direct beneficiaries: non-verbal/minimally verbal children with ASD/ADHD/speech delays, families, and therapists. (Protocol Section 2.2 & 5.3, p. 3, 7)"),
        (3, True, True, "Dissemination through clinical seminars at Faculty of Medicine, peer-reviewed journals, and free open software updates. (Protocol Section 5.8, p. 12)")
    ])

    # Table 23: Scientific Validity
    fill_checklist_table(doc.tables[23], [
        (2, True, True, "Fills critical assistive technology gap in Sri Lanka by providing trilingual (Sinhala/Tamil/English) offline digital AAC. (Protocol Section 2 & 3, p. 2–5)"),
        (3, False, False, "Not applicable (Novel prospective usability study; not a replication). (Protocol Section 2.2, p. 3)"),
        (4, True, True, "Sample size N = 30 child-caregiver dyads formulated per Nielsen-Virzi digital usability framework and saturation. (Protocol Section 5.4, p. 8)")
    ])

    # Table 24: Confidentiality
    fill_checklist_table(doc.tables[24], [
        (2, True, True, "Data obtained via direct usability observation, parent survey, and therapist interviews; no biological samples. (Protocol Section 5.6, p. 8)"),
        (3, True, True, "Anonymized digital data kept for 5 years in locked, encrypted departmental storage, then wiped. (Protocol Section 5.8 & DMP, p. 11)"),
        (4, True, True, "Minimal contact details collected solely for session coordination; stored separately under encrypted key. (Protocol Section 5.8 & DMP, p. 11)"),
        (5, True, True, "Restricted strictly to the designated Principal Investigator, Student Research Team, and Academic Supervisor. (Protocol Section 5.8 & DMP, p. 11)"),
        (6, True, True, "Confidentiality maintained via alphanumeric pseudonymization (e.g., AAC-DYAD-001); no names on research records. (Protocol Section 5.8, p. 11)"),
        (7, True, True, "Stored locally on AES-256 encrypted drives; zero cloud synchronization; hard copies in locked fireproof cabinets. (Protocol Section 5.8 & DMP, p. 11)"),
        (8, True, True, "Cryptographic data wiping for digital media; cross-cut shredding for hard copies following retention. (Protocol Section 5.8 & DMP, p. 12)")
    ])

    # Table 25: Rights of the participants
    fill_checklist_table(doc.tables[25], [
        (2, True, True, "Participants may withdraw unconditionally at any time without penalty or impact on routine clinical care. (Protocol Section 5.8 & ICF, p. 11)"),
        (3, True, True, "Clear channels established: contacts of PI, Lead Supervisor, and ERC Secretary provided on Information Sheet. (Protocol Section 5.8 & IFS, p. 12)"),
        (4, True, True, "Designated clinical supervisor and PI contact numbers provided on all participant sheets. (Protocol Section 5.8 & IFS, p. 12)"),
        (5, True, True, "Summary of aggregate results and usability insights shared with participating parents and PRAGATHI Centre. (Protocol Section 5.8, p. 12)"),
        (6, True, True, "Simple AAC application provided permanently free of charge to all participating families. (Protocol Section 5.8, p. 12)")
    ])

    # Table 26: Fair participant selection
    fill_checklist_table(doc.tables[26], [
        (2, True, True, "Children aged 2–12 with neurodevelopmental speech/language delays are the direct target group for AAC intervention. (Protocol Section 5.3, p. 7)"),
        (3, True, True, "Clear inclusion (ASD/ADHD/speech delay, 2–12 yrs, parent consent) and exclusion (acute severe illness preventing interaction) criteria. (Protocol Section 5.3, p. 7)")
    ])

    # Table 27: Responsibilities of researcher & Vulnerable populations
    fill_checklist_table(doc.tables[27], [
        (2, True, True, "Non-invasive study. Any incidental child distress managed immediately by on-site clinical team. (Protocol Section 5.8, p. 11)"),
        (3, True, True, "Routine psychiatric follow-up and speech therapy continue uninterrupted at clinical centres. (Protocol Section 5.8, p. 11)"),
        (4, True, True, "Zero financial, commercial, or intellectual conflicts; open non-commercial software tool. (Protocol Section 5.8, p. 12)"),
        (5, True, True, "Ethical safeguards in place addressing pediatric communication vulnerabilities and data privacy. (Protocol Section 5.8, p. 10–12)"),
        (8, True, True, "Vulnerable population justified: pediatric communication disorders must be investigated in the affected child population to develop effective AAC tools. (Protocol Section 5.3 & 5.8, p. 7, 10)")
    ])

    # Table 28: Foreign funding (Not applicable)
    t28 = doc.tables[28]
    t28.rows[0].cells[-1].text = "Not Applicable"
    t28.rows[1].cells[-1].text = "No foreign funding"
    for r in range(2, len(t28.rows)):
        t28.rows[r].cells[-1].text = "Not applicable (Locally designed, self-funded academic research without foreign sponsorship)."

    # Table 29: Community based research
    fill_checklist_table(doc.tables[29], [
        (2, True, True, "Addresses immediate communication needs of neurodivergent children in Galle and Southern Province. (Protocol Section 2 & 5.2, p. 2, 7)"),
        (3, True, True, "Co-designed with therapists and special educators at PRAGATHI Centre. (Protocol Section 1 & 5.2, p. 2, 7)"),
        (4, True, True, "Institutional permission from centre administration plus individual parental proxy consent. (Protocol Section 5.8 & Annex E, p. 10)"),
        (5, True, True, "Training local speech therapists, clinical staff, and families in digital AAC strategies. (Protocol Section 2.2 & 5.8, p. 3, 12)"),
        (6, True, True, "Findings shared directly through institutional workshops and free software updates. (Protocol Section 5.8, p. 12)")
    ])

    # Table 30: Clinical trials (Not applicable)
    t30 = doc.tables[30]
    t30.rows[0].cells[-1].text = "Not Applicable"
    t30.rows[1].cells[-1].text = "No clinical trial"
    for r in range(2, len(t30.rows)):
        t30.rows[r].cells[-1].text = "Not applicable (Non-invasive observational usability study of mobile software)."

    # Table 31: IFS / ICF Checklist
    t31 = doc.tables[31]
    t31.rows[2].cells[-1].text = "IFS Section 1 (Proposal Annexure B, p. 1)"
    t31.rows[3].cells[-1].text = "IFS Section 3 & ICF Section 2 (Proposal Annexure B & C, p. 1, 3)"
    t31.rows[4].cells[-1].text = "IFS Section 4 (Proposal Annexure B, p. 1)"
    t31.rows[5].cells[-1].text = "IFS Section 5 (Proposal Annexure B, p. 2)"
    t31.rows[6].cells[-1].text = "IFS Section 6 (Proposal Annexure B, p. 2)"
    t31.rows[7].cells[-1].text = "IFS Section 7 (Proposal Annexure B, p. 2)"
    t31.rows[8].cells[-1].text = "IFS Section 8 (Proposal Annexure B, p. 2)"
    t31.rows[9].cells[-1].text = "IFS Section 3 & ICF Section 3 (Proposal Annexure B & C, p. 1, 3)"

    # Table 32: Consent
    fill_checklist_table(doc.tables[32], [
        (2, True, True, "Initial contact made by attending speech therapist/psychiatrist at PRAGATHI and Ruhuna clinics. (Protocol Section 5.8, p. 10)"),
        (3, True, True, "Written proxy consent obtained from parent/guardian in Sinhala, Tamil, or English. (Protocol Section 5.8 & Annex C, p. 10)"),
        (4, True, True, "Written"),
        (5, True, True, "Comprehensive Information Sheet provided in parent's primary language. (Protocol Section 5.8 & Annex B, p. 10)"),
        (6, True, True, "Interactive explanation and comprehension check by investigator/therapist. (Protocol Section 5.8, p. 10)"),
        (7, True, True, "Formal written parental proxy consent required for all minors. (Protocol Section 5.8 & Annex C, p. 10)"),
        (8, True, True, "Unconditional withdrawal permitted at any stage upon verbal or written request. (Protocol Section 5.8 & Annex C, p. 11)"),
        (9, True, True, "No financial compensation; free permanent mobile application and training provided. (Protocol Section 5.8 & IFS, p. 11)"),
        (10, True, True, "Any protocol modifications submitted to ERC; re-consent obtained if procedures alter. (Protocol Section 5.8, p. 11)"),
        (11, True, True, "Special pediatric safeguards: Parental proxy consent PLUS ongoing child developmental assent. (Protocol Section 5.8 & Annex C, D, p. 10–11)"),
        (12, True, True, "Developmentally appropriate assent protocol with pictorial communication symbols. (Protocol Section 5.8 & Annex D, p. 11)")
    ])

    # 13. Question 12.1: Data Collection Procedure (P118)
    for p in doc.paragraphs[115:124]:
        if "12.1 What is the procedure" in p.text:
            p.text = "12.1 What is the procedure to be carried out on these subjects:\n\n" \
                     "The research evaluates the Pragathi AAC / Simple AAC application (Platform B), designed for children aged 2–12 years with Autism Spectrum Disorder (ASD), ADHD, and speech impairments. The application includes a picture-based visual communication board with voice output across 6 daily communication categories (food and drink, emotions, activities, school items, family members, basic needs: eating, drinking, toilet, sleep) and early learning modules (basic vocabulary, object recognition, emotional recognition, social communication, daily routine), functioning completely offline in Sinhala, Tamil, and English.\n\n" \
                     "The clinical evaluation protocol comprises:\n" \
                     "1. Orientation & Baseline Profiling (5 minutes): The caregiver completes a brief demographic and communication background survey regarding the child's primary communication mode and touchscreen familiarity.\n" \
                     "2. Guided Usability Observation (15–20 minutes): In a child-friendly therapy room at PRAGATHI Centre or Ruhuna Psychiatry clinic, the child and caregiver interact with the app on an Android tablet under therapist observation. The child is gently invited to perform 3 standard communicative tasks: (a) requesting a preferred snack/drink, (b) expressing an emotional feeling (happy/tired), and (c) choosing a daily play activity. Task completion (independent / prompted / incomplete), latency (seconds), and engagement behaviors are recorded.\n" \
                     "3. Caregiver Usability Evaluation: The caregiver completes an adapted System Usability Scale (SUS) assessing ease of navigation, card customization, and child engagement.\n" \
                     "4. Therapist Qualitative Feedback: The attending therapist completes a semi-structured interview regarding clinical utility, linguistic appropriateness, and session integration.\n\n" \
                     "*Note: The study is entirely non-invasive. No biological samples, blood, medications, or clinical diagnostic procedures are involved. No facial recognition or biometric emotion classification models exist in this application.*"

    # 14. Question 13.1: Experience of Investigators (P125)
    for p in doc.paragraphs[123:130]:
        if "13.1 Please provide a brief description" in p.text:
            p.text = "13.1 Experience of Investigators with this type of research:\n\n" \
                     "(i) Technical Research Collaborator & AAC Application Developer (Mr. E.K.Y.P. Fernando / Yasas Pasindu Fernando): " \
                     "MSc in Artificial Intelligence candidate (Kingston University, UK) and BEng (Hons) in Software Engineering graduate (London Metropolitan University, UK). Specialist in assistive mobile system engineering, Human-Computer Interaction (HCI), and offline-first digital health platforms. Principal architect of the Simple AAC / Pragathi AAC system.\n" \
                     "(ii) Research Supervisor (Dr. Gayani Punchihewa): " \
                     "Senior Lecturer in Psychiatry, Department of Psychiatry, Faculty of Medicine, University of Ruhuna, and Consultant Psychiatrist, Teaching Hospital Karapitiya. Extensive expertise in general and child/adolescent psychiatry, neurodevelopmental assessment, clinical research governance, and pediatric ethical oversight.\n" \
                     "(iii) Co-Investigators (Thamalka D. J. G. and D. V. W. Gunawardana): " \
                     "Undergraduate medical students, Faculty of Medicine, University of Ruhuna, trained in clinical pediatric communication, neurodevelopmental clinical observation, and medical research methodology.\n" \
                     "(iv) Clinical Collaborators: Specialists and speech therapists at PRAGATHI Child Intervention Centre, Galle, with dedicated expertise in early intervention for autism and ADHD."

    # 15. Part III: Risks and Benefits (P134 to P186)
    for p in doc.paragraphs[134:144]:
        if "(i) Physical risks" in p.text:
            p.text = "(i) Physical risks (bodily contact / administration of substances):    Yes [  ]    No [ X ]\n" \
                     "(ii) Psychological/emotional risks (feeling uncomfortable, upset):    Yes [ X ]    No [  ]\n" \
                     "(iii) Social risks (loss of status, privacy, reputation):            Yes [ X ]    No [  ]\n" \
                     "(iv) Legal risks (apprehension, arrest, subpoena):                    Yes [  ]    No [ X ]"
        elif "14.2\tIf Yes to any of the above" in p.text:
            p.text = "14.2 Description of Identified Risks:\n" \
                     "• Psychological Risk: A child with communication difficulties may occasionally experience mild frustration or fatigue during interactive screen tasks if an intended icon is not readily located.\n" \
                     "• Social / Privacy Risk: Risk of accidental disclosure of child's developmental diagnosis if research records were breached."
        elif "14.3\tState measures employed" in p.text:
            p.text = "14.3 Risk Minimization Measures:\n" \
                     "• Strict 15–20 minute time limits per session with frequent breaks.\n" \
                     "• Parent/caregiver remains present alongside the child throughout the entire session.\n" \
                     "• Immediate Cessation Rule: If the child shows any sign of distress, fatigue, or disinterest, the evaluation stops immediately without penalty.\n" \
                     "• Privacy & Data Protection: Rigorous pseudonymization (coded participant IDs), fully offline local device storage, zero cloud transmission, and AES-256 encrypted archival."

    # Benefits (P144 to P150)
    for p in doc.paragraphs[144:151]:
        if "Describe any potential direct benefits to participants" in p.text:
            p.text = "Direct benefits to participants:\n" \
                     "Participating children and families receive a tailored, trilingual digital AAC application permanently on their mobile devices free of charge, along with personalized card configuration and therapist guidance for daily communication."
        elif "Describe any potential direct benefits to the community" in p.text:
            p.text = "Benefits to the community:\n" \
                     "Establishes open-access, culturally adapted Sinhala and Tamil digital communication resources for the special education and clinical community in the Southern Province, building local therapist capacity in assistive digital interventions."
        elif "Comment on the potential benefits to the scientific/scholarly community" in p.text:
            p.text = "Benefits to the scientific/scholarly community:\n" \
                     "Provides empirical, peer-reviewed evidence on the feasibility, usability, and design requirements of low-cost, offline-first AAC systems in South Asian public health contexts."

    # Compensation (P150 to P161)
    for p in doc.paragraphs[150:161]:
        if "16.1\tWill participants receive compensation" in p.text:
            p.text = "16.1 Compensation:    Financial: Yes [  ]  No [ X ]      In-kind: Yes [ X ]  No [  ]      Other: Yes [  ]  No [ X ]"
        elif "16.2\tIf Yes, please provide details" in p.text:
            p.text = "16.2 Details of in-kind compensation:\n" \
                     "Families receive the complete Simple AAC application package with pre-loaded and customized Sinhala/Tamil/English communication cards on their personal or provided mobile devices completely free of charge."
        elif "16.3\tIf No, please explain" in p.text:
            p.text = "16.3 Explanation: Financial compensation is inappropriate as participation is completely voluntary and routine therapy is provided free at the centre."
        elif "16.4\tIf participants choose to withdraw" in p.text:
            p.text = "16.4 Withdrawal policy: Participants keep the free Simple AAC software even if they choose to withdraw from the research evaluation."

    # Feedback / Debriefing (P161-164)
    for p in doc.paragraphs[161:165]:
        if "17. Feedback/debriefing" in p.text:
            p.text = "17. Feedback/debriefing/referral/after care:\n" \
                     "Following usability trials, parents and therapists receive a debriefing session offering practical tips on customizing the AAC board for home routines. Standard clinical psychiatric care and developmental therapy at PRAGATHI Centre continue without interruption."

    # Conflict of interest (P164 to P186)
    for p in doc.paragraphs[164:186]:
        if "18. Do you have any conflict" in p.text:
            p.text = "18. Do you have any conflict of interests with regards to this project?    Yes [  ]    No [ X ]"
        elif "18.1 Commercially" in p.text:
            p.text = "18.1 Commercially: None. The software is developed voluntarily and distributed free of charge."
        elif "18.2 Financially" in p.text:
            p.text = "18.2 Financially: None. No commercial sponsors or patent royalties exist."
        elif "18.3 Intellectually" in p.text:
            p.text = "18.3 Intellectually: None."
        elif "18.4 Other" in p.text:
            p.text = "18.4 Other: None."
        elif "19. Does any member of the research team have any affiliation" in p.text:
            p.text = "19. Affiliation with funding providers: None (Unfunded independent research)."
        elif "20. If there is a duality of interest" in p.text:
            p.text = "20. Duality of interest: None."

    # 16. Question 21: Declaration of Applicant (P187-200)
    for p in doc.paragraphs[187:201]:
        if "Full name of Principal Investigator:" in p.text:
            p.text = "Full name of Principal Investigator / Applicant: [PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED:\n" \
                     "Lead Medical Student Researcher (Thamalka D. J. G. / D. V. W. Gunawardana) or Academic Supervisor (Dr. Gayani Punchihewa)]"

    # 17. Question 22: Consent from all Investigators (Table 37)
    t37 = doc.tables[37]
    # Row 0: Headers
    # Row 1: Designated Principal Investigator
    t37.cell(1, 0).text = "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED]\n[Lead Medical Student Researcher / Academic Supervisor]"
    t37.cell(1, 1).text = "[MBBS in progress / MBBS, MD (Psychiatry) — Pending Formal Team Confirmation]"
    t37.cell(1, 2).text = "Faculty of Medicine, University of Ruhuna, Karapitiya, Galle"
    t37.cell(1, 3).text = "_______________________\n[Wet-ink signature]"

    # Row 2: Lead Medical Student Researcher (Thamalka D. J. G.)
    t37.cell(2, 0).text = "Ms. Thamalka D. J. G.\n[Lead Medical Student Researcher]"
    t37.cell(2, 1).text = "Undergraduate Medical Student (MBBS in progress)"
    t37.cell(2, 2).text = "Faculty of Medicine, University of Ruhuna"
    t37.cell(2, 3).text = "_______________________\n[Wet-ink signature]"

    # Row 3: Medical Student Researcher (D. V. W. Gunawardana)
    t37.cell(3, 0).text = "D. V. W. Gunawardana\n[Medical Student Researcher]"
    t37.cell(3, 1).text = "Undergraduate Medical Student (MBBS in progress)"
    t37.cell(3, 2).text = "Faculty of Medicine, University of Ruhuna"
    t37.cell(3, 3).text = "_______________________\n[Wet-ink signature]"

    # Row 4: Research Supervisor (Dr. Gayani Punchihewa)
    t37.cell(4, 0).text = "Dr. Gayani Punchihewa\n[Proposed Research Supervisor]"
    t37.cell(4, 1).text = "MBBS, MD (Psychiatry)"
    t37.cell(4, 2).text = "Senior Lecturer, Dept of Psychiatry, Faculty of Medicine, University of Ruhuna; Consultant Psychiatrist"
    t37.cell(4, 3).text = "_______________________\n[Wet-ink signature]"

    # Row 5: Technical Research Collaborator & Developer (E.K.Y.P. Fernando)
    if len(t37.rows) > 5:
        t37.cell(5, 0).text = "E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n[Technical Research Collaborator & Software Developer]"
        t37.cell(5, 1).text = "MSc Artificial Intelligence (Kingston, ongoing);\nBEng (Hons) Software Eng (London Met, completed)"
        t37.cell(5, 2).text = "Simple AAC Project / Technical Collaborator"
        t37.cell(5, 3).text = "_______________________\n[Wet-ink signature]"

    for r in range(6, len(t37.rows)):
        t37.cell(r, 0).text = "Not applicable"
        t37.cell(r, 1).text = "Not applicable"
        t37.cell(r, 2).text = "Not applicable"
        t37.cell(r, 3).text = "Not applicable"

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated official application draft: {output_path}")

if __name__ == "__main__":
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    tmpl = os.path.join(base, "scripts", "templates", "Application_for_Human_Research_OFFICIAL_BLANK.docx")
    out = os.path.join(base, "forms", "02_Human_Research_Application_DRAFT.docx")
    populate_application_form(tmpl, out)
