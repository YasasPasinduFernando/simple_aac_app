# -*- coding: utf-8 -*-
"""
Full Trilingual User Guide Builder for Simple AAC Sri Lanka v1.1.6 (Build 16)
Author: Yasas Pasindu Fernando
Target: Parents, Caregivers, Teachers, Speech Therapists
"""

import os, sys, subprocess, shutil

ROOT_DIR = "/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release/docs/user-guides/v1.1.6"
ASSETS_DIR = os.path.join(ROOT_DIR, "assets")
DESKTOP_DIR = "/home/yasas/Desktop/SimpleAAC-Final-User-Guides-v1.1.6"

os.makedirs(ROOT_DIR, exist_ok=True)
os.makedirs(ASSETS_DIR, exist_ok=True)
os.makedirs(DESKTOP_DIR, exist_ok=True)

# -------------------------------------------------------------
# 1. HTML GENERATOR
# -------------------------------------------------------------

def build_html(lang, title, subtitle, footer_title, font_family, line_height, content_body):
    css = f"""
@page {{
  size: A4 portrait;
  margin: 14mm 16mm 14mm 16mm;
  @bottom-left {{
    content: "{footer_title}";
    font-size: 8pt;
    font-family: {font_family};
    color: #64748b;
  }}
  @bottom-right {{
    content: counter(page) " / " counter(pages);
    font-size: 8pt;
    font-family: {font_family};
    color: #64748b;
  }}
}}

* {{ box-sizing: border-box; }}

body {{
  font-family: {font_family};
  line-height: {line_height};
  color: #1e293b;
  margin: 0;
  padding: 0;
  background: #ffffff;
  font-size: 9.5pt;
  text-align: left;
}}

.cover-page {{
  page-break-after: always;
  padding-top: 36px;
  text-align: center;
}}

.cover-badge {{
  display: inline-block;
  background: #e0f2fe;
  color: #0369a1;
  padding: 4px 14px;
  border-radius: 20px;
  font-size: 8.5pt;
  font-weight: 600;
  margin-bottom: 16px;
  border: 1px solid #bae6fd;
}}

.cover-title {{
  color: #0f172a;
  font-size: 24pt;
  font-weight: 800;
  margin: 0 0 8px 0;
  line-height: 1.25;
}}

.cover-subtitle {{
  color: #0284c7;
  font-size: 12pt;
  font-weight: 600;
  margin: 0 0 16px 0;
}}

.cover-description {{
  color: #475569;
  font-size: 10pt;
  max-width: 540px;
  margin: 0 auto 26px auto;
  line-height: 1.5;
}}

.cover-card {{
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 20px;
  max-width: 480px;
  margin: 0 auto 30px auto;
  text-align: left;
}}

.cover-card-row {{
  display: flex;
  justify-content: space-between;
  padding: 6px 0;
  border-bottom: 1px solid #f1f5f9;
  font-size: 8.5pt;
}}

.cover-card-row:last-child {{
  border-bottom: none;
}}

.cover-card-label {{
  color: #64748b;
  font-weight: 500;
}}

.cover-card-value {{
  color: #0f172a;
  font-weight: 600;
}}

.section-header {{
  margin-top: 20px;
  margin-bottom: 10px;
  border-bottom: 2px solid #0284c7;
  padding-bottom: 4px;
  break-after: avoid;
  page-break-after: avoid;
}}

h1 {{
  color: #0369a1;
  font-size: 15pt;
  font-weight: 700;
  margin: 0 0 4px 0;
}}

h2 {{
  color: #0f172a;
  font-size: 11pt;
  font-weight: 700;
  margin: 14px 0 6px 0;
  break-after: avoid;
  page-break-after: avoid;
}}

h3 {{
  color: #334155;
  font-size: 9.5pt;
  font-weight: 600;
  margin: 10px 0 4px 0;
  break-after: avoid;
  page-break-after: avoid;
}}

p {{
  margin: 0 0 6px 0;
}}

ul, ol {{
  margin: 0 0 8px 0;
  padding-left: 18px;
}}

li {{
  margin-bottom: 3px;
}}

.page-break {{
  page-break-before: always;
  break-before: page;
}}

.screenshot-grid {{
  width: 100%;
  margin: 8px 0 12px 0;
  border-collapse: separate;
  border-spacing: 12px 0;
  break-inside: avoid;
  page-break-inside: avoid;
}}

.screenshot-cell {{
  vertical-align: top;
  text-align: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 6px;
}}

.screenshot-cell img {{
  max-width: 100%;
  max-height: 200px;
  border-radius: 6px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.06);
  display: block;
  margin: 0 auto 5px auto;
}}

.screenshot-caption {{
  font-size: 7.5pt;
  color: #475569;
  font-style: italic;
  line-height: 1.25;
}}

.tip-box {{
  background: #f0fdf4;
  border-left: 4px solid #16a34a;
  border-radius: 0 6px 6px 0;
  padding: 7px 11px;
  margin: 8px 0;
  font-size: 8.5pt;
  color: #166534;
  break-inside: avoid;
  page-break-inside: avoid;
}}

.caution-box {{
  background: #fffbeb;
  border-left: 4px solid #f59e0b;
  border-radius: 0 6px 6px 0;
  padding: 7px 11px;
  margin: 8px 0;
  font-size: 8.5pt;
  color: #92400e;
  break-inside: avoid;
  page-break-inside: avoid;
}}

.info-box {{
  background: #f0f9ff;
  border-left: 4px solid #0284c7;
  border-radius: 0 6px 6px 0;
  padding: 7px 11px;
  margin: 8px 0;
  font-size: 8.5pt;
  color: #075985;
  break-inside: avoid;
  page-break-inside: avoid;
}}

.box-title {{
  font-weight: 700;
  margin-bottom: 2px;
}}

.toc-box {{
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 10px 14px;
  margin-bottom: 14px;
  break-inside: avoid;
  page-break-inside: avoid;
}}

.toc-title {{
  font-size: 9pt;
  font-weight: 700;
  color: #0369a1;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 6px;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 3px;
}}

.toc-table {{
  width: 100%;
  border-collapse: collapse;
}}

.toc-table td {{
  padding: 3px 5px;
  font-size: 8.5pt;
  border-bottom: 1px dashed #e2e8f0;
}}

.toc-table tr:last-child td {{
  border-bottom: none;
}}

.step-badge {{
  display: inline-block;
  width: 16px;
  height: 16px;
  background: #0284c7;
  color: #ffffff;
  border-radius: 50%;
  text-align: center;
  line-height: 16px;
  font-size: 7.5pt;
  font-weight: 700;
  margin-right: 5px;
}}
"""
    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="UTF-8">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
{content_body}
</body>
</html>
"""

print("HTML generator framework ready.")
