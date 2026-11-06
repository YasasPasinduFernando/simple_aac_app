#!/usr/bin/env python3
"""Research proposal and participant documents for the Galle AAC study.

The proposal distinguishes software that already exists from human-participant
work that has not started. No participant numbers are invented.
"""

import os

from docx_common import (
    add_body,
    add_bullet,
    add_heading,
    add_mixed_body,
    add_numbered_item,
    add_page_break,
    add_plain_table,
    add_text,
    add_toc_line,
    create_styled_document,
    erc_root,
    save_doc,
    setup_header_footer,
    corresponding_contact_text,
)

TITLE = (
    "USABILITY AND CAREGIVER ACCEPTABILITY OF AN OFFLINE "
    "PICTURE-BASED COMMUNICATION APPLICATION FOR CHILDREN "
    "WITH COMMUNICATION DIFFICULTIES IN GALLE"
)

TOC_ENTRIES = [
    ("1. Introduction", 0),
    ("2. Justification", 0),
    ("3. Literature review", 0),
    ("4. Objectives", 0),
    ("4.1 General objective", 1),
    ("4.2 Specific objectives", 1),
    ("5. Methodology", 0),
    ("5.1 Study design", 1),
    ("5.2 Study setting", 1),
    ("5.3 Study population", 1),
    ("5.4 Study sample with inclusion and exclusion criteria", 1),
    ("Inclusion criteria", 2),
    ("Exclusion criteria", 2),
    ("5.5 Sampling method and sample size", 1),
    ("5.6 Data collection tools", 1),
    ("5.7 Data analysis plan", 1),
    ("5.8 Data collection procedure", 1),
    ("5.9 Administrative requirements", 1),
    ("5.10 Ethical consideration", 1),
    ("6. References", 0),
    ("7. Management matter", 0),
    ("8. Annexures", 0),
    ("Annex A. Information for parents and guardians", 1),
    ("Annex B. Consent of a parent or guardian", 1),
    ("Annex C. Assent of a child who can read this form", 1),
    ("Annex D. Session record and caregiver questions", 1),
    ("Annex E. Draft letters asking for permission", 1),
    ("Annex F. Sinhala and Tamil versions", 1),
]


def _page(toc, key):
    if not toc:
        return ""
    return toc.get(key, "")


def _team_block(doc, anonymous):
    if anonymous:
        add_body(
            doc,
            "Names and institutional affiliations of the investigators are omitted from this copy, "
            "as required for the anonymous proposal file. The proposed study site is retained.",
            italic=True,
            space_after=8,
        )
        return
    add_body(doc, "Proposed supervisor", bold=True, center=True, space_after=2)
    add_body(
        doc,
        "Dr Gayani Punchihewa, Senior Lecturer in Psychiatry, Department of Psychiatry, Faculty of "
        "Medicine, University of Ruhuna. She has not signed. She is not entered as the principal "
        "investigator. The applicant has not yet been confirmed.",
        space_after=6,
    )
    add_body(doc, "Medical student researchers", bold=True, center=True, space_after=2)
    add_body(
        doc,
        "J.G.D. Thamalka and D.V.W. Gunawardana, Faculty of Medicine, University of Ruhuna. They "
        "lead the clinical planning of this proposal and the ethics application.",
        space_after=6,
    )
    add_body(doc, "Researcher and technical collaborator", bold=True, center=True, space_after=2)
    add_body(
        doc,
        "Yasas Pasindu Fernando, developer of the communication application. He is not the principal "
        "investigator, and this study is not his degree dissertation.",
        space_after=6,
    )


def add_title_page(doc, anonymous):
    add_body(doc, TITLE, bold=True, center=True, space_after=12)
    add_body(doc, "RESEARCH PROPOSAL", bold=True, center=True, space_after=10)
    add_body(
        doc,
        "Draft for review by the research team and the supervisor. "
        "This document has not been signed. It is not an ethics approval.",
        center=True,
        italic=True,
        space_after=8,
    )
    _team_block(doc, anonymous)


def add_contents(doc, toc):
    add_page_break(doc)
    add_heading(doc, "Contents", 1)
    for title, level in TOC_ENTRIES:
        add_toc_line(doc, title, _page(toc, title), level)


def add_introduction(doc):
    add_page_break(doc)
    add_heading(doc, "1. Introduction")
    add_body(
        doc,
        "Some children can understand more than they can say. When speech is limited, everyday "
        "requests such as asking for water, naming a person, or showing that something hurts may "
        "not be understood by the family or by the people who teach and treat the child. Picture "
        "boards, signs and speech-generating devices are grouped under the term augmentative and "
        "alternative communication. They are a means of expression. They are not a treatment that "
        "can be assumed to increase speech, and they do not replace clinical care. (1,2)",
    )
    add_body(
        doc,
        "Much of the published work on these methods comes from high-income services with "
        "ready-made symbol sets in English. A project note prepared for a picture-based mobile "
        "application in Galle states that material in Sinhala and Tamil is scarce, and that many "
        "international applications are costly or culturally awkward for local families. That note "
        "is a description of the intended application. It is not a systematic review, and this "
        "proposal does not treat it as evidence that the application already helps children.",
    )
    add_body(
        doc,
        "The application itself has already been built. It presents pictures in categories, can "
        "store labels in Sinhala, Tamil and English, and is intended to speak a selected picture "
        "aloud. The project note says that the main communication functions can be used without "
        "an internet connection. The study session described below will be done with the device "
        "offline. Whether every part of the installed version behaves in that way must be checked "
        "by the developer before any child is invited.",
    )
    add_body(
        doc,
        "No child, parent, caregiver or therapist has been recruited. Consent has not been taken, "
        "and no session record exists. Earlier work on the software, including trials with sample "
        "cards that did not come from children, is not research with participants and will not be "
        "reported as a result. The sitting in this proposal will begin only after the Ethics Review "
        "Committee has approved the study and the centre has given written permission.",
    )
    add_body(
        doc,
        "The question is therefore a narrow one. If a parent and a child who already attends a "
        "child intervention centre in Galle are shown this application for one short supervised "
        "sitting, can the child select a picture, can the caregiver find the categories, and does "
        "the caregiver find the language and the screen acceptable? The study will not measure "
        "whether communication ability improves over time.",
    )


def add_justification(doc):
    add_heading(doc, "2. Justification")
    add_body(
        doc,
        "A communication application can be carefully made and still be impractical in a real room. "
        "The pictures may be unclear, the Sinhala or Tamil wording may sound wrong, the categories "
        "may not match what families actually need to say, or a child may become tired or upset "
        "before the sitting is finished. None of this is known for the application described here, "
        "because it has not been observed with participants under a protocol.",
    )
    add_body(
        doc,
        "A single descriptive sitting cannot show that the application is effective. It can show "
        "whether the team should change the screen, the words or the length of the sitting before "
        "anyone proposes a larger study. That is the gap this proposal addresses. The findings "
        "would belong to a local centre and a local language setting, which the international "
        "literature does not cover for this particular application. (1–4)",
    )
    add_body(
        doc,
        "Children who have difficulty with speech are not in a position to protect their own "
        "interests in the way an adult volunteer can. The study is justified only if it stays "
        "small, if a parent decides freely, if usual care continues, and if the sitting stops when "
        "the child does not want to continue. Those safeguards are set out in the methods. They are "
        "also the reason for not recruiting until the committee and the centre have agreed.",
    )
    add_body(
        doc,
        "The application already exists, so it could be shown to a child informally and later "
        "described as research. This proposal is the procedure that would be followed. Use outside "
        "that procedure is not part of the study, and it cannot be reported as if approval had "
        "already been given.",
    )


def add_literature(doc):
    add_heading(doc, "3. Literature review")
    add_body(
        doc,
        "Light described communicative competence for a person who uses a communication aid as "
        "more than the ability to operate a device. She distinguished linguistic, operational, "
        "social and strategic competence, and later work added the effect of motivation, confidence "
        "and the surrounding environment. (1,2) A single sitting with a new application can say "
        "something only about the operational part of that account: whether the child and the "
        "caregiver can make the screen do what it is supposed to do. It cannot show that the child "
        "has become a more competent communicator. This proposal uses the framework as a limit on "
        "what will be claimed, not as a list of outcomes to be scored.",
    )
    add_body(
        doc,
        "Romski and Sevcik reviewed beliefs that have delayed the offer of communication aids to "
        "young children, including the belief that an aid should be a last resort and the belief "
        "that a child must reach a particular age or skill before an aid is considered. They argued "
        "that the aid is a tool for language and communication, and that introducing it need not be "
        "postponed for those reasons. (3) Their paper is useful background. It is not evidence about "
        "the application in this proposal, and this study does not test their clinical argument.",
    )
    add_body(
        doc,
        "Standard teaching texts treat picture-based and speech-output systems as one part of "
        "communication support, to be chosen for a particular person and revised as that person’s "
        "needs change. (4) The same sources make clear that a device on its own is not an "
        "intervention. Someone has to choose the vocabulary, show the child what the pictures mean, "
        "and respond when a picture is selected. A usability sitting that ignores this will "
        "overstate what the software can do. The session in this proposal is therefore observed "
        "with the caregiver present, and the record asks what the caregiver could find on the "
        "screen, not whether therapy has succeeded.",
    )
    add_body(
        doc,
        "The World Health Organization describes autism as a developmental condition that can affect "
        "communication and social interaction. (5) The project note for the local application also "
        "names attention difficulties and speech and language delay among the children it hopes to "
        "support. Prevalence figures are not quoted here. A figure taken from another country, or "
        "from an unchecked local estimate, would not make this study more valid.",
    )
    add_body(
        doc,
        "What is missing, for the decision this team has to make, is any published observation of "
        "this application with children in Galle. The project note lists picture categories for food "
        "and drink, emotions, activities, school items, family members and everyday needs, and it "
        "says that Sinhala, Tamil and English are provided. Those statements describe the intended "
        "content. They have not been confirmed in this proposal by an independent count of the "
        "cards in the version that would be used, and they are not outcomes.",
    )
    add_body(
        doc,
        "Taken together, these sources support a modest design. The study asks whether children and "
        "caregivers at one centre can operate this existing application, in the languages it offers, "
        "during one sitting and with consent. It is not a trial of treatment. If the sitting is "
        "acceptable, a later study could ask a different question. That later study is not part of "
        "this application.",
    )


def add_objectives(doc):
    add_heading(doc, "4. Objectives")
    add_heading(doc, "4.1 General objective", 2)
    add_body(
        doc,
        "To describe, in one supervised sitting at a child intervention centre in Galle, whether "
        "children with communication difficulties and their caregivers can use an existing offline "
        "picture-based communication application, and whether caregivers find the screen and the "
        "language acceptable.",
    )
    add_heading(doc, "4.2 Specific objectives", 2)
    add_numbered_item(
        doc,
        "1",
        "To record whether the child selects at least one picture during the sitting.",
    )
    add_numbered_item(
        doc,
        "2",
        "To record whether the caregiver can open the communication categories that are present in the version of the application used that day.",
    )
    add_numbered_item(
        doc,
        "3",
        "To record the caregiver’s answers on ease of use, suitability of the language shown, and whether the caregiver would consider using the application again.",
    )
    add_numbered_item(
        doc,
        "4",
        "To record any sitting that is stopped because the child is distressed, tired or unwilling to continue.",
    )


def add_methods(doc, anonymous):
    add_heading(doc, "5. Methodology")
    add_heading(doc, "5.1 Study design", 2)
    add_body(
        doc,
        "This is a prospective descriptive study of one supervised sitting for each child–caregiver "
        "pair. There is no control group, no random allocation, and no change to medicine or to "
        "the child’s usual therapy. It is not a clinical trial. The application is shown; it is not "
        "prescribed. The sitting is the whole of the data collection for that pair.",
    )
    add_heading(doc, "5.2 Study setting", 2)
    add_body(
        doc,
        "The proposed setting is PRAGATHI Child Intervention Centre, Galle. The project note names "
        "this centre as the lead institution for the application and names the Department of "
        "Psychiatry, Faculty of Medicine, University of Ruhuna, as a collaborating department. "
        "Neither statement is permission to recruit. Written permission from the person in charge "
        "of the centre will be sought with the draft letter in Annex E. Until that letter is signed, "
        "the centre is a proposed site only.",
    )
    add_body(
        doc,
        "A hospital clinic is not included. The departmental services page lists a child and "
        "adolescent psychiatry clinic at Teaching Hospital Karapitiya under a different consultant. "
        "This draft does not assume that clinic, or any ward, is available. If the supervisor later "
        "wishes to add a second site, the proposal must be amended before submission and the "
        "sampling description rewritten.",
    )
    if not anonymous:
        add_body(
            doc,
            "Dr Gayani Punchihewa is the proposed supervisor. The Faculty staff page lists her as "
            "a senior lecturer and psychiatrist in the Department of Psychiatry, with interests in "
            "general adult psychiatry and maternal mental health. It does not list her as the "
            "consultant for the child and adolescent clinic. Her role in this study is academic "
            "supervision. It is not a claim that she directs the centre or the child clinic.",
        )
    add_heading(doc, "5.3 Study population", 2)
    add_body(
        doc,
        "The population is children who already attend the proposed centre, whose speech does not "
        "meet their everyday communication needs, together with the parent or guardian who attends "
        "with them. The project note refers to children aged about 2 to 12 years, including children "
        "described as having autism, attention difficulties, or speech and language delay. This "
        "study will not make those diagnoses. A child will be eligible only if a clinician or "
        "therapist who already knows the child at the centre considers that a picture-based aid is "
        "relevant, and if a parent or legal guardian is present.",
    )
    add_body(
        doc,
        "Therapists may help the investigators understand the usual routine of the room. They are "
        "not a separate study sample in this draft, and they will not be interviewed as research "
        "participants unless the supervisor adds that component and the committee is asked to "
        "review it.",
    )
    add_heading(doc, "5.4 Study sample with inclusion and exclusion criteria", 2)
    add_body(
        doc,
        "The sample is the children and caregivers who meet the criteria below and whose parents "
        "agree to take part. The recruitment period will be agreed with the centre and the "
        "supervisor before any family is invited.",
    )
    add_heading(doc, "Inclusion criteria", 2)
    add_bullet(doc, "The child attends the proposed centre.")
    add_bullet(doc, "The child is within the age range of about 2 to 12 years. The exact date-of-birth rule will be confirmed with the supervisor before recruitment.")
    add_bullet(doc, "A clinician or therapist at the centre considers that a picture-based communication aid is relevant to the child.")
    add_bullet(doc, "A parent or legal guardian is present and can be offered the information sheet in a language that person understands. At present only the English sheet has been drafted.")
    add_bullet(doc, "The parent or guardian gives written consent, and the child does not show unwillingness to enter the room for the sitting.")
    add_heading(doc, "Exclusion criteria", 2)
    add_bullet(doc, "The parent or guardian does not consent, or consent is given under pressure.")
    add_bullet(doc, "The child is acutely ill, or the sitting would delay urgent care.")
    add_bullet(doc, "The caregiver who is present cannot stay for the whole sitting.")
    add_bullet(doc, "The investigators cannot explain the study in a language the caregiver understands. Sinhala and Tamil sheets are not yet available, so this exclusion will apply until those sheets have been checked by competent speakers.")
    add_bullet(doc, "The child has already been included. Each child is eligible once.")
    add_heading(doc, "5.5 Sampling method and sample size", 2)
    add_body(
        doc,
        "Sampling would be consecutive. During a period agreed with the centre, families who meet "
        "the criteria would be told about the study by a clinician or therapist who is not using "
        "the invitation to alter the child’s usual care. Those who wish to hear more would then "
        "speak with a student researcher. Families who need time would be allowed to decide on a "
        "later visit. Recruitment would stop when the agreed number is reached, or when the agreed "
        "period ends, whichever comes first.",
    )
    add_body(
        doc,
        "The number of children is not yet entered. This is a descriptive study of one sitting. It "
        "does not compare groups, and it does not test whether communication improves, so a power "
        "calculation for a difference between groups is not the calculation required. The number "
        "still has to be set by the supervisor. It depends on how many eligible children attend the "
        "centre, and on what proportion she is prepared to use for the main observations: a picture "
        "selected, the categories opened, and the caregiver’s answers. Those figures have not been "
        "supplied. Until she writes the number into this section, this proposal is not ready for "
        "submission, and no family will be recruited.",
    )
    add_heading(doc, "5.6 Data collection tools", 2)
    add_body(
        doc,
        "Three study-specific forms are drafted in Annex D. They are not published scales, and no "
        "permission from an external author is required for them. They must still be accepted by "
        "the supervisor before use.",
    )
    add_numbered_item(
        doc,
        "1",
        "A background line on the session cover: age in completed years, home language, and who came with the child. The child’s name is not written on this line. Diagnosis is not copied from the clinical file.",
    )
    add_numbered_item(
        doc,
        "2",
        "A session record completed by the observer: whether a picture was selected, whether each category present that day could be opened by the caregiver, and whether the sitting was stopped early, with the reason.",
    )
    add_numbered_item(
        doc,
        "3",
        "Five short questions for the caregiver, with yes, no, or not sure, and a space for a comment. The questions ask about ease, language, and willingness to use the application again. They do not ask the caregiver to judge clinical improvement.",
    )
    add_body(
        doc,
        "The version of the application, the device, and the fact that the device was offline will "
        "be noted on the session cover. If the developer cannot confirm the version, the sitting "
        "will not proceed.",
    )
    add_heading(doc, "5.7 Data analysis plan", 2)
    add_body(
        doc,
        "The analysis will be descriptive. For each item on the session record and the caregiver "
        "questions, the number of yes, no, and not-sure answers will be counted and presented with "
        "the number of sittings. Sittings that stop early will be counted separately and the reason "
        "will be listed. Comments will be read for repeated practical problems, such as a word that "
        "caregivers could not understand. No hypothesis test is planned. No test will be added "
        "after the data are seen in order to produce a significant result.",
    )
    add_body(
        doc,
        "Empty items will be reported as missing. Forms will be checked on the day they are "
        "completed so that gaps can be corrected while the caregiver is still present, if the "
        "caregiver is willing. There is no interim analysis and no stopping rule based on efficacy, "
        "because efficacy is not being estimated. The only stopping rule for an individual child is "
        "distress or refusal, which is an ethical rule rather than a statistical one.",
    )
    add_heading(doc, "5.8 Data collection procedure", 2)
    add_body(
        doc,
        "A clinician or therapist at the centre will tell the parent that a student study is being "
        "planned and that refusal will not change usual care. If the parent is willing to listen, "
        "a student researcher will go through the information sheet, invite questions, and leave "
        "time to decide. Consent will be written. The child will be told, in simple words and with "
        "the parent’s help, that looking at pictures is voluntary. If the child turns away or "
        "becomes upset before the sitting starts, the sitting will not start.",
    )
    add_numbered_item(
        doc,
        "1",
        "The observer notes age, home language and the application version. This takes a few minutes.",
    )
    add_numbered_item(
        doc,
        "2",
        "The caregiver and child are shown the application on a device that is not connected to the internet. The observer asks the caregiver to open the categories that are on that version, and invites the child to choose a picture if the child wishes. The proposed length is about twenty minutes, including time to stop. The supervisor may shorten this before submission.",
    )
    add_numbered_item(
        doc,
        "3",
        "If the child is distressed, tired, or clearly unwilling, the observer stops at once. The parent may stop the sitting at any moment. Stopping is recorded. It is not a failure of the parent or the child.",
    )
    add_numbered_item(
        doc,
        "4",
        "If the sitting continues, the caregiver is asked the five questions. The observer does not argue with the answers.",
    )
    add_numbered_item(
        doc,
        "5",
        "The parent is thanked and reminded that usual care is unchanged. No promise is made that the application will be installed on a family telephone.",
    )
    add_body(
        doc,
        "The observer will be one of the medical student researchers, after the supervisor has "
        "shown that person how to stop a sitting and how to avoid prompting the child towards a "
        "particular picture. The technical collaborator may be present to deal with a fault in the "
        "application. He will not take consent and will not decide whether a child is eligible.",
    )
    add_heading(doc, "5.9 Administrative requirements", 2)
    add_body(
        doc,
        "The following are required before any invitation is made. None of them is in hand.",
    )
    add_bullet(doc, "Approval from the Ethics Review Committee, Faculty of Medicine, University of Ruhuna.")
    add_bullet(doc, "A signed reply to the permission letter from the person in charge of PRAGATHI Child Intervention Centre.")
    add_bullet(doc, "Confirmation from the supervisor of the applicant, the sample-size justification, and whether this project is a requirement of the undergraduate curriculum.")
    add_bullet(doc, "Sinhala and Tamil versions of the information sheet and consent form, checked by competent speakers, or a written justification for using English only with a stated group of caregivers.")
    add_bullet(doc, "Student registration numbers, entered by the students themselves on the application form.")
    if anonymous:
        add_body(
            doc,
            "The committee’s processing fee depends on who the principal investigator is and on "
            "whether the project is required by the undergraduate curriculum. Neither point has "
            "been confirmed, so no fee category is stated.",
        )
    else:
        add_body(
            doc,
            "The committee’s processing fee depends on who the principal investigator is and on "
            "whether the project is required by the undergraduate curriculum. Dr Gayani Punchihewa "
            "is a member of the University staff, but she has not been named as the principal "
            "investigator. The students have not confirmed that the project is a curriculum "
            "requirement. No fee category is selected in this draft, and no receipt is attached.",
        )
    add_heading(doc, "5.10 Ethical consideration", 2)
    add_body(
        doc,
        "Participation is voluntary. Refusal or withdrawal will not change the child’s place at "
        "the centre or the care already offered. A parent may withdraw by saying so. Data already "
        "written down will be removed from the analysis if the parent asks. The child may refuse "
        "by words, by turning away, or by distress. That refusal is respected even if the parent "
        "has signed.",
    )
    add_body(
        doc,
        "The main discomfort is that a child may become frustrated or tired. The sitting is short, "
        "the parent stays, and the observer stops at the first sign of distress. There is no "
        "blood sample, medicine, or physical test. There is a privacy risk if a form names the "
        "child. The session record will carry a code, not a name. A separate list linking the code "
        "to the name will be kept only if the centre requires it for safety, and that list will be "
        "stored apart from the session records. Where the list will be locked, and who will hold "
        "the key, has not been agreed. Recruitment will not start until the supervisor has named "
        "the place.",
    )
    add_body(
        doc,
        "How long the forms will be kept has not been agreed. They will be kept for the period the "
        "Faculty requires and then destroyed. They will not be placed on a public repository, and "
        "they will not be sent out of Sri Lanka. The application does not need an account for the "
        "sitting described here. The device used for the sitting will not be backed up to a cloud "
        "service during the sitting. If a later version of the software uploads data, that version "
        "will not be used unless the proposal is amended.",
    )
    add_body(
        doc,
        "The people who may see named contact details are the student researchers and the "
        "supervisor. The technical collaborator may see a fault report that has no name on it. "
        "He does not need the linking list. Results, if any are eventually reported, will be "
        "counts for the group. No child will be described in a way that identifies a family.",
    )
    add_body(
        doc,
        "One interest has to be declared. The technical collaborator developed the application, so "
        "he will not be the only person who records or interprets the sitting. The students will "
        "complete the forms, and the supervisor will review them. No payment, sale or advertisement "
        "has been identified. The investigators must still sign the conflict declaration on the "
        "application form.",
    )
    add_body(
        doc,
        "Parents will be given the information in Annex A and will sign Annex B if they agree. A "
        "child who can read the short form in Annex C will be invited to sign it as well. Younger "
        "children will not be asked to sign a form they cannot read. Their unwillingness to take "
        "part is enough. Complaints about the conduct of the study may be sent to the Ethics "
        "Review Committee, Faculty of Medicine, University of Ruhuna (ethics@med.ruh.ac.lk).",
    )
    if not anonymous:
        add_body(doc, corresponding_contact_text(doc_path_holder(doc)))


def doc_path_holder(doc):
    """Replaced per document; placeholder so the ethical section can call the contact helper."""
    return getattr(doc, "_output_path", "")


def add_references(doc):
    add_heading(doc, "6. References")
    refs = [
        "Light J, McNaughton D. Communicative competence for individuals who require augmentative and alternative communication: a new definition for a new era of communication? Augment Altern Commun. 2014;30(1):1–18.",
        "Light J. Toward a definition of communicative competence for individuals using augmentative and alternative communication systems. Augment Altern Commun. 1989;5(2):137–144.",
        "Romski M, Sevcik RA. Augmentative communication and early intervention: myths and realities. Infants Young Child. 2005;18(3):174–185.",
        "Beukelman DR, Light JC. Augmentative and alternative communication: supporting children and adults with complex communication needs. 5th ed. Baltimore: Paul H. Brookes Publishing; 2020.",
        "World Health Organization. Autism [Internet]. Geneva: World Health Organization; [cited 2026 Nov 6]. Available from: https://www.who.int/news-room/fact-sheets/detail/autism-spectrum-disorders",
    ]
    for index, ref in enumerate(refs, start=1):
        add_numbered_item(doc, str(index), ref, justify=False)


def add_management(doc):
    add_heading(doc, "7. Management matter")
    add_body(
        doc,
        "The timetable below is counted from ethics approval, not from a calendar date. It is a "
        "working sketch for the supervisor to correct. It is not evidence that the work has been scheduled.",
    )
    add_plain_table(
        doc,
        ["Activity", "Before approval", "Month 1 after approval", "Month 2", "Month 3"],
        [
            ["Agree sample size, languages and applicant", "To be done", "", "", ""],
            ["Ethics review and site permission", "Submitted only when signed", "May continue", "", ""],
            ["Prepare checked Sinhala and Tamil forms", "To be done", "", "", ""],
            ["Invite families and hold sittings", "Will not occur", "Only if approved", "Only if approved", ""],
            ["Describe the counts and comments", "", "", "", "After sittings"],
            ["Report to the committee as required", "", "", "", "After analysis"],
        ],
    )
    add_body(
        doc,
        "No research grant has been identified. No sponsor is named. Amounts have not been costed, "
        "so the budget does not invent figures. The software already exists. Printing, local travel "
        "and the use of a device still need to be priced by the team if the Faculty asks for a "
        "rupee budget.",
    )
    add_plain_table(
        doc,
        ["Item", "Amount", "Source"],
        [
            ["Printing of forms", "Not yet costed", "No grant identified"],
            ["Travel within Galle", "Not yet costed", "No grant identified"],
            ["Device for the sitting", "Not yet costed", "No grant identified"],
            ["Payment to participants", "None planned", "Not applicable"],
            ["Translation checking", "Not yet costed", "No grant identified"],
        ],
    )


def add_annex_info(doc, anonymous):
    add_heading(doc, "Annex A. Information for parents and guardians", 2)
    add_body(
        doc,
        "Please read this before you decide. You may take it home. You do not have to decide today.",
        italic=True,
    )
    add_body(doc, "What is this about?", bold=True, space_after=4)
    add_body(
        doc,
        "We want to see whether a picture application on a mobile device can be used in one short "
        "sitting by your child and by you. The application has already been made. We are not testing "
        "a medicine. We are not claiming that the application will teach your child to speak.",
    )
    add_body(doc, "Why are we asking you?", bold=True, space_after=4)
    add_body(
        doc,
        "Your child attends this centre and a clinician or therapist here thinks that pictures may "
        "be a useful way for your child to express everyday needs. You are being asked because you "
        "are the parent or guardian who is here today.",
    )
    add_body(doc, "Do we have to take part?", bold=True, space_after=4)
    add_body(
        doc,
        "No. If you say no, your child’s usual care at the centre will not change. If you say yes "
        "and later change your mind, you may stop. Your child may also refuse, and we will stop.",
    )
    add_body(doc, "What will happen?", bold=True, space_after=4)
    add_body(
        doc,
        "If you agree, we will sit with you and your child for about twenty minutes. The device will "
        "not be connected to the internet. We will ask you to open the picture categories, and we "
        "will invite your child to choose a picture. We will then ask you five short questions. We "
        "will write a code on the form, not your child’s name.",
    )
    add_body(doc, "What are the risks and the benefits?", bold=True, space_after=4)
    add_body(
        doc,
        "Your child may become tired or frustrated. We will stop if that happens. There is no blood "
        "test and no new medicine. There may be no direct benefit. You will see the application "
        "during the sitting. We are not promising to install it on your telephone, and we are not "
        "paying you.",
    )
    add_body(doc, "Who can you speak to?", bold=True, space_after=4)
    if anonymous:
        add_body(
            doc,
            "The name and telephone number of the applicant will be printed on the copy given to "
            "families. They are left off this anonymous review copy. You may also write to the "
            "Ethics Review Committee, Faculty of Medicine, University of Ruhuna, at ethics@med.ruh.ac.lk.",
        )
    else:
        add_body(
            doc,
            "The applicant’s name will be written here once the research team and the supervisor "
            "have confirmed who that person is. "
            + corresponding_contact_text(getattr(doc, "_output_path", "")),
        )
        add_body(
            doc,
            "You may also write to the Ethics Review Committee, Faculty of Medicine, University of "
            "Ruhuna, at ethics@med.ruh.ac.lk.",
        )


def add_annex_consent(doc, anonymous):
    add_heading(doc, "Annex B. Consent of a parent or guardian", 2)
    add_body(
        doc,
        "I have read the information, or it has been read to me. I have been able to ask questions. "
        "I know that I can refuse or withdraw, and that my child’s usual care will not change if I do. "
        "I agree to one supervised sitting with the picture application, and to answering the short questions.",
    )
    add_body(doc, "Name of parent or guardian: ________________________________", justify=False)
    add_body(doc, "Signature: ________________________________    Date: ______________", justify=False)
    add_body(doc, "Name of child (for the centre’s copy only): ________________________________", justify=False)
    add_body(
        doc,
        "I confirm that I explained the study and that I did not pressure this person to agree.",
    )
    if anonymous:
        add_body(doc, "Name of the person who explained the study: ________________________________", justify=False)
    else:
        add_body(
            doc,
            "Name of the person who explained the study (student researcher): ________________________________",
            justify=False,
        )
    add_body(doc, "Signature: ________________________________    Date: ______________", justify=False)
    add_body(
        doc,
        "A witness is needed if the parent asks for one, or if the explanation was given orally "
        "because the parent does not read English.",
    )
    add_body(doc, "Witness name and signature: ________________________________", justify=False)


def add_annex_assent(doc):
    add_heading(doc, "Annex C. Assent of a child who can read this form", 2)
    add_body(
        doc,
        "This page is only for a child who can read it. Younger children will not be asked to sign. "
        "If a younger child does not want to look at the pictures, the sitting will not happen.",
    )
    add_body(
        doc,
        "We will show you some pictures on a screen. You can point to a picture if you want. You can "
        "say no. You can stop. Nothing bad will happen if you stop.",
    )
    add_body(doc, "I am willing to look at the pictures today.")
    add_body(doc, "Child’s name: ________________________________", justify=False)
    add_body(doc, "Child’s mark or signature: ________________________________    Date: ______________", justify=False)
    add_body(doc, "Parent present (name): ________________________________", justify=False)


def add_annex_tools(doc):
    add_heading(doc, "Annex D. Session record and caregiver questions", 2)
    add_body(
        doc,
        "These forms are drafts for this study. They are not a published questionnaire. The observer "
        "completes the record. The caregiver may answer the questions orally if writing is difficult.",
        italic=True,
    )
    add_body(doc, "Session cover", bold=True, space_after=4)
    add_plain_table(
        doc,
        ["Item", "Entry"],
        [
            ["Code (no name)", ""],
            ["Age in completed years", ""],
            ["Language used at home", ""],
            ["Person with the child", "Parent / guardian / other"],
            ["Application version and device", ""],
            ["Device offline at the start", "Yes / No"],
            ["Date of sitting", ""],
        ],
    )
    add_body(doc, "Observer’s record", bold=True, space_after=4)
    add_plain_table(
        doc,
        ["Item", "Entry"],
        [
            ["Child selected at least one picture", "Yes / No / Sitting stopped"],
            ["Caregiver opened the categories present that day", "Yes / No / Not all of them"],
            ["Sitting stopped early", "Yes / No"],
            ["If stopped, reason", "Distress / tired / refused / parent stopped / other"],
            ["Anything that failed in the application", "No name of the child in this note"],
        ],
    )
    add_body(doc, "Questions for the caregiver", bold=True, space_after=4)
    add_plain_table(
        doc,
        ["Question", "Yes", "No", "Not sure"],
        [
            ["Was the screen easy for you to use?", "", "", ""],
            ["Were the words in your language acceptable?", "", "", ""],
            ["Could you find a picture you might need at home?", "", "", ""],
            ["Would you consider using this application again?", "", "", ""],
            ["Did your child seem upset by the sitting?", "", "", ""],
        ],
    )
    add_body(doc, "Comment, if the caregiver wishes to add one:", justify=False)
    add_body(doc, "________________________________________________________________", justify=False)


def add_annex_letters(doc, anonymous):
    add_heading(doc, "Annex E. Draft letters asking for permission", 2)
    add_body(
        doc,
        "These letters have not been sent and have not been signed. They are drafts so that the "
        "committee can see what permission will be requested.",
        italic=True,
    )
    add_body(doc, "Draft letter to the centre", bold=True, space_after=4)
    add_body(
        doc,
        "The person in charge, PRAGATHI Child Intervention Centre, Galle.",
    )
    add_body(
        doc,
        "We ask permission to invite parents of children who already attend the centre to one "
        "supervised sitting with an existing picture-based communication application. The sitting "
        "would take place only after the Ethics Review Committee of the Faculty of Medicine, "
        "University of Ruhuna, has approved the study. Usual care would not be changed. No child "
        "would be included without the written consent of a parent or guardian. We have not yet "
        "fixed the number of children. We would agree that number with our supervisor and with "
        "the centre before invitations begin. Please reply in writing if the centre is willing to "
        "consider this request. A refusal will be respected.",
    )
    if anonymous:
        add_body(doc, "From the research team. Names are omitted in this copy.")
    else:
        add_body(
            doc,
            "From J.G.D. Thamalka and D.V.W. Gunawardana, medical student researchers, with "
            "Yasas Pasindu Fernando as technical research collaborator, under the proposed "
            "supervision of Dr Gayani Punchihewa.",
        )
        add_body(doc, "Signature: ____________________    Date: ____________", justify=False)
    add_body(doc, "Draft note to the Head, Department of Psychiatry", bold=True, space_after=4)
    if anonymous:
        add_body(
            doc,
            "The research team asks the Department of Psychiatry to note the proposal. The study "
            "site requested in this draft is the child intervention centre named above, not a ward "
            "of the Teaching Hospital. Departmental acknowledgement, if given, is not a substitute "
            "for ethics approval or for the centre’s permission. Investigator names are omitted from this copy.",
        )
    else:
        add_body(
            doc,
            "We ask the Department of Psychiatry to note that medical students of the Faculty propose "
            "to seek ethics review for the study described in this proposal, with Dr Gayani Punchihewa "
            "as the proposed supervisor. The study site requested in this draft is the child "
            "intervention centre named above, not a ward of the Teaching Hospital. Departmental "
            "acknowledgement, if given, is not a substitute for ethics approval or for the centre’s permission.",
        )
    if not anonymous:
        add_body(
            doc,
            "The Faculty staff page currently names Dr S.A.C. Senadheera as Head of the Department. "
            "An internal quality-assurance page has also listed Dr Punchihewa in that role. The "
            "letter must be addressed to the person who is Head on the day it is sent. This draft "
            "does not resolve that point.",
        )


def add_annex_languages(doc):
    add_heading(doc, "Annex F. Sinhala and Tamil versions", 2)
    add_body(
        doc,
        "Parents at the centre may be more comfortable in Sinhala or Tamil than in English. The "
        "information sheet, the consent form and the caregiver questions should be available in "
        "the languages the centre actually uses. Those translations are not in this draft.",
    )
    add_body(
        doc,
        "A machine translation would not be safe to hand to a parent. The translations need to be "
        "prepared and read by people who use the language in clinical or family settings, and the "
        "student researchers need to be able to explain them. Until that has been done, the study "
        "cannot recruit a caregiver who needs Sinhala or Tamil to give informed consent. The "
        "committee is asked to treat this annex as an outstanding requirement, not as a completed translation.",
    )


def build_research_protocol(output_path, anonymous=False, toc=None):
    doc = create_styled_document()
    doc._output_path = output_path
    setup_header_footer(doc)
    add_title_page(doc, anonymous)
    add_contents(doc, toc)
    add_introduction(doc)
    add_justification(doc)
    add_literature(doc)
    add_objectives(doc)
    add_methods(doc, anonymous)
    add_references(doc)
    add_management(doc)
    add_page_break(doc)
    add_heading(doc, "8. Annexures")
    add_body(
        doc,
        "The annexures are part of the proposal. They are drafts. They are not signed consent, "
        "and they are not evidence that anyone has taken part.",
        italic=True,
    )
    add_annex_info(doc, anonymous)
    add_annex_consent(doc, anonymous)
    add_annex_assent(doc)
    add_annex_tools(doc)
    add_annex_letters(doc, anonymous)
    add_annex_languages(doc)
    title = "Research proposal" if anonymous else "Research proposal, named draft"
    save_doc(doc, output_path, title)
    return output_path


def main():
    root = erc_root()
    named = os.path.join(root, "protocol", "04_AAC_ERC_Research_Protocol_DRAFT.docx")
    anon = os.path.join(root, "protocol", "04_AAC_ERC_Research_Protocol_ANONYMOUS_DRAFT.docx")
    build_research_protocol(named, anonymous=False)
    build_research_protocol(anon, anonymous=True)
    print(f"Wrote {named}")
    print(f"Wrote {anon}")


if __name__ == "__main__":
    main()
