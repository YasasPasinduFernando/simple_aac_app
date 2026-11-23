# -*- coding: utf-8 -*-
"""
Documentation Generator for Simple AAC Sri Lanka v1.1.6 (Build 16)
Generates trilingual user guides in HTML, Markdown, and PDF formats.
"""

import os, sys, subprocess, shutil

ROOT_DIR = "/media/yasas/New Volume2/yasas/PersonalProjects/simple aac/simple_aac_play_release/docs/user-guides/v1.1.6"
ASSETS_DIR = os.path.join(ROOT_DIR, "assets")
DESKTOP_DIR = "/home/yasas/Desktop/SimpleAAC-Final-User-Guides-v1.1.6"

os.makedirs(ROOT_DIR, exist_ok=True)
os.makedirs(ASSETS_DIR, exist_ok=True)
os.makedirs(DESKTOP_DIR, exist_ok=True)

# Common CSS for professional, print-friendly A4 layout
CSS_TEMPLATE = """
@page {
  size: A4 portrait;
  margin: 14mm 16mm 14mm 16mm;
  @bottom-left {
    content: "__DOC_FOOTER_TITLE__";
    font-size: 8pt;
    font-family: __FONT_FAMILY__;
    color: #64748b;
  }
  @bottom-right {
    content: "__PAGE_LABEL__ " counter(page) " __PAGE_OF__ " counter(pages);
    font-size: 8pt;
    font-family: __FONT_FAMILY__;
    color: #64748b;
  }
}

* { box-sizing: border-box; }

body {
  font-family: __FONT_FAMILY__;
  line-height: __LINE_HEIGHT__;
  color: #1e293b;
  margin: 0;
  padding: 0;
  background: #ffffff;
  font-size: 9.5pt;
  text-align: left;
}

.cover-page {
  page-break-after: always;
  padding-top: 40px;
  text-align: center;
}

.cover-badge {
  display: inline-block;
  background: #e0f2fe;
  color: #0369a1;
  padding: 4px 14px;
  border-radius: 20px;
  font-size: 9pt;
  font-weight: 600;
  margin-bottom: 20px;
  border: 1px solid #bae6fd;
}

.cover-title {
  color: #0f172a;
  font-size: 26pt;
  font-weight: 800;
  margin: 0 0 10px 0;
  line-height: 1.2;
}

.cover-subtitle {
  color: #0284c7;
  font-size: 13pt;
  font-weight: 600;
  margin: 0 0 18px 0;
}

.cover-description {
  color: #475569;
  font-size: 10.5pt;
  max-width: 540px;
  margin: 0 auto 30px auto;
  line-height: 1.5;
}

.cover-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px;
  max-width: 480px;
  margin: 0 auto 40px auto;
  text-align: left;
}

.cover-card-row {
  display: flex;
  justify-content: space-between;
  padding: 6px 0;
  border-bottom: 1px solid #f1f5f9;
  font-size: 9pt;
}

.cover-card-row:last-child {
  border-bottom: none;
}

.cover-card-label {
  color: #64748b;
  font-weight: 500;
}

.cover-card-value {
  color: #0f172a;
  font-weight: 600;
}

.section-header {
  margin-top: 24px;
  margin-bottom: 12px;
  border-bottom: 2px solid #0284c7;
  padding-bottom: 4px;
  break-after: avoid;
  page-break-after: avoid;
}

h1 {
  color: #0369a1;
  font-size: 16pt;
  font-weight: 700;
  margin: 0 0 4px 0;
}

h2 {
  color: #0f172a;
  font-size: 12pt;
  font-weight: 700;
  margin: 16px 0 6px 0;
  break-after: avoid;
  page-break-after: avoid;
}

h3 {
  color: #334155;
  font-size: 10pt;
  font-weight: 600;
  margin: 12px 0 4px 0;
  break-after: avoid;
  page-break-after: avoid;
}

p {
  margin: 0 0 8px 0;
}

ul, ol {
  margin: 0 0 10px 0;
  padding-left: 20px;
}

li {
  margin-bottom: 4px;
}

.page-break {
  page-break-before: always;
  break-before: page;
}

/* Screenshot Tables */
.screenshot-grid {
  width: 100%;
  margin: 10px 0 14px 0;
  border-collapse: separate;
  border-spacing: 12px 0;
  break-inside: avoid;
  page-break-inside: avoid;
}

.screenshot-cell {
  vertical-align: top;
  text-align: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px;
}

.screenshot-cell img {
  max-width: 100%;
  max-height: 220px;
  border-radius: 6px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
  display: block;
  margin: 0 auto 6px auto;
}

.screenshot-caption {
  font-size: 8pt;
  color: #475569;
  font-style: italic;
  line-height: 1.3;
}

/* Callout Boxes */
.tip-box {
  background: #f0fdf4;
  border-left: 4px solid #16a34a;
  border-radius: 0 6px 6px 0;
  padding: 8px 12px;
  margin: 10px 0;
  font-size: 9pt;
  color: #166534;
  break-inside: avoid;
  page-break-inside: avoid;
}

.tip-title {
  font-weight: 700;
  margin-bottom: 2px;
}

.caution-box {
  background: #fffbeb;
  border-left: 4px solid #f59e0b;
  border-radius: 0 6px 6px 0;
  padding: 8px 12px;
  margin: 10px 0;
  font-size: 9pt;
  color: #92400e;
  break-inside: avoid;
  page-break-inside: avoid;
}

.caution-title {
  font-weight: 700;
  margin-bottom: 2px;
}

.info-box {
  background: #f0f9ff;
  border-left: 4px solid #0284c7;
  border-radius: 0 6px 6px 0;
  padding: 8px 12px;
  margin: 10px 0;
  font-size: 9pt;
  color: #075985;
  break-inside: avoid;
  page-break-inside: avoid;
}

.info-title {
  font-weight: 700;
  margin-bottom: 2px;
}

/* Table of Contents */
.toc-box {
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 18px;
  break-inside: avoid;
  page-break-inside: avoid;
}

.toc-title {
  font-size: 10pt;
  font-weight: 700;
  color: #0369a1;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 4px;
}

.toc-table {
  width: 100%;
  border-collapse: collapse;
}

.toc-table td {
  padding: 4px 6px;
  font-size: 9pt;
  border-bottom: 1px dashed #e2e8f0;
}

.toc-table tr:last-child td {
  border-bottom: none;
}

.step-num {
  display: inline-block;
  width: 18px;
  height: 18px;
  background: #0284c7;
  color: #ffffff;
  border-radius: 50%;
  text-align: center;
  line-height: 18px;
  font-size: 8pt;
  font-weight: 700;
  margin-right: 6px;
}
"""

print("Base CSS template initialized.")
