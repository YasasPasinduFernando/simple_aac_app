# Clinical Team Inquiries: Essential Methodological and Ethical Decisions

**Document:** `05_Clinical_Team_Questions.md`  
**Project:** Simple AAC (Sri Lanka)  
**Package Identifier:** `lk.yasas.simpleaac`  
**Addressed To:**  
- **J.G.D. Thamalka & D.V.W. Gunawardana** (Medical Student Research Leads, Faculty of Medicine, University of Ruhuna)  
- **Dr. Gayani Punchihewa** (Co-Investigator & Psychiatrist, Department of Psychiatry, Faculty of Medicine, University of Ruhuna)  
**Submitted By:** Yasas Pasindu Fernando (Technical Collaborator & Application Developer)  
**Purpose:** This document consolidates the fundamental clinical, methodological, regulatory, and ethical questions that **cannot be resolved through software engineering or source code inspection**. These decisions are the exclusive responsibility of the medical research team and are required to finalize the Ethics Review Committee (ERC) submission package.

---

## 1. Study Population and Eligibility Criteria

### 1.1 Target Age Range and Exact Cut-Off Rule
- **Technical Context:** The software UI adapts from 1 to 5 grid columns and can be configured with varying card sizes, accommodating toddlers through older adolescents.
- **Clinical Question:** What is the precise chronological age range for prospective study participants?
  - Existing protocol drafts refer loosely to *"children aged about 2 to 12 years"*. 
  - An exact date-of-birth rule is required for the ERC application (e.g., *“Children aged 3 years 0 months to 11 years 11 months on the date of recruitment”*).
  - Will children under 3 years be included, given diagnostic stability considerations in early autism?

### 1.2 Autism Spectrum Disorder (ASD) Diagnostic Definition
- **Technical Context:** The app does not perform any diagnostic screening.
- **Clinical Question:** How will the diagnosis of ASD be operationalized for study inclusion?
  - Will eligibility require a formal written diagnosis by a Consultant Child Psychiatrist, Consultant Psychiatrist, or Consultant Paediatrician?
  - Will standardized diagnostic instruments be required (e.g., DSM-5 criteria, CARS-2, ADOS-2, or clinical notes from the hospital/centre file)?
  - Is the study limited strictly to children with confirmed ASD, or will it encompass children with broader speech, language, and communication needs (SLCN)?

### 1.3 Baseline Communication and Cognitive Ability
- **Technical Context:** Simple AAC is designed for picture-pointing direct selection.
- **Clinical Question:** What level of baseline communication ability is required for inclusion?
  - Is the study targeting exclusively non-verbal children (zero functional words), minimally verbal children (<20 intelligible words), or any child with functional communication deficits?
  - Are children with severe intellectual disability or profound motor spasticity (e.g., inability to isolate a finger to point at a screen) excluded, or will physical caregiver assistance be accommodated?

### 1.4 Medical and Sensory Exclusion Criteria
- **Clinical Question:** What medical exclusion criteria must be enforced?
  - E.g., Uncontrolled epilepsy (potential risk from flashing screens or rapid visual stimuli, although Simple AAC has no flashing content)?
  - Severe uncorrected visual impairment or profound bilateral sensorineural hearing loss?
  - Acute medical instability or active behavioural crisis on the day of the session?

---

## 2. Study Design and Site Protocol

### 2.1 Study Site Approval and Administrative Permission
- **Context:** The draft protocol proposes the **PRAGATHI Child Intervention Centre, Galle**, as the single study site.
- **Clinical Question:** 
  - Has formal administrative permission been requested or granted in writing from the directorate of PRAGATHI Child Intervention Centre?
  - What physical room and facilities are allocated to ensure privacy, comfort, and minimal sensory distraction during the supervised sitting?
  - Does the study involve any clinical clinics under the Teaching Hospital Karapitiya or the Faculty of Medicine? (Existing drafts confirm no hospital clinic is included).

### 2.2 Study Design: Single-Sitting vs Multi-Session Feasibility
- **Context:** The draft protocol describes a **single supervised sitting lasting approximately 20 to 30 minutes**.
- **Clinical Question:** 
  - Does the research team intend to maintain this single-sitting usability design, or is a short follow-up (e.g., a 2-week home feasibility trial) envisioned?
  - *Recommendation:* For an undergraduate medical student feasibility project, a single supervised sitting provides a tight, manageable, and safe scope that minimizes risk and attrition.

### 2.3 Sample Size and Justification
- **Context:** The draft gap matrix identified two competing options:
  - **Option A:** A time-bounded convenience sample of all eligible child–caregiver pairs attending PRAGATHI Centre during a specified recruitment period (e.g., 4 weeks).
  - **Option B:** A fixed cohort of 10 to 12 child–caregiver pairs.
- **Clinical Question:** Which sample size strategy will Dr. Punchihewa and the student leads officially adopt and justify to the ERC? 
  - If 12 pairs is selected, what is the clinical justification (e.g., standard usability testing saturation where 80–90% of critical usability barriers are uncovered within 10–12 users)?

---

## 3. Clinical Measures and Feasibility Outcomes

### 3.1 Primary Feasibility Outcomes
- **Technical Context:** The software does not automatically log keystrokes or record usage telemetry (prioritizing privacy).
- **Clinical Question:** What primary feasibility outcomes will the student researchers record on paper case report forms (CRFs)?
  - **Recruitment Rate:** Proportion of approached families who consent.
  - **Session Completion Rate:** Proportion of children who complete the 20-minute sitting without session-terminating distress.
  - **Task Success:** Number of visual cards successfully selected (spontaneous vs prompted).
  - **Caregiver Usability:** Structured caregiver rating score (e.g., System Usability Scale [SUS] or a 5-item Likert questionnaire).

### 3.2 Standardized Clinical Instruments
- **Clinical Question:** Will any validated developmental or communication scale be administered at baseline?
  - E.g., Communication and Symbolic Behavior Scales (CSBS), Goal Attainment Scaling (GAS), or Vineland Adaptive Behavior Scales?
  - *Note:* Administering extensive psychometric scales may overburden families during a brief feasibility study. The team should confirm whether a simplified communication profile form is sufficient.

---

## 4. Documentation of Past Consultations and Expert Review

### 4.1 Historical Expert Consultations
- **Context:** Previous informal project notes mentioned past discussions with healthcare professionals.
- **Clinical Question:** 
  - Do the medical student leads possess dated written notes, meeting minutes, or emails documenting past consultations with psychiatrists, paediatricians, or speech and language therapists?
  - If informal discussions took place, who was consulted, what was discussed, and can their names be included in research documentation?
  - *Crucial Rule:* In the absence of signed consultation records, the research protocol must describe past consultations as *informal development discussions*, not *formal expert validation*.

### 4.2 Proposed Formal Expert Validation Panel (Phase 3)
- **Clinical Question:** 
  - Will a structured expert validation panel be conducted prior to the child pilot?
  - If so, who will be invited (e.g., 2 Speech and Language Therapists, 1 Child Psychiatrist, 1 Special Education Teacher)?
  - What rating tool will be used to review the 179 trilingual vocabulary items and picture symbols?

---

## 5. Ethical, Legal, and Regulatory Approvals

### 5.1 Formal Applicant for the Ruhuna ERC Submission
- **Context:** Guidelines from the Faculty of Medicine, University of Ruhuna, stipulate clear requirements regarding principal applicants and student status.
- **Clinical Question:** Who will be the formal applicant on the Ruhuna ERC submission?
  - Will the primary applicant be student researcher **J.G.D. Thamalka**, **D.V.W. Gunawardana**, or supervisor **Dr. Gayani Punchihewa**?
  - *(Confirmed fact: Yasas Pasindu Fernando is the technical collaborator/developer and is NOT the ethics applicant).*

### 5.2 Participant Information and Informed Consent in Sinhala and Tamil
- **Context:** Draft information sheets and consent forms currently exist only in English.
- **Clinical Question:** 
  - Who on the medical research team will translate and back-translate the Participant Information Sheets (PIS) and Informed Consent Forms (ICF) into grammatically sound, culturally sensitive Sinhala and Tamil?
  - This is a strict prerequisite for ERC submission in Sri Lanka.

### 5.3 Child Assent and Distress Discontinuation Protocol
- **Clinical Question:** 
  - What is the explicit procedure for seeking child assent (e.g., simplified picture-based assent card for children with basic comprehension)?
  - What is the unambiguous rule for session discontinuation if a child shows behavioral distress, crying, avoidance, or reluctance to continue? (Existing drafts specify that a child’s unwillingness immediately halts the session without penalty to the family).

### 5.4 Physical Data Custody and Storage
- **Clinical Question:** Where will the signed physical informed consent forms and paper case report forms be stored?
  - Institutional guidelines require storage in a locked cabinet within the Department of Psychiatry, Faculty of Medicine, University of Ruhuna, accessible only to authorized investigators.
  - What is the designated retention period (e.g., 5 years post-study)?

---

## 6. Action Checklist for the Medical Team

1. [ ] Confirm primary applicant name, designation, and registration numbers.
2. [ ] Finalize exact age range (e.g., 3;0 to 11;11 years) and ASD diagnostic criteria.
3. [ ] Confirm single-sitting study design (20–30 min) and sample size (e.g., 10–12 pairs).
4. [ ] Request and secure written permission letter from PRAGATHI Child Intervention Centre.
5. [ ] Translate PIS and ICF into Sinhala and Tamil.
6. [ ] Approve the formal supervisor letter draft with Dr. Gayani Punchihewa.
7. [ ] Finalize the ERC application form and submit the package to the Faculty ERC office.
