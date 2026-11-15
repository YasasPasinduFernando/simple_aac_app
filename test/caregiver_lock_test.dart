import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/services/caregiver_lock_service.dart';
import 'package:simple_aac_app/utils/tutorial_strings.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';
import 'package:simple_aac_app/widgets/tutorial/mini_guides_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CaregiverLockService.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('aac_auth'), (MethodCall methodCall) async {
      if (methodCall.method == 'isDeviceSecure') {
        return false;
      }
      if (methodCall.method == 'authenticate') {
        return {'success': false, 'reason': 'fallback'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('aac_auth'), null);
  });

  group('CaregiverLockService Tests', () {
    test('Defaults to disabled and persists toggle state', () async {
      final service = CaregiverLockService.instance;
      await service.init();
      expect(service.isEnabled, isFalse);

      await service.setEnabled(true);
      expect(service.isEnabled, isTrue);

      CaregiverLockService.resetForTesting();
      final reloaded = CaregiverLockService.instance;
      await reloaded.init();
      expect(reloaded.isEnabled, isTrue);
    });

    testWidgets('authenticate returns true immediately when lock is disabled', (tester) async {
      final service = CaregiverLockService.instance;
      await service.init();
      await service.setEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () async {
                  final ok = await service.authenticate(ctx);
                  expect(ok, isTrue);
                },
                child: const Text('Auth'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Auth'));
      await tester.pumpAndSettle();
    });

    testWidgets('authenticate prompts for fallback PIN when enabled and validates input', (tester) async {
      final service = CaregiverLockService.instance;
      await service.init();
      await service.setEnabled(true);
      await service.setFallbackPin('4321');

      bool? authResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () async {
                    authResult = await service.authenticate(
                      ctx,
                      title: 'Caregiver Verification',
                      reason: 'Enter PIN to unlock',
                    );
                  },
                  child: const Text('Trigger Auth'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Auth'));
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Verification'), findsOneWidget);
      expect(find.text('Enter PIN to unlock'), findsOneWidget);

      // Enter wrong PIN
      await tester.enterText(find.byType(TextField), '9999');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(authResult, isNull);

      // Enter correct PIN
      await tester.enterText(find.byType(TextField), '4321');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(authResult, isTrue);
      expect(find.text('Caregiver Verification'), findsNothing);
    });
  });

  group('HomeDrawer Caregiver Lock Toggle', () {
    testWidgets('HomeDrawer displays Caregiver Lock switch and responds to user toggle', (tester) async {
      bool toggleValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDrawer(
              selectedCategory: 'All',
              currentLanguageLabel: 'English',
              gridColumns: 2,
              visibleCardsLabel: 'All cards',
              isEditMode: false,
              showTtsInput: true,
              orientationLabel: 'Portrait',
              fullScreen: false,
              headerColor: Colors.blue,
              headerTextColor: Colors.white,
              hideTtsText: false,
              useImageOverlayLabel: false,
              applyTextColorToCards: false,
              isDarkMode: false,
              isColorBlindMode: false,
              primaryColorSwatch: Colors.blue,
              textColorSwatch: Colors.white,
              backgroundColorSwatch: Colors.white,
              cardTextColorSwatch: Colors.black,
              isOnlineEnabled: false,
              onToggleOnline: (_) {},
              onToggleDarkMode: (_) {},
              onChangeColorBlindMode: (_) {},
              onSelectCategory: () {},
              onAddCategory: () {},
              onToggleEdit: () {},
              onToggleTtsInput: () {},
              onToggleTtsText: () {},
              onToggleCardImageLabel: () {},
              onToggleApplyTextColorToCards: () {},
              onChangeOrientation: () {},
              onPickPrimaryColor: () {},
              onPickTextColor: () {},
              onPickBackgroundColor: () {},
              onShowTtsBarSize: () {},
              onToggleFullScreen: () {},
              onShowLanguage: () {},
              onShowGrid: () {},
              onShowVisibleCount: () {},
              onBackup: () {},
              onRestore: () {},
              onResetSettings: () {},
              onShowAbout: () {},
              isCaregiverLockEnabled: false,
              onToggleCaregiverLock: (val) {
                toggleValue = val;
              },
            ),
          ),
        ),
      );

      expect(find.text('Caregiver Lock'), findsOneWidget);
      expect(find.text('Protect board & settings with phone fingerprint, face, pattern or PIN'), findsOneWidget);

      // Find switch
      expect(find.byType(Switch), findsWidgets);

      // Tap Caregiver Lock item
      await tester.tap(find.text('Caregiver Lock'));
      await tester.pumpAndSettle();

      expect(toggleValue, isTrue);
    });
  });

  group('MiniGuidesDialog & TutorialStrings', () {
    testWidgets('MiniGuidesDialog renders updated Caregiver Lock guide title and descriptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniGuidesDialog(language: 'en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver Lock & Biometrics'), findsOneWidget);
      expect(find.textContaining('fingerprint, face unlock, pattern'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    test('Trilingual Caregiver Lock guide strings are populated across En, Si, Ta', () {
      expect(TutorialStrings.getPinGuideTitle('en'), equals('Caregiver Lock & Biometrics'));
      expect(TutorialStrings.getPinGuideTitle('si'), contains('Caregiver Lock'));
      expect(TutorialStrings.getPinGuideTitle('ta'), contains('Caregiver Lock'));

      expect(TutorialStrings.getPinGuideDesc('en'), contains('fingerprint, face unlock, pattern'));
      expect(TutorialStrings.getPinGuideDesc('si'), contains('Fingerprint, Face unlock, Pattern'));
      expect(TutorialStrings.getPinGuideDesc('ta'), contains('கைரேகை'));
    });
  });
}
