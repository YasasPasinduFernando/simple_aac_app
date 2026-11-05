# University of Ruhuna Faculty of Medicine Ethics Review Committee (ERC) Documentation Package
## Platform B: Simple AAC Application Research Study

This directory contains the formal research ethics submission documentation and reproducible build pipeline for the **Simple AAC Application (SL AAC / Pragathi AAC)** research protocol, submitted for ethical review to the **Ethics Review Committee (ERC), Faculty of Medicine, University of Ruhuna, Sri Lanka**.

---

### 1. Repository Structure & Layout

```text
simple_aac_app/
├── lib/                             # Core Flutter AAC application source code
├── pubspec.yaml                     # Application package metadata (lk.yasas.simpleaac)
├── docs/
│   └── ethics/
│       └── ruhuna_erc/
│           ├── README.md                    # This document
│           ├── master_prompt.md             # Master specification & prompt v2
│           ├── source_register.md           # Audit of source files and references
│           ├── applicability_and_missing_info.md # Ethics applicability & gap analysis
│           ├── source_fact_matrix.md        # Fact verification matrix
│           ├── protocol/
│           │   └── 04_AAC_ERC_Research_Protocol_DRAFT.docx # Ruhuna ERC structured proposal
│           ├── forms/
│           │   ├── 01_Cover_Letter_DRAFT.docx             # Cover letter to ERC Chairperson (Item 1)
│           │   ├── 02_Human_Research_Application_DRAFT.docx # Official Ruhuna ERC application form (Item 2)
│           │   ├── 03_Supervisor_Letter_DRAFT.docx        # Supervisor endorsement & consent letter (Item 3)
│           │   ├── 10_CV_Principal_Investigator_DRAFT.docx# PI academic CV template (Item 5)
│           │   ├── 13_Training_Certificates_PI_Supervisor_DRAFT.docx # GCP & Ethics training certificates dossier (Item 6)
│           │   ├── 14_Animal_Handling_Statement_DRAFT.docx# Animal handling non-applicability declaration (Item 7)
│           │   └── 15_Fee_Payment_Receipt_Placeholder_DRAFT.docx # Faculty Shroff fee payment receipt record (Item 8)
│           ├── annexures/
│           │   ├── 05_Parent_or_Guardian_Information_Sheet_DRAFT.docx # Participant information
│           │   ├── 06_Parent_or_Guardian_Consent_Form_DRAFT.docx     # Parental proxy consent
│           │   ├── 07_Child_Assent_Protocol_DRAFT.docx              # Child assent procedure
│           │   ├── 08_Study_Instruments_DRAFT.docx                 # Usability & feedback scales
│           │   └── 09_Site_Permission_Request_Letters_DRAFT.docx    # Institutional permission drafts
│           ├── data_management/
│           │   └── 11_Data_Management_Plan_DRAFT.docx     # Data security and child privacy plan
│           ├── scripts/
│           │   ├── build_erc_package.py            # Automated DOCX-to-PDF & compilation engine
│           │   └── requirements.txt                # Python build dependencies
│           └── qa/
│               ├── document_inventory.md           # Complete file tracking inventory
│               ├── qa_report.md                    # Quality assurance & verification report
│               ├── submission_checklist.md         # Official Ruhuna ERC submission checklist
│               ├── 12_ERC_Submission_Checklist.docx# Editable checklist document
│               └── git_delivery_log.md             # Verified Git commit & push audit trail
└── .local_erc_private/              # [GIT-IGNORED] Sensitive, identity-bearing & signed items
    ├── verified_identity_details/   # Unredacted contact details & personal data
    ├── unsigned_or_signed_private_sources/ # Authentic wet-ink signatures & certificates
    └── exports_private/             # Generated submission PDF packages
        ├── 01_Complete_ERC_Application.pdf    # Soft copy 1 (Items 1–7 combined)
        └── 02_Anonymous_Research_Proposal.pdf # Soft copy 2 (Item 4 strictly de-identified)
```

---

### 2. Research Overview

- **Title of Research**: *SL AAC: A Mobile Application for Early Childhood Communication and Learning Support for Children with Learning and Communication Disabilities in Sri Lanka: A Prospective Usability and Feasibility Evaluation*
- **Lead Clinical / Community Institution**: PRAGATHI – Child Intervention Centre, Galle, Sri Lanka.
- **Collaborating Academic Institution**: Department of Psychiatry, Faculty of Medicine, University of Ruhuna, Sri Lanka.
- **Target Population**: Children aged 2–12 years with Autism Spectrum Disorder (ASD), Attention Deficit Hyperactivity Disorder (ADHD), and related speech/language communication difficulties; accompanied by parents/caregivers, speech-language therapists, and special educators.
- **Study Nature**: **Prospective** observational usability and feasibility evaluation. No experimental medication, no invasive procedures, no clinical diagnostic claims, and no prior unapproved human data collection.
- **Application Architecture**: Fully offline-first Flutter application (`lk.yasas.simpleaac`). All child card configurations and audio recordings remain strictly on the local device. No biometric or facial recognition data is stored or processed by the core app.

---

### 3. Ethical Principles & Data Privacy Boundary

1. **Zero Fabrication**: All facts derive from verified repository code and the project proposal (`SL_AAC_Project_Proposal.docx`). Any unconfirmed personal details, supervisor names, or dates are clearly tagged as `DRAFT - NEEDS CONFIRMATION`.
2. **Strict Separation of Technical Work**: The codebase represents Platform B (Flutter AAC app). Research activities involving human participants are prospective and conditional upon Ruhuna ERC approval and institutional administrative clearances.
3. **Privacy by Design**: Sensitive submission artifacts (containing wet-ink signatures, real contact numbers, training certificates, and identity-bearing soft copies) reside exclusively in `.local_erc_private/` and are strictly excluded from version control via `.gitignore`.
4. **De-identification of Soft Copy 2**: In compliance with Ruhuna ERC submission instructions, Soft Copy 2 (`02_Anonymous_Research_Proposal.pdf`) is compiled from a strictly anonymized stream where all investigator names, institutional titles, and email addresses are systematically omitted.

---

### 4. Reproducible Build Pipeline

The document generation suite converts all authored `.docx` files into publication-grade PDFs using headless LibreOffice and merges them using `pypdf`:

```bash
# Navigate to scripts directory
cd docs/ethics/ruhuna_erc/scripts

# Install dependencies (python-docx, pypdf)
pip install -r requirements.txt

# Compile both submission packages
python3 build_erc_package.py
```

Generated outputs are placed in `.local_erc_private/exports_private/`.
