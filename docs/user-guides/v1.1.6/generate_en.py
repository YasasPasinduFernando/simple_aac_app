# -*- coding: utf-8 -*-
"""
English User Guide Generator for Simple AAC Sri Lanka v1.1.6 (Build 16)
"""

import os, sys

def get_english_html():
    return """
<div class="cover-page">
  <div class="cover-badge">OFFICIAL USER DOCUMENTATION • VERSION 1.1.6 (BUILD 16)</div>
  <h1 class="cover-title">Simple AAC Sri Lanka</h1>
  <div class="cover-subtitle">Complete Trilingual Augmentative & Alternative Communication Guide</div>
  <p class="cover-description">
    A comprehensive, practical manual designed for parents, caregivers, special educators, and speech therapists to empower non-verbal children and individuals with communication difficulties through intuitive visual communication cards and instant offline speech.
  </p>

  <div class="cover-card">
    <div class="cover-card-row">
      <span class="cover-card-label">Application Version:</span>
      <span class="cover-card-value">v1.1.6 (Production Build 16)</span>
    </div>
    <div class="cover-card-row">
      <span class="cover-card-label">Supported Languages:</span>
      <span class="cover-card-value">English (en-US), Sinhala (si-LK), Tamil (ta-IN)</span>
    </div>
    <div class="cover-card-row">
      <span class="cover-card-label">Operating System:</span>
      <span class="cover-card-value">Android 5.0 (API 21) to Android 15+ (Target SDK 34)</span>
    </div>
    <div class="cover-card-row">
      <span class="cover-card-label">Offline Architecture:</span>
      <span class="cover-card-value">100% Offline-First (No Internet / No Cloud Required)</span>
    </div>
    <div class="cover-card-row">
      <span class="cover-card-label">Package Identifier:</span>
      <span class="cover-card-value">lk.yasas.simpleaac</span>
    </div>
    <div class="cover-card-row">
      <span class="cover-card-label">Release Date:</span>
      <span class="cover-card-value">November 2026</span>
    </div>
  </div>
</div>

<div class="toc-box">
  <div class="toc-title">Table of Contents</div>
  <table class="toc-table">
    <tr><td><strong>Quick Start Guide</strong> — 5 Steps to First Communication</td><td style="text-align:right;">Page 2</td></tr>
    <tr><td><strong>Chapter 1</strong> — Getting Started & Everyday Navigation</td><td style="text-align:right;">Page 2</td></tr>
    <tr><td><strong>Chapter 2</strong> — Communicating with Speech & Sentence Composition</td><td style="text-align:right;">Page 3</td></tr>
    <tr><td><strong>Chapter 3</strong> — Communication Cards & Category Folders</td><td style="text-align:right;">Page 4</td></tr>
    <tr><td><strong>Chapter 4</strong> — Camera, Gallery & Multimedia Support</td><td style="text-align:right;">Page 5</td></tr>
    <tr><td><strong>Chapter 5</strong> — Appearance, Customisation & Accessibility</td><td style="text-align:right;">Page 6</td></tr>
    <tr><td><strong>Chapter 6</strong> — Caregiver Safety & Child Lock Protection</td><td style="text-align:right;">Page 7</td></tr>
    <tr><td><strong>Chapter 7</strong> — Data Backup, Restore & Offline Privacy</td><td style="text-align:right;">Page 7</td></tr>
    <tr><td><strong>Chapter 8</strong> — Troubleshooting & Frequently Asked Questions</td><td style="text-align:right;">Page 8</td></tr>
  </table>
</div>

<div class="section-header">
  <h1>Quick Start Guide — 5 Steps to First Communication</h1>
</div>
<p>Simple AAC Sri Lanka is designed for instant communication without complex setup. Follow these five simple steps to begin:</p>
<ol>
  <li><strong>Open the App:</strong> Tap the Simple AAC icon on your home screen. The calming blue communication board opens immediately.</li>
  <li><strong>Tap Any Card to Speak:</strong> Tap the <em>Hello</em> card. The app speaks "Hello" instantly in clear, natural speech and highlights the card.</li>
  <li><strong>Build a Sentence:</strong> Tap <em>I want</em>, followed by <em>Water</em>. Both words appear in order on the top Sentence Composer bar.</li>
  <li><strong>Speak the Sentence:</strong> Tap the blue Speaker icon <span style="font-size:11pt;">🔊</span> on the right side of the sentence bar to vocalize the complete thought.</li>
  <li><strong>Lock the Board (Optional):</strong> Tap the Pin icon <span style="font-size:11pt;">📌</span> in the top-left corner to activate Caregiver Lock, preventing accidental changes while your child communicates.</li>
</ol>

<div class="tip-box">
  <div class="box-title">Caregiver Tip</div>
  Place the tablet or phone on a stable surface or wheelchair tray at comfortable arm's length. Demonstrate tapping a card yourself ("modeling") so the child sees how touch produces voice.
</div>

<div class="section-header">
  <h1>Chapter 1 — Getting Started & Everyday Navigation</h1>
</div>
<p>
  <strong>Simple AAC Sri Lanka</strong> is an augmentative and alternative communication (AAC) platform developed for children with speech delays, non-verbal autism spectrum conditions (ASD), cerebral palsy, Down syndrome, and aphasia. It operates 100% offline, keeping sensitive personal recordings and photos completely secure on your device.
</p>

<h2>1.1 Understanding the Home Screen</h2>
<p>The screen is cleanly organized into three functional zones designed to avoid sensory overload:</p>
<ul>
  <li><strong>Top Navigation Bar:</strong> Contains the <strong>Pin Board</strong> lock (left), the application title <strong>Simple AAC</strong> (centre), and the <strong>Settings Drawer</strong> button (right).</li>
  <li><strong>Sentence Composer Bar:</strong> Displays selected words in chronological sequence, complete with <em>Delete</em> (removes the last word), <em>Clear</em> (empties the bar), and the <em>Speak</em> button.</li>
  <li><strong>Communication Grid:</strong> High-contrast cards featuring friendly visual illustrations, clear bold typography, and pastel touch surfaces optimized for fine-motor control.</li>
</ul>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/01_home_screen.png" alt="Simple AAC Home Screen Light Mode">
      <div class="screenshot-caption">Figure 1.1: Home screen in Light Mode with high-contrast cards and sentence bar.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/27_dark_mode_home.png" alt="Simple AAC Home Screen Dark Mode">
      <div class="screenshot-caption">Figure 1.2: Home screen in Dark Mode with seamless pastel artwork integration.</div>
    </td>
  </tr>
</table>

<h2>1.2 Category Navigation & Automatic Folder Memory</h2>
<p>
  Cards are organized into intuitive categories (e.g., <em>Needs</em>, <em>Feelings</em>, <em>Food</em>, <em>Animals</em>). Tapping a category folder opens its sub-cards. 
  A breadcrumb trail at the top (e.g., <code>Home &gt; Default &gt; Needs</code>) shows exactly where you are. Tap any breadcrumb segment or the Back arrow to return.
</p>
<div class="info-box">
  <div class="box-title">New in Build 16 — Automatic Folder Stack Recovery</div>
  Simple AAC now automatically remembers your active folder path. If you switch to another app or the system temporarily restarts the app in the background, reopening Simple AAC returns you directly to your active folder without resetting to the home screen.
</div>

<div class="page-break"></div>

<div class="section-header">
  <h1>Chapter 2 — Communicating with Speech & Sentence Composition</h1>
</div>

<h2>2.1 Instant Speech & Multi-Sensory Feedback</h2>
<p>
  Every tap provides immediate multi-sensory confirmation:
</p>
<ul>
  <li><strong>Instant Voice Output:</strong> Touching a card triggers immediate speech in English, Sinhala, or Tamil. In Build 16, background speech pre-warming ensures zero speech delay even on first touch.</li>
  <li><strong>Visual Highlight:</strong> The card gently expands with a bright visual border, reassuring the learner of their selection.</li>
  <li><strong>Haptic Confirmation:</strong> A gentle vibration (haptic feedback) confirms the touch for sensory-seeking children. Haptics can be adjusted or silenced in Settings.</li>
</ul>

<h2>2.2 Building Multi-Word Sentences</h2>
<p>
  For learners transitioning from single words to complete sentences, the horizontal <strong>Sentence Composer bar</strong> provides an intuitive sequencing space:
</p>
<ol>
  <li>Tap the words in sequence: for example, <code>Hungry</code> &rarr; <code>Burger</code>.</li>
  <li>Each card token appears inside the sentence bar with its thumbnail icon and text.</li>
  <li>Tap the blue <strong>Speak (🔊)</strong> button. Simple AAC vocalizes the entire sentence naturally from start to finish.</li>
  <li>Tap <strong>Delete (⌫)</strong> to remove the most recent card, or <strong>Clear (✕)</strong> to start a new sentence.</li>
</ol>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/04_sentence_bar.png" alt="Sentence Composer Bar">
      <div class="screenshot-caption">Figure 2.1: Sentence Composer bar holding active communication cards.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/03_speaking_card.png" alt="Card Audio Feedback">
      <div class="screenshot-caption">Figure 2.2: Instant speech feedback and visual card elevation.</div>
    </td>
  </tr>
</table>

<h2>2.3 Trilingual Offline Speech (English, Sinhala, Tamil)</h2>
<p>
  Simple AAC supports Sri Lanka's three national languages natively. Speech generation is powered by on-device Text-to-Speech (TTS):
</p>
<ul>
  <li><strong>English (en-US / en-GB):</strong> Clear, expressive natural pronunciation.</li>
  <li><strong>Sinhala (si-LK):</strong> Native phonetic pronunciation of Sinhala vocabulary and phrases.</li>
  <li><strong>Tamil (ta-IN / ta-LK):</strong> Authentic Tamil pronunciation optimized for everyday phrases.</li>
</ul>

<div class="tip-box">
  <div class="box-title">Ensuring Offline Speech Works</div>
  Ensure your device has the offline voice pack installed: On your Android device, navigate to <strong>Settings &gt; System &gt; Language &amp; Input &gt; Text-to-Speech output &gt; Google Speech Recognition &amp; Synthesis &gt; Install voice data</strong>, and download English, Sinhala, and Tamil for permanent offline availability.
</div>

<div class="section-header">
  <h1>Chapter 3 — Communication Cards & Category Folders</h1>
</div>

<h2>3.1 The 13 Default Starter Pack Categories</h2>
<p>
  Simple AAC includes a comprehensive, pre-installed starter communication library organized into 13 high-frequency daily categories:
</p>
<ul>
  <li><strong>Needs:</strong> Urgent necessities (Hungry, Thirsty, Toilet, Help, Rest, Pain).</li>
  <li><strong>Feelings:</strong> Emotional states (Happy, Sad, Angry, Excited, Scared, Tired).</li>
  <li><strong>Food &amp; Snacks:</strong> Meals, fruits, snacks, and drinks commonly used in daily routines.</li>
  <li><strong>Colours &amp; Shapes:</strong> Fundamental descriptive concepts for educational sessions.</li>
  <li><strong>Family &amp; People:</strong> Mom, Dad, Teacher, Doctor, and key support figures.</li>
  <li><strong>Animals, Actions, Places, Hygiene, Clothes, Toys &amp; School.</strong></li>
</ul>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/07_folder_view.png" alt="Category Folder View">
      <div class="screenshot-caption">Figure 3.1: Category folder displaying categorized child-friendly vocabulary.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/28_dark_mode_nested_needs.png" alt="Needs Category in Dark Mode">
      <div class="screenshot-caption">Figure 3.2: Needs category in Dark Mode featuring seamless perimeter fill.</div>
    </td>
  </tr>
</table>

<h2>3.2 Creating &amp; Customising Cards</h2>
<p>Caregivers can add unlimited custom cards to reflect the child's real life (family members, favourite toys, local foods):</p>
<ol>
  <li>Tap the Menu icon (☰) and toggle <strong>Edit Mode</strong> ON.</li>
  <li>Tap the floating <strong>+ (Add Card)</strong> button.</li>
  <li>Enter the <strong>Card Label</strong> (e.g., "Grandmother") and the <strong>Spoken Text</strong>.</li>
  <li>Select an image using the Camera, Gallery, or built-in icon library.</li>
  <li>Tap <strong>Save</strong>. The new card is immediately ready for communication.</li>
</ol>

<div class="page-break"></div>

<div class="section-header">
  <h1>Chapter 4 — Camera, Gallery & Multimedia Support</h1>
</div>

<h2>4.1 Taking Real-World Photos with Camera</h2>
<p>
  Recognizing real-world objects and familiar faces is critical for many autistic children. Simple AAC makes camera capture effortless:
</p>
<ol>
  <li>In the Card Editor, tap <strong>Camera</strong>.</li>
  <li>Point the camera at the item (e.g., the child's water cup) and take the photo.</li>
  <li>Confirm the photo. Simple AAC automatically returns to the Card Editor with the photo attached.</li>
  <li><strong>Draft Protection:</strong> If you take a photo or Android temporarily pauses the app, your entered card title and settings are completely preserved upon return.</li>
</ol>

<h2>4.2 Selecting Photos via Android Photo Picker</h2>
<p>
  Tap <strong>Gallery</strong> to choose existing photos. Simple AAC utilizes the modern, privacy-focused Android Photo Picker, granting access only to the exact photo you choose without scanning your personal storage.
</p>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/08_camera_flow.png" alt="Camera Capture Flow">
      <div class="screenshot-caption">Figure 4.1: Camera photo capture integrated seamlessly into the Card Editor.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/09_gallery_picker.png" alt="Android Photo Picker">
      <div class="screenshot-caption">Figure 4.2: Privacy-respecting Android Photo Picker for personal images.</div>
    </td>
  </tr>
</table>

<h2>4.3 Animated GIFs &amp; Video-to-GIF Conversion</h2>
<p>
  Action concepts such as <em>Jump</em>, <em>Wash hands</em>, or <em>Dance</em> are far easier to comprehend through movement. Simple AAC supports animated GIF cards:
</p>
<ul>
  <li><strong>Selecting Animated GIFs:</strong> Choose any standard GIF from your gallery; it plays smoothly in an endless loop on the card.</li>
  <li><strong>Convert Video to GIF:</strong> Select a short video clip (up to 10 seconds). Simple AAC's native converter turns it into an optimized, battery-efficient GIF.</li>
  <li><strong>Cooperative Cancellation (New in Build 16):</strong> If you select the wrong video or wish to cancel processing, tapping <strong>Cancel</strong> or closing the dialog immediately halts the conversion in the background, cleans up temporary files, and returns you to editing without delays.</li>
</ul>

<h2>4.4 Recording Personal Voice Clips</h2>
<p>
  When a child prefers a mother's voice, a familiar teacher's voice, or specific local pronunciations, you can record custom audio:
</p>
<ol>
  <li>In the Card Editor, scroll down to <strong>Custom Voice Recording</strong>.</li>
  <li>Tap the red Microphone button <span style="font-size:11pt;">🎙️</span> and speak clearly.</li>
  <li>Tap Stop. Tap Play <span style="font-size:11pt;">▶️</span> to review the recorded clip.</li>
  <li>When this card is tapped on the board, Simple AAC plays the authentic human recording instead of the synthetic voice.</li>
</ol>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/12_video_to_gif.png" alt="Video to GIF Conversion">
      <div class="screenshot-caption">Figure 4.3: High-efficiency native Video-to-GIF encoder with cancel support.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/13_custom_voice_recorder.png" alt="Custom Voice Recorder">
      <div class="screenshot-caption">Figure 4.4: In-app voice recorder for personal parent and teacher recordings.</div>
    </td>
  </tr>
</table>

<div class="page-break"></div>

<div class="section-header">
  <h1>Chapter 5 — Appearance, Customisation & Accessibility</h1>
</div>

<p>Every child has unique visual preferences and sensory requirements. Simple AAC offers rich appearance customisation:</p>

<h2>5.1 Light Mode & Seamless Dark Mode</h2>
<p>
  Toggle between <strong>Light Mode</strong> (crisp, high-contrast white and soft pastel cards) and <strong>Dark Mode</strong> (deep slate background that prevents glare and eye fatigue during evening use).
</p>
<div class="info-box">
  <div class="box-title">New in Build 16 — Seamless Dark Mode Perimeter Fill</div>
  In Dark Mode, starter category cards now dynamically match their background surface to the illustration's perimeter pastel colour. Inset dark borders have been completely eliminated across <em>Default</em>, <em>Needs</em>, <em>Animals</em>, and all sub-folders.
</div>

<h2>5.2 Text-to-Speech Bar Colour Setting (New in Build 16)</h2>
<p>
  Located in <strong>Settings &gt; Appearance &amp; Theme</strong> immediately below <em>Board Background Colour</em>:
</p>
<ul>
  <li><strong>Custom Background:</strong> Customise the background colour of the horizontal sentence-building bar.</li>
  <li><strong>Independent Day/Night Persistence:</strong> Choose independent colours for Light Mode and Dark Mode (e.g., Sky Blue for day, Deep Indigo for night).</li>
  <li><strong>Live Mini Preview Chip:</strong> The settings item displays a live interactive preview chip showing sample tokens (<em>Elephant</em>, <em>Fish</em>) and speaker icon.</li>
  <li><strong>Dynamic Text Contrast:</strong> Card token text automatically adapts between crisp black and pure white to ensure maximum readability against your chosen background colour.</li>
  <li><strong>Professional Colour Picker:</strong> Choose from quick accessible preset palettes or tap <em>Custom colour</em> for a full HSV gradient picker with hex code support.</li>
</ul>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/26_tts_bar_colour_setting.png" alt="TTS Bar Colour Setting and Dialog">
      <div class="screenshot-caption">Figure 5.1: New Text-to-Speech Bar Colour setting with live preview & picker.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/20_appearance_and_color_vision.png" alt="Colour Vision Accessibility">
      <div class="screenshot-caption">Figure 5.2: Colour Vision Support with Protanopia, Deuteranopia & Tritanopia modes.</div>
    </td>
  </tr>
</table>

<h2>5.3 Card Label Visibility & Image Overlay Controls</h2>
<p>Fine-tune how text labels appear on cards to suit emerging readers versus pre-readers:</p>
<ul>
  <li><strong>Show Card Labels:</strong> Toggle ON to show labels, or OFF to display pure image-only flashcards.</li>
  <li><strong>Overlay Card Labels:</strong> When ON, labels float over the bottom of the artwork with a soft transparent gradient. When OFF, labels sit in a clean solid footer below the artwork.</li>
  <li><strong>Global Card Label Background Colour:</strong> Set a uniform background colour behind all card labels for optimal contrast.</li>
</ul>

<h2>5.4 Colour Vision Support & Layout Flexibility</h2>
<ul>
  <li><strong>Colour Vision Modes:</strong> Real-time visual adaptation for Protanopia (red-blind), Deuteranopia (green-blind), and Tritanopia (blue-blind).</li>
  <li><strong>Grid Column Sizing:</strong> Customise grid density from 1 column up to 12 columns. Simple AAC automatically optimizes card aspect ratios for phones and tablets in both portrait and landscape orientations.</li>
  <li><strong>Open Settings Full Screen:</strong> Toggle whether Settings opens as a compact slide-out drawer or an expansive full-screen view.</li>
  <li><strong>British English UI:</strong> All English interface text consistently uses British English terminology (<em>Colour</em>, <em>Colours</em>, <em>Customise</em>).</li>
</ul>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/29_mode_1_overlay_on.png" alt="Overlay Mode ON">
      <div class="screenshot-caption">Figure 5.3: Visual Mode 1 — Text Overlay ON with gradient artwork blending.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/30_mode_2_overlay_off.png" alt="Overlay Mode OFF">
      <div class="screenshot-caption">Figure 5.4: Visual Mode 2 — Text Overlay OFF with separate footer bar.</div>
    </td>
  </tr>
</table>

<div class="page-break"></div>

<div class="section-header">
  <h1>Chapter 6 — Caregiver Safety & Child Lock Protection</h1>
</div>

<h2>6.1 Activating Caregiver Lock (Pin Board Mode)</h2>
<p>
  Children exploring communication boards may accidentally tap menu items, delete cards, or alter settings. Simple AAC incorporates a tamper-proof <strong>Caregiver Lock</strong>:
</p>
<ol>
  <li>Tap the <strong>Pin icon (📌)</strong> in the top-left corner of the header.</li>
  <li>The application enters <strong>Locked Mode</strong>: the Settings Menu, Edit Mode, and Card Deletion buttons become completely inaccessible.</li>
  <li>The child can freely communicate, tap cards, build sentences, and explore folders without risk.</li>
  <li>To unlock, tap the Lock icon and enter your 4-digit security PIN.</li>
</ol>

<table class="screenshot-grid">
  <tr>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/15_pin_dialog.png" alt="Caregiver PIN Dialog">
      <div class="screenshot-caption">Figure 6.1: Secure 4-digit PIN setup protecting administrative settings.</div>
    </td>
    <td class="screenshot-cell" style="width:50%;">
      <img src="./assets/15_pin_mode_locked.png" alt="Locked Board Mode">
      <div class="screenshot-caption">Figure 6.2: Locked Board Mode active: editing disabled for child safety.</div>
    </td>
  </tr>
</table>

<h2>6.2 Setting and Resetting Your Security PIN</h2>
<ul>
  <li><strong>Initial PIN:</strong> When first enabling Caregiver Lock, enter any 4-digit PIN of your choice (e.g., <code>1234</code>).</li>
  <li><strong>Master Unlock Safeguard:</strong> If you ever forget your PIN, tap <em>Forgot PIN</em> and enter the master override key: <code>0000</code>.</li>
</ul>

<div class="section-header">
  <h1>Chapter 7 — Data Backup, Restore & Offline Privacy</h1>
</div>

<h2>7.1 Creating a Complete Data Backup</h2>
<p>
  Never lose your customized cards, recorded voices, or photos. Simple AAC features an all-in-one export tool:
</p>
<ol>
  <li>Open <strong>Settings &gt; Backup &amp; Restore</strong>.</li>
  <li>Tap <strong>Create Backup</strong>.</li>
  <li>Simple AAC compiles your communication database, custom images, animated GIFs, audio recordings, and theme preferences into a single encrypted <code>.zip</code> file.</li>
  <li>Save the backup file to your device Downloads, an SD Card, or share it via Google Drive, WhatsApp, or email to a family member's phone.</li>
</ol>

<h2>7.2 Restoring onto a New Phone or Tablet</h2>
<p>
  Moving to a new tablet or sharing vocabulary between a child's home tablet and school tablet takes seconds:
</p>
<ol>
  <li>Copy the backup file onto the new device.</li>
  <li>Install Simple AAC, open <strong>Settings &gt; Backup &amp; Restore</strong>, and tap <strong>Restore Backup</strong>.</li>
  <li>Select your backup file. Simple AAC safely verifies the archive and restores all cards, photos, recorded voices, and colors.</li>
</ol>

<div class="caution-box">
  <div class="box-title">Data Privacy & Security Guarantee</div>
  Simple AAC operates 100% offline. It contains <strong>zero external trackers, zero telemetry, and zero third-party advertising</strong>. Your child's voice recordings, photos, and communication history are stored solely inside your device's private sandbox and are never uploaded to any remote server.
</div>

<div class="page-break"></div>

<div class="section-header">
  <h1>Chapter 8 — Troubleshooting & Frequently Asked Questions</h1>
</div>

<h2>8.1 Common Questions & Quick Solutions</h2>

<table style="width:100%; border-collapse:collapse; margin-top:6px; font-size:8.5pt;">
  <tr style="background:#f1f5f9; border-bottom:2px solid #cbd5e1;">
    <th style="padding:6px 8px; text-align:left; width:35%;">Symptom / Question</th>
    <th style="padding:6px 8px; text-align:left;">Solution & Step-by-Step Guidance</th>
  </tr>
  <tr style="border-bottom:1px solid #e2e8f0;">
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">Cards do not speak audio when tapped.</td>
    <td style="padding:6px 8px;">
      1. Check your tablet's <strong>Media Volume</strong> (buttons on device side). Ensure media is not muted.<br>
      2. In Simple AAC Settings, verify <strong>Tap to Speak</strong> is switched ON.<br>
      3. Verify your device has an active TTS engine installed (Google Speech Recognition &amp; Synthesis).
    </td>
  </tr>
  <tr style="border-bottom:1px solid #e2e8f0;">
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">Sinhala or Tamil speech is silent or sounds unnatural.</td>
    <td style="padding:6px 8px;">
      Android devices require the offline language data pack for Sinhala and Tamil. Go to Android <strong>Settings &gt; System &gt; Language &gt; Text-to-Speech &gt; Google TTS settings &gt; Install voice data</strong>, and tap download for Sinhala and Tamil.
    </td>
  </tr>
  <tr style="border-bottom:1px solid #e2e8f0;">
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">Camera or photo selection does not open.</td>
    <td style="padding:6px 8px;">
      Ensure Simple AAC has permission to use the camera: Go to Android <strong>Settings &gt; Apps &gt; Simple AAC &gt; Permissions</strong>, and grant <em>Camera</em> permission. For gallery images, Simple AAC uses the system Photo Picker which requires no storage permissions.
    </td>
  </tr>
  <tr style="border-bottom:1px solid #e2e8f0;">
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">I accidentally deleted an important card.</td>
    <td style="padding:6px 8px;">
      Cards are not immediately destroyed! Open <strong>Settings &gt; Recycle Bin</strong>. Locate your deleted card and tap <strong>Restore</strong> to return it to its original category.
    </td>
  </tr>
  <tr style="border-bottom:1px solid #e2e8f0;">
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">App reopened to the home screen instead of my folder.</td>
    <td style="padding:6px 8px;">
      In Build 16, active folders are automatically saved to internal memory. Simply resume Simple AAC from Android Recent Apps to maintain your exact sub-folder position.
    </td>
  </tr>
  <tr>
    <td style="padding:6px 8px; font-weight:600; color:#0f172a;">How do I backup my child's customized vocabulary?</td>
    <td style="padding:6px 8px;">
      Open <strong>Settings &gt; Backup &amp; Restore &gt; Create Backup</strong>. Save the generated zip file to Google Drive or an external USB flash drive every month for peace of mind.
    </td>
  </tr>
</table>

<div class="tip-box" style="margin-top:14px;">
  <div class="box-title">Support & Community</div>
  Simple AAC Sri Lanka was developed as an open accessibility initiative for Sri Lankan children and families. For feedback, community resources, and printable communication boards, visit our project repository or contact your local speech therapy center.
</div>
"""

print("English content module ready.")
