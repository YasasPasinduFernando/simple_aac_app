# Final Evidence Summary: Simple AAC Technical Evidence Package

**Document:** `06_Final_Evidence_Summary_For_Research_Writing.md`  
**Purpose:** Standalone research briefing package designed to be shared directly with ChatGPT, medical research co-authors, and supervisor Dr. Gayani Punchihewa alongside the 10-domain feasibility framework.  
**Self-Contained Requirement:** This document contains all verified software engineering facts, clinical mappings, and language boundaries necessary to write the research protocol and ERC application without requiring access to the application source code.

---

## Executive Context and Research Roles

- **Project Title:** Simple AAC (Sri Lanka)
- **Target Health Condition:** Autism Spectrum Disorder (ASD) and associated functional communication difficulties in children.
- **Geographic Setting:** Galle / Southern Province, Sri Lanka.
- **Lead Investigators:** J.G.D. Thamalka and D.V.W. Gunawardana (Medical Student Researchers, Faculty of Medicine, University of Ruhuna).
- **Academic Supervisor & Co-Investigator:** Dr. Gayani Punchihewa (MBBS, MD Psych, Senior Lecturer and Psychiatrist, Department of Psychiatry, Faculty of Medicine, University of Ruhuna).
- **Technical Collaborator & Application Developer:** Yasas Pasindu Fernando (MSc Artificial Intelligence ongoing, BEng Software Engineering completed).
- **Current Research Standing:** Pre-clinical feasibility stage. Software development is complete and stable; **no clinical study has been conducted, no children have been enrolled, and no ethics approval has been granted yet**.

---

## SECTION A: VERIFIED APPLICATION FACTS (Code-Grounded Truths)

1. **Target Software Identity:**
   - Package Identifier: `lk.yasas.simpleaac`
   - Verified Codebase Version: `1.1.4+12` (Version 1.1.4, Build 12).
   - Technology: Google Flutter (Dart 3.x), targeting Android OS (API 24 to 36 / Android 7.0 to Android 16).
   - Code Stability: 210 passing automated unit, widget, and integration tests; verified on physical hardware (Samsung Galaxy A34 5G).

2. **Picture-Based Communication (AAC Core):**
   - **Grid of Cards:** Renders picture communication cards in a flexible grid. Each card holds an image, a primary English label, optional Sinhala and Tamil labels, an optional voice recording, an accent colour, and a category.
   - **Sentence Strip (Communication Bar):** A persistent bar across the top of the screen (`TtsBar`). Tapping cards adds them sequentially to the strip. A speaker button reads the whole sequence aloud, allowing multi-card sentence building (e.g., "Want" + "Water"). Individual tokens or the entire strip can be deleted.
   - **Hierarchical Folders:** Cards can act as folders containing nested sub-cards, allowing categorized vocabulary organisation.
   - **Multi-Category Selection:** A "Choose Categories" dialog allows filtering the board to show cards from one, several, or all categories simultaneously, displaying a live preview with removable category chips.

3. **Speech and Audio Output:**
   - **Synthetic Text-to-Speech (TTS):** Uses Android's system `TextToSpeech` service (`flutter_tts`) at a calibrated rate (`0.5`) and pitch (`1.0`). Capable of requesting `en-US`, `si-LK`, and `ta-IN`.
   - **Recorded Human Audio:** Allows caregivers to record voice notes directly for any card using the device microphone (`record` package). Recorded audio plays back via `audioplayers` and always overrides synthetic TTS.
   - **Mixed-Script Routing:** Uses a custom router (`MultilingualSpeechRouter`) that splits composite text into Unicode script runs and Romanized phrases, sending words to the correct language engine without phonetic corruption.

4. **Trilingual Language Implementation:**
   - **Metadata Storage:** Every card model stores `label` (English), `labelSinhala`, and `labelTamil`. If a Sinhala or Tamil label is blank, the app safely falls back to displaying the English label.
   - **Starter Vocabulary:** The factory-installed seed database contains exactly 7 items (5 top-level cards: Hello, Happy, Sad, Angry, More; and 2 sub-cards: Good, Play). All 7 have verified English, Sinhala, and Tamil labels.
   - **Offline Concept Bank:** Contains a built-in dictionary of **179 curated trilingual everyday concepts** (`MultilingualConceptService`). Typing an everyday word auto-populates the other two languages.

5. **User Interface and Cognitive Accessibility:**
   - **Adjustable Grid Density:** Caregivers can select between 1, 2, 3, 4, or 5 columns on the home board, dynamically altering card dimensions to match the child's motor and visual abilities.
   - **Selective Visibility ("Visible Cards"):** Allows hiding specific cards from view without deleting them, supporting stepped vocabulary learning.
   - **Board Pinning (Child-Safe Lock):** Tapping the Pin icon locks the interface against accidental app exit or menu navigation; unlocking requires pressing and holding the pin icon continuously for 1.5 seconds.
   - **Caregiver Security Lock:** Protects Edit Mode and the Settings Drawer using Android device biometrics (fingerprint/face) or screen lock (pattern/PIN), falling back to an in-app 4-digit PIN.
   - **Tactile Touch Feedback:** Executes a dual haptic pulse (`heavyImpact` + `vibrate`) on card selection to confirm input physically.
   - **Visual Accessibility:** Built-in color filters for Color Vision Deficiencies (Protanopia, Deuteranopia, Tritanopia) and High Contrast mode.

6. **Offline Operation and Privacy:**
   - **Strict Offline-by-Default:** Central network gate (`NetworkPolicyService`) defaults to OFF. When disabled, all outbound internet traffic is blocked. Runtime fetching of Google Fonts is explicitly disabled in code.
   - **Optional Image Search:** If (and only if) the caregiver enables "Online Features", the app can query the free Openverse Creative Commons library to fetch public-domain images.
   - **Local Storage:** All card data and media are stored exclusively in the app's local sandbox (`app_flutter/`).
   - **Data Backup / Restore:** Generates an unencrypted standard ZIP archive (`aac_backup.zip`) containing cards, settings, and media files, exportable to the device Downloads folder.
   - **Hardened Permissions:** Requests only `RECORD_AUDIO`, `CAMERA`, and `VIBRATE`. Broad media and external storage access permissions are explicitly stripped.

---

## SECTION B: POTENTIAL MEDICAL RELEVANCE (Theoretical Clinical Rationale)

1. **Visual Processing Strengths:** Many children with ASD demonstrate relative strengths in processing visuospatial stimuli compared to transient acoustic speech. Static picture cards provide a persistent visual anchor for communication.
2. **Reduction of Frustration and Challenging Behaviour:** Communication breakdowns in non-verbal children frequently precipitate severe distress, tantrums, or self-injurious behaviour. Providing a reliable means to request basic necessities (e.g., food, water, toilet, pain relief) may mitigate frustration.
3. **PECS Alignment and Sentence Formulation:** The horizontal sentence strip closely mirrors physical PECS Stage IV, enabling children to transition from single-word requests to structured multi-word utterances.
4. **Motor and Cognitive Adaptability:** Adjustable grid densities (1–5 columns) and selective card visibility accommodate a wide developmental spectrum, from a child requiring large single-target cards to an advanced user navigating a dense board.
5. **Cultural and Dialect Familiarity:** Recorded human voice playback allows parents to provide warm, culturally authentic vocal models in the child's natural domestic dialect, avoiding the flat or mechanical tone of synthetic TTS.
6. **Local Trilingual Context:** Sri Lanka’s multi-ethnic population requires communication tools that support Sinhala, Tamil, and English within the same household and classroom.

---

## SECTION C: CLAIMS REQUIRING CLINICAL CONFIRMATION (Unverified Hypotheses)

1. **Clinical Suitability and Acceptance:** Whether children with ASD will spontaneously engage with the app, accept the physical device, or show communicative intent cannot be determined from code; it requires direct clinical observation.
2. **Caregiver Burden and Usability:** Whether Sri Lankan parents (particularly those with low digital literacy) can independently configure cards, record audio, and manage categories requires field evaluation.
3. **Vocabulary Appropriateness:** The 179 built-in trilingual vocabulary items represent a software engineering compilation; they have **not** been formally validated by a Speech and Language Therapist (SLT) or child development panel.
4. **Local Speech Engine Availability:** While the app requests Sinhala (`si-LK`) and Tamil (`ta-IN`) speech, real-world low-cost Android handsets sold in Sri Lanka frequently lack local-language speech data. The clinical viability of synthetic speech vs recorded voice needs field verification.
5. **Therapeutic Effectiveness:** The software does not possess proven clinical efficacy. Any claim of "improved communication", "enhanced speech acquisition", or "behavioural improvement" requires a formal prospective clinical trial with standardized baseline and outcome measures.

---

## SECTION D: NOT YET IMPLEMENTED OR NOT VERIFIED (Strict Boundaries)

1. **Visual Schedules and Routine Timers:** **NOT IMPLEMENTED.** The application has no visual schedule engine, time-ordered task checklists, or first–then routine boards.
2. **Social Stories:** **NOT IMPLEMENTED.** There is no visual narrative or multi-page social story reader.
3. **Facial-Expression Recognition / Emotion AI:** **NOT IMPLEMENTED.** Google ML Kit is used strictly to detect inanimate physical objects in camera photos (to suggest card labels). There is zero facial emotion recognition.
4. **Apple iOS Support:** **NOT IMPLEMENTED / UNVERIFIED.** The iOS codebase is an unadapted framework template lacking the native method channels for backup, authentication, and object detection.
5. **Encrypted Backups & Cloud Sync:** **NOT IMPLEMENTED.** Backups are unencrypted ZIP archives stored on the local device. There is no automated cloud synchronization.
6. **Clinical Participant Data:** **ZERO.** No children, caregivers, or clinical patients have participated in a formal research study using this application to date.

---

## SECTION E: RECOMMENDED RESEARCH WORDING (Templates for Academic Writing)

### 1. Describing the Purpose of the Application
- **Recommended:** *"We developed an offline mobile augmentative and alternative communication (AAC) application designed to provide picture-based communication support for children with speech and language impairments in Sri Lanka."*
- **Avoid:** *"The application cures non-verbal autism"* or *"The app was clinically proven to improve speech."*

### 2. Describing Core Functionality
- **Recommended:** *"The application provides a customizable visual grid of communication cards, hierarchical folders, and a persistent communication sentence strip capable of generating spoken output via device text-to-speech or recorded caregiver audio in English, Sinhala, and Tamil."*
- **Avoid:** *"The app uses advanced artificial intelligence to automate speech therapy."*

### 3. Describing the Trilingual Capabilities
- **Recommended:** *"The software supports trilingual card labeling and includes an offline reference dictionary of 179 common daily concepts. Because synthetic Sinhala and Tamil speech availability depends on device-specific voice packages, the app incorporates a custom voice recording feature allowing caregivers to provide authentic local speech models."*
- **Avoid:** *"The application provides complete, professionally validated linguistic translation."*

### 4. Describing the Research Objective
- **Recommended:** *"This prospective study investigates the feasibility, usability, and caregiver acceptability of a single supervised sitting with the Simple AAC application among children with Autism Spectrum Disorder at a child intervention centre in Galle."*
- **Avoid:** *"This study evaluates the clinical effectiveness of an existing approved medical intervention."*

### 5. Describing Privacy and Child Protection
- **Recommended:** *"To safeguard child privacy and reduce digital distractions, the application functions strictly offline by default, storing all photographs, voice recordings, and customized communication boards locally within the sandboxed application directory without external cloud transmission."*
- **Avoid:** *"The app utilizes high-security military-grade cloud encryption."*
