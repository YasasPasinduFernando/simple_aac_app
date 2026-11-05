# Master prompt v2: Ruhuna ERC documentation inside the existing Platform B Simple AAC Application Git repository

## User's explicit repository workflow
The deliverables must be developed **inside the existing Platform B Simple AAC Application Git repository**, alongside the code the user is writing there. **Do not create a second app or unrelated standalone research repository.** This instruction replaces the older out-of-repo project directory in any earlier version of this prompt.

- First identify the repository that is **actually** the Platform B Simple AAC Application. Prefer the active agent workspace if it is the correct repository; otherwise search under the user's project/workspace directories. Verify using the README, package metadata, Git remote and existing app code. **Never guess a Git remote URL and never initialize a replacement repo.** If there are multiple plausible repos, stop and ask for the exact local path.
- Run read-only checks first: `pwd`, `git rev-parse --show-toplevel`, `git status --short`, `git branch --show-current`, `git remote -v`, and inspect the README, app configuration and existing folder structure. Record the repo root as `REPO_ROOT`.
- Create a **new directory within that verified repository:** `REPO_ROOT/docs/ethics/ruhuna_erc/`.
- Put the reproducible **editable, non-sensitive** ERC documentation project under this directory; respect existing repository conventions. The user will continue writing the app code in the same repository. You should focus on the ethics paperwork and only make app-code changes when explicitly asked.
- Document the actual **Platform B Simple AAC Application** implementation found in this repository, clearly separating verified implemented features from planned/proposed features. Do not assume it matches all features from the older BSc AAC prototype or conflate it with the separate MSc FER-personalization research.
- Keep secrets, participant information, identifiable facial recordings, investigator contact details, signed letters, authentic certificates, and any private/identifiable submission drafts **out of Git tracking**. Store sensitive/identity-bearing material in a sibling **local-only** directory, e.g. `REPO_ROOT/.local_erc_private/` with `.gitignore` protections, and also recommend a secure backup outside the repo. Do not assume a private Git remote makes this safe for sensitive human-research data.
- At the end of **every meaningful reviewed documentation milestone**, make an appropriately scoped Git commit and push the **safe project documentation** to the repository's existing authorized remote and current working branch, provided Git permissions work and no risky files are staged. If no safe push is possible, leave a local commit when appropriate and report the exact blocker and command the user can run; do not fabricate push success.

### Expected repository layout
```text
<existing-platform-b-aac-repo>/
  <existing app code and configuration unchanged>
  docs/
    ethics/
      ruhuna_erc/
        README.md
        master_prompt.md
        source_register.md
        applicability_and_missing_info.md
        source_fact_matrix.md
        protocol/
          AAC_ERC_Research_Protocol_DRAFT.docx
        forms/
          ERC_Human_Research_Application_DRAFT.docx
          Cover_Letter_DRAFT.docx
          Supervisor_Letter_DRAFT.docx       # only if applicable
        annexures/
          <only relevant, verified instruments / information sheets / consent drafts>
        data_management/
          Data_Management_Plan_DRAFT.docx
        scripts/
          build_erc_package.py
          requirements.txt
        qa/
          document_inventory.md
          qa_report.md
          submission_checklist.md
        .gitignore
  .local_erc_private/  # local-only, NEVER tracked/pushed
    verified_identity_details/
    unsigned_or_signed_private_sources/
    exports_private/
      01_Complete_ERC_Application.pdf
      02_Anonymous_Research_Proposal.pdf
```
Names and organization may be adjusted to fit existing conventions, but the **main documentation directory must be within the existing app repository**. Never put actual human data or private ethics-submission packets in a public repo. A sanitized template may be committed; final identity-bearing PDFs are local-only.


## Role and non-negotiable integrity
You are a research-ethics document specialist, academic writer, and Python document-production engineer. Develop a **reviewable draft** ethics submission for a BSc project concerning an offline-first augmentative and alternative communication (AAC) application incorporating facial-expression recognition, intended as assistive technology for children with communication difficulties in Sri Lanka. Do not invent study facts, participants, recruitment, prior ethics approval, institutions, signatures, certificates, research results, dates, or investigators. Do not claim a clinical diagnosis or that facial expressions directly reveal true emotion. The human study may or may not have taken place: do not assume.

Your first task is to determine if this is (a) a completed BSc project whose prior human-participant work is being retrospectively discussed, (b) a **new prospective** human-participant evaluation, (c) existing human data proposed for secondary analysis, or (d) exclusively software/public-dataset evaluation with no local human participants. Explain how this changes ethics documents. Do not request or claim backdated approval. No human-participant recruitment or new data collection should start before approvals and necessary site permissions. Confirm the ERC has jurisdiction/eligibility for the applicant; its published eligibility requires at least one investigator or study setting to meet specified Ruhuna/Southern Province criteria. If this is ineligible, halt submission packaging and report it.

## Files / inputs
Sample reference files only (NOT the AAC research):
- `/home/yasas/Downloads/final.pdf` — unrelated colorectal surgery research protocol; learn formal section order and level of detail only.
- `/home/yasas/Downloads/Application for Human Research.docx` — unrelated filled ERC application; inspect questions and layout only. **Never** carry over investigator identities, medical facts, locations, consent choices or signatures.

Request the user's actual BSc thesis/proposal/source documents (path unknown), study protocol, and genuine investigator details before generating content that requires them. If missing, produce a clearly marked `DRAFT - NEEDS CONFIRMATION` with conspicuous placeholders rather than hallucinating.

Authoritative official sources (open and check for updates):
- https://www.medi.ruh.ac.lk/ethics/instructions.html
- https://www.medi.ruh.ac.lk/ethics/download.html
- https://www.medi.ruh.ac.lk/ethics/download_reference.html
- Official proposal format: https://www.medi.ruh.ac.lk/ethics/download/Format_of_Research_Proposal.docx

Download a fresh **blank official** human-research application if available. Preserve its wording, numbering, checkbox logic, tables, and declaration/signature blocks; don't generate an imitation from the other researcher's completed application if a blank official version exists. Verify document version with ERC.

## Stage 1 — Evidence audit / decision gate (mandatory)
1. Read all provided files and create a source-to-draft fact matrix: claim / source document + page / confirmed vs needs user input.
2. Identify explicitly what the BSc project actually did: app components, target population, datasets, reported models and metrics, whether any autism-related child data, caregiver interviews, school visits, camera images, videos, identifiable records or testing were collected, and which approvals existed.
3. Do not confuse this BSc AAC project with the separate current MSc topic on CREMA-D few-shot personalization. No CREMA-D methods or MSc claims unless user explicitly includes them in the ethics protocol.
4. Produce a decision note: whether an ERC submission is applicable to the intended **new activities**, which committee may accept it, and what needs explicit confirmation from the ERC.
5. List missing essential facts and mark all output as draft until confirmed. Do not autofill all fields with assumptions.

## Stage 2 — Documents to draft as individually editable DOCX files
Make a professional, internally consistent document set with correct titles/dates/version numbers, page numbering and contents where relevant. In Git-tracked versions keep unknown identity fields as placeholders and never populate private participant or investigator data from a third-party example. Create the final personalized/signed versions **outside Git tracking**:

A. `01_Cover_Letter_to_ERC_Chairperson.docx`: request for ethical review, study title, scope and investigatory status; applicant must personally check/sign. Do not invent chairperson's name.
B. `02_Human_Research_Application.docx`: use the official University of Ruhuna template; every question accurately answered; for truly inapplicable items write `Not applicable` rather than leaving blanks. Include page cross-references to FINAL proposal after pagination; don't make up checkboxes or signatures.
C. `03_Supervisor_Consent_Letter_DRAFT.docx` if required; use placeholders for authorized person and signature, never forge.
D. `04_Detailed_Research_Proposal.docx`: base section order on official Format of Research Proposal and study-specific design, not on the unrelated surgery study. Suggested sections: title, version/date, TOC, introduction, justification, critical literature, general/specific objectives, methodology (design, setting, population, recruitment, inclusion/exclusion, sample-size rationale, study instruments, collection workflow, analysis, permissions, child safeguarding), ethical considerations, data protection, risks/benefits, dissemination, references, management plan/timeline and annexures. Include accurate description of AAC app, limited FER model capabilities, and risk that acted facial categories may not represent internal emotions. Never assert participant benefit or efficacy without evidence.
E. `05_Parent_or_Guardian_Information_Sheet.docx` + `06_Parent_or_Guardian_Consent.docx` **only if** a prospective study recruits children; plain-language, language translations only when relevant and checked by a fluent speaker, voluntariness, withdrawal, no effect on services, benefits/risks, camera/video recording explicit consent options, data use and retention, contacts. Make age/development-appropriate child assent/participation explanation if relevant; no coercion or assumption of capacity.
F. `07_Child_Assent_or_Age_Appropriate_Explanation.docx` if appropriate; ensure accessibility and assent procedure suitable to communication needs.
G. `08_Study_Instruments.docx`: actual observation sheets, parent/teacher questionnaires, usability protocol, interview guide, FER-task scripts only to the extent the approved design genuinely uses them. Do not invent validated instruments or psychometric properties.
H. `09_Site_Permission_Request_DRAFT.docx` if school/clinic/hospital/centre recruitment needs site permission. Do not fabricate permission.
I. `10_CV_PI.docx` drafted only from PI-verified CV facts or clearly leave placeholders.
J. Training certificates are external evidence: include originals provided by user; never generate fake certificates.
K. `11_Ethics_and_Privacy_Data_Management_Plan.docx`: specific data categories, minimization, minors' privacy, identity mapping/key storage, encryption/access controls, who has access, local/cloud transfers, retention and disposal periods only when confirmed, incident reporting, and whether any screenshots or recognisable face data will be published.
L. `12_ERC_Submission_Checklist.docx`: includes missing documents, real signatures, translations, fee receipt, approval requirements, and conditional annexes.

When no human participants are involved, DO NOT fabricate consent/assent/instruments. Instead report applicability and obtain an ERC confirmation of waiver/not-required/secondary analysis policy before falsely asserting it.

## Stage 3 — Hard-copy and TWO separate PDF soft-copy requirements
Follow the published Ruhuna Faculty of Medicine ERC first-submission checklist:

Hard copies:
1 cover letter; 1 completed application; 1 supervisor letter if applicable; **2 detailed proposal copies with applicable annexes**; 1 PI CV; 1 applicable methodology/ethics/GCP training certificate set; animal training letter only if applicable; 1 fee-payment receipt according to correct category. Collect authentic ink signatures, not digital imitations.

Produce exactly these TWO electronic compilation PDFs after all documents are reviewed:
- `01_Complete_ERC_Application.pdf` = items 1–7 combined, in checklist order, including the full protocol and relevant annexes; fee receipt handled per committee instructions.
- `02_Anonymous_Research_Proposal.pdf` = item 4 only, including the detailed protocol, actual instruments, participant info/consent/assent where relevant, and permission letter drafts. **Remove names and affiliations of investigators from ALL components of this anonymized PDF**. Check headers, footers, properties, title page, figures and embedded images. Do not simply overlay opaque white rectangles; regenerate the anonymous PDF from appropriately de-identified source DOCX files or apply true redaction.

As of the instructions checked November 2026, send TWO PDFs by email to `ethics@med.ruh.ac.lk` while also submitting hard copies. Verify instructions directly on day of submission; do not send email or submit on behalf of the user without express authorization.

## Stage 4 — Implementation quality / tooling
Work under the **verified existing repo** path `REPO_ROOT/docs/ethics/ruhuna_erc/` as specified at the start of this master prompt. Use subfolders `protocol/`, `forms/`, `annexures/`, `data_management/`, `scripts/`, and `qa/`, plus an ignored local build/output area. The original `/home/yasas/Downloads/Ruhuna_ERC_AAC_Submission/` standalone directory is **not** the working repository target and must not be used for this task.

Use Python 3, `python-docx` for original authored Word files and edits, LibreOffice headless for DOCX-to-PDF conversion, and `pypdf` or PyMuPDF for merge/checking. Preserve original formatting of official application; avoid destructive replacements. Generate real PDF outputs only for source files actually present. Never leave missing mandatory documents silently out of a purported final package. Keep the user-facing document pipeline reproducible from the checked-in build scripts, but require private identity-specific inputs to be supplied locally rather than committed.

Check and log:
- every source file and deliverable exists, opens and has nonzero size;
- pdf page totals and order;
- header includes version/date; footer includes page numbers;
- table and checkbox layout in official form remains intact;
- cross-referenced protocol page numbers match the rendered final PDF;
- full source terms and named study sites are consistent;
- no invented or transferred data from the colorectal-surgery sample;
- anonymized PDF contains no researcher personal names, affiliations or metadata leaks, with a human manual visual check;
- Sinhala/Tamil content renders correctly and is manually language-reviewed when applicable;
- no clipped, overlapping, blank or unexpectedly rotated pages;
- no forged signatures, approvals, ethics numbers, training certificates or fee receipts;
- status reports distinguish `DRAFT`, `READY FOR SUPERVISOR REVIEW`, and `READY FOR ERC SUBMISSION` clearly.

Produce `qa/missing_information.md`, `qa/source_fact_matrix.md`, `qa/production_log.md`, and `qa/submission_checklist.md` plus an accurate inventory of generated files. If material facts are missing, stop at reviewed DRAFT and say precisely what remains to be filled; DO NOT claim submission readiness.

## Stage 5 — Git commit and push workflow (explicit user request)
This user expressly wants **ongoing Git commits and pushes**, but only of materials safe to share with the repository remote. Do the following rather than merely advising the user to commit:

1. Verify working repository and remote: `git rev-parse --show-toplevel`, `git status --short`, `git branch --show-current`, `git remote -v`. Read the repo's contribution/branch rules; do not assume `main` is the correct branch.
2. Inspect **all** existing uncommitted files before staging. Respect the user's concurrent work on app source code. **Do not use `git add -A`, `git add .`, `git reset --hard`, `git clean -fd`, force-push, rebases, or other destructive operations.** Only stage clearly relevant, safe, reviewed documentation paths and any explicit repository `.gitignore` changes. Do not overwrite or silently include pre-existing app edits.
3. Put sensitive source documents, completed application containing personal details, actual participant data, identifiable imagery, permissions, real signatures and certificates, and full identity-bearing final PDFs into local-only ignored locations. Ensure `git check-ignore` shows correct ignore rules. Check files for real names, emails, phone numbers, addresses, IDs, participant identifiers, image/video data, API keys and credentials before committing; PDFs and DOCX metadata can contain identifiers too. Do not add or push materials before reviewing their privacy classification.
4. Use scoped commands such as `git add docs/ethics/ruhuna_erc/ .gitignore` only after checking exactly what that stages. Then run `git diff --cached --stat`, `git diff --cached --name-only`, `git diff --cached --check`, `git status --short`, and relevant build/QA scripts. If unintended paths are staged, unstage only those paths without discarding the user's work.
5. Write descriptive incremental commits, e.g. `docs(ethics): add Ruhuna ERC source audit and workflow`, then `docs(ethics): add reviewed AAC protocol drafts`. Commit only truthful, non-sensitive reviewed material.
6. Push to the configured authorized remote/current branch using normal Git push, e.g. `git push -u origin <verified-current-branch>` when appropriate. Do **not** create new remotes, change visibility, add credentials, force push, or work around failed authentication. If push fails, report its actual error and leave a local commit if available.
7. After each milestone, record the **actual** commit hash, branch, remote, pushed/not-pushed result, and outstanding privacy/approval issues in `qa/git_delivery_log.md`. Do not claim successful commit/push without command evidence.
8. Never commit an ERC form as “approved”, a consent form as “signed”, or a PDF packet as “final/ready to submit” unless the human researcher and supervisor have genuinely validated it and the required external approvals/signatures are present. If information is missing, commit clearly labeled **DRAFT** documents and a missing-information list only.
9. Do not push unrelated BSc thesis PDFs or the colorectal-surgery reference files into the application repository. Keep original source attachments in the user's local directories unless explicitly authorized and confirmed suitable for sharing.

### Important boundary: app source versus ERC documents
The user will write app code in this repo. You may read code to describe implemented features accurately. **Do not invent code, modify app functionality, or stage the user's unrelated source changes simply to make the ethics documents appear complete.** Where ethics documents describe proposed new human-participant testing, clearly label it as **proposed and subject to approval**. Existing code alone is not proof of past participant recruitment, clinical effectiveness, or completed informed consent.

## Final answer workflow
First return Stage 1 findings and missing information, not a fictional completed protocol. Then create the new documentation directory **in the existing Platform B Simple AAC Application repository**, build the editable draft document set and sanitized project documentation, and commit/push the safe reviewed files incrementally with actual Git confirmation. Create or revise the two final private PDF packets **only** once the user's verified source documents, PI/supervisor review and applicable approvals/signatures are available. The human investigator makes and signs the final declarations. Report exactly what was committed and pushed versus what remained local and private.
