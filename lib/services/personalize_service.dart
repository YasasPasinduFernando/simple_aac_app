import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tutorial_service.dart';

/// Service managing the First Launch Personalization (Language & Theme) lifecycle.
///
/// Ensures:
/// 1. Appears before Quick Tour on genuine first launches.
/// 2. Does NOT disturb existing users during app upgrades.
/// 3. Does NOT repeat once completed or dismissed.
class PersonalizeService {
  static const String prefPersonalizeCompleted =
      'pref_personalize_setup_completed_v1';

  /// Determines if the First Launch Personalization dialog should be shown.
  ///
  /// Returns `true` ONLY on a genuine first install.
  /// If an existing user is upgrading (detected via existing cards or settings),
  /// silently marks the setup completed and returns `false`.
  static bool shouldShowFirstLaunchSetup(SharedPreferences prefs) {
    if (prefs.getBool(prefPersonalizeCompleted) == true) {
      return false;
    }

    // Safeguard: Check if this installation already has user data or prior settings
    final bool isExistingUser =
        prefs.containsKey('seededDefaultCardsVersion') ||
        prefs.containsKey(TutorialService.prefCompleted) ||
        prefs.containsKey(TutorialService.prefSkipped) ||
        prefs.containsKey('themePrimaryColor') ||
        prefs.containsKey('gridColumns') ||
        prefs.containsKey('grid_columns') ||
        prefs.containsKey('language');

    if (isExistingUser) {
      // Existing user upgrading — silently mark completed to prevent disruption
      prefs.setBool(prefPersonalizeCompleted, true);
      return false;
    }

    return true;
  }

  /// Marks first launch personalization as completed in persistent storage.
  static Future<void> markCompleted(SharedPreferences prefs) async {
    await prefs.setBool(prefPersonalizeCompleted, true);
  }

  /// Reset hook strictly for automated testing.
  @visibleForTesting
  static Future<void> resetForTesting(SharedPreferences prefs) async {
    await prefs.remove(prefPersonalizeCompleted);
  }
}
