# Technical note on the source inspected on 8 November 2026

This note records what was read in the application source. It is not a test of an installed handset, and it is not ethics approval. The pilot sitting will use one named build. That build has not yet been frozen on a device.

Repository version in `pubspec.yaml`: 1.0.2+3.

## Languages

- Each card can store an English label, a Sinhala label and a Tamil label (`lib/models/aac_card_model.dart`).
- The home screen can be set to English, Sinhala or Tamil. Empty Sinhala or Tamil labels fall back to the English label.
- The seed list in `lib/data/default_seed_cards.dart` contains Sinhala and Tamil for only a small set of words (hello, happy, sad, angry, more, good, play). The rest of the catalogue was not counted as translated.
- `lib/pages/home_page.dart` asks the device speech engine for `si-LK`, `ta-IN` or `en-US` when the language is changed. `lib/services/tts_service.dart` initially sets `en-US`. Speech in Sinhala and Tamil has not been heard on the pilot device. A competent speaker has not checked the wording.

## Permissions and network

- `android/app/src/main/AndroidManifest.xml` requests `INTERNET`, `RECORD_AUDIO` and `CAMERA`.
- The application can take a photograph for a card and can record a voice for a card. Those functions are present. Switching them off for a sitting does not remove them from the package.
- `NetworkPolicyService` starts with online features off. While they are off, the gated HTTP client used by the application throws and does not send that request. This was read in source. It was not demonstrated on the handset, and it does not prove that every library on the phone is unable to use the network.

## Storage and backup

- Cards are written under the application documents directory, with a local backup file beside them (`lib/services/card_storage_service.dart`).
- `lib/services/backup_service.dart` can write a local backup directory and speaks to a platform channel named `aac_backup`. That code was not run for this note. It is not evidence that cloud backup is impossible.
- No encryption of the card file was identified in the passages read.

## Rule for the sitting

Online features off. No new photograph. No new voice recording. Device cloud backup off for the sitting. One recorded build only. A later build needs an amendment of the proposal.
