import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/services/card_storage_service.dart';
import 'package:simple_aac_app/services/backup_service.dart';
import 'package:simple_aac_app/widgets/home_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('settings_fs_test_');
    CardStorageService.docsDirectoryOverride = () async => tempDir;
    SharedPreferences.setMockInitialValues({});
    HomePage.initialCardsForTesting = const [];
    HomePage.enableTtsInit = false;
    HomePage.speakPerformer = (_) async {};
  });

  tearDown(() {
    CardStorageService.resetTestHooks();
    HomePage.initialCardsForTesting = null;
    HomePage.enableTtsInit = true;
    HomePage.speakPerformer = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createTestWidget() {
    return const MaterialApp(
      home: HomePage(),
    );
  }

  group('Open Settings Full Screen Preference Tests', () {
    testWidgets('1. Fresh installation defaults to OFF and opens Settings in partial width',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open drawer via AppBar menu button
      final menuButton = find.byTooltip('Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.byType(HomeDrawer), findsOneWidget);
      final drawerWidget = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawerWidget.openSettingsFullScreen, isFalse);
      expect(drawerWidget.isExpanded, isFalse);

      // Verify switch exists below Caregiver Lock
      final switchFinder =
          find.byKey(const ValueKey('open_settings_full_screen_switch'));
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.descendant(
        of: switchFinder,
        matching: find.byType(Switch),
      ));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('2. Toggling switch ON expands Settings immediately and saves preference',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      final switchFinder =
          find.byKey(const ValueKey('open_settings_full_screen_switch'));
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isTrue);
      expect(homeState.isDrawerExpandedForTesting, isTrue);

      final drawerWidget = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawerWidget.openSettingsFullScreen, isTrue);
      expect(drawerWidget.isExpanded, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('openSettingsFullScreen'), isTrue);
    });

    testWidgets('3. Close and reopen with ON automatically opens fully expanded',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      final drawerWidget = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawerWidget.openSettingsFullScreen, isTrue);
      expect(drawerWidget.isExpanded, isTrue);

      // Close via X button
      final closeButton = find.byTooltip('Close Settings');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(find.byType(HomeDrawer), findsNothing);

      // Reopen
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      final reopenedDrawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(reopenedDrawer.openSettingsFullScreen, isTrue);
      expect(reopenedDrawer.isExpanded, isTrue);
    });

    testWidgets('4. Manually tapping chevron while ON shrinks panel without turning OFF preference',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      var drawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawer.isExpanded, isTrue);

      // Tap header resize button ('Shrink Settings')
      final shrinkButton = find.byTooltip('Shrink Settings');
      expect(shrinkButton, findsOneWidget);
      await tester.tap(shrinkButton);
      await tester.pumpAndSettle();

      drawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawer.isExpanded, isFalse);

      // Preference remains ON
      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isTrue);
      expect(prefs.getBool('openSettingsFullScreen'), isTrue);

      // Close Settings
      final closeButton = find.byTooltip('Close Settings');
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Reopen -> Opens FULL SCREEN again
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      final reopenedDrawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(reopenedDrawer.openSettingsFullScreen, isTrue);
      expect(reopenedDrawer.isExpanded, isTrue);
    });

    testWidgets('5. Toggling switch OFF collapses panel and restores partial opening',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      final switchFinder =
          find.byKey(const ValueKey('open_settings_full_screen_switch'));
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      var drawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawer.openSettingsFullScreen, isFalse);
      expect(drawer.isExpanded, isFalse);
      expect(prefs.getBool('openSettingsFullScreen'), isFalse);

      // Close and reopen
      await tester.tap(find.byTooltip('Close Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      drawer = tester.widget<HomeDrawer>(find.byType(HomeDrawer));
      expect(drawer.openSettingsFullScreen, isFalse);
      expect(drawer.isExpanded, isFalse);
    });

    testWidgets('6. Preference persists across app restart / cold launch',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isTrue);
      expect(homeState.isDrawerExpandedForTesting, isTrue);
    });

    testWidgets('7. Resetting settings restores default OFF', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isTrue);

      homeState.resetSettingsForTesting();
      await tester.pumpAndSettle();

      expect(homeState.openSettingsFullScreenForTesting, isFalse);
      expect(homeState.isDrawerExpandedForTesting, isFalse);
      expect(prefs.getBool('openSettingsFullScreen'), isFalse);
    });

    testWidgets('8. Caregiver Lock and Disable Back Card switches remain unaffected',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      // Scroll ListView slightly up to bring switch comfortably into view
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      // Disable Back Card switch
      final backCardSwitch =
          find.byKey(const ValueKey('disable_back_card_in_pin_mode_switch'));
      expect(backCardSwitch, findsOneWidget);
      await tester.tap(backCardSwitch);
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.disableBackCardInPinModeForTesting, isTrue);

      // Open Settings Full Screen switch is independent
      expect(homeState.openSettingsFullScreenForTesting, isFalse);
    });

    testWidgets('9. Backup and restore: legacy backup restores default false without corrupting data',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('openSettingsFullScreen', true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isTrue);

      // Simulate legacy backup without openSettingsFullScreen
      final legacySettings = <String, dynamic>{
        'ttsBarSize': 1.2,
        'cardTextScale': 1.1,
        'drawerFullScreen': false,
      };

      // Call restore handler
      homeState.applyRestoredBackupForTesting(
          BackupPayload(cards: const [], settings: legacySettings));
      await tester.pumpAndSettle();

      // Defaults to false
      expect(homeState.openSettingsFullScreenForTesting, isFalse);
    });

    testWidgets('10. Backup and restore: new backup restores openSettingsFullScreen true successfully',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final homeState = tester.state(find.byType(HomePage)) as dynamic;
      expect(homeState.openSettingsFullScreenForTesting, isFalse);

      final newSettings = <String, dynamic>{
        'openSettingsFullScreen': true,
        'drawerFullScreen': true,
      };

      homeState.applyRestoredBackupForTesting(
          BackupPayload(cards: const [], settings: newSettings));
      await tester.pumpAndSettle();

      expect(homeState.openSettingsFullScreenForTesting, isTrue);
      expect(homeState.isDrawerExpandedForTesting, isTrue);
    });
  });
}
