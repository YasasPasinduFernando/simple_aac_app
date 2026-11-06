# University of Ruhuna ERC drafts — picture-based communication study

These files are a **draft for the research team and Dr Gayani Punchihewa**. They are not an ethics application that has been signed, and they are not an approval.

The study would ask whether children with communication difficulties and their caregivers can use an existing offline picture-based application during one supervised sitting in Galle, and whether caregivers find the screen and the language acceptable. No child has been recruited. The application has not been shown to improve communication.

## Investigators

- **J.G.D. Thamalka** and **D.V.W. Gunawardana** — medical student researchers, Faculty of Medicine, University of Ruhuna. They lead the clinical planning and the ethics application.
- **Yasas Pasindu Fernando** — researcher, technical research collaborator and developer of the application. He is not entered as the applicant.
- **Dr Gayani Punchihewa** — proposed supervisor. She has not signed. The Faculty staff page lists her as Senior Lecturer and Psychiatrist (MBBS, MD Psych). She is not described here as Head of Department.

The person who will sign as the applicant has **not** been confirmed. Telephone and email are kept in `.local_erc_private/investigator_contacts.json` and are printed only in the private named file.

## What was rebuilt on 6 November 2026

The proposal is written in plain British academic English and set in the plain layout of a previous Faculty proposal: A4, 2.54 cm margins, Times New Roman, 12 pt body text, 1.5 line spacing, 14 pt bold main headings, **Version 01** at the top left, **06 November 2026** at the top right, and a page number at the foot. The official application form was filled from the blank downloaded that day. Its own page size is US Letter and was left unchanged so the tables would not be reflowed.

No participant number is stated. A sample size has not been calculated. Sinhala and Tamil parent forms have not been translated. No certificate, signature, permission or fee receipt is invented.

## Build

```bash
cd docs/ethics/ruhuna_erc/scripts
python3 build_erc_package.py
```

Private outputs:

- `.local_erc_private/exports_private/01_Complete_ERC_Application.pdf` — cover letter, application, unsigned supervisor draft, proposal with annexes, and curriculum-vitae notes. Certificates and the fee receipt are not included.
- `.local_erc_private/exports_private/02_Anonymous_Research_Proposal.pdf` — the proposal and its annexes only, without investigator names.

The anonymous proposal in `protocol/` may be committed. Named Word files and the private PDFs stay out of git.

Editable copies for the supervisor and the student researchers are written to `.local_erc_private/review_word/`. The file `MANIFEST.md` in that folder lists each Word document. The PDFs are previews. The sample size is still unset.
