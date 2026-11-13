# Simple AAC Sri Lanka — User Guide Documentation Suite

**Version:** 1.1.0 (Release Candidate, November 14, 2026)  
**Target Audience:** Parents, Caregivers, Special Educators, Speech Therapists, AAC Users  
**Language:** English with authentic Sinhala contextual guidance  
**Location:** `docs/user-guide/`  

---

## Directory Structure

```
docs/user-guide/
├── README.md                          # Documentation overview & asset manifest
├── Simple_AAC_User_Guide.md           # Master English user guide (Markdown)
├── Simple_AAC_User_Guide.html         # Responsive, print-ready HTML documentation (English)
├── Simple_AAC_User_Guide.pdf          # High-resolution offline vector PDF export (English, 7 pages)
├── Simple_AAC_User_Guide_SI.md        # Master Sinhala user guide / පරිශීලක අත්පොත (Markdown)
├── Simple_AAC_User_Guide_SI.html      # Responsive, print-ready HTML documentation (Sinhala)
├── Simple_AAC_User_Guide_SI.pdf       # High-resolution offline vector PDF export (Sinhala, 7 pages)
├── USER_GUIDE_QA_REPORT.md            # Verification, accessibility audit & QA report
├── screenshots/                       # Real ADB captured application screens (PNG)
├── gifs/                              # Optimized animated walkthrough demonstrations (GIF)
└── videos/                            # Source screen recording captures (MP4)
```

---

## Capture & Generation Pipeline

1. **Static Screenshots:** Captured at native Samsung Galaxy A34 FHD+ resolution ($1080 \times 2400$) via `adb exec-out screencap -p`.
2. **Interactive Walkthroughs:** Recorded on hardware via `adb shell screenrecord` (60fps, native bitrate) and converted using `ffmpeg` with custom Lanczos scaling and two-pass palette optimization.
3. **HTML / PDF Compilation:** Handled via Google Chrome Headless engine (`--headless --print-to-pdf`), guaranteeing crisp vector typography and uncropped media figures.
