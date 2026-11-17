# Testing Utility Hooks

> 12 nodes · cohesion 0.17

## Key Concepts

- **@visibleForTesting** (12 connections)
- **buildTheme** (2 connections) — `lib/main.dart`
- **enableHapticsForTesting** (2 connections) — `lib/pages/home_page.dart`
- **resetSettingsForTesting** (2 connections) — `lib/pages/home_page.dart`
- **useImageOverlayLabelForTesting** (2 connections) — `lib/pages/home_page.dart`
- **resetTestHooks** (2 connections) — `lib/services/card_storage_service.dart`
- **resetCooldown** (2 connections) — `lib/services/openverse_search_provider.dart`
- **resetTestHooks** (2 connections) — `lib/services/recycle_bin_service.dart`
- **clearCache** (2 connections) — `lib/services/starter_pack_service.dart`
- **resetTestHooks** (2 connections) — `lib/utils/animated_media_helper.dart`
- **resetTestHooks** (2 connections) — `lib/utils/app_permissions_helper.dart`
- **resetTestHooks** (2 connections) — `lib/utils/camera_object_helper.dart`

## Relationships

- [Home Screen Logic](Home_Screen_Logic.md) (3 shared connections)
- [Personalization Service](Personalization_Service.md) (1 shared connections)
- [App Entry Point](App_Entry_Point.md) (1 shared connections)
- [Card Storage Service](Card_Storage_Service.md) (1 shared connections)
- [Openverse Image Search](Openverse_Image_Search.md) (1 shared connections)
- [Recycle Bin Service](Recycle_Bin_Service.md) (1 shared connections)
- [Starter Pack Service](Starter_Pack_Service.md) (1 shared connections)
- [Video to GIF Conversion](Video_to_GIF_Conversion.md) (1 shared connections)
- [App Permissions Helper](App_Permissions_Helper.md) (1 shared connections)
- [Camera Analysis Helper](Camera_Analysis_Helper.md) (1 shared connections)

## Source Files

- `lib/main.dart`
- `lib/pages/home_page.dart`
- `lib/services/card_storage_service.dart`
- `lib/services/openverse_search_provider.dart`
- `lib/services/recycle_bin_service.dart`
- `lib/services/starter_pack_service.dart`
- `lib/utils/animated_media_helper.dart`
- `lib/utils/app_permissions_helper.dart`
- `lib/utils/camera_object_helper.dart`

## Audit Trail

- EXTRACTED: 23 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*