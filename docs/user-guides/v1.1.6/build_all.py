# -*- coding: utf-8 -*-
"""
Master Builder for Simple AAC Sri Lanka v1.1.6 (Build 16) Trilingual User Guides
Generates HTML, Markdown, and High-Resolution PDFs for English, Sinhala, and Tamil.
"""

import os, sys, subprocess, shutil, re

ROOT_DIR = "/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release/docs/user-guides/v1.1.6"
ASSETS_DIR = os.path.join(ROOT_DIR, "assets")
DESKTOP_DIR = "/home/yasas/Desktop/SimpleAAC-Final-User-Guides-v1.1.6"

os.chdir(ROOT_DIR)

import build_full_guides
import generate_en
import generate_si
import generate_ta

GUIDES = [
    {
        "code": "en",
        "name": "English",
        "lang": "en",
        "title": "Simple AAC Sri Lanka - Complete User Guide (v1.1.6)",
        "subtitle": "A Parent, Caregiver, and Educator Guide to Visual Communication",
        "footer": "Simple AAC Sri Lanka v1.1.6 (Build 16) • Official User Guide",
        "font": "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        "line_height": "1.55",
        "body_fn": generate_en.get_english_html,
        "html_file": "SimpleAAC_User_Guide_English_v1.1.6.html",
        "pdf_file": "SimpleAAC_User_Guide_English_v1.1.6.pdf",
        "md_file": "SimpleAAC_User_Guide_English_v1.1.6.md",
    },
    {
        "code": "si",
        "name": "Sinhala",
        "lang": "si",
        "title": "Simple AAC ශ්‍රී ලංකා - පරිශීලක අත්පොත (v1.1.6)",
        "subtitle": "දෙමාපියන්, රැකබලා ගන්නන් සහ ගුරුවරුන් සඳහා සම්පූර්ණ ප්‍රායෝගික මඟපෙන්වීම",
        "footer": "Simple AAC ශ්‍රී ලංකා v1.1.6 (Build 16) • නිල පරිශීලක අත්පොත",
        "font": "'Noto Sans Sinhala', 'Inter', sans-serif",
        "line_height": "1.75",
        "body_fn": generate_si.get_sinhala_html,
        "html_file": "SimpleAAC_User_Guide_Sinhala_v1.1.6.html",
        "pdf_file": "SimpleAAC_User_Guide_Sinhala_v1.1.6.pdf",
        "md_file": "SimpleAAC_User_Guide_Sinhala_v1.1.6.md",
    },
    {
        "code": "ta",
        "name": "Tamil",
        "lang": "ta",
        "title": "Simple AAC இலங்கை - பயனர் வழிகாட்டி (v1.1.6)",
        "subtitle": "பெற்றோர்கள், பராமரிப்பாளர்கள் மற்றும் ஆசிரியர்களுக்கான முழுமையான பயனர் வழிகாட்டி",
        "footer": "Simple AAC இலங்கை v1.1.6 (Build 16) • அதிகாரப்பூர்வ பயனர் வழிகாட்டி",
        "font": "'Noto Sans Tamil', 'Inter', sans-serif",
        "line_height": "1.75",
        "body_fn": generate_ta.get_tamil_html,
        "html_file": "SimpleAAC_User_Guide_Tamil_v1.1.6.html",
        "pdf_file": "SimpleAAC_User_Guide_Tamil_v1.1.6.pdf",
        "md_file": "SimpleAAC_User_Guide_Tamil_v1.1.6.md",
    }
]

def html_to_markdown(html_content, title):
    # Basic clean converter from HTML to readable Markdown
    md = html_content
    # Remove HTML headers/meta
    body_match = re.search(r'<body[^>]*>(.*?)</body>', md, re.DOTALL)
    if body_match:
        md = body_match.group(1)
    
    # Headings
    md = re.sub(r'<h1[^>]*>(.*?)</h1>', r'\n# \1\n', md)
    md = re.sub(r'<h2[^>]*>(.*?)</h2>', r'\n## \1\n', md)
    md = re.sub(r'<h3[^>]*>(.*?)</h3>', r'\n### \1\n', md)
    md = re.sub(r'<h4[^>]*>(.*?)</h4>', r'\n#### \1\n', md)
    
    # Paragraphs and line breaks
    md = re.sub(r'<p[^>]*>(.*?)</p>', r'\1\n\n', md)
    md = re.sub(r'<br\s*/?>', r'\n', md)
    
    # Formatting
    md = re.sub(r'<strong[^>]*>(.*?)</strong>', r'**\1**', md)
    md = re.sub(r'<b[^>]*>(.*?)</b>', r'**\1**', md)
    md = re.sub(r'<em[^>]*>(.*?)</em>', r'*\1*', md)
    md = re.sub(r'<i[^>]*>(.*?)</i>', r'*\1*', md)
    md = re.sub(r'<code[^>]*>(.*?)</code>', r'`\1`', md)
    
    # Lists
    md = re.sub(r'<li[^>]*>(.*?)</li>', r'- \1\n', md)
    md = re.sub(r'</?(?:ul|ol)[^>]*>', r'\n', md)
    
    # Images
    md = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*>', r'![\2](\1)', md)
    md = re.sub(r'<img[^>]+alt=["\']([^"\']*)["\'][^>]*src=["\']([^"\']+)["\'][^>]*>', r'![\1](\2)', md)
    md = re.sub(r'<img[^>]+src=["\']([^"\']+)["\'][^>]*>', r'![](\1)', md)
    
    # Callouts
    md = re.sub(r'<div class="tip-box"[^>]*>(.*?)</div>', r'\n> **TIP:** \1\n', md, flags=re.DOTALL)
    md = re.sub(r'<div class="caution-box"[^>]*>(.*?)</div>', r'\n> **CAUTION:** \1\n', md, flags=re.DOTALL)
    md = re.sub(r'<div class="info-box"[^>]*>(.*?)</div>', r'\n> **NOTE:** \1\n', md, flags=re.DOTALL)
    
    # Clean up generic tags
    md = re.sub(r'<div[^>]*>', r'\n', md)
    md = re.sub(r'</div>', r'\n', md)
    md = re.sub(r'<span[^>]*>(.*?)</span>', r'\1', md)
    md = re.sub(r'<table[^>]*>', r'\n', md)
    md = re.sub(r'</table>', r'\n', md)
    md = re.sub(r'<tr[^>]*>', r'\n', md)
    md = re.sub(r'</tr>', r'', md)
    md = re.sub(r'<td[^>]*>(.*?)</td>', r'| \1 ', md)
    
    # Collapse multiple blank lines
    md = re.sub(r'\n{3,}', '\n\n', md)
    return f"# {title}\n\n" + md.strip() + "\n"

def main():
    print("=== Generating Trilingual User Guides for Simple AAC Sri Lanka v1.1.6 ===")
    os.makedirs(DESKTOP_DIR, exist_ok=True)
    
    for g in GUIDES:
        print(f"\n--- Processing {g['name']} ({g['code']}) ---")
        body_content = g["body_fn"]()
        
        full_html = build_full_guides.build_html(
            lang=g["lang"],
            title=g["title"],
            subtitle=g["subtitle"],
            footer_title=g["footer"],
            font_family=g["font"],
            line_height=g["line_height"],
            content_body=body_content
        )
        
        html_path = os.path.join(ROOT_DIR, g["html_file"])
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(full_html)
        print(f"Generated HTML: {html_path} ({len(full_html)} bytes)")
        
        # Generate Markdown
        md_content = html_to_markdown(full_html, g["title"])
        md_path = os.path.join(ROOT_DIR, g["md_file"])
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)
        print(f"Generated Markdown: {md_path} ({len(md_content)} bytes)")
        
        # Generate PDF using Google Chrome headless
        pdf_path = os.path.join(ROOT_DIR, g["pdf_file"])
        print(f"Rendering PDF with Chrome headless: {pdf_path}...")
        cmd = [
            "google-chrome",
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--no-pdf-header-footer",
            f"--print-to-pdf={pdf_path}",
            html_path
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Error rendering PDF: {res.stderr}")
        else:
            pdf_size = os.path.getsize(pdf_path)
            print(f"Rendered PDF successfully: {pdf_path} ({pdf_size:,} bytes)")

    # Copy to Desktop Directory
    print(f"\n--- Staging deliverables to {DESKTOP_DIR} ---")
    desktop_assets = os.path.join(DESKTOP_DIR, "assets")
    if os.path.exists(desktop_assets):
        shutil.rmtree(desktop_assets)
    shutil.copytree(ASSETS_DIR, desktop_assets)
    print("Copied assets directory.")
    
    for g in GUIDES:
        shutil.copy2(os.path.join(ROOT_DIR, g["html_file"]), os.path.join(DESKTOP_DIR, g["html_file"]))
        shutil.copy2(os.path.join(ROOT_DIR, g["pdf_file"]), os.path.join(DESKTOP_DIR, g["pdf_file"]))
        shutil.copy2(os.path.join(ROOT_DIR, g["md_file"]), os.path.join(DESKTOP_DIR, g["md_file"]))
    
    # Create README in Desktop Directory
    readme_path = os.path.join(DESKTOP_DIR, "README.md")
    readme_content = """# Simple AAC Sri Lanka — Official User Guides (v1.1.6 / Build 16)

This folder contains the complete, professionally formatted user guides and documentation for **Simple AAC Sri Lanka** (Version 1.1.6, Build 16).

Developed for parents, caregivers, special education teachers, and speech therapists in Sri Lanka to assist non-verbal children and individuals with communication difficulties.

---

## Deliverables in this Package

### 1. English User Guide
- **PDF (Print & Digital):** `SimpleAAC_User_Guide_English_v1.1.6.pdf`
- **HTML (Responsive Web):** `SimpleAAC_User_Guide_English_v1.1.6.html`
- **Markdown (Source):** `SimpleAAC_User_Guide_English_v1.1.6.md`

### 2. Sinhala User Guide (සිංහල පරිශීලක අත්පොත)
- **PDF (Print & Digital):** `SimpleAAC_User_Guide_Sinhala_v1.1.6.pdf`
- **HTML (Responsive Web):** `SimpleAAC_User_Guide_Sinhala_v1.1.6.html`
- **Markdown (Source):** `SimpleAAC_User_Guide_Sinhala_v1.1.6.md`

### 3. Tamil User Guide (தமிழ் பயனர் வழிகாட்டி)
- **PDF (Print & Digital):** `SimpleAAC_User_Guide_Tamil_v1.1.6.pdf`
- **HTML (Responsive Web):** `SimpleAAC_User_Guide_Tamil_v1.1.6.html`
- **Markdown (Source):** `SimpleAAC_User_Guide_Tamil_v1.1.6.md`

### 4. Supporting Visual Assets
- **Folder:** `assets/` (Contains 35 authentic high-resolution screenshots from Samsung Galaxy A34 physical device QA).

---

## Verified Features Documented (v1.1.6+16)
1. **Core Communication Grid & Sentence Bar** (Tap to speak, clear bar, speak whole sentence).
2. **Trilingual TTS & Custom Voice Recording** (Sinhala, Tamil, English offline speech + personalized voice recordings).
3. **Card Management & Editing** (Add/Edit cards, drag-and-drop reordering, smart image search, GIF support, camera capture with draft recovery).
4. **Adaptive Navigation & Settings Drawer** (Compact quick-access drawer, full-screen toggle, responsive 4-column landscape mode).
5. **Dark Mode & Contrast Improvements** (Seamless dark pastel fills for nested cards, high-contrast labels, card text overlays).
6. **Text-to-Speech Bar Colour Customization** (Independent Light/Dark Mode bar colours with live preview).
7. **Cloud Backup & Local Restore** (Google Drive backup, `.aacbackup` export/import, cross-device sync).
8. **Caregiver PIN Security & Protection** (Lock edit mode and settings with custom 4-digit PIN).
9. **Accessibility & Sensory Features** (Haptic feedback, touch hold delay, high contrast, British English terminology).

---
*Created by Yasas Pasindu Fernando for the Simple AAC Sri Lanka Project.*
"""
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(readme_content)
    
    # Also write README in repo docs dir
    with open(os.path.join(ROOT_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write(readme_content)
    
    print(f"README created at {readme_path}")
    print("\n=== All Trilingual Documentation Generated Successfully! ===")

if __name__ == "__main__":
    main()
