#!/usr/bin/env python3
"""Discussion drafts for a broader feasibility scope.

These files are not the approved ethics protocol. They are written only
under the git-ignored private directory. The existing one-sitting protocol
is left unchanged.
"""

import os

import docx

from build_erc_package import convert_docx_to_pdf
from docx_common import (
    add_body,
    add_heading,
    add_numbered_item,
    add_page_break,
    add_plain_table,
    create_styled_document,
    repo_root,
    save_doc,
    setup_header_footer,
)

ALT_TITLE = (
    "Feasibility of a customised trilingual picture-based AAC mobile application "
    "for children with communication difficulties in Galle, Sri Lanka: "
    "an alternative staged design for discussion"
)

REFERENCES = [
    "Light J, McNaughton D. Communicative competence for individuals who require augmentative and alternative communication: a new definition for a new era of communication? Augment Altern Commun. 2014;30(1):1–18.",
    "Light J. Toward a definition of communicative competence for individuals using augmentative and alternative communication systems. Augment Altern Commun. 1989;5(2):137–144.",
    "Romski M, Sevcik RA. Augmentative communication and early intervention: myths and realities. Infants Young Child. 2005;18(3):174–185.",
    "Beukelman DR, Light JC. Augmentative and alternative communication: supporting children and adults with complex communication needs. 5th ed. Baltimore: Paul H. Brookes Publishing; 2020.",
    "World Health Organization. Autism [Internet]. Geneva: World Health Organization; [cited 2026 Nov 6]. Available from: https://www.who.int/news-room/fact-sheets/detail/autism-spectrum-disorders",
]


def out_dir():
    path = os.path.join(repo_root(), ".local_erc_private", "scope_discussion")
    os.makedirs(path, exist_ok=True)
    return path


def new_doc(path, title):
    doc = create_styled_document()
    setup_header_footer(doc)
    return doc


def add_decision(doc):
    add_body(doc, "Study scope", bold=True, center=True, size=16, space_after=4, line_spacing=1.0)
    add_body(
        doc,
        "A decision for Dr Gayani Punchihewa, J.G.D. Thamalka and D.V.W. Gunawardana",
        center=True,
        space_after=6,
        line_spacing=1.0,
    )
    add_body(
        doc,
        "The proposal dated 08 November 2026 describes one supervised sitting of about twenty "
        "minutes. The feasibility note shared from the supervisor discussion describes a wider "
        "set of questions: local need, user requirements, technical performance, expert review, "
        "acceptability, cost, implementation and a pilot. That note is guidance. It is not a "
        "signed protocol, and it is not evidence that those stages have been done. This document "
        "asks the supervisor and the two student researchers to choose the scope. It does not "
        "replace the current ethics draft.",
        space_after=6,
        line_spacing=1.15,
    )
    add_heading(doc, "Option A. Keep the narrow usability pilot", 2)
    add_body(
        doc,
        "Each child–caregiver pair would attend one sitting at PRAGATHI Child Intervention Centre, "
        "Galle, after ethics approval and site permission. An observer would record whether a "
        "willing child selects a picture, keeping “not attempted” separate from “attempted but "
        "not selected”, and the caregiver would answer five short questions. There is no control "
        "group and no claim that communication improves. The sample size is still unset. Twelve "
        "pairs is only an example, and only if it is accepted in writing.",
        space_after=4,
        line_spacing=1.15,
    )
    add_body(
        doc,
        "Option A can show whether that short procedure can be carried out. It cannot establish "
        "need across families and staff, expert judgement of the words, cost, how the centre would "
        "maintain the application, acceptability over time, or clinical change. Those limits are "
        "why the student researchers did not accept Option A as the full feasibility study.",
        space_after=6,
        line_spacing=1.15,
    )
    add_heading(doc, "Option B. A staged feasibility study, for discussion", 2)
    add_body(
        doc,
        "Option B is not approved by being written here. No new participant procedure will be "
        "submitted, or started, unless this option is selected in writing.",
        space_after=3,
        line_spacing=1.15,
    )
    for stage in (
        "Stage 1. Desk description of the application already built, the language gaps found in the source, and a cost-heading list. No interviews.",
        "Stage 2. Checks on one frozen handset: languages, speech, offline use, storage and permissions. Engineering records, not clinical outcomes.",
        "Stage 3. Expert feedback only if approved as research, with its own consent and ethics review. Informal conversations are not validation.",
        "Stage 4. A supervised child–caregiver pilot. Length, visits and sample are not set. Not an effectiveness trial.",
        "Stage 5. One report of recruitment, completion, safety, language, usability, barriers and cost, each with a denominator. No claim of improved speech.",
    ):
        add_body(doc, stage, space_after=2, line_spacing=1.08)
    add_body(
        doc,
        "The population also needs a decision. The current draft includes children with "
        "communication difficulties, not an autism-only group. Restricting the study to children "
        "with autism would change the title, the background, inclusion, the outcomes and the "
        "consent form. That change is not made here.",
        space_after=4,
        line_spacing=1.15,
    )
    add_plain_table(
        doc,
        ["Decision", "Mark one", "Initial"],
        [
            ["Scope", "Option A  /  Option B  /  Amend as follows", ""],
            ["Population", "Communication difficulties  /  Autism only  /  Other", ""],
            ["Expert or caregiver interviews", "Not in this study  /  Add, and write a new ethics method first", ""],
            ["Sample size for any child sitting", "Still open. 12 is not accepted unless a reason is written.", ""],
        ],
    )
    add_body(
        doc,
        "Dr Gayani Punchihewa, signature ______________________    Date ____________",
        justify=False,
        space_after=2,
        line_spacing=1.0,
    )
    add_body(
        doc,
        "J.G.D. Thamalka, signature ______________________    Date ____________",
        justify=False,
        space_after=2,
        line_spacing=1.0,
    )
    add_body(
        doc,
        "D.V.W. Gunawardana, signature ______________________    Date ____________",
        justify=False,
        space_after=2,
        line_spacing=1.0,
    )


def add_proposal(doc):
    add_body(doc, ALT_TITLE, bold=True, center=True, size=16, space_after=8, line_spacing=1.08)
    add_body(doc, "DISCUSSION DRAFT", bold=True, center=True, size=14, space_after=6, line_spacing=1.0)
    add_body(
        doc,
        "Alternative for discussion. This is not the approved protocol and it has not been submitted.",
        center=True,
        italic=True,
        space_after=8,
        line_spacing=1.0,
    )
    add_body(doc, "Medical student researchers", bold=True, center=True, space_after=0, line_spacing=1.0)
    add_body(
        doc,
        "J.G.D. Thamalka and D.V.W. Gunawardana",
        center=True,
        space_after=4,
        line_spacing=1.0,
    )
    add_body(doc, "Faculty of Medicine, University of Ruhuna", center=True, space_after=6, line_spacing=1.0)
    add_body(doc, "Proposed supervisor", bold=True, center=True, space_after=0, line_spacing=1.0)
    add_body(
        doc,
        "Dr Gayani Punchihewa, Department of Psychiatry",
        center=True,
        space_after=6,
        line_spacing=1.0,
    )
    add_body(doc, "Technical research collaborator and application developer", bold=True, center=True, space_after=0, line_spacing=1.0)
    add_body(doc, "E.K.Y.P. Fernando", center=True, space_after=8, line_spacing=1.0)
    add_body(doc, "Proposed site: PRAGATHI Child Intervention Centre, Galle", center=True, space_after=4, line_spacing=1.0)

    add_page_break(doc)
    add_heading(doc, "1. Purpose")
    add_body(
        doc,
        "The student researchers asked for a feasibility study that covers more than one short "
        "sitting. The guidance they shared includes local need, what users require, whether the "
        "application works in Sinhala, Tamil and English, expert comment on the content, "
        "acceptability, cost, implementation at a centre, and a pilot. This draft sets out how "
        "that wider study could be done. It is offered so the team can accept, amend or reject it. "
        "The existing one-sitting proposal remains the only ethics draft until a written choice is made.",
    )
    add_body(
        doc,
        "Two kinds of fact are kept apart. The first is work already done on the software, read "
        "from the source on 8 November 2026. The second is research that has not started. No "
        "family has been enrolled. No expert panel has been convened for this study. No cost has "
        "been obtained. No approval has been given.",
    )

    add_heading(doc, "2. What the software record already shows")
    add_body(
        doc,
        "The application source inspected on 8 November 2026 is version 1.0.2+3. A card can store "
        "an English label, a Sinhala label and a Tamil label. The home screen can be set to any "
        "of the three languages. If a Sinhala or Tamil label is empty, the English label is shown. "
        "The seed list has Sinhala and Tamil for seven items only: hello, happy, sad, angry, more, "
        "good and play. The rest of the catalogue was not counted as translated. The speech engine "
        "is asked for si-LK, ta-IN or en-US. Speech in Sinhala and Tamil has not been heard on a "
        "study device, and a competent speaker has not checked the wording.",
    )
    add_body(
        doc,
        "Online features are off unless switched on, and the network helper used by the application "
        "blocks its own web requests while they are off. That was read in source. It was not shown "
        "on a handset. The Android package still requests internet, microphone and camera access, "
        "because a card can be given a photograph or a recorded voice. Cards are stored in the "
        "application documents folder, with a local backup file. No encryption of that file was "
        "identified. A local backup does not prove that cloud backup is impossible.",
    )
    add_body(
        doc,
        "These points describe a product under development. They are not research results, and "
        "they are not a statement that the application is ready for families.",
    )

    add_heading(doc, "3. Questions a wider feasibility study would ask")
    add_body(
        doc,
        "If Option B is selected, the study would ask whether a picture-based application of this "
        "kind can be specified, checked, and then tried in one supervised contact with children "
        "who already attend the proposed centre and with their caregivers. It would also ask what "
        "the application costs to run and what the centre would have to provide. It would not ask "
        "whether communication or speech improves. A question of that kind needs repeated "
        "measurement and a separate scientific and ethical review.",
    )
    add_numbered_item(doc, "1", "Which words and functions are present in the named build, and which local-language labels are missing?")
    add_numbered_item(doc, "2", "On the handset that would be used, do the selected languages display and speak as intended, and can a sitting proceed without a network connection?")
    add_numbered_item(doc, "3", "If an expert-review stage is approved, do clinicians or language specialists judge the displayed words as suitable for the intended children?")
    add_numbered_item(doc, "4", "In a later supervised pilot, can a willing child and a caregiver complete the agreed tasks, and what stops a sitting?")
    add_numbered_item(doc, "5", "What staff time, device, printing and upkeep would the centre need, using figures the team actually obtains?")

    add_heading(doc, "4. Population, still to be chosen")
    add_body(
        doc,
        "The current ethics draft uses children with communication difficulties. It does not require "
        "a diagnosis of autism, and it does not copy a diagnosis from the clinical file. The shared "
        "guidance speaks more often of autism. Both choices are left open.",
    )
    add_plain_table(
        doc,
        ["If the supervisor chooses", "What would change"],
        [
            [
                "Children with communication difficulties",
                "Title, background and consent stay broad. A clinician at the centre judges that a picture aid is relevant. Autism may be present, but it is not required.",
            ],
            [
                "Children with autism only",
                "The title, the literature emphasis, inclusion, the outcomes and every consent form would be rewritten before submission. Children with other communication difficulties would be excluded.",
            ],
        ],
    )

    add_heading(doc, "5. Design, if Option B is selected")
    add_heading(doc, "5.1 Stage 1. Desk review", 2)
    add_body(
        doc,
        "The students and the developer would write an inventory of the named source version: "
        "screens, languages, seed words, permissions and storage. They would list cost headings "
        "for a device, printing, local travel, translation checking and upkeep. Cells without a "
        "quotation would stay blank. Published descriptions of augmentative and alternative "
        "communication would be used only for definitions. No parent, clinician or therapist would "
        "be interviewed in this stage. Past informal conversations are not entered as data.",
    )
    add_heading(doc, "5.2 Stage 2. Technical verification", 2)
    add_body(
        doc,
        "One build would be frozen and named before any later pilot. On that handset the developer "
        "would record whether Sinhala, Tamil and English labels appear, whether speech is heard, "
        "whether the sitting can start with online features off, and whether a new photograph or "
        "a new voice recording can be avoided. A competent speaker would check wording before any "
        "family sees it. The record is an engineering log. It is not a clinical measure. The "
        "checks themselves do not require a child participant. They are listed in the technical annex.",
    )
    add_heading(doc, "5.3 Stage 3. Expert feedback, only if added", 2)
    add_body(
        doc,
        "A structured review by clinicians or language specialists is not part of the study unless "
        "the supervisor adds it. If it is added, those people become research participants. The "
        "team would then write who is invited, what they are asked, how long it takes, how notes "
        "are stored, and how they may refuse. That method, and its consent form, would go to the "
        "Ethics Review Committee before anyone is approached. No such review has been done.",
    )
    add_heading(doc, "5.4 Stage 4. Child and caregiver pilot", 2)
    add_body(
        doc,
        "After ethics approval and written permission from the centre, each participating pair "
        "would be invited to a supervised contact. The number of contacts, the length and the "
        "sample are not stated, because they have not been chosen. The existing draft uses about "
        "twenty minutes and one contact. A longer or repeated contact is a different study and "
        "is not adopted here. Usual care and medicine would not change. A child who does not wish "
        "to take part would not be included. The developer would not take consent and would not "
        "decide eligibility.",
    )
    add_body(
        doc,
        "The observer would record task completion, early stopping, the language set that day, "
        "and technical faults that contain no name. The caregiver would be asked only questions "
        "listed in the approved form. The five questions in the current draft cover screen ease, "
        "language, finding a picture, willingness to use the application again, and whether the "
        "child seemed upset. Further questions would be added only when the scope is chosen.",
    )
    add_heading(doc, "5.5 Stage 5. Feasibility report", 2)
    add_body(
        doc,
        "The report would give counts and proportions for the stages that were actually approved: "
        "how many labels were checked, how many technical checks passed, how many families were "
        "invited, how many completed, how many stopped, and which cost cells were filled. Each "
        "figure would have a denominator. The report would not say that the child’s communication improved.",
    )

    add_heading(doc, "6. How each question would be answered")
    add_body(
        doc,
        "The tools below are proposed for Option B. They are not approved instruments, and they "
        "are not validated scales. They will not be used until the scope and the ethics application "
        "name them.",
    )
    add_plain_table(
        doc,
        ["Question", "Record", "Analysis, if that stage is approved"],
        [
            ["What is on the build?", "Content inventory from the named source and the frozen handset.", "Counts of labels by language. No participant."],
            ["Does the handset do what the source suggests?", "Engineering checklist. Result left blank until the test.", "Pass, fail, or not tested, for each row."],
            ["Do specialists accept the words?", "Only if Stage 3 is added. A short form written at that time.", "Counts of suitable / amend / reject. Not done now."],
            ["Can a pair finish the contact?", "Observer record: not attempted; attempted and selected; attempted but not selected; stopped early; fault.", "Counts and proportions among pairs who were invited."],
            ["Is the contact acceptable to the caregiver?", "The approved questions only. Yes, no, or not sure.", "Counts. No score is invented."],
            ["What would it cost to run?", "Quotations obtained by the team. Unknown cells stay blank.", "A table of figures, or of items still uncosted."],
        ],
    )

    add_heading(doc, "7. Sample size")
    add_body(
        doc,
        "No number is selected. Stages 1 and 2 do not have a participant sample. Stage 3 has no "
        "panel size, because the stage itself is not included. For a child–caregiver contact, two "
        "ideas remain open and neither is in force. One is to invite every eligible pair during a "
        "period agreed with the centre. The number would be whatever that period yields. The other "
        "is a fixed group of 12 pairs, offered only as a way to see whether the procedure can be "
        "finished. Twelve is not a power calculation, it is not based on a count of eligible "
        "families, and it is not the sample of this study unless the supervisor accepts it in "
        "writing and states the reason. Accepting 12 would not support a claim of clinical effect.",
    )

    add_heading(doc, "8. Ethics")
    add_body(
        doc,
        "Desk inspection of software the developer already holds is not enrolment of a child. "
        "Any approach to a child, a caregiver, a clinician or a language specialist for study data "
        "requires approval from the Ethics Review Committee, Faculty of Medicine, University of "
        "Ruhuna, and permission from the centre where relevant. English information, consent and "
        "assent drafts exist for the one-sitting design only. Sinhala and Tamil versions have not "
        "been written. A new participant group needs new documents. Consent would be stored apart "
        "from coded records. The place and the retention period are not yet agreed.",
    )
    add_body(
        doc,
        "The proposed site is PRAGATHI Child Intervention Centre, Galle. Permission has not been "
        "received. Whether the Ministry of Health, a provincial authority, or only the centre must "
        "be asked is not known. A request for advice is a separate letter. It is not part of this "
        "discussion draft, and it has not been sent.",
    )

    add_heading(doc, "9. References")
    add_body(
        doc,
        "The five items below were checked for the 6 November bibliographic note and are used "
        "only for definitions. The World Health Organization page is cited as a general source "
        "on autism. No prevalence figure is taken from it. No local study result is claimed.",
        space_after=4,
    )
    for index, ref in enumerate(REFERENCES, start=1):
        add_numbered_item(doc, str(index), ref, justify=False, size=12)

    add_heading(doc, "10. Decisions still required")
    add_plain_table(
        doc,
        ["Item", "Position in this draft"],
        [
            ["Scope", "Option B is written for discussion. Option A remains the current ethics draft."],
            ["Population", "Communication difficulties, unless changed in writing."],
            ["Applicant", "Not named. The students lead the research."],
            ["Sample size and number of contacts", "Not selected."],
            ["Expert review", "Not included unless added with its own ethics method."],
            ["Site permission and ethics approval", "Not requested and not given."],
            ["Handset build", "Not frozen. Speech and wording not checked."],
            ["Sinhala and Tamil parent forms", "Not written."],
            ["Costs", "Not obtained. No figure is entered."],
        ],
    )


def add_annex(doc):
    add_body(
        doc,
        "Technical and implementation feasibility annex",
        bold=True,
        center=True,
        size=16,
        space_after=6,
        line_spacing=1.05,
    )
    add_body(
        doc,
        "Engineering record for the discussion draft. Not a clinical result and not a completed test.",
        center=True,
        italic=True,
        space_after=8,
    )
    add_body(
        doc,
        "Source read on 8 November 2026, version 1.0.2+3. The result column is blank because the "
        "handset that would be used has not been tested. E.K.Y.P. Fernando would carry out the "
        "device checks. J.G.D. Thamalka and D.V.W. Gunawardana would not treat this log as a "
        "measure of a child’s communication.",
    )
    add_heading(doc, "1. Build and device", 2)
    add_plain_table(
        doc,
        ["Check", "Read in source", "Still required", "Result"],
        [
            ["Named build", "Version 1.0.2+3 in the repository. No device build is frozen.", "File name, version and date of the one build to be used.", ""],
            ["Installation", "Not tested on the centre’s device.", "Record the device model and whether the build installs.", ""],
            ["Later change", "A different build is a different product.", "Do not replace the named build after any approved recruitment without an amendment.", ""],
        ],
    )
    add_heading(doc, "2. Languages and speech", 2)
    add_plain_table(
        doc,
        ["Check", "Read in source", "Still required", "Result"],
        [
            ["Labels", "English, Sinhala and Tamil fields exist. Empty local labels fall back to English.", "Inventory of the frozen build: translated, English only, or empty.", ""],
            ["Seed words", "Sinhala and Tamil were seen for hello, happy, sad, angry, more, good and play.", "A competent speaker checks those seven items and any others that are added.", ""],
            ["Speech", "Codes requested: si-LK, ta-IN, en-US. The service starts on en-US.", "Listen on the pilot device. Record heard, not heard, or wrong language.", ""],
        ],
    )
    add_heading(doc, "3. Offline behaviour, storage and permissions", 2)
    add_plain_table(
        doc,
        ["Check", "Read in source", "Still required", "Result"],
        [
            ["Network", "Online features start off. The application’s gated client throws while they are off. The package still requests internet access.", "Confirm the sitting can start with online features off.", ""],
            ["Camera and microphone", "Present, for card photographs and card voice recordings.", "No new photograph and no new voice recording during a research contact.", ""],
            ["Storage", "Application documents folder and a local backup file. Encryption was not identified.", "Cloud backup off for any research contact. Do not put study forms on a shared drive.", ""],
        ],
    )
    add_heading(doc, "4. Cost, upkeep and responsibility", 2)
    add_body(
        doc,
        "No licence fee, hosting charge or maintenance contract was identified in the passages read. "
        "No quotation is invented below. The developer is the person who would prepare the named "
        "build. The students would not be asked to change the software. Who pays for a device, "
        "printing and travel is not agreed.",
    )
    add_plain_table(
        doc,
        ["Heading", "Figure", "Who would obtain it"],
        [
            ["Handset for a research contact", "Not yet costed", "The research team"],
            ["Printing of forms", "Not yet costed", "The research team"],
            ["Travel within Galle", "Not yet costed", "The research team"],
            ["Translation checking", "Not yet costed", "A competent speaker, once identified"],
            ["Replacement or upkeep after the study", "Not yet costed", "Not agreed"],
            ["Licence or hosting", "None identified in the source reading", "Developer, if a charge exists"],
        ],
    )
    add_heading(doc, "5. What this annex is not", 2)
    add_body(
        doc,
        "It is not a certificate, not a security audit, and not permission to enrol a child. "
        "A pass on a row would mean only that the named build did that thing on that day.",
    )


def build_all():
    folder = out_dir()
    specs = [
        ("Feasibility_Framework_Alignment_and_Supervisor_Decision.docx", "Study scope decision", add_decision),
        ("Feasibility_Research_Proposal_REVISED_DRAFT.docx", "Feasibility alternative for discussion", add_proposal),
        ("Technical_and_Implementation_Feasibility_Annex.docx", "Technical feasibility annex", add_annex),
    ]
    written = []
    for name, title, writer in specs:
        path = os.path.join(folder, name)
        doc = new_doc(path, title)
        writer(doc)
        save_doc(doc, path, title)
        check = docx.Document(path)
        if check.core_properties.author:
            raise RuntimeError("author metadata was not cleared")
        pdf = convert_docx_to_pdf(path, folder)
        written.append((path, pdf))
        print(path)
        print(pdf)
    return written


if __name__ == "__main__":
    build_all()
