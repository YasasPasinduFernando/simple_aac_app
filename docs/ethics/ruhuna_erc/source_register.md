# Source Register: University of Ruhuna ERC Submission

This document registers all source files, templates, reference artifacts, and codebase inputs evaluated during the preparation of the Ethics Review Committee (ERC) submission for the Simple AAC Application.

---

## 1. Primary Factual Project Sources

| Item | File / Path | Authoritative Content Used | Status & Handling |
| :--- | :--- | :--- | :--- |
| **P-1** | `SL_AAC_Project_Proposal.docx` (`/home/yasas/Downloads/`) | Project title, background on ASD/ADHD in Sri Lanka, lack of local Sinhala/Tamil AAC apps, lead institution (PRAGATHI Child Intervention Centre, Galle), collaborating academic department (Department of Psychiatry, Faculty of Medicine, University of Ruhuna), endorsing authority (Ministry of Health, Sri Lanka: Secretary of Health, Director of Health Information, Director of Mental Health), Apple App Store publishing partner (Idea-Hub Pvt Ltd, Nugegoda), target age range (2–12 yrs), core application features (6 daily categories: food & drink, emotions, activities, school items, family members, basic needs: eating, drinking, toilet, sleep; early learning modules), governance structure, data protection principles (offline-first, zero analytics), research team members (Yasas Pasindu Fernando / E.K.Y.P. Fernando, Thamalka D. J. G., D. V. W. Gunawardana). | **Factual Basis.** Genuine project proposal. Confirmed facts migrated into ethics protocol. |
| **P-2** | Platform B Repository Codebase (`simple_aac_app/`) | Application package ID (`lk.yasas.simpleaac`), Flutter framework, implemented features: visual card grid, category browsing, trilingual labels (Sinhala, Tamil, English), TTS voice output (`flutter_tts`), custom card image capture/picking, voice recording (`record`), offline zip backup/restore, offline-first network policy. | **Factual Codebase Truth.** All technical descriptions in the protocol reflect verified implementation. Confirms NO facial expression recognition (FER) model or camera emotion tracking is currently active in Platform B. |
| **P-3** | `ANTIGRAVITY_CODEX_PLATFORM_B_AAC_ERC_MASTER_PROMPT.md` | Master instructions, repository workflow rules, staged git delivery protocol, privacy boundaries, document numbering, checklist requirements. | **Operational Directive.** Followed in full. |
| **P-4** | Verified Academic Profile: Dr. Gayani Punchihewa | MBBS, MD (Psychiatry). Senior Lecturer in Psychiatry, Department of Psychiatry, Faculty of Medicine, University of Ruhuna; Consultant Psychiatrist, Teaching Hospital Karapitiya. | **Verified Research Supervisor.** Confirmed institutional staff eligibility under Ruhuna ERC Category I. |
| **P-5** | Verified Profile: E.K.Y.P. Fernando | Edirisinghe Kankanamge Yasas Pasindu Fernando (Yasas Pasindu Fernando). MSc in Artificial Intelligence, Kingston University, UK (ongoing); BEng (Hons) in Software Engineering, London Metropolitan University, UK (completed). | **Verified Technical Research Collaborator & Software Developer.** Formally recognized as technical collaborator contributing to software engineering, technical feasibility, system architecture, and evaluation metrics interpretation. (Note: Academic qualifications only; does NOT represent institutional sponsorship or thesis supervision for this Ruhuna medical student study). |
| **P-6** | Verified Profile: Ruhuna Medical Student Researchers | Thamalka D. J. G. and D. V. W. Gunawardana, Undergraduate Medical Students, Faculty of Medicine, University of Ruhuna. | **Primary Student Research Team.** Leading medical/clinical research components, participant interaction, and ethics submission under Dr. Gayani Punchihewa's supervision. |

---

## 2. Official University of Ruhuna ERC Requirements & Templates

| Item | Official URL / Asset | Description | Usage in Package |
| :--- | :--- | :--- | :--- |
| **R-1** | `https://www.medi.ruh.ac.lk/ethics/instructions.html` | Official submission rules, submission deadlines, hard-copy (8 items) and soft-copy (2 PDFs) checklists, opening hours, fee schedule, CIU building office location. | Defines exact submission packaging rules. |
| **R-2** | `https://www.medi.ruh.ac.lk/ethics/download/Format_of_Research_Proposal.docx` | Official proposal structural guideline (effective 1 March 2021): Title, Introduction & Justification (1000–3000w), Literature Review (1000–3000w), Objectives, Methodology (5.1–5.8), Referencing (<50 refs), Gantt chart, Budget. | Exact structural framework for `04_AAC_ERC_Research_Protocol_DRAFT.docx`. |
| **R-3** | `https://www.medi.ruh.ac.lk/ethics/download/Application for Human Research.docx` | Official Blank Application Form (Annexure UOR/03-001) retrieved live from Ruhuna ERC server. | Exact document used as template for `02_Human_Research_Application_DRAFT.docx`. All question numbering, table formatting, and declaration cages strictly preserved. |
| **R-4** | `https://www.medi.ruh.ac.lk/ethics/download/Informed Consent forms.docx` | Official template for Information Sheet (Part 1) and Certificate of Consent (Part 2), guidelines for proxy consent for minors (<18 yrs), child assent provisions, trilingual translation requirements. | Exact structural basis for `05_Parent_or_Guardian_Information_Sheet_DRAFT.docx`, `06_Parent_or_Guardian_Consent_Form_DRAFT.docx`, and `07_Child_Assent_Protocol_DRAFT.docx`. |
| **R-5** | `https://www.medi.ruh.ac.lk/ethics/download/Checklist for initial submission.docx` | Official Initial Submission Checklist form. | Used to formulate `qa/submission_checklist.md` and `qa/12_ERC_Submission_Checklist.docx`. |

---

## 3. Reference Files Used for Formatting ONLY (Zero Factual Transfer)

| Item | File / Path | Actual Content | Strict Limitation |
| :--- | :--- | :--- | :--- |
| **REF-1** | `/home/yasas/Downloads/final.pdf` | Unrelated clinical trial protocol on adult colorectal cancer patients undergoing anterior resection with prophylactic intravenous albumin at National Hospital Galle. | **FORMATTING & DETAIL DEPTH REFERENCE ONLY.** Zero medical or clinical facts transferred. No albumin, surgical outcomes, adult cancer data, or hospital statistics used. |
| **REF-2** | `/home/yasas/Downloads/Application for Human Research.docx` | Filled ERC application for the aforementioned colorectal surgery clinical trial. | **QUESTION-ANSWER PATTERN REFERENCE ONLY.** Zero investigator identities, clinical trial registry numbers, or surgical procedures transferred. |

---

## 4. Verification Check: Scope Separation

- **BSc / Platform B AAC Focus**: Assistive mobile communication software for non-verbal or minimally verbal children with autism spectrum disorder, ADHD, and communication impairments in Sri Lanka.
- **MSc FER Research Separation**: The current master prompt explicitly mandates that the unrelated MSc research regarding CREMA-D few-shot facial expression recognition personalization MUST NOT be conflated with the Platform B AAC ethics submission. In the current Platform B codebase, no facial recognition ML models exist. Any prospective camera usage is strictly limited to caregiver-guided photography for custom communication card icons (e.g., photo of child's water cup or family member).
