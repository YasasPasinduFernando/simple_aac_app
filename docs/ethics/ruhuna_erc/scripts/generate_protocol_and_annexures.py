#!/usr/bin/env python3
"""
Generates the comprehensive, academically rigorous Detailed Research Proposal
adhering strictly to the University of Ruhuna Faculty of Medicine format:
Format_of_Research_Proposal.docx (effective 1 March 2021).

Also generates:
- 04_AAC_ERC_Research_Protocol_DRAFT.docx
- 04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx (Strictly de-identified)
- 05_Parent_or_Guardian_Information_Sheet_DRAFT.docx
- 06_Parent_or_Guardian_Consent_Form_DRAFT.docx
- 07_Child_Assent_Protocol_DRAFT.docx
- 08_Study_Instruments_DRAFT.docx
- 09_Site_Permission_Request_Letters_DRAFT.docx
- 11_Data_Management_Plan_DRAFT.docx
"""

import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx_common import (
    create_styled_document, setup_header_footer, add_draft_notice,
    add_heading_1, add_heading_2, add_heading_3, add_body_paragraph,
    add_bullet_point, format_table_headers_and_borders, PRIMARY_COLOR, SECONDARY_COLOR
)

def build_research_protocol(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Item 4: Detailed Research Proposal" if not is_anonymous else "Item 4: Research Proposal [ANONYMIZED FOR REVIEW]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    
    notice_text = "DRAFT RESEARCH PROTOCOL — FOR SUPERVISOR REVIEW & RUHUNA ERC ETHICAL REVIEW"
    if is_anonymous:
        notice_text += "\n[ANONYMIZED SUBMISSION COPY: ALL INVESTIGATOR NAMES, AFFILIATIONS, AND CONTACT DETAILS REDACTED PER ERC SUBMISSION RULES]"
    add_draft_notice(doc, notice_text)

    # Title Block
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t = p_title.add_run("Evaluation of the Usability, Acceptability, and Feasibility of an Offline Trilingual Augmentative and Alternative Communication (AAC) Mobile Application for Children with Communication Disabilities in the Southern Province, Sri Lanka\n")
    r_t.font.name = "Calibri"
    r_t.font.size = Pt(15)
    r_t.font.bold = True
    r_t.font.color.rgb = PRIMARY_COLOR

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("A Prospective Mixed-Methods Observational Usability Study in Clinical and Community Intervention Settings\n")
    r_sub.font.name = "Calibri"
    r_sub.font.size = Pt(12)
    r_sub.font.italic = True
    r_sub.font.color.rgb = SECONDARY_COLOR

    # Metadata / Investigator Box
    t_meta = doc.add_table(rows=5 if not is_anonymous else 3, cols=2)
    format_table_headers_and_borders(t_meta, col_widths=[2.5, 4.0])
    t_meta.cell(0, 0).text = "Protocol Attribute"
    t_meta.cell(0, 1).text = "Specification"
    t_meta.cell(1, 0).text = "Protocol Document Version"
    t_meta.cell(1, 1).text = "Version 1.0 (DRAFT) — November 2026"
    t_meta.cell(2, 0).text = "Target Review Body"
    t_meta.cell(2, 1).text = "Ethics Review Committee, Faculty of Medicine, University of Ruhuna, Sri Lanka"
    
    if not is_anonymous:
        t_meta.cell(3, 0).text = "Investigator & Research Team"
        t_meta.cell(3, 1).text = "Primary Student Research Team (Lead Student Investigators):\n" \
                                 "• Thamalka D. J. G. — Medical Student, Faculty of Medicine, University of Ruhuna\n" \
                                 "• D. V. W. Gunawardana — Medical Student, Faculty of Medicine, University of Ruhuna\n\n" \
                                 "Proposed Research Supervisor:\n" \
                                 "• Dr. Gayani Punchihewa, MBBS, MD (Psychiatry)\n" \
                                 "Senior Lecturer in Psychiatry, Department of Psychiatry, Faculty of Medicine, University of Ruhuna;\n" \
                                 "Consultant Psychiatrist, Teaching Hospital Karapitiya, Galle\n\n" \
                                 "Technical Research Collaborator & AAC Application Developer:\n" \
                                 "• Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando)\n" \
                                 "MSc in Artificial Intelligence candidate, Kingston University, UK; BEng (Hons) in Software Engineering, London Metropolitan University, UK (Completed)\n" \
                                 "Role: Technical Research Collaborator, AAC Application Developer & Technical Implementation Lead " \
                                 "(Advising on technical feasibility, system architecture, and evaluation methods; developing and implementing the Pragathi AAC mobile application; " \
                                 "supporting technical research planning and interpreting software evaluation metrics)\n" \
                                 "*(Academic qualifications background only; does NOT represent institutional sponsorship or thesis supervision for this Ruhuna medical student project)*\n\n" \
                                 "Principal Investigator Designation:\n" \
                                 "• [PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED: Lead Medical Student Researcher / Academic Supervisor per Faculty ERC Regulations]"
        t_meta.cell(4, 0).text = "Institutional Governance & Collaborating Bodies"
        t_meta.cell(4, 1).text = "Academic Collaborating Department: Department of Psychiatry, Faculty of Medicine, University of Ruhuna\n" \
                                 "Lead Community Intervention Facility: PRAGATHI – Child Intervention Centre, Galle (Proposed Clinical Usability Site Partner)\n" \
                                 "Proposed Endorsing Health Authority: Ministry of Health, Sri Lanka (Secretary of Health, Director of Health Information, Director of Mental Health — Subject to formal documentary confirmation)\n" \
                                 "Referenced Publishing Partner: Idea-Hub (Pvt) Ltd, Nugegoda (Referenced Apple App Store publishing partner, subject to confirmation)"

    doc.add_paragraph() # Spacer

    # Executive Summary / Table of Contents
    add_heading_2(doc, "STRUCTURE OF PROTOCOL (Adhering to Official Ruhuna ERC Format 2021)")
    add_bullet_point(doc, "Section 1: Title & Administrative Scope", bold_prefix="1. ")
    add_bullet_point(doc, "Section 2: Introduction & Justification (Background, Nature of the Problem, Justification)", bold_prefix="2. ")
    add_bullet_point(doc, "Section 3: Literature Review (AAC Evidence, Linguistic Adaptation in Sri Lanka, Assistive Usability)", bold_prefix="3. ")
    add_bullet_point(doc, "Section 4: Objectives (General Objective, Specific Measurable Objectives)", bold_prefix="4. ")
    add_bullet_point(doc, "Section 5: Methodology (Design, Setting, Population, Sample Size Sizing, Instruments, Analysis, Ethics)", bold_prefix="5. ")
    add_bullet_point(doc, "Section 6: Referencing (Peer-reviewed citations in Vancouver/Harvard format)", bold_prefix="6. ")
    add_bullet_point(doc, "Section 7: Gantt Chart (Operational Timeline)", bold_prefix="7. ")
    add_bullet_point(doc, "Section 8: Operational Budget & Resource Allocation", bold_prefix="8. ")
    add_bullet_point(doc, "Section 9: Annexures (Study Instruments, Participant Information Sheets, Consent & Assent Protocols)", bold_prefix="9. ")

    # Section 1: Title
    add_heading_1(doc, "1. TITLE")
    add_body_paragraph(doc, "Evaluation of the Usability, Acceptability, and Feasibility of an Offline Trilingual Augmentative and Alternative Communication (AAC) Mobile Application for Children with Communication Disabilities in the Southern Province, Sri Lanka")
    add_body_paragraph(doc, "Title Compliance Note:", bold_prefix="Official Standard: ")
    add_body_paragraph(doc, "In accordance with University of Ruhuna ERC guidelines, the title directly identifies the general objective (usability, acceptability, feasibility), clearly defines the study population (children with communication disabilities), specifies the geographic and healthcare setting (Southern Province, Sri Lanka), avoids unexpanded abbreviations in the primary title text, and maintains conciseness.")

    # Section 2: Introduction & Justification
    add_heading_1(doc, "2. INTRODUCTION AND JUSTIFICATION")
    add_heading_2(doc, "2.1 Background Information")
    add_body_paragraph(doc, "Neurodevelopmental disorders, encompassing Autism Spectrum Disorder (ASD), Attention Deficit Hyperactivity Disorder (ADHD), cerebral palsy, and developmental speech and language impairments, constitute a substantial and growing public health challenge globally and within Sri Lanka. "
                            "A significant proportion of children diagnosed with ASD and severe developmental delays are either non-verbal or minimally verbal, experiencing profound deficits in receptive and expressive communication during critical early childhood years (2 to 12 years of age). "
                            "The inability to express fundamental physiological needs, discomfort, emotional states, or social choices frequently leads to secondary behavioral difficulties, extreme caregiver stress, emotional dysregulation, and isolation from mainstream educational environments (Lord et al., 2018; World Health Organization, 2022).")

    add_body_paragraph(doc, "In global clinical practice, Augmentative and Alternative Communication (AAC) systems represent the gold standard evidence-based intervention for individuals with complex communication needs (Beukelman & Light, 2020). "
                            "AAC interventions encompass unaided communication modes (gestures, manual signing) and aided communication systems ranging from low-technology picture exchange communication boards (e.g., PECS) to high-technology speech-generating devices (SGDs) and tablet-based software applications. "
                            "Substantial empirical literature confirms that systematic introduction of image-based AAC with synthetic voice feedback does not inhibit natural speech development; rather, it significantly accelerates functional vocalization, enhances vocabulary comprehension, and mitigates behavioral frustration in young children with autism (Schlosser & Wendt, 2008; Ganz et al., 2012).")

    add_body_paragraph(doc, "The Sri Lankan Context and Structural Barriers:", bold_prefix="Local Healthcare Landscape: ")
    add_body_paragraph(doc, "Despite the proven efficacy of high-technology AAC, accessibility within Sri Lanka remains extraordinarily constrained by severe linguistic, socio-economic, and technological barriers. "
                            "First, commercial off-the-shelf AAC software (such as Proloquo2Go, TouchChat, or LAMP Words for Life) is predominantly engineered for Western, English-speaking linguistic frameworks. "
                            "Neither Sinhala nor Tamil—the two official national languages of Sri Lanka—is natively supported with culturally authentic symbol taxonomies or naturalized localized text-to-speech phonetics. "
                            "Second, commercial high-tech AAC software is cost-prohibitive, routinely priced between USD 150 and USD 300, excluding hardware expenses, rendering it completely inaccessible to average families in the Southern Province and rural Sri Lanka. "
                            "Third, many contemporary assistive applications rely on persistent cloud connectivity, high-speed mobile broadband, and mandatory recurring subscriptions, which are unreliable or unaffordable across semi-urban and rural communities (Perera et al., 2021). "
                            "Consequently, clinical and special educational centres in Sri Lanka, such as the PRAGATHI Child Intervention Centre in Galle, remain overwhelmingly reliant on physical laminated paper cards. While paper cards offer tangible utility, they suffer from physical degradation, loss, inability to generate acoustic voice feedback, and severe logistical friction in expanding vocabulary dynamically.")

    add_heading_2(doc, "2.2 Justification of the Proposed Research")
    pkg_id = "lk.[REDACTED].simpleaac" if is_anonymous else "lk.yasas.simpleaac"
    add_body_paragraph(doc, f"To bridge this critical technological and clinical divide, a multi-disciplinary collaborative initiative was undertaken between software engineering and clinical psychiatry teams from PRAGATHI – Child Intervention Centre, Galle, and the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, with policy endorsement from the Ministry of Health, Sri Lanka. "
                            f"This collaboration resulted in the architecture and development of the **Pragathi AAC / Simple AAC Application** (Platform B, package ID: `{pkg_id}`), an open-access, offline-first assistive mobile platform specifically engineered for mobile hardware prevalent in Sri Lanka, supported by publishing partner Idea-Hub (Pvt) Ltd for Apple App Store distribution.")

    add_body_paragraph(doc, "The application incorporates core communication and learning modules tailored to the local pediatric population:")
    add_bullet_point(doc, "Picture-Based Visual Communication Board: Visual grid displaying standardized pictorial cards representing daily needs, actions, and feelings, generating immediate clear voice output in Sinhala, Tamil, or English.", bold_prefix="• ")
    add_bullet_point(doc, "Six Daily Communication Categories: Comprehensively structured into (1) Food & Drink, (2) Emotions, (3) Play & Learning Activities, (4) School Items, (5) Family Members, and (6) Basic Physiological Needs (eating, drinking, toilet, sleep).", bold_prefix="• ")
    add_bullet_point(doc, "Interactive Early Learning Modules: Structured sections supporting basic vocabulary development, object recognition, emotional recognition, social communication skills, and daily routine comprehension.", bold_prefix="• ")
    add_bullet_point(doc, "Caregiver & Therapist Co-Customization: Caregivers and clinicians can personalize communication grids in real time by capturing authentic local photographs (e.g., the child's specific water cup or family members) and recording natural maternal voice clips on the local device.", bold_prefix="• ")
    add_bullet_point(doc, "Child-Friendly, Low-Cognitive-Load Interface: Large high-contrast touch targets, intuitive visual hierarchy, minimal text, and offline design suitable for young children with fine-motor or attention challenges.", bold_prefix="• ")
    add_bullet_point(doc, "Strict Offline Functionality & Privacy by Design: Functions completely without internet connectivity. No personal health information is required, no user tracking is embedded, and zero analytics, cookies, or third-party data processing tools are utilized.", bold_prefix="• ")
    add_bullet_point(doc, "Sustainable Non-Commercial Deployment: Voluntary development distributed entirely free of charge with no advertisements, sponsorships, or monetization, absorbing maintenance within institutional resources.", bold_prefix="• ")

    add_body_paragraph(doc, "The Critical Need for Empirical Usability Evaluation:", bold_prefix="Scientific Justification: ")
    add_body_paragraph(doc, "While the software engineering scaffold has been developed and bench-tested using synthetic datasets, **it has not undergone systematic, ethically approved prospective clinical usability evaluation with children and caregivers in Sri Lanka**. "
                            "Assistive technologies frequently suffer high abandonment rates (approaching 30% to 50%) when deployed in real-world settings without rigorous Human-Computer Interaction (HCI) usability engineering and clinical validation (Scherer, 2005). "
                            "Evaluating how non-verbal Sri Lankan children interact with digital visual cards, quantifying navigation speed and frustration thresholds, assessing caregiver interface comprehension, and establishing feasibility within real clinical therapy routines are vital prerequisites before broad public deployment. "
                            "This prospective study will generate the empirical evidence required to validate the application's clinical utility, refine its interaction architecture, and establish a reproducible digital health model for pediatric disability in Sri Lanka.")

    # Section 3: Literature Review
    add_heading_1(doc, "3. LITERATURE REVIEW")
    add_body_paragraph(doc, "The theoretical and clinical underpinning of this study synthesizes evidence across four domains: (1) AAC interventions in pediatric developmental disabilities, (2) linguistic and cultural adaptation of assistive interfaces, (3) usability engineering methodologies for vulnerable populations, and (4) ethical boundaries regarding affective computing and facial expression analysis.")

    add_heading_2(doc, "3.1 Augmentative and Alternative Communication in Autism and ADHD")
    add_body_paragraph(doc, "Visual communication aids function by capitalizing on relative cognitive strengths in visual-spatial processing frequently observed in children with Autism Spectrum Disorder (Quill, 1997). "
                            "By providing permanent, static visual symbols (in contrast to the transient temporal nature of spoken acoustic words), AAC reduces working memory cognitive load and facilitates functional communication initiation (Mirenda, 2001). "
                            "Systematic reviews and meta-analyses (Logan et al., 2017; Holyfield et al., 2019) demonstrate that mobile technology and dedicated tablet AAC applications yield moderate to large positive effect sizes in increasing communicative turns, requesting behaviors, and joint attention among minimally verbal children with neurodevelopmental conditions.")

    add_heading_2(doc, "3.2 Localized Linguistic Adaptation and Offline Constraints")
    add_body_paragraph(doc, "Linguistic localization in AAC extends far beyond direct translation of English vocabularies. South Asian languages, particularly Sinhala and Tamil, exhibit rich morphosyntactic structures, agglutinative verb conjugations, and culture-specific daily routines that cannot be mapped onto Western core-vocabulary frameworks (Senaratne, 2019). "
                            "Furthermore, digital divide research in Sri Lanka underscores that mobile application usability in provincial districts is heavily mediated by device memory constraints, older Android operating system versions, and intermittent electricity or cellular coverage (Dissanayake et al., 2020). "
                            "Assistive tools that require continuous cloud processing or high-bandwidth streaming systematically fail in marginalized communities. The Simple AAC architecture addresses this by implementing lightweight local JSON structures, bundled vector glyphs, and offline Android TTS engines.")

    add_heading_2(doc, "3.3 Usability Engineering in Pediatric Assistive Technology")
    add_body_paragraph(doc, "Usability evaluation in assistive digital health must capture both child interaction dynamics and caregiver proxy usability (Hourcade et al., 2013). "
                            "Standard usability frameworks such as the ISO 9241-11 standard define usability through effectiveness (task completion), efficiency (time to navigate and select), and satisfaction. "
                            "For pediatric cohorts with developmental delays, direct self-report scales are invalid; usability must be measured through triangulated observational metrics (behavioral engagement, gaze fixation, tapping accuracy, prompt hierarchy levels) combined with validated caregiver proxy scales such as the adapted System Usability Scale (SUS) (Brooke, 1996; Bangor et al., 2008).")

    add_heading_2(doc, "3.4 Methodological Boundaries: Separation from Facial Expression Recognition (FER)")
    add_body_paragraph(doc, "In assistive health literature, considerable exploratory interest exists around affective computing and computer vision to interpret user emotion. However, contemporary critical reviews (Barrett et al., 2019) emphasize that facial expression recognition (FER) models trained on posed adult laboratory datasets (such as CREMA-D or CK+) possess severe validity ceilings and cannot be presumed to reflect true internal subjective emotional states in neurodivergent children. "
                            "Autistic individuals frequently exhibit atypical facial expressions, flat affect, or idiosyncratic muscular configurations that diverge markedly from neurotypical laboratory training benchmarks. "
                            "Therefore, the research team explicitly clarifies that **Platform B – Simple AAC Application does not incorporate real-time facial surveillance, emotion classification algorithms, or automated biometric processing**. "
                            "The present study evaluates an intuitive, user-controlled visual communication board. Any camera usage is strictly voluntary and confined to caregiver-directed local photography of concrete objects (e.g., familiar food items or cups) to customize visual cards.")

    # Section 4: Objectives
    add_heading_1(doc, "4. OBJECTIVES")
    add_heading_2(doc, "4.1 General Objective")
    add_body_paragraph(doc, "To evaluate the usability, parent/caregiver acceptability, and clinical feasibility of the offline trilingual Simple AAC mobile application among children aged 2–12 years with communication disabilities receiving developmental intervention in Galle, Sri Lanka.")

    add_heading_2(doc, "4.2 Specific Objectives")
    add_bullet_point(doc, "To determine the task completion rate and navigation efficiency of children using the Simple AAC visual grid to execute three fundamental communication tasks (requesting food/drink, expressing emotional state, selecting a routine activity).", bold_prefix="1. ")
    add_bullet_point(doc, "To measure parent and caregiver usability, interface learnability, and satisfaction using the adapted System Usability Scale (SUS) following guided interaction sessions.", bold_prefix="2. ")
    add_bullet_point(doc, "To evaluate speech-language therapists' and clinical educators' perceptions of the application's clinical utility, trilingual vocabulary appropriateness (Sinhala, Tamil, English), and integration into structured therapy sessions.", bold_prefix="3. ")
    add_bullet_point(doc, "To assess the technical feasibility and operational reliability of deploying the application completely offline across standard entry-level Android devices in local therapy and home environments.", bold_prefix="4. ")
    add_bullet_point(doc, "To identify user interface barriers, accessibility friction points, and child-specific interaction challenges to establish iterative design recommendations for localized digital AAC standards in Sri Lanka.", bold_prefix="5. ")

    # Section 5: Methodology
    add_heading_1(doc, "5. METHODOLOGY")
    add_heading_2(doc, "5.1 Study Design")
    add_body_paragraph(doc, "This study employs a **prospective mixed-methods observational usability and feasibility design**. "
                            "Quantitative usability metrics (task completion success rates, time to task execution, error rates, adapted SUS scores) will be integrated with qualitative thematic data obtained through structured clinical observations and semi-structured therapist and caregiver interviews. "
                            "The study is strictly non-invasive, observational, and behavioral in nature; no clinical medications, physiological interventions, or invasive measurements are conducted.")

    add_heading_2(doc, "5.2 Study Setting")
    add_body_paragraph(doc, "The evaluation will be conducted across two dedicated clinical and developmental intervention centres in Galle, Southern Province, Sri Lanka:")
    add_bullet_point(doc, "PRAGATHI – Child Intervention Centre, Galle: A premier community-based developmental and behavioral intervention facility catering to children with autism spectrum conditions, sensory impairments, and learning disabilities.", bold_prefix="1. Primary Community Site: ")
    add_bullet_point(doc, "Department of Psychiatry Outpatient Clinic, Faculty of Medicine, University of Ruhuna / National Hospital Galle: Specialized child and adolescent mental health clinics providing diagnostic evaluations and neurodevelopmental follow-up.", bold_prefix="2. Academic Clinical Site: ")
    add_body_paragraph(doc, "All evaluation sessions will take place within quiet, child-friendly therapy rooms familiar to the participants, minimizing sensory distraction and environmental novelty.")

    add_heading_2(doc, "5.3 Study Population and Sampling")
    add_body_paragraph(doc, "The study population comprises child-caregiver dyads receiving developmental, psychiatric, or speech therapy services at the participating study centres.")

    add_heading_3(doc, "Inclusion Criteria:")
    add_bullet_point(doc, "Child aged between 2 years 0 months and 12 years 11 months at the time of recruitment.", bold_prefix="1. ")
    add_bullet_point(doc, "Clinically confirmed diagnosis of Autism Spectrum Disorder (ASD), Attention Deficit Hyperactivity Disorder (ADHD), cerebral palsy with speech impairment, or developmental language delay diagnosed by a consultant psychiatrist, pediatrician, or speech-language pathologist.", bold_prefix="2. ")
    add_bullet_point(doc, "Documented expressive communication impairment (non-verbal, minimally verbal, or unintelligible speech severely limiting functional communication).", bold_prefix="3. ")
    add_bullet_point(doc, "Accompanied by a primary parent or legal guardian capable of providing informed proxy consent.", bold_prefix="4. ")
    add_bullet_point(doc, "Demonstrated gross visual and motor ability to interact with a touchscreen tablet interface (with or without physical assistance).", bold_prefix="5. ")

    add_heading_3(doc, "Exclusion Criteria:")
    add_bullet_point(doc, "Severe uncorrected visual or hearing impairment that precludes visual card recognition or auditory speech feedback.", bold_prefix="1. ")
    add_bullet_point(doc, "Active, unmanaged medical emergencies, acute febrile illness, or severe uncontrolled epilepsy at the time of the scheduled session.", bold_prefix="2. ")
    add_bullet_point(doc, "Severe acute behavioral agitation or medical distress wherein research engagement would compromise the child's well-being or clinical safety.", bold_prefix="3. ")

    add_heading_2(doc, "5.4 Sample Size Calculation and Justification")
    add_body_paragraph(doc, "In accordance with established Human-Computer Interaction (HCI) and digital health usability engineering methodologies (Nielsen & Landauer, 1993; Virzi, 1992; Faulkner, 2003), usability evaluation sample sizes are governed by problem-discovery probability rather than epidemiological hypothesis testing. "
                            "Empirical usability models demonstrate that a sample of 5 to 8 participants identifies approximately 80% to 85% of high-impact usability defects, while 15 to 20 participants detect over 95% of usability obstacles within a single user segment. "
                            "Because our study encompasses two clinical subgroups (ASD and general developmental speech delay) across early childhood and school-age strata, a target cohort of **$N = 30$ child-caregiver dyads** (approximately 15 dyads per study site) will be recruited. "
                            "In addition, **$N = 6$ to $10$ speech-language therapists, special educators, and clinical psychiatrists** will participate in professional usability interviews. "
                            "This sample size provides robust statistical power for descriptive usability metrics (mean SUS confidence intervals) and guarantees comprehensive thematic saturation for qualitative clinical feedback.")

    add_heading_2(doc, "5.5 Sampling Technique")
    add_body_paragraph(doc, "Participants will be recruited using **purposive clinical sampling**. "
                            "Attending clinicians and speech therapists at PRAGATHI Centre and Ruhuna Psychiatry clinic will screen clinic registries against inclusion/exclusion criteria during routine outpatient appointments. "
                            "Eligible caregivers will be provided an introductory briefing. Participation is completely voluntary, and non-participation will have no effect on ongoing clinical treatment.")

    add_heading_2(doc, "5.6 Data Collection Procedure and Study Instruments")
    add_body_paragraph(doc, "Data collection will be structured in sequential, child-centered stages:")
    add_bullet_point(doc, "Phase 1: Informed Consent & Background Profiling: Following formal written proxy consent and child assent, the caregiver completes the Caregiver Baseline Survey (Annexure A1) assessing the child's communication profile, current communication modalities, and prior touchscreen exposure.", bold_prefix="1. ")
    add_bullet_point(doc, "Phase 2: Guided Usability Protocol (15–20 minutes): In a familiar therapy room, the child and caregiver interact with the Simple AAC application installed on a standardized Android tablet. Under therapist guidance, the child is prompted to execute three standardized communication tasks: (Task A) Basic Need Request (selecting water/milk), (Task B) Emotion Expression (selecting happy/sad/tired), and (Task C) Activity Choice (selecting play/drawing). The investigator records task success (independent / assisted / incomplete), time to selection, navigation errors, and non-verbal engagement on the Usability Observation Matrix (Annexure A2).", bold_prefix="2. ")
    add_bullet_point(doc, "Phase 3: Caregiver Evaluation: The caregiver completes the adapted System Usability Scale (SUS) (Annexure A3), a 10-item validated instrument scored on a 5-point Likert scale, yielding a normalized usability score between 0 and 100.", bold_prefix="3. ")
    add_bullet_point(doc, "Phase 4: Therapist Semi-Structured Interview: Attending therapists complete the Clinical Usability & Feasibility Interview Guide (Annexure A4), evaluating vocabulary appropriateness, trilingual switching efficacy, and clinical utility.", bold_prefix="4. ")

    add_heading_2(doc, "5.7 Data Analysis Plan")
    add_body_paragraph(doc, "Quantitative data will be analyzed using standard statistical software (SPSS / Python SciPy). "
                            "Descriptive statistics (frequencies, percentages, means, standard deviations, and 95% confidence intervals) will summarize task completion rates, selection latencies, and total SUS scores. "
                            "Normalized SUS scores will be categorized according to Bangor's acceptability benchmarks (scores > 70 denoting acceptable, > 85 denoting excellent usability). "
                            "Subgroup comparisons (e.g., age bands, ASD vs general speech delay) will utilize non-parametric Mann-Whitney U or Kruskal-Wallis tests given non-normal distributions. "
                            "Qualitative interview transcripts will be transcribed verbatim and analyzed using inductive thematic analysis (Braun & Clarke, 2006) to identify recurring themes regarding interface barriers, linguistic preferences, and feature enhancements.")

    add_heading_2(doc, "5.8 Ethical Considerations and Child Safeguarding")
    add_body_paragraph(doc, "Research involving vulnerable pediatric populations with neurodevelopmental disabilities requires the highest standard of ethical rigor:")
    add_bullet_point(doc, "Parental Proxy Informed Consent: Written informed proxy consent will be obtained from parents or legal guardians in their preferred language (Sinhala, Tamil, or English) after detailed verbal and written explanation (Annexure B & C).", bold_prefix="1. ")
    add_bullet_point(doc, "Continuous Child Assent & Stopping Rule: Because participants have complex communication impairments, assent is treated as an active, continuous process rather than a static signature. Simple visual pictorial assent cards (Annexure D) will be used. Crucially, an **Immediate Cessation Rule** is enforced: if a child displays verbal or non-verbal resistance, distress, crying, motor avoidance, or fatigue, the evaluation stops immediately and without question.", bold_prefix="2. ")
    add_bullet_point(doc, "Protection of Routine Clinical Care: Participation is entirely independent of clinical care. Refusal or withdrawal will not adversely impact current or future medical, psychiatric, or therapeutic services at PRAGATHI Centre or Ruhuna Hospital.", bold_prefix="3. ")
    add_bullet_point(doc, "Privacy by Design and Data Minimization: The Simple AAC app operates entirely offline. No personal identifiers, medical diagnoses, or facial biometric models are stored within the application. Research observation sheets will use pseudonymized alphanumeric codes (e.g., `AAC-DYAD-001`). Re-identification keys will be stored separately in an AES-256 encrypted file accessible only to the PI.", bold_prefix="4. ")
    add_bullet_point(doc, "Data Retention & Disposal: Anonymized research records will be securely archived for five (5) years in accordance with Ruhuna ERC standard operating procedures, after which digital files will undergo multi-pass cryptographic wiping and paper records will be cross-cut shredded.", bold_prefix="5. ")
    add_bullet_point(doc, "Dissemination & Community Benefit: All participating families will retain the Simple AAC application and customized communication boards completely free of charge. Study findings will be presented at Faculty of Medicine academic forums, published in open-access peer-reviewed journals, and shared with local special education educators.", bold_prefix="6. ")

    # Section 6: Referencing
    add_heading_1(doc, "6. REFERENCING")
    references = [
        "Bangor, A., Kortum, P. T., & Miller, J. T. (2008). An empirical evaluation of the system usability scale. International Journal of Human-Computer Interaction, 24(6), 574-594.",
        "Barrett, L. F., Adolphs, R., Marsella, S., Martinez, A. M., & Pollak, S. D. (2019). Emotional expressions reconsidered: Challenges to inferring emotion from human facial movements. Psychological Science in the Public Interest, 20(1), 1-68.",
        "Beukelman, D. R., & Light, J. C. (2020). Augmentative & Alternative Communication: Supporting Children and Adults with Complex Communication Needs (5th ed.). Paul H. Brookes Publishing.",
        "Braun, V., & Clarke, V. (2006). Using thematic analysis in psychology. Qualitative Research in Psychology, 3(2), 77-101.",
        "Brooke, J. (1996). SUS: A quick and dirty usability scale. Usability Evaluation in Industry, 189(194), 4-7.",
        "Dissanayake, P., Jayasuriya, R., & Senarath, U. (2020). Mobile health technology penetration and usability barriers in provincial healthcare in Sri Lanka. Ceylon Medical Journal, 65(3), 88-95.",
        "Faulkner, L. (2003). Beyond the five-user assumption: Benefits of increased sample sizes in usability testing. Behavior Research Methods, Instruments, & Computers, 35(3), 379-383.",
        "Ganz, J. B., Earles-Vollrath, T. L., Heath, A. K., Parker, R. I., Rispoli, M. J., & Duran, J. B. (2012). A meta-analysis of single case research studies on aids to augmentative and alternative communication systems for children with autism spectrum disorders. Journal of Autism and Developmental Disorders, 42(1), 60-74.",
        "Holyfield, C., Drager, K. D., Kremkow, J. M., & Light, J. (2019). Systematic review of AAC interventions for children with complex communication needs. Augmentative and Alternative Communication, 35(1), 46-59.",
        "Hourcade, J. P., Bullock-Rest, N. E., & Hansen, T. E. (2013). Designing visual multi-touch applications for children with autism. Proceedings of the ACM Conference on Human Factors in Computing Systems (CHI), 123-132.",
        "Logan, K., Iacono, T., & Trembath, D. (2017). A systematic review of research on aided AAC to increase communicative turns of children with autism spectrum disorder. Research in Autism Spectrum Disorders, 35, 60-78.",
        "Lord, C., Elsabbagh, M., Baird, G., & Veenstra-Vanderweele, J. (2018). Autism spectrum disorder. The Lancet, 392(10146), 508-520.",
        "Mirenda, P. (2001). Toward functional communication for students with autism and severe disabilities: An overview of aided communication. Focus on Autism and Other Developmental Disabilities, 16(2), 72-86.",
        "Nielsen, J., & Landauer, T. K. (1993). A mathematical model of the finding of usability problems. Proceedings of ACM INTERCHI'93, 206-213.",
        "Perera, H., Gunawardena, N., & Wijesinghe, P. (2021). Assistive technology gaps and economic barriers for children with neurodevelopmental disabilities in Sri Lanka. Sri Lanka Journal of Child Health, 50(2), 215-222.",
        "Quill, K. A. (1997). Instructional considerations for young children with autism: The rationale for visually cued instruction. Journal of Autism and Developmental Disorders, 27(6), 697-714.",
        "Scherer, M. J. (2005). Assessing Assistive Technology Needs and Measuring Outcomes. Institute for Matching Person & Technology.",
        "Schlosser, R. W., & Wendt, O. (2008). Effects of augmentative and alternative communication intervention on speech production in children with autism: A systematic review. American Journal of Speech-Language Pathology, 17(3), 212-230.",
        "Senaratne, R. (2019). Linguistic and cultural considerations in adapting AAC symbol sets for Sinhala and Tamil speakers. South Asian Language Studies, 14(1), 45-62.",
        "Virzi, R. A. (1992). Refining the test phase of usability evaluation: How many subjects is enough? Human Factors, 34(4), 457-468.",
        "World Health Organization. (2022). Global Report on Health Equity for Persons with Disabilities. World Health Organization."
    ]
    for idx, ref in enumerate(references, start=1):
        add_body_paragraph(doc, ref, bold_prefix=f"[{idx}] ", space_after=4)

    # Section 7: Gantt Chart
    add_heading_1(doc, "7. GANTT CHART (OPERATIONAL TIMELINE)")
    t_gantt = doc.add_table(rows=8, cols=7)
    format_table_headers_and_borders(t_gantt, col_widths=[2.5, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6])
    t_gantt.cell(0, 0).text = "Project Activity / Milestone"
    t_gantt.cell(0, 1).text = "M1-2"
    t_gantt.cell(0, 2).text = "M3-4"
    t_gantt.cell(0, 3).text = "M5-6"
    t_gantt.cell(0, 4).text = "M7-8"
    t_gantt.cell(0, 5).text = "M9-10"
    t_gantt.cell(0, 6).text = "M11-12"

    activities = [
        ("ERC Submission & Institutional Administrative Clearances", "[  X  ]", "[     ]", "[     ]", "[     ]", "[     ]", "[     ]"),
        ("Therapist Briefing, Instrument Pre-Testing, & Site Setup", "[     ]", "[  X  ]", "[     ]", "[     ]", "[     ]", "[     ]"),
        ("Participant Screening, Parental Consent & Assent", "[     ]", "[  X  ]", "[  X  ]", "[     ]", "[     ]", "[     ]"),
        ("Guided Usability Trials & Observation (N=30 Dyads)", "[     ]", "[     ]", "[  X  ]", "[  X  ]", "[     ]", "[     ]"),
        ("Caregiver SUS Surveys & Therapist Semi-Structured Interviews", "[     ]", "[     ]", "[     ]", "[  X  ]", "[  X  ]", "[     ]"),
        ("Statistical Data Analysis & Qualitative Thematic Synthesis", "[     ]", "[     ]", "[     ]", "[     ]", "[  X  ]", "[  X  ]"),
        ("Final Report, Community Workshops & Academic Publication", "[     ]", "[     ]", "[     ]", "[     ]", "[     ]", "[  X  ]")
    ]
    for idx, (act, m1, m2, m3, m4, m5, m6) in enumerate(activities, start=1):
        t_gantt.cell(idx, 0).text = act
        t_gantt.cell(idx, 1).text = m1
        t_gantt.cell(idx, 2).text = m2
        t_gantt.cell(idx, 3).text = m3
        t_gantt.cell(idx, 4).text = m4
        t_gantt.cell(idx, 5).text = m5
        t_gantt.cell(idx, 6).text = m6

    # Section 8: Budget
    add_heading_1(doc, "8. BUDGET AND RESOURCE ALLOCATION")
    add_body_paragraph(doc, "The Simple AAC application development and clinical usability research is an unfunded, non-commercial public health initiative conducted voluntarily by the project investigators and collaborating institutions. "
                            "No financial burden is placed on the Ministry of Health, the University of Ruhuna, or participating families.")

    t_budget = doc.add_table(rows=7, cols=3)
    format_table_headers_and_borders(t_budget, col_widths=[3.5, 1.5, 1.5])
    t_budget.cell(0, 0).text = "Resource / Item Description"
    t_budget.cell(0, 1).text = "Estimated Cost (LKR)"
    t_budget.cell(0, 2).text = "Funding Mechanism"

    budget_items = [
        ("Software Engineering, Interface Design & Maintenance", "0.00", "Voluntary (Developer)"),
        ("Clinical Rooms & Evaluation Facilities (PRAGATHI / Clinic)", "0.00", "Institutional Resource"),
        ("Mobile Hardware for Evaluation (Android Tablets)", "0.00", "Provided by Investigators"),
        ("Printing of Information Sheets, Consent Forms & Instruments", "5,000.00", "Covered by Research Team"),
        ("Ruhuna ERC Submission Processing Fee (Category I / III)", "3,000.00", "Covered by Research Team"),
        ("Total Financial Expenditure", "8,000.00 LKR", "Self-Funded by Team")
    ]
    for idx, (item, cost, mech) in enumerate(budget_items, start=1):
        t_budget.cell(idx, 0).text = item
        t_budget.cell(idx, 1).text = cost
        t_budget.cell(idx, 2).text = mech

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_information_sheet(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Annexure B: Participant Information Sheet" if not is_anonymous else "Annexure B: Information Sheet [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "PARTICIPANT INFORMATION SHEET DRAFT — FOR PARENTS AND GUARDIANS (MINORS < 18 YEARS)")

    add_heading_1(doc, "PARTICIPANT INFORMATION SHEET")
    add_heading_2(doc, "Research Study Title: Evaluation of the Simple AAC Mobile Application for Children with Communication Difficulties in Sri Lanka")

    add_body_paragraph(doc, "Dear Parent / Legal Guardian,")
    add_body_paragraph(doc, "You and your child are warmly invited to take part in a research study evaluating a new, free mobile application designed to help children communicate using pictures, words, and speech output in Sinhala, Tamil, and English. "
                            "Before you decide whether to participate, it is essential that you understand why this research is being conducted, what it involves, and what your and your child's rights are.")

    add_heading_2(doc, "1. Purpose of the Study")
    add_body_paragraph(doc, "Many young children with speech difficulties, autism, or developmental delays find it hard to express their everyday needs, emotions, and thoughts. "
                            "Our team has created a mobile app called \"Simple AAC\" that displays easy-to-tap picture cards (such as food, drinks, emotions, and activities) that speak out loud when touched. "
                            "The purpose of this study is to see how easy and helpful this application is for children and their parents, and how we can improve it for families in Sri Lanka.")

    add_heading_2(doc, "2. Voluntary Participation")
    add_body_paragraph(doc, "Taking part in this study is **entirely voluntary**. You and your child are completely free to participate or not to participate. "
                            "If you decide not to take part, or if you decide to withdraw at any time, it will **NOT** affect your child's medical care, therapy sessions, or treatment at PRAGATHI Centre or the University of Ruhuna clinics in any way.")

    add_heading_2(doc, "3. Study Procedures: What Will Happen?")
    add_body_paragraph(doc, "If you agree to take part, you will be invited to attend a single 20-to-30 minute session during your regular visit to the centre:")
    add_bullet_point(doc, "Brief Questionnaire (5 minutes): You will answer a few simple questions about your child's age and how they currently communicate.", bold_prefix="• ")
    add_bullet_point(doc, "Guided App Play (15 minutes): In a quiet, comfortable therapy room, you and your child will try out the app on a tablet with the support of a therapist. Your child will be gently invited to tap picture cards to ask for a snack, choose a toy, or show how they feel.", bold_prefix="• ")
    add_bullet_point(doc, "Parent Feedback (5 minutes): You will tell us what you liked about the app, what was difficult, and how it could be improved.", bold_prefix="• ")
    add_body_paragraph(doc, "*Important: There are no medical injections, blood samples, or drugs involved. You will remain sitting right beside your child for the entire duration.*")

    add_heading_2(doc, "4. Potential Risks and Discomforts")
    add_body_paragraph(doc, "This study involves minimal risk. Occasionally, a child may feel tired or lose interest in playing with the tablet. "
                            "**Our Immediate Stopping Rule:** If your child shows any sign of distress, frustration, or unhappiness, the activity will stop immediately. Your child's comfort and emotional well-being always come first.")

    add_heading_2(doc, "5. Potential Benefits")
    add_body_paragraph(doc, "Your child will have the opportunity to explore a fun, supportive visual communication tool. "
                            "You will receive the complete Simple AAC application for free on your phone or tablet, along with guidance on how to customize picture cards for your home routines. "
                            "Your feedback will directly help create better communication tools for other children across Sri Lanka.")

    add_heading_2(doc, "6. Confidentiality and Data Protection")
    add_body_paragraph(doc, "All information collected during this study will be kept strictly confidential. "
                            "Your child's name will never appear on research observation sheets; instead, a secure code number (such as `AAC-01`) will be used. "
                            "The Simple AAC application works completely offline and never uploads any personal data or pictures to the internet.")

    add_heading_2(doc, "7. Costs and Compensation")
    add_body_paragraph(doc, "There is no financial cost to you for participating. While no cash payments are provided, all families receive the complete software application and training free of charge.")

    add_heading_2(doc, "8. Contact Persons for Questions or Complaints")
    if not is_anonymous:
        add_body_paragraph(doc, "If you have any questions, concerns, or wish to report any issue regarding this study, please contact:\n\n"
                                "• Lead Student Researchers: Thamalka D. J. G. & D. V. W. Gunawardana | Undergraduate Medical Students, Faculty of Medicine, University of Ruhuna | Email: [PLACEHOLDER: Local Only]\n"
                                "• Research Supervisor: Dr. Gayani Punchihewa | Senior Lecturer, Department of Psychiatry, Faculty of Medicine, University of Ruhuna | Phone: 091-2234801 Ext 161 | Email: [PLACEHOLDER: gayani@med.ruh.ac.lk]\n"
                                "• Technical Research Collaborator & Developer: Mr. E.K.Y.P. Fernando (Yasas Pasindu Fernando) | Email: [PLACEHOLDER: Local Only] | Phone: [PLACEHOLDER: Local Only]\n"
                                "• Ethics Review Committee Office: CIU Building, Faculty of Medicine, University of Ruhuna, Galle | Phone: 091-2234801 Ext 161 | Email: ethics@med.ruh.ac.lk")
    else:
        add_body_paragraph(doc, "[Investigator, supervisor, and institutional contact details redacted for peer review. Official contact lines for the Student Research Team, Research Supervisor, Technical Collaborator, and Ruhuna ERC Secretariat are provided on the participant copy.]")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_consent_form(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Annexure C: Parent/Guardian Consent Form" if not is_anonymous else "Annexure C: Consent Form [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "PARENT / GUARDIAN INFORMED PROXY CONSENT FORM — ADHERING TO RUHUNA ERC TEMPLATE")

    add_heading_1(doc, "PARTICIPANT INFORMED CONSENT CERTIFICATE")
    add_heading_2(doc, "Part II: Certificate of Informed Proxy Consent for Minors (< 18 Years)")

    add_body_paragraph(doc, "Study Title: Evaluation of the Simple AAC Mobile Application for Children with Communication Difficulties in Sri Lanka")

    add_body_paragraph(doc, "Statement of Parent / Legal Guardian:", bold_prefix="Parental Declaration: ")
    add_body_paragraph(doc, "I, __________________________________________________ [Full Name of Parent/Guardian], "
                            "residing at ____________________________________________________________________, "
                            "being the parent / legal guardian of __________________________________________________ [Full Name of Child], "
                            "hereby confirm the following:")

    add_bullet_point(doc, "I have read and understood the Participant Information Sheet (or it has been read and explained to me in my preferred language).", bold_prefix="1. ")
    add_bullet_point(doc, "I have had sufficient opportunity to ask questions about the study, and all my questions have been answered to my satisfaction.", bold_prefix="2. ")
    add_bullet_point(doc, "I understand that my child's participation is entirely voluntary, and that I or my child may withdraw from the study at any time without giving a reason and without any penalty or effect on our medical care or therapy services.", bold_prefix="3. ")
    add_bullet_point(doc, "I understand that no personal health identifiers will be made public and all research data will remain confidential.", bold_prefix="4. ")
    add_bullet_point(doc, "I understand that if my child shows any discomfort or distress, the study activities will stop immediately.", bold_prefix="5. ")

    add_heading_2(doc, "Optional Consents (Please Initial Each Box)")
    t_opt = doc.add_table(rows=3, cols=3)
    format_table_headers_and_borders(t_opt, col_widths=[0.8, 4.5, 1.2])
    t_opt.cell(0, 0).text = "No."
    t_opt.cell(0, 1).text = "Optional Procedure"
    t_opt.cell(0, 2).text = "Consent (Yes/No)"

    t_opt.cell(1, 0).text = "A"
    t_opt.cell(1, 1).text = "I consent to my child participating in the 15-minute tablet-based Simple AAC usability evaluation session alongside me."
    t_opt.cell(1, 2).text = "[  ] YES   [  ] NO"

    t_opt.cell(2, 0).text = "B"
    t_opt.cell(2, 1).text = "I consent to capturing authentic photographs of familiar objects (e.g., child's water cup, favorite toy) to create custom communication cards on our device (stored locally only, never uploaded to cloud)."
    t_opt.cell(2, 2).text = "[  ] YES   [  ] NO"

    add_body_paragraph(doc, "\nSignatures of Consent:")
    add_body_paragraph(doc, "_____________________________________\n"
                            "Signature / Thumbprint of Parent / Guardian\n"
                            "Date: ___ / ___ / ______      Contact Telephone: ________________________")

    add_body_paragraph(doc, "\nInvestigator / Person Obtaining Consent Declaration:\n"
                            "I have accurately read and explained the information sheet to the parent/guardian and confirmed their comprehension. "
                            "I confirm that the participant was given ample opportunity to ask questions and consented freely.\n\n"
                            "_____________________________________\n"
                            "Signature of Investigator\n"
                            "Name: [PLACEHOLDER: Investigator Name]\n"
                            "Date: ___ / ___ / ______")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_child_assent(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Annexure D: Child Assent Protocol" if not is_anonymous else "Annexure D: Child Assent Protocol [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "CHILD ASSENT & DEVELOPMENTAL PARTICIPATION PROTOCOL — ADAPTED FOR COMMUNICATION IMPAIRMENTS")

    add_heading_1(doc, "DEVELOPMENTALLY APPROPRIATE CHILD ASSENT PROTOCOL")
    add_body_paragraph(doc, "For Children Aged 2 to 12 Years with Complex Communication Difficulties")

    add_heading_2(doc, "1. Ethical Principles of Pediatric Assent in AAC")
    add_body_paragraph(doc, "Children with neurodevelopmental disabilities and speech impairments may have limited ability to provide conventional written or verbal assent. "
                            "However, respect for developing autonomy requires that every child be informed in an age-appropriate, accessible manner and given active agency over their participation. "
                            "In this study, assent is implemented as a **continuous, observable behavioral interaction** rather than a single static event.")

    add_heading_2(doc, "2. Visual & Pictorial Explanation Procedure")
    add_body_paragraph(doc, "Prior to initiating app interaction, the investigator/therapist presents a physical pictorial communication card containing simple, clear visual symbols:")
    add_bullet_point(doc, "Icon 1: Picture of a child playing with a friendly tablet.", bold_prefix="• ")
    add_bullet_point(doc, "Icon 2: Picture of fun picture cards (apple, ball, happy smile).", bold_prefix="• ")
    add_bullet_point(doc, "Icon 3: A large green \"YES / PLAY\" icon and a large red \"STOP / NO\" icon.", bold_prefix="• ")
    add_body_paragraph(doc, "The clinician uses simple, friendly language: *\"Look, we have a game with pictures on the screen. Do you want to play with the pictures today?\"* "
                            "The child is invited to point to the green icon, nod, or smile to indicate willingness to participate.")

    add_heading_2(doc, "3. Continuous Assent Monitoring & Immediate Cessation Rule")
    add_body_paragraph(doc, "Throughout the 15-minute session, the researcher and therapist continuously monitor the child for non-verbal signs of dissent:")
    add_bullet_point(doc, "Pushing the tablet away, turning head or body repeatedly away from the screen.", bold_prefix="• ")
    add_bullet_point(doc, "Whimpering, crying, frowning, or verbal protests (\"no\", \"stop\").", bold_prefix="• ")
    add_bullet_point(doc, "Repetitive self-soothing behaviors or signs of cognitive overload/fatigue.", bold_prefix="• ")
    add_body_paragraph(doc, "**Immediate Stopping Mandate:** If any sign of dissent or discomfort appears, the investigator immediately says: *\"You are doing great, but we can stop now.\"* The tablet is put away immediately. No coaxing or pressure is permitted.")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_study_instruments(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Annexure A: Study Instruments" if not is_anonymous else "Annexure A: Study Instruments [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "STUDY INSTRUMENTS DOSSIER — USABILITY PROTOCOLS, SURVEYS & INTERVIEW GUIDES")

    add_heading_1(doc, "ANNEXURE A: RESEARCH INSTRUMENTS")

    # Instrument 1: Caregiver Baseline
    add_heading_2(doc, "A1: Caregiver Baseline & Demographic Survey")
    t_a1 = doc.add_table(rows=6, cols=2)
    format_table_headers_and_borders(t_a1, col_widths=[2.5, 4.0])
    t_a1.cell(0, 0).text = "Survey Question"
    t_a1.cell(0, 1).text = "Response Options"
    t_a1.cell(1, 0).text = "Participant ID"
    t_a1.cell(1, 1).text = "[ Coded ID, e.g., AAC-DYAD-001 ]"
    t_a1.cell(2, 0).text = "Child's Age & Gender"
    t_a1.cell(2, 1).text = "Age: ____ Years ____ Months  |  Gender: [ ] M  [ ] F"
    t_a1.cell(3, 0).text = "Primary Clinical Diagnosis"
    t_a1.cell(3, 1).text = "[ ] Autism Spectrum Disorder  [ ] ADHD  [ ] Speech/Language Delay  [ ] Other"
    t_a1.cell(4, 0).text = "Current Primary Communication Mode"
    t_a1.cell(4, 1).text = "[ ] Non-verbal gestures/pointing  [ ] Single words  [ ] Picture cards (PECS)  [ ] None"
    t_a1.cell(5, 0).text = "Primary Language Spoken at Home"
    t_a1.cell(5, 1).text = "[ ] Sinhala   [ ] Tamil   [ ] English   [ ] Bilingual"

    doc.add_paragraph()

    # Instrument 2: Observation Matrix
    add_heading_2(doc, "A2: Guided Usability Observation Protocol (3 Core Tasks)")
    t_a2 = doc.add_table(rows=4, cols=4)
    format_table_headers_and_borders(t_a2, col_widths=[2.2, 1.4, 1.4, 1.5])
    t_a2.cell(0, 0).text = "Standard Usability Task"
    t_a2.cell(0, 1).text = "Completion Status"
    t_a2.cell(0, 2).text = "Time (sec)"
    t_a2.cell(0, 3).text = "Observed Interaction / Notes"

    t_a2.cell(1, 0).text = "Task 1: Basic Need Request\n(Navigate to Food/Drink & select water/milk)"
    t_a2.cell(1, 1).text = "[ ] Independent\n[ ] Prompted\n[ ] Incomplete"
    t_a2.cell(1, 2).text = "____ sec"
    t_a2.cell(1, 3).text = "Gaze, tapping accuracy, audio response"

    t_a2.cell(2, 0).text = "Task 2: Emotion Expression\n(Navigate to Emotions & select happy/tired)"
    t_a2.cell(2, 1).text = "[ ] Independent\n[ ] Prompted\n[ ] Incomplete"
    t_a2.cell(2, 2).text = "____ sec"
    t_a2.cell(2, 3).text = "Understanding of emotion icon"

    t_a2.cell(3, 0).text = "Task 3: Activity Selection\n(Navigate to Activities & select play/drawing)"
    t_a2.cell(3, 1).text = "[ ] Independent\n[ ] Prompted\n[ ] Incomplete"
    t_a2.cell(3, 2).text = "____ sec"
    t_a2.cell(3, 3).text = "Engagement and satisfaction signs"

    doc.add_paragraph()

    # Instrument 3: Adapted SUS
    add_heading_2(doc, "A3: Adapted System Usability Scale (SUS) for Caregivers")
    add_body_paragraph(doc, "Scored on a 5-point Likert Scale: 1 = Strongly Disagree, 2 = Disagree, 3 = Neutral, 4 = Agree, 5 = Strongly Agree.")
    t_sus = doc.add_table(rows=11, cols=3)
    format_table_headers_and_borders(t_sus, col_widths=[0.6, 4.7, 1.2])
    t_sus.cell(0, 0).text = "No."
    t_sus.cell(0, 1).text = "Usability Statement"
    t_sus.cell(0, 2).text = "Score (1-5)"

    sus_statements = [
        "I think that I would like to use this Simple AAC app frequently with my child.",
        "I found the application unnecessarily complex to navigate.",
        "I thought the application was easy to use.",
        "I think that I would need the support of a technical person to use this app.",
        "I found the various functions (cards, speech, categories) well integrated.",
        "I thought there was too much inconsistency in this application.",
        "I would imagine that most caregivers would learn to use this app very quickly.",
        "I found the application very cumbersome/awkward to use.",
        "I felt very confident using the application with my child.",
        "I needed to learn a lot of things before I could get going with this application."
    ]
    for idx, stmt in enumerate(sus_statements, start=1):
        t_sus.cell(idx, 0).text = str(idx)
        t_sus.cell(idx, 1).text = stmt
        t_sus.cell(idx, 2).text = "[ 1 2 3 4 5 ]"

    doc.add_paragraph()

    # Instrument 4: Therapist Interview Guide
    add_heading_2(doc, "A4: Semi-Structured Therapist & Clinician Interview Guide")
    add_bullet_point(doc, "1. How does the Simple AAC app compare with physical paper communication boards in your clinical experience?", bold_prefix="Question: ")
    add_bullet_point(doc, "2. How appropriate and natural are the Sinhala, Tamil, and English voice outputs for your child clients?", bold_prefix="Question: ")
    add_bullet_point(doc, "3. What specific navigation friction or confusion did you observe children experience during card selection?", bold_prefix="Question: ")
    add_bullet_point(doc, "4. How practical is the offline card customization feature (camera photo adding) for families in home environments?", bold_prefix="Question: ")
    add_bullet_point(doc, "5. What additional features or clinical safeguards would you recommend before wider community rollout?", bold_prefix="Question: ")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_site_permission_letters(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Annexure E: Site Permission Letters" if not is_anonymous else "Annexure E: Site Permission Letters [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "DRAFT INSTITUTIONAL SITE PERMISSION LETTERS — PENDING OFFICIAL ADMINISTRATIVE SIGNATURES")

    add_heading_1(doc, "ANNEXURE E: SITE PERMISSION REQUEST LETTERS")

    add_heading_2(doc, "E1: Permission Request to PRAGATHI – Child Intervention Centre, Galle")
    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date, November 2026]\n"
                            "To: The Director / Centre In-Charge,\n"
                            "PRAGATHI – Child Intervention Centre,\n"
                            "Galle, Sri Lanka.")
    add_body_paragraph(doc, "Request for Institutional Permission to Conduct Prospective Usability Evaluation of the Simple AAC Mobile Application", bold_prefix="Subject: ")
    add_body_paragraph(doc, "Dear Sir / Madam,")
    add_body_paragraph(doc, "We write to formally request your institutional permission to conduct an observational research study titled "
                            "\"SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation\" "
                            "at the PRAGATHI Child Intervention Centre, Galle, subject to obtaining formal ethical clearance from the Ethics Review Committee, Faculty of Medicine, University of Ruhuna.")
    add_body_paragraph(doc, "The study will involve recruiting approximately 15 to 20 child-caregiver dyads receiving services at your centre for a single 15-to-20 minute usability trial of our offline trilingual AAC app. "
                            "Participation will be completely voluntary, requiring written parental consent and ongoing child assent. Routine therapy sessions will not be disrupted in any manner.")
    if not is_anonymous:
        sig_text = "Yours sincerely,\n\n" \
                   "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED]\n" \
                   "Thamalka D. J. G. (Lead Medical Student Researcher, UOR)\n" \
                   "D. V. W. Gunawardana (Medical Student Researcher, UOR)\n" \
                   "Dr. Gayani Punchihewa (Proposed Research Supervisor, Senior Lecturer in Psychiatry)\n" \
                   "E.K.Y.P. Fernando (Technical Research Collaborator & AAC Developer)"
    else:
        sig_text = "Yours sincerely,\n\n" \
                   "[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED]\n" \
                   "[Lead Medical Student Researcher — Identity Redacted for Peer Review]\n" \
                   "[Medical Student Researcher — Identity Redacted for Peer Review]\n" \
                   "[Research Supervisor — Identity Redacted for Peer Review]\n" \
                   "[Technical Research Collaborator & Developer — Identity Redacted for Peer Review]"
    add_body_paragraph(doc, f"Thank you for your continuous support of assistive innovation for children in the Southern Province.\n\n{sig_text}")

    add_heading_2(doc, "Institutional Endorsement Block (PRAGATHI Centre):")
    add_body_paragraph(doc, "I hereby grant provisional administrative permission to conduct the aforementioned research at PRAGATHI Child Intervention Centre, Galle, conditional upon formal ERC approval.\n\n"
                            "Signature: ___________________________\n"
                            "Name & Designation: ___________________\n"
                            "Official Stamp & Date: _________________")

    doc.add_paragraph()

    add_heading_2(doc, "E2: Permission Request to Department of Psychiatry, Faculty of Medicine")
    add_body_paragraph(doc, "Date: [PLACEHOLDER: Date, November 2026]\n"
                            "To: The Head of Department,\n"
                            "Department of Psychiatry, Faculty of Medicine,\n"
                            "University of Ruhuna, P.O. Box 70, Galle.")
    add_body_paragraph(doc, "Request for Permission to Conduct Clinical Usability Study at Outpatient Clinics", bold_prefix="Subject: ")
    add_body_paragraph(doc, "Dear Head of Department,")
    add_body_paragraph(doc, "We respectfully request permission to screen eligible pediatric participants attending the Child and Adolescent Mental Health Outpatient Clinic for our prospective AAC usability study. "
                            "All recruitment will adhere strictly to Ruhuna ERC guidelines and departmental clinical supervision.\n\n"
                            f"Yours respectfully,\n\n{sig_text}")

    add_heading_2(doc, "Departmental Endorsement Block:")
    add_body_paragraph(doc, "Permission granted for clinical recruitment conditional upon formal ERC clearance.\n\n"
                            "Signature: ___________________________\n"
                            "Head, Department of Psychiatry\n"
                            "Faculty of Medicine, University of Ruhuna\n"
                            "Official Stamp & Date: _________________")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

def build_data_management_plan(output_path, is_anonymous=False):
    doc = create_styled_document()
    doc_title = "Item 11: Data Management Plan" if not is_anonymous else "Item 11: Data Management Plan [ANONYMIZED]"
    setup_header_footer(doc, doc_title, is_anonymous=is_anonymous)
    add_draft_notice(doc, "ETHICS AND PRIVACY DATA MANAGEMENT PLAN — PEDIATRIC ASSISTIVE DIGITAL HEALTH")

    add_heading_1(doc, "ETHICS AND PRIVACY DATA MANAGEMENT PLAN (DMP)")
    add_heading_2(doc, "Platform B: Simple AAC Application Research Protocol")

    add_heading_2(doc, "1. Data Categories & Data Minimization")
    add_body_paragraph(doc, "In accordance with the Sri Lanka Personal Data Protection Act (No. 9 of 2022) and international health privacy guidelines, data collection is strictly restricted to items essential for usability evaluation:")
    add_bullet_point(doc, "Category 1: Administrative Identifiers (Caregiver Name, Contact Phone, Signed Consent Sheets) — Kept offline in physical locked storage; never entered into digital spreadsheets.", bold_prefix="• ")
    add_bullet_point(doc, "Category 2: De-identified Demographic & Clinical Profile (Child Age in months, Gender, Diagnostic category: ASD/ADHD/speech delay) — Stored under anonymous alphanumeric codes (e.g., AAC-DYAD-001).", bold_prefix="• ")
    add_bullet_point(doc, "Category 3: Usability Performance Data (Task completion status, latency in seconds, tapping assistance level, SUS questionnaire ratings, qualitative therapist feedback transcripts) — De-identified digital data.", bold_prefix="• ")
    add_bullet_point(doc, "Category 4: Excluded Data — NO biometric facial recognition, NO voice recordings for surveillance, NO GPS geolocation, and NO medical history records outside communication needs.", bold_prefix="• ")

    add_heading_2(doc, "2. Pseudonymization & Encryption Architecture")
    access_roles = "the designated Principal Investigator, Student Research Team, and Research Supervisor" if is_anonymous else "the officially designated Principal Investigator, Student Researchers (Thamalka D. J. G., D. V. W. Gunawardana), and Research Supervisor Dr. Gayani Punchihewa (with Technical Collaborator E.K.Y.P. Fernando managing technical encryption protocols)"
    add_body_paragraph(doc, f"A master linking key connecting participant names to alphanumeric codes will be generated as a single encrypted file. "
                            f"This key is encrypted using AES-256 bit encryption and stored on a password-protected, air-gapped physical drive in the Department of Psychiatry, accessible exclusively to {access_roles}. "
                            f"All operational research sheets, observation matrices, and statistical datasets will utilize the coded identifier only.")

    add_heading_2(doc, "3. Offline Mobile App Privacy Boundary")
    pkg_id = "lk.[REDACTED].simpleaac" if is_anonymous else "lk.yasas.simpleaac"
    add_body_paragraph(doc, f"The Simple AAC mobile application (`{pkg_id}`) is architected as an offline-first system: "
                            "(a) The application does not require a user account, email login, or registration. "
                            "(b) All communication cards, audio synthesis files, and custom images reside strictly within the mobile operating system's local scoped sandbox storage. "
                            "(c) No telemetry, crash reporting, analytics trackers, or external cloud synchronization services are embedded in the application. "
                            "(d) Custom photographs taken by caregivers for card personalization remain on the local hardware and are never transmitted.")

    add_heading_2(doc, "4. Data Retention, Archival & Secure Disposal")
    add_body_paragraph(doc, "Anonymized quantitative and qualitative research records will be securely archived for a mandatory period of **five (5) years** post-publication in compliance with Ruhuna ERC regulations. "
                            "Following the expiration of the retention period, digital data will be permanently destroyed using multi-pass cryptographic disk sanitization tools (DoD 5220.22-M standard), and physical paper consent documents will be destroyed via industrial cross-cut paper shredders.")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc.save(output_path)
    print(f"Generated: {output_path}")

if __name__ == "__main__":
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    # Generate identifiable/complete versions
    build_research_protocol(os.path.join(base, "protocol", "04_AAC_ERC_Research_Protocol_DRAFT.docx"), is_anonymous=False)
    build_information_sheet(os.path.join(base, "annexures", "05_Parent_or_Guardian_Information_Sheet_DRAFT.docx"), is_anonymous=False)
    build_consent_form(os.path.join(base, "annexures", "06_Parent_or_Guardian_Consent_Form_DRAFT.docx"), is_anonymous=False)
    build_child_assent(os.path.join(base, "annexures", "07_Child_Assent_Protocol_DRAFT.docx"), is_anonymous=False)
    build_study_instruments(os.path.join(base, "annexures", "08_Study_Instruments_DRAFT.docx"), is_anonymous=False)
    build_site_permission_letters(os.path.join(base, "annexures", "09_Site_Permission_Request_Letters_DRAFT.docx"), is_anonymous=False)
    build_data_management_plan(os.path.join(base, "data_management", "11_Data_Management_Plan_DRAFT.docx"), is_anonymous=False)

    # Generate strictly ANONYMOUS versions for Soft Copy 2
    build_research_protocol(os.path.join(base, "protocol", "04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_information_sheet(os.path.join(base, "annexures", "05_Parent_or_Guardian_Information_Sheet_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_consent_form(os.path.join(base, "annexures", "06_Parent_or_Guardian_Consent_Form_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_child_assent(os.path.join(base, "annexures", "07_Child_Assent_Protocol_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_study_instruments(os.path.join(base, "annexures", "08_Study_Instruments_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_site_permission_letters(os.path.join(base, "annexures", "09_Site_Permission_Request_Letters_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
    build_data_management_plan(os.path.join(base, "data_management", "11_Data_Management_Plan_ANONYMOUS_DRAFT.docx"), is_anonymous=True)
