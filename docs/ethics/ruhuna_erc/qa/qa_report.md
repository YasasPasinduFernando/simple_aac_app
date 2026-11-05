# Quality Assurance & Verification Report: Ruhuna ERC Documentation

**Date of Audit**: November 2026  
**Auditor**: Senior Research Ethics & Document Specialist  
**Package Status**: **REVIEWED DRAFT — READY FOR SUPERVISOR REVIEW**

---

## 1. Compliance with Official University of Ruhuna ERC Requirements

| Rule / Requirement | Verification Outcome | Detail & Evidence |
| :--- | :--- | :--- |
| **Official Proposal Format Adherence** | **PASSED** | Structured strictly according to Ruhuna `Format_of_Research_Proposal.docx`: Title, Introduction & Justification (1000–3000w), Literature Review (1000–3000w), Objectives, Methodology (5.1–5.8), Referencing (<50 references), Gantt chart, Budget. Generated: `protocol/04_AAC_ERC_Research_Protocol_DRAFT.docx` (9 pages). |
| **Official Application Form Authenticity** | **PASSED** | Built directly from a fresh blank copy of `Application for Human Research.docx` (Annexure UOR/03-001) retrieved from `medi.ruh.ac.lk/ethics`. Preserves all tables, declaration cages, checkboxes, and section sequencing. Generated: `forms/02_Human_Research_Application_DRAFT.docx` (26 pages). |
| **No Blanks in Application** | **PASSED** | Every cage is completed. Inapplicable sections (e.g. animal research, ionizing radiation, clinical trial SCOCT approvals, biological sample storage) are explicitly filled with "Not applicable" rather than left blank. |
| **Mandatory Headers and Footers** | **PASSED** | All documents specify the version number (`Version 1.0 (DRAFT)`) and date in the header, and page numbers in the footer, per Ruhuna ERC formatting rules. |
| **Submission Structure (Hard & Soft Copies)** | **PASSED** | Hard copies accommodate Items 1 to 8 (including dedicated cover sheets/placeholders: `forms/13_Training_Certificates_PI_Supervisor_DRAFT.docx`, `forms/14_Animal_Handling_Statement_DRAFT.docx`, and `forms/15_Fee_Payment_Receipt_Placeholder_DRAFT.docx`). Soft copies accommodate exactly TWO files: `01_Complete_ERC_Application.pdf` (71 pages, 1.23 MB) and `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB). |
| **Strict Proposal Anonymization** | **PASSED (0 LEAKS)** | In Soft Copy 2, all investigator names, supervisor names, co-investigator names, personal emails, student numbers, foreign universities, and package ID identifiers are systematically excluded/redacted. Automated string scanning confirmed 0 leaks across 24 pages. |

---

## 2. Integrity and Fact-Checking Safeguards

| Risk Area | Verification Check | Safeguard Implemented |
| :--- | :--- | :--- |
| **Research Leadership & Ownership** | **PASSED (STUDENT LED)** | Corrected throughout all documents: the research is led by undergraduate medical students **Thamalka D. J. G.** and **D. V. W. Gunawardana** (Faculty of Medicine, University of Ruhuna), supervised by **Dr. Gayani Punchihewa**. E.K.Y.P. Fernando is properly designated as **Technical Research Collaborator, AAC Application Developer & Technical Implementation Lead**. |
| **Principal Investigator Designation** | **PASSED (NOT AUTO-ASSIGNED)** | E.K.Y.P. Fernando is NOT assigned as Principal Investigator. The PI slot is formally marked as `[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED: Lead Medical Student Researcher / Academic Supervisor]` pending formal team/departmental appointment. |
| **Separation from Kingston MSc AI Dissertation** | **PASSED (CLEAN SEPARATION)** | Fully verified: this project is NOT an MSc AI dissertation for Kingston University or London Metropolitan University. Those institutions are cited strictly as academic qualifications of E.K.Y.P. Fernando. |
| **Contamination from Colorectal Surgery Reference** | **PASSED (ZERO LEAKAGE)** | Rigorously scanned for any mention of colorectal surgery, anterior resection, intravenous albumin, adult cancer, or surgical ward data from `final.pdf`. All content is 100% specific to pediatric AAC and neurodevelopmental communication support. |
| **Conflation with MSc FER Research** | **PASSED (CLEAN SEPARATION)** | Checked against CREMA-D dataset claims, few-shot personalization models, or claims of computer vision emotion detection in the current app. The protocol clearly specifies that Platform B is an offline-first AAC app using picture cards and speech synthesis, with no biometric facial tracking. |
| **Participant Data and Privacy** | **PASSED (NO PRIVATE DATA IN GIT)** | No real child data, participant identities, personal contact phone numbers, or residential addresses are committed. Real personal contact info and wet-ink signatures are isolated in `.local_erc_private/`. Personal emails sanitized to placeholders in tracked files. |
| **Non-Fabrication of Approvals & Signatures** | **PASSED** | No digital signature forgery or manufactured approval letters. All signature cages are designated for genuine physical wet-ink execution by the authorized parties. |

---

## 3. Summary of Document Status Levels

- **DRAFT**: All working documents are explicitly labeled `DRAFT — FOR SUPERVISOR REVIEW AND ERC SUBMISSION`.
- **READY FOR SUPERVISOR REVIEW**: Document structure, academic literature, methodology, data protection plans, and consent protocols are mature, rigorous, and ready for internal sign-off by the academic and clinical team.
- **READY FOR ERC SUBMISSION**: Pending wet-ink signatures, supervisor consent letter execution, institutional permission letters, ethics training certificates, and fee payment receipt.
