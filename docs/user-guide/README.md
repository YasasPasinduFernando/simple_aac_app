# Simple AAC Sri Lanka — User Guide Documentation Suite

**Version:** 1.1.0 (Release Candidate, November 14, 2026)  
**Target Audience:** Parents, Caregivers, Special Educators, Speech Therapists, AAC Users  
**Languages:** English & Sinhala (සිංහල)  
**Location:** `docs/user-guide/`  

---

## Directory Structure

```
docs/user-guide/
├── README.md                                  # Documentation suite overview & guide
├── USER_GUIDE_LAYOUT_QA.md                    # Typographic hierarchy, pagination & visual layout QA report
├── USER_GUIDE_QA_REPORT.md                    # Hardware metrics, asset manifest & forensic verification
├── Simple_AAC_v1.1.0_User_Guides_EN_SI.zip    # Complete bundled multi-language user guide distribution
├── english/                                   # English User Guide Suite (7 Pages)
│   ├── Simple_AAC_User_Guide_EN.md            # Master English user guide (Markdown source)
│   ├── Simple_AAC_User_Guide_EN.html          # Semantic HTML print source (English)
│   └── Simple_AAC_User_Guide_EN.pdf           # Vector PDF export (English, 7 pages)
├── sinhala/                                   # Sinhala User Guide Suite (7 Pages)
│   ├── Simple_AAC_User_Guide_SI.md            # Master Sinhala user guide / පරිශීලක මාර්ගෝපදේශය (Markdown source)
│   ├── Simple_AAC_User_Guide_SI.html          # Semantic HTML print source (Sinhala)
│   └── Simple_AAC_User_Guide_SI.pdf           # Vector PDF export (Sinhala, 7 pages)
├── screenshots/                               # Real ADB FHD+ captured application screens (PNG)
├── gifs/                                      # Battery-efficient animated walkthrough demonstrations (GIF)
└── videos/                                    # Source high-resolution screen recordings (MP4)
```

---

## Technical Specifications

1. **Static Screenshots:** Captured directly on Samsung Galaxy A34 FHD+ ($1080 \times 2340$) hardware via ADB (`adb exec-out screencap -p`). Zero simulated assets.
2. **Typography & Shaping:**
   - English: `-apple-system`, `Segoe UI`, `Roboto` (line-height 1.38, 9.5 pt body)
   - Sinhala: `Noto Sans Sinhala` (line-height 1.50, 9.3 pt body, complex text shaping verified)
3. **Print Layout:** Compact, balanced 7-page layouts formatted using CSS Paged Media `@page` margin boxes, flexbox `.fig-row` and `.fig-row-3`, semantic `<figure>` elements with `break-inside: avoid;`, and zero isolated screenshots.
4. **HTML / PDF Compilation:** Headless Chromium (`--headless=new --disable-gpu --no-sandbox --no-pdf-header-footer --print-to-pdf`), guaranteeing crisp vector typography, zero browser header/footer timestamps, and authentic vector page numbers.
