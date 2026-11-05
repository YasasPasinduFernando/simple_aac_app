# Git Delivery Audit Log: Platform B Ruhuna ERC Documentation

This log records every staged, committed, and pushed milestone for the University of Ruhuna ERC documentation package in the `simple_aac_app` repository.

---

## Repository Verification Baseline

- **Repository Root**: `/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_app`
- **Initial Branch**: `fix/production-package-id`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Pre-existing Working Tree State**: Clean (`working tree clean`, zero uncommitted changes).
- **Concurrent Developer Scope**: App code in `lib/`, assets, manifests, and build configurations are strictly preserved. Only `docs/ethics/ruhuna_erc/` and repository `.gitignore` protections are managed in this workflow.

---

## Milestone Execution Trail

### Milestone 1: Framework, Source Audit & Governance Setup
- **Objectives**:
  1. Verify repository root, remote, and clean status.
  2. Protect sensitive/private assets by updating `.gitignore` with `/.local_erc_private/`.
  3. Create documentation directory structure under `docs/ethics/ruhuna_erc/`.
  4. Author Stage 1 governance documentation: `README.md`, `master_prompt.md`, `source_register.md`, `applicability_and_missing_info.md`, `source_fact_matrix.md`, `qa/document_inventory.md`, `qa/qa_report.md`, `qa/submission_checklist.md`, and `qa/git_delivery_log.md`.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`, `.gitignore`
- **Commit Hash**: `cf90d638be6e6b5413ba0c8d1cfd474582f34795` (short: `cf90d63`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`6eee9ef..cf90d63  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Verified no private participant data, real phone numbers, credentials, or third-party colorectal surgery facts staged.

---

### Milestone 2: Complete Protocol, Application Forms, Annexures & Build Pipeline
- **Objectives**:
  1. Generate all 12 editable DOCX documents adhering strictly to Ruhuna ERC 2021 proposal guidelines and official blank application form (Annexure UOR/03-001).
  2. Author reproducible python build scripts (`build_erc_package.py`, `generate_admin_docs.py`, `generate_application_form.py`, `generate_protocol_and_annexures.py`, `docx_common.py`, `requirements.txt`).
  3. Produce both required soft-copy submission packages locally in `.local_erc_private/exports_private/`:
     - `01_Complete_ERC_Application.pdf` (62 pages, 1.05 MB)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, verified 0 anonymity leaks)
  4. Update `.gitignore` and document inventory.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `67a8e3371f4b8cfebc3e6d8ba98b760a9f5d1ce3` (short: `67a8e33`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`cf90d63..67a8e33  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Zero leaks in Soft Copy 2. All identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

### Milestone 3: Team Revisions & Proposal Fact Incorporation
- **Objectives**:
  1. Incorporate **Dr. Gayani Punchihewa**, MBBS, MD (Psychiatry), Senior Lecturer in Psychiatry at University of Ruhuna / Consultant Psychiatrist at Teaching Hospital Karapitiya, as Proposed Research Supervisor across Cover Letter, Application Form, Supervisor Consent Letter, Protocol, Information Sheet, and Permission Letters.
  2. Explicitly establish **E.K.Y.P. Fernando (Yasas Pasindu Fernando)** as Researcher, Software Developer & Technical Implementation Lead, recognizing substantive research contributions to design, evaluation, and documentation; update academic qualifications to MSc in Artificial Intelligence (Kingston University, ongoing) and BEng (Hons) in Software Engineering (London Metropolitan University, completed).
  3. Integrate features and governance from `SL_AAC_Project_Proposal.docx`: Pragathi AAC / Simple AAC, 6 daily categories (food & drink, emotions, activities, school items, family members, basic needs: eating, drinking, toilet, sleep), early learning modules, Ministry of Health endorsement, and Idea-Hub publishing partnership.
  4. Rebuild both PDF packages locally in `.local_erc_private/exports_private/`:
     - `01_Complete_ERC_Application.pdf` (64 pages, 1.07 MB)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, verified 0 anonymity leaks across all investigator/supervisor names and universities)
  5. Update audit registers, applicability notes, and QA records.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `7cd027b5993685f403e061806fb6b0a8f71bb2f0` (short: `7cd027b`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`a2ceb48..7cd027b  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Verified zero anonymity leaks in Soft Copy 2. All private identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

### Milestone 4: Complete Submission Dossier Alignment with Published ERC Website Guidelines
- **Objectives**:
  1. Author dedicated formal documents for:
     - Item 6: `forms/13_Training_Certificates_PI_Supervisor_DRAFT.docx` (Certificates of training of PI and Supervisor in Research Methodology, Basic Research Ethics, and Good Clinical Practice / GCP).
     - Item 7: `forms/14_Animal_Handling_Statement_DRAFT.docx` (Formal declaration of non-applicability of animal handling training; strictly human-computer interaction and non-invasive assistive software evaluation).
     - Item 8: `forms/15_Fee_Payment_Receipt_Placeholder_DRAFT.docx` (Faculty Shroff payment record and verification placeholder for the physical hard-copy dossier).
  2. Update `build_erc_package.py` and compilation pipeline to sequence Soft Copy 1 (`01_Complete_ERC_Application.pdf`) in exact 1-to-7 order as mandated on the official website:
     - Item 1: Cover letter to Chairperson (`01_Cover_Letter_DRAFT.docx`)
     - Item 2: Completed Application Form (`02_Human_Research_Application_DRAFT.docx`)
     - Item 3: Supervisor Consent Letter (`03_Supervisor_Letter_DRAFT.docx`)
     - Item 4: Detailed Research Protocol + All Annexures (`04_AAC_ERC_Research_Protocol_DRAFT.docx`, `05`, `06`, `07`, `08`, `09`, `11`)
     - Item 5: Curriculum Vitae of Principal Investigator / Researcher (`10_CV_Principal_Investigator_DRAFT.docx`)
     - Item 6: Training Certificates Dossier (`13_Training_Certificates_PI_Supervisor_DRAFT.docx`)
     - Item 7: Animal Handling Training Non-Applicability Declaration (`14_Animal_Handling_Statement_DRAFT.docx`)
     - Verification Checklist (`12_ERC_Submission_Checklist.docx`)
  3. Recompile and verify packages:
     - `01_Complete_ERC_Application.pdf` (68 pages, 1.21 MB)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, verified 0 anonymity leaks)
  4. Update `README.md`, `qa/document_inventory.md`, `qa/submission_checklist.md`, `qa/qa_report.md`, and production logs.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `718f009a6ee3bb609b55239e249964176cf3832c` (short: `718f009`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`7cd027b..718f009  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Zero leaks in Soft Copy 2. All private identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

### Milestone 5: Critical Correction of Research Ownership, Team Leadership & PI Designation
- **Objectives**:
  1. Realign research leadership and ownership: Explicitly establish undergraduate medical student researchers **Thamalka D. J. G.** and **D. V. W. Gunawardana** (Faculty of Medicine, University of Ruhuna) as the primary student researchers leading the clinical protocol, participant evaluations, and ethics application under the academic supervision of **Dr. Gayani Punchihewa** (Senior Lecturer in Psychiatry & Consultant Psychiatrist).
  2. Revoke unauthorized Principal Investigator appointment: Consistently mark PI cages and declarations across all forms and protocols as `[PRINCIPAL INVESTIGATOR — FORMAL CONFIRMATION REQUIRED: Lead Medical Student Researcher / Academic Supervisor]` pending formal departmental confirmation per Faculty ERC regulations.
  3. Accurately position **E.K.Y.P. Fernando (Yasas Pasindu Fernando)** as **Technical Research Collaborator, AAC Application Developer & Technical Implementation Lead**. Clarify that his MSc in Artificial Intelligence studies (Kingston University, ongoing) and BEng (Hons) in Software Engineering (London Metropolitan University, completed) represent personal academic qualifications only; this study is an independent Ruhuna medical student project and NOT a foreign university dissertation or sponsored thesis.
  4. Audit, correct, and regenerate all 15 DOCX documents across `forms/`, `protocol/`, `annexures/`, `data_management/`, and `qa/`. In `forms/10_CV_Principal_Investigator_DRAFT.docx`, establish Section A as the official PI CV Template [Confirmation Required] and Section B as the Technical Collaborator CV.
  5. Privacy audit & sanitization: Sanitized personal email address (`Dulithvisura7@gmail.com`) to placeholders in git files. Confirmed all private contact details, authentic signatures, and final PDF packages remain isolated in untracked `.local_erc_private/`.
  6. Rebuild and verify PDF packages locally:
     - `01_Complete_ERC_Application.pdf` (71 pages, 1.23 MB, Items 1 through 7 + submission verification checklist)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, Item 4 only, strictly de-identified with **PASSED: Zero investigator names, emails, or student identity leaks**).
  7. Update `README.md`, `source_register.md`, `applicability_and_missing_info.md`, `source_fact_matrix.md`, `qa/qa_report.md`, `qa/submission_checklist.md`, and `qa/document_inventory.md`.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `059ef3123b364438340d02778dae32801e06fae9` (short: `059ef31`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`d245d11..059ef31  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Verified zero anonymity leaks in Soft Copy 2 (0 leaks across 24 pages). Personal emails sanitized to placeholders in tracked files. All private identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

### Milestone 6: Neutral ERC Chairperson Addressee & Fee Schedule Classification Alignment
- **Objectives**:
  1. Neutralize ERC Chairperson addressee: Replaced individual chairperson references with "The Chairperson, Ethics Review Committee, Faculty of Medicine, University of Ruhuna, P.O. Box 70, Galle, Sri Lanka" across `forms/01_Cover_Letter_DRAFT.docx`, `forms/14_Animal_Handling_Statement_DRAFT.docx`, and document registries, preventing discrepancies from differing website/secretariat personnel notices.
  2. Reconcile ERC processing fee classification with official faculty instructions (`https://www.medi.ruh.ac.lk/ethics/instructions.html`): Replaced assumed fixed Category I (LKR 3,000) with "PENDING PI DESIGNATION AND ERC CONFIRMATION: Category I (LKR 3,000 if Faculty Academic Staff PI) / Category III (No fee / Free if Undergraduate Medical Student PI for curriculum project)".
  3. Update `forms/15_Fee_Payment_Receipt_Placeholder_DRAFT.docx`, `forms/01_Cover_Letter_DRAFT.docx`, `protocol/04_AAC_ERC_Research_Protocol_DRAFT.docx` (budget), `qa/12_ERC_Submission_Checklist.docx`, `applicability_and_missing_info.md`, `source_fact_matrix.md`, `qa/submission_checklist.md`, and `qa/qa_report.md`.
  4. Regenerate all 15 DOCX documents and recompile submission packages:
     - `01_Complete_ERC_Application.pdf` (71 pages, 1.24 MB, Items 1 through 7 + submission verification checklist)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, Item 4 only, strictly de-identified with **PASSED: Zero investigator names, emails, or student identity leaks**).
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `32953503b22cf331b26284646543b59df515e197` (short: `3295350`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`a0ae172..3295350  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Verified zero anonymity leaks in Soft Copy 2. All private identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

### Milestone 7: Final Role Terminology Simplification & Student Title Correction
- **Objectives**:
  1. Remove "Lead" designation from E.K.Y.P. Fernando's role across all documents: Updated title from "Technical Implementation Lead" to strictly "Technical Research Collaborator & AAC Application Developer", ensuring zero ambiguity regarding research project leadership.
  2. Correct student investigator title & salutation: Explicitly designated lead medical student researcher as "Ms. Thamalka D. J. G." (`Title: Ms.`) across Application Form (Table 4 & Table 37), Cover Letter, Animal Statement, Protocol metadata, and Information Sheet contact lines.
  3. Rebuild all 15 DOCX documents and recompile official PDF packages:
     - `01_Complete_ERC_Application.pdf` (71 pages, 1.24 MB)
     - `02_Anonymous_Research_Proposal.pdf` (24 pages, 0.55 MB, strictly de-identified with 0 leaks)
  4. Update `source_fact_matrix.md`, `qa/qa_report.md`, `README.md`, and production logs.
- **Staged Paths**: `docs/ethics/ruhuna_erc/`
- **Commit Hash**: `61eb22d8616a233519b781da26084013063f134c` (short: `61eb22d`)
- **Working Branch**: `feature/modern-ui-offline-smart-images`
- **Configured Remote**: `origin https://github.com/YasasPasinduFernando/simple_aac_app.git`
- **Push Result**: **SUCCESSFUL** (`1243b51..61eb22d  feature/modern-ui-offline-smart-images -> feature/modern-ui-offline-smart-images`).
- **Privacy Status**: Verified zero anonymity leaks in Soft Copy 2. All private identity-bearing PDFs and private details kept strictly in `.local_erc_private/` (untracked).

---

*(Further milestones logged upon completion)*
