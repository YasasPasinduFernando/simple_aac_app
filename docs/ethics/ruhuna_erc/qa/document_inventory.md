# Document Inventory: Ruhuna ERC Ethics Submission Package

This inventory catalogs all documents comprising the Platform B AAC research ethics submission suite within `docs/ethics/ruhuna_erc/` and the local-only build area `.local_erc_private/`.

---

## 1. Governance, Audit, and Guidance Documents

| File Name | Path | Format | Status | Description |
| :--- | :--- | :--- | :--- | :--- |
| `README.md` | `docs/ethics/ruhuna_erc/` | Markdown | Complete | Package overview, structure, principles, and build guide |
| `master_prompt.md` | `docs/ethics/ruhuna_erc/` | Markdown | Complete | Master specification directives and execution rules |
| `source_register.md` | `docs/ethics/ruhuna_erc/` | Markdown | Complete | Register of all project documents, URLs, and reference files |
| `applicability_and_missing_info.md` | `docs/ethics/ruhuna_erc/` | Markdown | Complete | Study categorization, eligibility analysis, and missing data list |
| `source_fact_matrix.md` | `docs/ethics/ruhuna_erc/` | Markdown | Complete | Fact-by-fact traceability matrix against source documents |

---

## 2. Core Ethics Application and Protocol Documents (Editable DOCX)

| File Name | Path | Format | Status | Description |
| :--- | :--- | :--- | :--- | :--- |
| `01_Cover_Letter_DRAFT.docx` | `forms/` | DOCX | Draft | Formal cover letter to Prof. C. M. Wickramatilake, Chairperson ERC |
| `02_Human_Research_Application_DRAFT.docx` | `forms/` | DOCX | Draft | Official Ruhuna ERC Application Form (Annexure UOR/03-001) |
| `03_Supervisor_Letter_DRAFT.docx` | `forms/` | DOCX | Draft | Letter of consent and academic endorsement from supervisor |
| `04_AAC_ERC_Research_Protocol_DRAFT.docx` | `protocol/` | DOCX | Draft | Detailed Research Proposal adhering strictly to Ruhuna 2021 format |
| `05_Parent_or_Guardian_Information_Sheet_DRAFT.docx` | `annexures/` | DOCX | Draft | Participant Information Sheet for parents/guardians (minors <18 yrs) |
| `06_Parent_or_Guardian_Consent_Form_DRAFT.docx` | `annexures/` | DOCX | Draft | Informed proxy consent certificate for parents/guardians |
| `07_Child_Assent_Protocol_DRAFT.docx` | `annexures/` | DOCX | Draft | Developmentally tailored assent explanation and monitoring protocol |
| `08_Study_Instruments_DRAFT.docx` | `annexures/` | DOCX | Draft | Usability evaluation tools, observation sheets, and survey scales |
| `09_Site_Permission_Request_Letters_DRAFT.docx` | `annexures/` | DOCX | Draft | Administrative clearance requests for PRAGATHI and Psychiatry clinic |
| `10_CV_Principal_Investigator_DRAFT.docx` | `forms/` | DOCX | Draft | Curriculum vitae dossier: Designated Principal Investigator template [Confirmation Required] and Technical Research Collaborator CV (Item 5) |
| `11_Data_Management_Plan_DRAFT.docx` | `data_management/` | DOCX | Draft | Ethics and privacy data management plan for child participants |
| `12_ERC_Submission_Checklist.docx` | `qa/` | DOCX | Draft | Official submission checklist verification form |
| `13_Training_Certificates_PI_Supervisor_DRAFT.docx` | `forms/` | DOCX | Draft | Training certificates cover and verification dossier (Item 6) |
| `14_Animal_Handling_Statement_DRAFT.docx` | `forms/` | DOCX | Draft | Formal declaration of non-applicability of animal handling training (Item 7) |
| `15_Fee_Payment_Receipt_Placeholder_DRAFT.docx` | `forms/` | DOCX | Draft | Physical hard-copy attachment sheet for Faculty Shroff processing fee receipt (Item 8) |

---

## 3. Automation and Build Scripts

| File Name | Path | Format | Status | Description |
| :--- | :--- | :--- | :--- | :--- |
| `build_erc_package.py` | `scripts/` | Python | Complete | Automated script to compile DOCX to PDF and assemble submission packages |
| `requirements.txt` | `scripts/` | Text | Complete | Python dependencies (`python-docx`, `pypdf`) |

---

## 4. Local-Only Private Submission Outputs (Ignored from Version Control)

| File Name | Path | Format | Status | Description |
| :--- | :--- | :--- | :--- | :--- |
| `01_Complete_ERC_Application.pdf` | `.local_erc_private/exports_private/` | PDF | Compiled | Soft Copy 1: Items 1 to 7 compiled sequentially as a single PDF |
| `02_Anonymous_Research_Proposal.pdf` | `.local_erc_private/exports_private/` | PDF | Compiled | Soft Copy 2: Item 4 only (Proposal + Annexures), strictly de-identified |
| Authentic Wet-Ink Signed Forms | `.local_erc_private/unsigned_or_signed_private_sources/` | PDF/Scan | Pending | Physical signed copies held offline |
| Training Certificates | `.local_erc_private/unsigned_or_signed_private_sources/` | PDF/Cert | Pending | GCP and ethics training certificates |
| Fee Payment Receipt | `.local_erc_private/unsigned_or_signed_private_sources/` | PDF/Receipt | Pending | Official receipt from Faculty of Medicine Shroff counter |
