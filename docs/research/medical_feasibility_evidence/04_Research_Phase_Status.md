# Research Phase Status Report: Simple AAC Feasibility Study

**Document:** `04_Research_Phase_Status.md`  
**Project:** Simple AAC (Sri Lanka)  
**Package Identifier:** `lk.yasas.simpleaac`  
**Inspected Version:** `1.1.4+12` (Build 12)  
**Lead Investigators:** J.G.D. Thamalka, D.V.W. Gunawardana (Medical Student Researchers, Faculty of Medicine, University of Ruhuna)  
**Supervisor / Co-Investigator:** Dr. Gayani Punchihewa (Senior Lecturer & Psychiatrist, Department of Psychiatry, Faculty of Medicine, University of Ruhuna)  
**Technical Collaborator / Developer:** Yasas Pasindu Fernando  
**Context and Methodological Notice:** This document establishes the exact research status of the project across the five proposed research phases defined in the medical feasibility framework. It explicitly distinguishes between retrospective software development activities and prospective clinical research requiring formal ethical approval.

---

## 1. Methodological Principles

1. **Temporal Distinction:** The Simple AAC software was developed iteratively prior to the initiation of this formal medical feasibility protocol. Development history must not be retroactively presented as though it was conducted prospectively under an approved clinical trial protocol.
2. **Evidence Boundaries:** Source code, automated tests, and engineering benchmarks verify technical functionality only. They do not constitute evidence of clinical consultation, professional consensus, or therapeutic efficacy.
3. **Ethical Prerequisite:** No human participant research involving children with Autism Spectrum Disorder (ASD), their caregivers, or healthcare professionals may commence prior to receiving written ethical clearance from the Ethics Review Committee (ERC), Faculty of Medicine, University of Ruhuna, and institutional permission from prospective recruitment sites.

---

## 2. Phase-by-Phase Status Mapping

### Phase 1: Needs Assessment
- **Intended Clinical Objective:** To formally identify the functional communication barriers, linguistic requirements, socio-economic constraints, and technology access factors of Sri Lankan children with ASD and their families.
- **Work Supported by Repository Evidence:**
  - Technical implementation of trilingual metadata structures (`en`, `si`, `ta`) in `lib/models/aac_card_model.dart`.
  - Creation of an offline dictionary containing 179 trilingual daily communication concepts (`lib/services/multilingual_concept_service.dart`).
  - Implementation of offline-by-default architecture to eliminate mobile data costs (`lib/services/network_policy_service.dart`).
- **Work Completed to Date:**
  - Software developer and student researchers conducted informal reviews of existing international AAC apps and observed high costs and lack of Sinhala/Tamil language support.
- **Informal Consultations / Discussions:**
  - The project background notes suggest preliminary discussions occurred regarding local communication barriers. However, these are not documented in formal research records.
- **What Requires Clinical Documentation:**
  - A formal report or protocol detailing the methodology of a structured needs assessment (e.g., surveys or focus groups with parents and therapists).
- **What Remains Proposed:**
  - A structured survey or qualitative interview study with caregivers attending child development clinics in the Southern Province to formally quantify vocabulary priorities.
- **Ethical Approval Requirement:**
  - **MANDATORY.** Any future structured questionnaire or interview involving parents, caregivers, or clinicians requires ERC review and informed consent prior to data collection.

---

### Phase 2: Application Development
- **Intended Objective:** Iterative engineering of an accessible, offline, trilingual AAC application for Android devices based on identified functional requirements.
- **Work Supported by Repository Evidence:**
  - Complete, functional Flutter/Dart codebase (`simple_aac_play_release/`).
  - Production Android application (`lk.yasas.simpleaac`, v1.1.4, versionCode 12).
  - 210 passing automated unit, widget, and integration tests (`test/`).
  - Implemented features: Picture grid, custom card creator, category filtering, persistent sentence strip, system TTS and human audio recording, haptics, color vision modes, pin-lock, and offline gate.
- **Work Completed to Date:**
  - Full software engineering lifecycle, automated quality assurance, regression testing, and Android package signing.
- **What Requires Clinical Documentation:**
  - Documentation explaining how specific UI design choices (e.g., card aspect ratios, color palettes, 1.5s unpin delay) align with occupational therapy and special education recommendations.
- **What Remains Proposed:**
  - Software maintenance and minor bug fixes responding to feedback from subsequent clinical evaluation phases.
- **Ethical Approval Requirement:**
  - **NOT REQUIRED** for purely desk-based software engineering and automated device benchmarking. Any code adjustments made by the developer do not require ERC approval as long as no human subjects are involved.

---

### Phase 3: Expert Validation
- **Intended Clinical Objective:** Structured, formal evaluation of the application’s clinical appropriateness, user interface safety, symbol clarity, and vocabulary relevance by an interdisciplinary panel of experts (psychiatrists, paediatricians, speech and language therapists, special education teachers, and clinical psychologists).
- **Work Supported by Repository Evidence:**
  - Zero repository evidence. The codebase contains no expert rating scales, validation rubrics, or recorded panel scores.
- **Work Completed to Date:**
  - Dr. Gayani Punchihewa has reviewed draft documentation and provided the 10-domain feasibility guidance framework.
- **Informal Consultations / Discussions:**
  - Informal discussions may have taken place between student researchers and clinical mentors. However, these informal exchanges do not constitute formal expert validation.
- **What Requires Clinical Documentation:**
  - An expert review protocol defining the evaluation tool (e.g., using a modified Content Validity Index [CVI] or a structured Likert questionnaire), reviewer selection criteria, and written feedback documentation.
- **What Remains Proposed:**
  - Convening a formal multidisciplinary panel to review:
    1. The clinical appropriateness of the 179 trilingual vocabulary concepts.
    2. The clarity and cultural familiarity of the pictorial symbols.
    3. The cognitive load and navigation structure of the user interface.
- **Ethical Approval Requirement:**
  - **MANDATORY if experts are enrolled as research participants** providing study data under a formal research protocol. If consulted informally as advisory project mentors, formal ERC approval may not be required by the faculty, but their written consent to be acknowledged must be secured.

---

### Phase 4: User Testing (Caregivers and Children)
- **Intended Clinical Objective:** Direct observation of child engagement, communicative intent, user navigation, motor accessibility, and caregiver ease-of-use during structured interaction with the application.
- **Work Supported by Repository Evidence:**
  - Zero repository evidence. No human participant data, interaction logs, or usability scores exist in the repository.
- **Work Completed to Date:**
  - Bench-testing of the interface by the developer on simulator and a single physical smartphone (Samsung Galaxy A34 5G).
- **Informal Consultations / Discussions:**
  - No clinical usability sessions have been performed.
- **What Requires Clinical Documentation:**
  - Detailed user-testing observation rubrics, task scenarios (e.g., "Select the food card", "Build a two-card sentence"), and caregiver satisfaction questionnaires.
- **What Remains Proposed:**
  - Supervised usability sessions with child–caregiver dyads to evaluate interface ergonomics, child responsiveness, and caregiver usability.
- **Ethical Approval Requirement:**
  - **MANDATORY.** Enrolling children (especially vulnerable individuals with neurodevelopmental disorders) requires comprehensive ethical review, parental informed consent, child assent where practicable, and strict safety protocols.

---

### Phase 5: Pilot Evaluation
- **Intended Clinical Objective:** A formal, prospective feasibility and usability pilot study conducted in a clinical or intervention setting (e.g., PRAGATHI Child Intervention Centre, Galle) to establish protocol viability, recruitment rates, session completion rates, and preliminary communication observations.
- **Work Supported by Repository Evidence:**
  - A draft research proposal document exists in `docs/ethics/ruhuna_erc/protocol/`.
  - Administrative draft letters and template forms exist in `docs/ethics/ruhuna_erc/scripts/`.
- **Work Completed to Date:**
  - Preparation of preliminary protocol drafts for a single supervised sitting.
- **What Requires Clinical Documentation:**
  - Written institutional permission from the administration of PRAGATHI Child Intervention Centre, Galle.
  - Finalized Sinhala and Tamil Participant Information Sheets and Informed Consent Forms.
  - Formal justification of sample size (e.g., 10–12 dyads vs clinic attendance sampling).
- **What Remains Proposed:**
  - Submission of the completed application to the ERC, Faculty of Medicine, University of Ruhuna.
  - Execution of the pilot study following receipt of written ERC approval.
  - Data analysis and compilation of the final feasibility report.
- **Ethical Approval Requirement:**
  - **ABSOLUTELY MANDATORY.** No pilot evaluation activities involving participants may begin until full ethical approval has been granted and signed by the ERC Chairperson.

---

## 3. Summary of Research Phase Status

| Phase | Description | Current Status | Completed Activities | Immediate Next Step |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | Needs Assessment | `PARTIALLY IMPLEMENTED` (Informal only) | Informal problem identification; trilingual card structure created. | Medical team to document clinical justification from local literature and clinic observations. |
| **Phase 2** | App Development | `IMPLEMENTED` / `COMPLETED` | Production Android Build 12 (v1.1.4); 210 tests passed; stable offline release. | Code freeze maintained; preserve stability during feasibility evaluation. |
| **Phase 3** | Expert Validation | `PROPOSED` / `NOT COMPLETED` | Guidance received from Dr. Gayani Punchihewa on 10 feasibility domains. | Formulate structured expert review tool (SLT, Psychiatry, Paediatrics) to validate vocabulary. |
| **Phase 4** | User Testing | `PROPOSED` / `NOT STARTED` | Developer usability verification on physical device only. | Define usability observation metrics for subsequent ethical application. |
| **Phase 5** | Pilot Evaluation | `PROPOSED` / `PROTOCOL DRAFTING` | Draft proposal prepared; gap analysis completed; code frozen. | Finalize Sinhala/Tamil forms, secure site permission from PRAGATHI Centre, submit ERC package. |
