#!/usr/bin/env python3
"""Build the two electronic files required for an initial human-research application.

Item 6 certificates, the animal letter and the fee receipt are not inserted.
The anonymous file is item 4 only.
"""

import os
import shutil
import subprocess
import sys

from pypdf import PdfReader, PdfWriter

from docx_common import (
    add_body,
    create_styled_document,
    erc_root,
    load_private_contacts,
    repo_root,
    save_doc,
    setup_header_footer,
)
from generate_admin_docs import (
    build_animal_statement,
    build_cover_letter,
    build_cv,
    build_fee_status,
    build_submission_checklist,
    build_supervisor_letter,
    build_training_status,
)
from generate_application_form import populate_application_form
from generate_protocol_and_annexures import TOC_ENTRIES, build_research_protocol

HEADINGS = [title for title, _level in TOC_ENTRIES]


def convert_docx_to_pdf(docx_path, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("HOME", os.path.join(out_dir, "lo_home"))
    os.makedirs(env["HOME"], exist_ok=True)
    env["SAL_USE_VCLPLUGIN"] = "svp"
    command = [
        "libreoffice",
        "--headless",
        "--norestore",
        "--convert-to",
        "pdf",
        "--outdir",
        out_dir,
        docx_path,
    ]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
    if result.returncode != 0:
        raise RuntimeError(result.stderr or result.stdout)
    pdf_path = os.path.join(out_dir, os.path.splitext(os.path.basename(docx_path))[0] + ".pdf")
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(pdf_path)
    return pdf_path


def extract_toc(pdf_path):
    text = subprocess.check_output(["pdftotext", "-layout", pdf_path, "-"], text=True, errors="replace")
    found = {}
    for number, page in enumerate(text.split("\f"), start=1):
        if "Contents" in page and "1. Introduction" in page and "6. References" in page:
            continue
        lines = [" ".join(line.split()) for line in page.splitlines()]
        for index, line in enumerate(lines):
            if not line or "...." in line:
                continue
            window = line
            if index + 1 < len(lines):
                window = f"{line} {lines[index + 1]}"
            for heading in HEADINGS:
                if heading in found:
                    continue
                if line == heading or line.startswith(heading) or window.startswith(heading):
                    found[heading] = number
    return found


def strip_and_write(pdf_paths, output_path, title):
    writer = PdfWriter()
    for path in pdf_paths:
        reader = PdfReader(path)
        for page in reader.pages:
            writer.add_page(page)
    writer.add_metadata({"/Title": title, "/Author": "", "/Creator": "", "/Producer": "", "/Subject": ""})
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as handle:
        writer.write(handle)
    return len(writer.pages)


def text_of_pdf(path):
    reader = PdfReader(path)
    parts = []
    for page in reader.pages:
        parts.append(page.extract_text() or "")
    meta = reader.metadata or {}
    meta_text = " ".join(str(value) for value in meta.values() if value)
    return "\n".join(parts), meta_text


def write_pointer(path, message):
    doc = create_styled_document()
    setup_header_footer(doc)
    add_body(doc, message)
    save_doc(doc, path, "Pointer")


def main():
    root = erc_root()
    repository = repo_root()
    private = os.path.join(repository, ".local_erc_private")
    named_dir = os.path.join(private, "named_drafts")
    build_dir = os.path.join(root, "scripts", "build")
    exports = os.path.join(private, "exports_private")
    os.makedirs(named_dir, exist_ok=True)
    if os.path.isdir(build_dir):
        shutil.rmtree(build_dir)
    os.makedirs(build_dir, exist_ok=True)
    os.makedirs(exports, exist_ok=True)

    template = os.path.join(root, "scripts", "templates", "Application_for_Human_Research_OFFICIAL_BLANK.docx")

    print("Generating tracked drafts without telephone or email")
    build_cover_letter(os.path.join(root, "forms", "01_Cover_Letter_DRAFT.docx"))
    populate_application_form(template, os.path.join(root, "forms", "02_Human_Research_Application_DRAFT.docx"))
    build_supervisor_letter(os.path.join(root, "forms", "03_Supervisor_Letter_DRAFT.docx"))
    build_cv(os.path.join(root, "forms", "10_CV_Principal_Investigator_DRAFT.docx"))
    build_training_status(os.path.join(root, "forms", "13_Training_Certificates_PI_Supervisor_DRAFT.docx"))
    build_animal_statement(os.path.join(root, "forms", "14_Animal_Handling_Statement_DRAFT.docx"))
    build_fee_status(os.path.join(root, "forms", "15_Fee_Payment_Receipt_Placeholder_DRAFT.docx"))
    build_submission_checklist(os.path.join(root, "qa", "12_ERC_Submission_Checklist.docx"))

    pointer = (
        "This separate file is not part of the submission. The current English text is an annex "
        "of the research proposal, Version 01, 06 November 2026. Do not submit an older annex in its place. "
        "Sinhala and Tamil translations have not been prepared."
    )
    for name in (
        "05_Parent_or_Guardian_Information_Sheet_DRAFT.docx",
        "05_Parent_or_Guardian_Information_Sheet_ANONYMOUS_DRAFT.docx",
        "06_Parent_or_Guardian_Consent_Form_DRAFT.docx",
        "06_Parent_or_Guardian_Consent_Form_ANONYMOUS_DRAFT.docx",
        "07_Child_Assent_Protocol_DRAFT.docx",
        "07_Child_Assent_Protocol_ANONYMOUS_DRAFT.docx",
        "08_Study_Instruments_DRAFT.docx",
        "08_Study_Instruments_ANONYMOUS_DRAFT.docx",
        "09_Site_Permission_Request_Letters_DRAFT.docx",
        "09_Site_Permission_Request_Letters_ANONYMOUS_DRAFT.docx",
    ):
        write_pointer(os.path.join(root, "annexures", name), pointer)
    data_note = (
        "Data handling is described in section 5.10 of the research proposal. "
        "A second data-management document is not part of this draft."
    )
    write_pointer(os.path.join(root, "data_management", "11_Data_Management_Plan_DRAFT.docx"), data_note)
    write_pointer(os.path.join(root, "data_management", "11_Data_Management_Plan_ANONYMOUS_DRAFT.docx"), data_note)

    anon_docx = os.path.join(root, "protocol", "04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx")
    named_docx = os.path.join(named_dir, "04_Research_Proposal_NAMED.docx")
    tracked_named = os.path.join(root, "protocol", "04_AAC_ERC_Research_Protocol_DRAFT.docx")

    print("First protocol pass")
    build_research_protocol(anon_docx, anonymous=True)
    build_research_protocol(named_docx, anonymous=False)
    anon_pdf = convert_docx_to_pdf(anon_docx, build_dir)
    named_pdf = convert_docx_to_pdf(named_docx, build_dir)
    anon_toc = extract_toc(anon_pdf)
    named_toc = extract_toc(named_pdf)
    print("Anonymous contents pages:", anon_toc)
    print("Named contents pages:", named_toc)

    print("Second protocol pass with contents page numbers")
    build_research_protocol(anon_docx, anonymous=True, toc=anon_toc)
    build_research_protocol(named_docx, anonymous=False, toc=named_toc)
    build_research_protocol(tracked_named, anonymous=False, toc=named_toc)

    print("Private named copies")
    build_cover_letter(os.path.join(named_dir, "01_Cover_Letter.docx"))
    populate_application_form(template, os.path.join(named_dir, "02_Application.docx"))
    build_supervisor_letter(os.path.join(named_dir, "03_Supervisor_Letter.docx"))
    build_cv(os.path.join(named_dir, "05_CV_notes.docx"))
    # Rebuild named proposal after the private path is known so the contact line can appear.
    build_research_protocol(named_docx, anonymous=False, toc=named_toc)

    print("Converting submission documents")
    cover_pdf = convert_docx_to_pdf(os.path.join(named_dir, "01_Cover_Letter.docx"), build_dir)
    application_pdf = convert_docx_to_pdf(os.path.join(named_dir, "02_Application.docx"), build_dir)
    supervisor_pdf = convert_docx_to_pdf(os.path.join(named_dir, "03_Supervisor_Letter.docx"), build_dir)
    proposal_pdf = convert_docx_to_pdf(named_docx, build_dir)
    # Contents numbers were taken from the previous pass. Rebuild once more if the contact line moved them.
    named_toc_final = extract_toc(proposal_pdf)
    if named_toc_final != named_toc:
        print("Contents shifted after the contact line. Rebuilding the named proposal.")
        build_research_protocol(named_docx, anonymous=False, toc=named_toc_final)
        proposal_pdf = convert_docx_to_pdf(named_docx, build_dir)
    cv_pdf = convert_docx_to_pdf(os.path.join(named_dir, "05_CV_notes.docx"), build_dir)
    anon_final = convert_docx_to_pdf(anon_docx, build_dir)

    complete = os.path.join(exports, "01_Complete_ERC_Application.pdf")
    anonymous = os.path.join(exports, "02_Anonymous_Research_Proposal.pdf")
    complete_pages = strip_and_write(
        [cover_pdf, application_pdf, supervisor_pdf, proposal_pdf, cv_pdf],
        complete,
        "Draft ERC application",
    )
    anonymous_pages = strip_and_write([anon_final], anonymous, "Research proposal")

    contacts = load_private_contacts() or {}
    forbidden = [
        "Yasas",
        "Fernando",
        "Punchihewa",
        "Gayani",
        "Thamalka",
        "Gunawardana",
        "Kingston",
        "London Metropolitan",
        "Pasindu",
        "Idea-Hub",
        "Idea Hub",
        "Ideahub",
        "E.K.Y.P",
    ]
    if contacts.get("phone"):
        forbidden.append(contacts["phone"])
    if contacts.get("email"):
        forbidden.append(contacts["email"])
    body, meta = text_of_pdf(anonymous)
    leaks = []
    haystack = (body + "\n" + meta).lower()
    for term in forbidden:
        if term.lower() in haystack:
            leaks.append(term)
    named_body, _named_meta = text_of_pdf(complete)
    idea = "idea-hub" in named_body.lower() or "idea hub" in named_body.lower()

    preview_dir = os.path.join(private, "qa_pages")
    os.makedirs(preview_dir, exist_ok=True)
    for label, pdf, pages in (
        ("anon", anonymous, "1-3"),
        ("named_proposal", proposal_pdf, "1-3"),
        ("cover", cover_pdf, "1"),
        ("form", application_pdf, "1"),
    ):
        subprocess.run(
            ["pdftoppm", "-f", pages.split("-")[0], "-l", pages.split("-")[-1], "-r", "110", "-png", pdf, os.path.join(preview_dir, label)],
            check=True,
        )

    log_path = os.path.join(root, "qa", "production_log.md")
    with open(log_path, "w", encoding="utf-8") as log:
        log.write("# Production log\n\n")
        log.write("Draft date used in the headers: 06 November 2026. Version 01.\n\n")
        log.write(f"- Complete named file: `{complete}` — {complete_pages} pages.\n")
        log.write(f"- Anonymous proposal: `{anonymous}` — {anonymous_pages} pages.\n")
        log.write(f"- Anonymous identity leaks: {leaks if leaks else 'none found'}.\n")
        log.write(f"- Former publishing-partner name in the named file: {'yes' if idea else 'no'}.\n")
        log.write("- Training certificates, animal-handling letter and fee receipt were not inserted.\n")
        log.write("- Telephone and email are read from the local contact file and are not written in the generator.\n")
        log.write("\n## Contents page numbers, anonymous proposal\n\n")
        for heading in HEADINGS:
            log.write(f"- {heading}: {anon_toc.get(heading, 'not found')}\n")
    review = os.path.join(private, "review_word")
    os.makedirs(review, exist_ok=True)
    review_files = [
        ("01_Cover_Letter.docx", os.path.join(named_dir, "01_Cover_Letter.docx")),
        ("02_Application_Form.docx", os.path.join(named_dir, "02_Application.docx")),
        ("03_Supervisor_Letter.docx", os.path.join(named_dir, "03_Supervisor_Letter.docx")),
        ("04_Research_Proposal.docx", os.path.join(named_dir, "04_Research_Proposal_NAMED.docx")),
        ("04_Research_Proposal_ANONYMOUS.docx", anon_docx),
        ("05_CV_notes.docx", os.path.join(named_dir, "05_CV_notes.docx")),
    ]
    manifest_lines = [
        "# Editable Word files for supervisor review",
        "",
        "Version 01. 06 November 2026. Unsigned.",
        "",
        "Open these in Word. The PDF files in `exports_private` are previews only.",
        "",
    ]
    for dest_name, source in review_files:
        target = os.path.join(review, dest_name)
        shutil.copy2(source, target)
        manifest_lines.append(f"- `{target}`")
    manifest_lines.extend(
        [
            "",
            "## Required before this package can be treated as complete",
            "",
            "1. Sample size. Dr Gayani Punchihewa must set the number of children. No number has been entered. A power calculation for a difference between groups does not fit this one-sitting descriptive study. The number depends on how many eligible children attend the centre and on the proportion she will accept for the main observations.",
            "2. The person who will sign as the applicant. This has not been confirmed. E.K.Y.P. Fernando is not the applicant.",
            "3. The supervisor’s signature. The Faculty staff page lists her as Senior Lecturer and Psychiatrist. The cover letter uses Senior Lecturer in Psychiatry, which she should confirm.",
            "4. Whether the study is required by the undergraduate curriculum, and which fee applies.",
            "5. Written permission from PRAGATHI Child Intervention Centre.",
            "6. Sinhala and Tamil parent forms, checked by competent speakers.",
            "7. Training certificates, student registration numbers, and the place where consent forms will be locked.",
            "",
        ]
    )
    manifest_path = os.path.join(review, "MANIFEST.md")
    with open(manifest_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(manifest_lines))
    print("Review Word files:", review)

    print(f"Complete pages: {complete_pages}")
    print(f"Anonymous pages: {anonymous_pages}")
    print(f"Leaks: {leaks if leaks else 'none'}")
    print(f"Former partner name in named file: {idea}")
    if leaks or idea:
        sys.exit(1)


if __name__ == "__main__":
    main()
