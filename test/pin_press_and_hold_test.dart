import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/pages/home_page.dart';
import 'package:simple_aac_app/widgets/home_app_bar.dart';
import 'package:simple_aac_app/widgets/landscape_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pin and Unpin Press-and-Hold Widget Tests', () {
    testWidgets('HomeAppBar: Single tap pins when unpinned', (tester) async {
      bool pinToggled = false;
      bool unpinLongPressed = false;
      bool pinTapWhenPinned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Simple AAC',
              showBack: false,
              onBack: () {},
              showPin: true,
              isPinned: false,
              onTogglePin: () => pinToggled = true,
              onUnpinLongPress: () => unpinLongPressed = true,
              onPinTapWhenPinned: () => pinTapWhenPinned = true,
              isEditMode: false,
              showMenu: true,
              onOpenMenu: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      final pinButton = find.byIcon(Icons.push_pin_outlined);
      expect(pinButton, findsOneWidget);

      await tester.tap(pinButton);
      await tester.pump();

      expect(pinToggled, isTrue);
      expect(unpinLongPressed, isFalse);
      expect(pinTapWhenPinned, isFalse);
    });

    testWidgets('HomeAppBar: Single tap does not unpin; long press unpins', (tester) async {
      bool pinToggled = false;
      bool unpinLongPressed = false;
      bool pinTapWhenPinned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              title: 'Simple AAC',
              showBack: false,
              onBack: () {},
              showPin: true,
              isPinned: true,
              onTogglePin: () => pinToggled = true,
              onUnpinLongPress: () => unpinLongPressed = true,
              onPinTapWhenPinned: () => pinTapWhenPinned = true,
              isEditMode: false,
              showMenu: false,
              onOpenMenu: () {},
              backgroundColor: const Color(0xFF0277BD),
            ),
          ),
        ),
      );

      final pinButton = find.byIcon(Icons.push_pin);
      expect(pinButton, findsOneWidget);

      // Single tap should NOT unpin
      await tester.tap(pinButton);
      await tester.pump();

      expect(pinToggled, isFalse);
      expect(unpinLongPressed, isFalse);
      expect(pinTapWhenPinned, isTrue);

      // Press and hold (long press) SHOULD unpin
      await tester.longPress(pinButton);
      await tester.pump();

      expect(unpinLongPressed, isTrue);
    });

    testWidgets('LandscapeMenu: Single tap does not unpin; long press unpins', (tester) async {
      bool pinToggled = false;
      bool unpinLongPressed = false;
      bool pinTapWhenPinned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LandscapeMenu(
              isPinned: true,
              canGoBack: false,
              baseColor: const Color(0xFF0277BD),
              textColor: Colors.white,
              onTogglePin: () => pinToggled = true,
              onUnpinLongPress: () => unpinLongPressed = true,
              onPinTapWhenPinned: () => pinTapWhenPinned = true,
              onOpenMenu: () {},
              onGoBack: () {},
              onHome: () {},
              onUp: () {},
              onDown: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      final pinButton = find.byIcon(Icons.push_pin);
      expect(pinButton, findsOneWidget);

      // Single tap
      await tester.tap(pinButton);
      await tester.pump();
      expect(pinTapWhenPinned, isTrue);
      expect(pinToggled, isFalse);
      expect(unpinLongPressed, isFalse);

      // Long press
      await tester.longPress(pinButton);
      await tester.pump();
      expect(unpinLongPressed, isTrue);
    });

    testWidgets('HomePage: Tap pins board, tap while pinned shows notice, long press triggers haptic & unpins', (tester) async {
      int hapticCallCount = 0;
      HomePage.hapticPerformer = () async {
        hapticCallCount++;
      };

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pinFinder = find.byIcon(Icons.push_pin_outlined);
      expect(pinFinder, findsOneWidget);

      // 1. Single tap to pin
      await tester.tap(pinFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now it must be pinned!
      final pinnedFinder = find.byIcon(Icons.push_pin);
      expect(pinnedFinder, findsOneWidget);

      // 2. Single tap while pinned: must NOT unpin, must show SnackBar
      await tester.tap(pinnedFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Still pinned!
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.text('Press and hold to unpin'), findsOneWidget);

      // 3. Long press while pinned: must trigger haptic and unpin!
      await tester.longPress(pinnedFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Haptic feedback was triggered!
      expect(hapticCallCount, greaterThanOrEqualTo(1));
      // Board is unpinned back to push_pin_outlined!
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    });
  });
}
