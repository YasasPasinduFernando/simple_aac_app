# Simple AAC Sri Lanka — Trilingual User Documentation Suite

**Version:** 1.1.0 (Release Candidate, November 14, 2026)  
**Target Audience:** Parents, Caregivers, Special Educators, Speech Therapists, AAC Users  
**Languages:** English (EN), Sinhala (SI — සිංහල), Tamil (TA — தமிழ்)  
**Location:** `docs/user-guide/`  

---

## Directory Structure

```
docs/user-guide/
├── README.md                                  # Trilingual documentation suite guide
├── TRILINGUAL_DOCUMENT_QA_REPORT.md           # Master QA report across all 3 languages (PDF & DOCX)
├── USER_GUIDE_LAYOUT_QA.md                    # Layout, font metrics, and pagination audit report
├── USER_GUIDE_QA_REPORT.md                    # Hardware metrics, device logs & asset manifest
├── Simple_AAC_User_Guides_EN_SI_TA.zip        # Master distribution bundle (PDFs, DOCX, Markdown, HTML, media)
├── english/                                   # English User Guide Suite
│   ├── Simple_AAC_User_Guide_EN.pdf           # Vector PDF export (7 pages)
│   ├── Simple_AAC_User_Guide_EN.docx          # Editable Microsoft Word document (13 pages)
│   ├── Simple_AAC_User_Guide_EN.html          # Semantic HTML print source
│   └── Simple_AAC_User_Guide_EN.md            # Master Markdown source
├── sinhala/                                   # Sinhala User Guide Suite (සිංහල)
│   ├── Simple_AAC_User_Guide_SI.pdf           # Vector PDF export (7 pages)
│   ├── Simple_AAC_User_Guide_SI.docx          # Editable Microsoft Word document (14 pages)
│   ├── Simple_AAC_User_Guide_SI.html          # Semantic HTML print source (Noto Sans Sinhala)
│   └── Simple_AAC_User_Guide_SI.md            # Master Sinhala Markdown source
├── tamil/                                     # Tamil User Guide Suite (தமிழ்)
│   ├── Simple_AAC_User_Guide_TA.pdf           # Vector PDF export (7 pages)
│   ├── Simple_AAC_User_Guide_TA.docx          # Editable Microsoft Word document (14 pages)
│   ├── Simple_AAC_User_Guide_TA.html          # Semantic HTML print source (Noto Sans Tamil)
│   └── Simple_AAC_User_Guide_TA.md            # Master Tamil Markdown source
├── assets/
│   └── screenshots/                           # Direct link to authentic FHD+ screen captures
├── screenshots/                               # Real ADB captured application screens (PNG)
├── gifs/                                      # Battery-efficient animated walkthrough demonstrations (GIF)
└── videos/                                    # Source high-resolution screen recordings (MP4)
```

---

## Technical Specifications

1. **Dual Format Delivery:**
   - **Vector PDF:** Optimized 7-page print-ready manual with balanced margins (14mm/18mm), custom headers/footers, and vector page numbers.
   - **Microsoft Word DOCX:** Fully editable Word documents utilizing native `Heading 1`, `Heading 2`, `Normal`, and `List Bullet` styles, borderless layout tables, embedded images, and dynamic `PAGE` / `NUMPAGES` fields.
2. **Typography & Script Shaping:**
   - **English:** `Calibri` / `-apple-system` (line-height 1.38, 9.5 pt body)
   - **Sinhala:** `Noto Sans Sinhala` (line-height 1.50, 9.3 pt body, complex HarfBuzz text shaping verified)
   - **Tamil:** `Noto Sans Tamil` (line-height 1.48, 9.3 pt body, pulli marks, kombu, and conjunct ligatures verified)
3. **Asset Authenticity:** 100% captured on physical Samsung Galaxy A34 5G hardware via wireless ADB (`adb exec-out screencap -p`). Zero fabricated or AI-hallucinated mockups.
