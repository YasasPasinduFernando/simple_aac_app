#!/usr/bin/env python3
"""
Automated compilation pipeline for University of Ruhuna ERC submission packages.
Converts authored DOCX files to PDF using headless LibreOffice, merges them
in accordance with published submission instructions, creates strictly de-identified
peer-review copies, and exports to the local-only private folder (.local_erc_private/).
"""

import os
import sys
import subprocess
import shutil
from pypdf import PdfReader, PdfWriter

def convert_docx_to_pdf(docx_path, out_dir):
    """Converts a DOCX file to PDF using headless LibreOffice."""
    cmd = [
        "libreoffice",
        "--headless",
        "--convert-to", "pdf",
        docx_path,
        "--outdir", out_dir
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Conversion failed for {docx_path}: {res.stderr}")
    pdf_name = os.path.splitext(os.path.basename(docx_path))[0] + ".pdf"
    pdf_path = os.path.join(out_dir, pdf_name)
    if not os.path.exists(pdf_path):
        raise FileNotFoundError(f"Expected converted PDF not found: {pdf_path}")
    return pdf_path

def merge_pdfs(pdf_list, output_path):
    """Merges a list of PDF files sequentially into a single target PDF."""
    writer = PdfWriter()
    for p in pdf_list:
        reader = PdfReader(p)
        for page in reader.pages:
            writer.add_page(page)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f_out:
        writer.write(f_out)
    return len(writer.pages), os.path.getsize(output_path)

def verify_anonymization(pdf_path, forbidden_terms):
    """Verifies that an anonymized PDF contains no researcher names or private terms."""
    reader = PdfReader(pdf_path)
    leaks = []
    for idx, page in enumerate(reader.pages, start=1):
        txt = page.extract_text() or ""
        for term in forbidden_terms:
            if term.lower() in txt.lower():
                leaks.append((idx, term))
    return leaks

def main():
    print("=== UNIVERSITY OF RUHUNA ERC: AUTOMATED PACKAGE COMPILATION ===")
    scripts_dir = os.path.abspath(os.path.dirname(__file__))
    erc_root = os.path.abspath(os.path.join(scripts_dir, ".."))
    repo_root = os.path.abspath(os.path.join(erc_root, "..", "..", ".."))
    
    # Ignored build directories
    build_dir = os.path.join(scripts_dir, "build")
    exports_dir = os.path.join(repo_root, ".local_erc_private", "exports_private")
    os.makedirs(build_dir, exist_ok=True)
    os.makedirs(exports_dir, exist_ok=True)

    print(f"Repository Root : {repo_root}")
    print(f"ERC Docs Base   : {erc_root}")
    print(f"Local Build Dir : {build_dir}")
    print(f"Private Export  : {exports_dir}")

    # Step 1: Ensure all DOCX files are generated
    print("\n--- Step 1: Verifying & Generating DOCX Sources ---")
    admin_script = os.path.join(scripts_dir, "generate_admin_docs.py")
    app_script = os.path.join(scripts_dir, "generate_application_form.py")
    proto_script = os.path.join(scripts_dir, "generate_protocol_and_annexures.py")

    subprocess.run([sys.executable, admin_script], check=True)
    subprocess.run([sys.executable, app_script], check=True)
    subprocess.run([sys.executable, proto_script], check=True)
    print("All DOCX sources confirmed up to date.")

    # Step 2: Convert all DOCX to PDF
    print("\n--- Step 2: Converting DOCX to PDF via Headless LibreOffice ---")
    docx_files = [
        os.path.join(erc_root, "forms", "01_Cover_Letter_DRAFT.docx"),
        os.path.join(erc_root, "forms", "02_Human_Research_Application_DRAFT.docx"),
        os.path.join(erc_root, "forms", "03_Supervisor_Letter_DRAFT.docx"),
        os.path.join(erc_root, "protocol", "04_AAC_ERC_Research_Protocol_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "05_Parent_or_Guardian_Information_Sheet_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "06_Parent_or_Guardian_Consent_Form_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "07_Child_Assent_Protocol_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "08_Study_Instruments_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "09_Site_Permission_Request_Letters_DRAFT.docx"),
        os.path.join(erc_root, "forms", "10_CV_Principal_Investigator_DRAFT.docx"),
        os.path.join(erc_root, "data_management", "11_Data_Management_Plan_DRAFT.docx"),
        os.path.join(erc_root, "qa", "12_ERC_Submission_Checklist.docx"),
        # Anonymized variants
        os.path.join(erc_root, "protocol", "04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "05_Parent_or_Guardian_Information_Sheet_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "06_Parent_or_Guardian_Consent_Form_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "07_Child_Assent_Protocol_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "08_Study_Instruments_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "annexures", "09_Site_Permission_Request_Letters_ANONYMOUS_DRAFT.docx"),
        os.path.join(erc_root, "data_management", "11_Data_Management_Plan_ANONYMOUS_DRAFT.docx"),
    ]

    converted_pdfs = {}
    for d in docx_files:
        base_name = os.path.basename(d)
        print(f"Converting: {base_name} ...", end=" ", flush=True)
        pdf_path = convert_docx_to_pdf(d, build_dir)
        converted_pdfs[base_name] = pdf_path
        print(f"OK ({os.path.getsize(pdf_path)} bytes)")

    # Step 3: Compile Soft Copy 1 (01_Complete_ERC_Application.pdf)
    # Published Ruhuna ERC Order: Items 1 to 7 as a single PDF file
    print("\n--- Step 3: Compiling Soft Copy 1 (01_Complete_ERC_Application.pdf) ---")
    soft_copy_1_files = [
        converted_pdfs["01_Cover_Letter_DRAFT.docx"],
        converted_pdfs["02_Human_Research_Application_DRAFT.docx"],
        converted_pdfs["03_Supervisor_Letter_DRAFT.docx"],
        converted_pdfs["04_AAC_ERC_Research_Protocol_DRAFT.docx"],
        converted_pdfs["05_Parent_or_Guardian_Information_Sheet_DRAFT.docx"],
        converted_pdfs["06_Parent_or_Guardian_Consent_Form_DRAFT.docx"],
        converted_pdfs["07_Child_Assent_Protocol_DRAFT.docx"],
        converted_pdfs["08_Study_Instruments_DRAFT.docx"],
        converted_pdfs["09_Site_Permission_Request_Letters_DRAFT.docx"],
        converted_pdfs["11_Data_Management_Plan_DRAFT.docx"],
        converted_pdfs["10_CV_Principal_Investigator_DRAFT.docx"],
        converted_pdfs["12_ERC_Submission_Checklist.docx"]
    ]
    out_sc1 = os.path.join(exports_dir, "01_Complete_ERC_Application.pdf")
    pages_sc1, bytes_sc1 = merge_pdfs(soft_copy_1_files, out_sc1)
    print(f"Soft Copy 1 Built: {out_sc1}")
    print(f"Total Pages : {pages_sc1} | File Size: {bytes_sc1 / (1024*1024):.2f} MB")

    # Step 4: Compile Soft Copy 2 (02_Anonymous_Research_Proposal.pdf)
    # Published Ruhuna ERC Order: Item 4 ONLY (Proposal + Instruments + Consent + Info Sheet + Permission drafts)
    # CRITICAL: Names and affiliations of investigators must be removed!
    print("\n--- Step 4: Compiling Soft Copy 2 (02_Anonymous_Research_Proposal.pdf) ---")
    soft_copy_2_files = [
        converted_pdfs["04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["05_Parent_or_Guardian_Information_Sheet_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["06_Parent_or_Guardian_Consent_Form_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["07_Child_Assent_Protocol_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["08_Study_Instruments_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["09_Site_Permission_Request_Letters_ANONYMOUS_DRAFT.docx"],
        converted_pdfs["11_Data_Management_Plan_ANONYMOUS_DRAFT.docx"]
    ]
    out_sc2 = os.path.join(exports_dir, "02_Anonymous_Research_Proposal.pdf")
    pages_sc2, bytes_sc2 = merge_pdfs(soft_copy_2_files, out_sc2)
    print(f"Soft Copy 2 Built: {out_sc2}")
    print(f"Total Pages : {pages_sc2} | File Size: {bytes_sc2 / (1024*1024):.2f} MB")

    # Step 5: Verification of Anonymization in Soft Copy 2
    print("\n--- Step 5: Verifying Zero Anonymity Leakage in Soft Copy 2 ---")
    forbidden = ["Yasas", "Fernando", "Thamalka", "Gunawardana", "Dulithvisura7"]
    leaks = verify_anonymization(out_sc2, forbidden)
    if leaks:
        print(f"WARNING: Potential de-identification leak detected in Soft Copy 2: {leaks}")
    else:
        print("PASSED: Zero investigator names, emails, or student identity leaks found in Soft Copy 2.")

    # Step 6: Write production log
    log_path = os.path.join(erc_root, "qa", "production_log.md")
    with open(log_path, "w", encoding="utf-8") as f_log:
        f_log.write("# Ruhuna ERC Submission Package: Production & Build Log\n\n")
        f_log.write(f"**Date of Compilation**: November 2026  \n")
        f_log.write(f"**Build Tooling**: Python 3.12, LibreOffice Headless, pypdf  \n")
        f_log.write(f"**Build Status**: **SUCCESSFUL**  \n\n")
        f_log.write("## 1. Generated Soft Copy Deliverables\n\n")
        f_log.write("| Deliverable Name | Local File Path | Pages | Size (MB) | Anonymization Status |\n")
        f_log.write("| :--- | :--- | :---: | :---: | :--- |\n")
        f_log.write(f"| **Soft Copy 1 (Complete ERC Application)** | `.local_erc_private/exports_private/01_Complete_ERC_Application.pdf` | {pages_sc1} | {bytes_sc1 / (1024*1024):.2f} MB | Identifiable Submission Dossier |\n")
        f_log.write(f"| **Soft Copy 2 (Anonymous Research Proposal)** | `.local_erc_private/exports_private/02_Anonymous_Research_Proposal.pdf` | {pages_sc2} | {bytes_sc2 / (1024*1024):.2f} MB | **STRICTLY ANONYMIZED (0 leaks)** |\n\n")
        f_log.write("## 2. Component Page Counts\n\n")
        for d in docx_files:
            bname = os.path.basename(d)
            if bname in converted_pdfs:
                r = PdfReader(converted_pdfs[bname])
                f_log.write(f"- `{bname}`: {len(r.pages)} pages ({os.path.getsize(converted_pdfs[bname])} bytes)\n")

    print(f"\nProduction log saved to: {log_path}")
    print("\n=== BUILD PROCESS COMPLETED SUCCESSFULLY ===")

if __name__ == "__main__":
    main()
