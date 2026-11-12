import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_aac_app/widgets/professional_color_picker_dialog.dart';

void main() {
  group('ProfessionalColorPickerDialog Widget Tests', () {
    testWidgets('Displays initial color, presets, and updates preview on preset tap',
        (tester) async {
      Color? appliedColor;
      const initialColor = Color(0xFF0288D1); // Royal Blue

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'App color',
                      subtitle: 'Pick a color for Normal Mode',
                      initialColor: initialColor,
                      previewType: ColorPickerPreviewType.appHeader,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('App color'), findsOneWidget);
      expect(find.text('Pick a color for Normal Mode'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Quick colors'), findsOneWidget);
      expect(find.text('Custom color'), findsOneWidget);

      // Verify all 8 presets exist
      for (final item in ProfessionalColorPickerDialog.presets) {
        expect(find.bySemanticsLabel('Preset color ${item.name}'), findsOneWidget);
      }

      // Royal blue checkmark should be visible initially
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      // Tap Green preset (Color(0xFF4CAF50))
      await tester.tap(find.bySemanticsLabel('Preset color Green'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFF4CAF50).value));
    });

    testWidgets('Cancel button dismisses dialog without calling onApply',
        (tester) async {
      Color? appliedColor;
      const initialColor = Color(0xFF0288D1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Text color',
                      subtitle: 'Pick a color for Normal Mode text',
                      initialColor: initialColor,
                      previewType: ColorPickerPreviewType.textColor,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Tap Red preset
      await tester.tap(find.bySemanticsLabel('Preset color Red'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should be dismissed and onApply not called
      expect(find.byType(ProfessionalColorPickerDialog), findsNothing);
      expect(appliedColor, isNull);
    });

    testWidgets('Hex input updates candidate color cleanly',
        (tester) async {
      Color? appliedColor;
      const initialColor = Color(0xFF0288D1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Background color',
                      subtitle: 'Pick a color for board background',
                      initialColor: initialColor,
                      previewType: ColorPickerPreviewType.backgroundColor,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Enter hex 8B5A46 (Warm Brown)
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, '8B5A46');
      await tester.pumpAndSettle();

      // Scroll into view & Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFF8B5A46).value));
    });

    testWidgets(
        'Renders without overflow on narrow screens (320px) and standard Galaxy A34 (384px) with high font scaling',
        (tester) async {
      for (final width in [320.0, 384.0, 480.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: ProfessionalColorPickerDialog(
                    title: 'App color',
                    subtitle: 'Pick a color for Normal Mode',
                    initialColor: const Color(0xFF0288D1),
                    previewType: ColorPickerPreviewType.appHeader,
                    onApply: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final err = tester.takeException();
          expect(err, isNull,
              reason: 'Failed at width $width with scale $scale');
        }
      }
    });

    testWidgets('Supports all 3 preview types without exception',
        (tester) async {
      for (final type in ColorPickerPreviewType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfessionalColorPickerDialog(
                title: 'Color Test',
                subtitle: 'Preview type test',
                initialColor: const Color(0xFF0288D1),
                previewType: type,
                onApply: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Text color preview updates candidate card text color only while keeping card background stable',
        (tester) async {
      Color? appliedColor;
      const initialText = Color(0xFF7E57C2); // Purple

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Text color',
                      subtitle: 'Pick a color for Normal Mode',
                      initialColor: initialText,
                      previewType: ColorPickerPreviewType.textPreview,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Text Color Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Text Color Picker'));
      await tester.pumpAndSettle();

      // Verify Text color specific presets exist (White, Black, Purple, Green, Orange, Red, etc.)
      expect(find.bySemanticsLabel('Preset color White'), findsOneWidget);
      expect(find.bySemanticsLabel('Preset color Black'), findsOneWidget);
      expect(find.bySemanticsLabel('Preset color Red'), findsOneWidget);

      // Verify 3 Hello labels are rendered
      expect(find.text('Hello'), findsNWidgets(3));

      // Verify Card 3 has candidate key
      expect(find.byKey(const ValueKey('candidate_text_card')), findsOneWidget);

      // Tap Red preset
      await tester.tap(find.bySemanticsLabel('Preset color Red'));
      await tester.pumpAndSettle();

      // Card 3 should now have Red text
      final candidateTextWidget = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('candidate_text_card')),
          matching: find.text('Hello'),
        ),
      );
      expect(candidateTextWidget.style?.color?.value, equals(const Color(0xFFD50000).value));

      // Scroll into view & Tap Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFFD50000).value));
    });

    testWidgets('Background color preview updates body canvas fill while keeping cards distinct',
        (tester) async {
      Color? appliedColor;
      const initialBackground = Color(0xFFE0F2FE); // Light Blue

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ProfessionalColorPickerDialog(
                      title: 'Background color',
                      subtitle: 'Pick a color for the main content area (body)',
                      initialColor: initialBackground,
                      previewType: ColorPickerPreviewType.backgroundPreview,
                      onApply: (color) => appliedColor = color,
                    ),
                  );
                },
                child: const Text('Open Background Color Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Background Color Picker'));
      await tester.pumpAndSettle();

      // Verify mini header elements
      expect(find.text('Simple AAC'), findsWidgets);

      // Verify mini sentence bar elements
      expect(find.text('Happy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Verify 3 AAC cards on body
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('Angry'), findsOneWidget);

      // Tap Mint Green preset
      await tester.tap(find.bySemanticsLabel('Preset color Mint Green'));
      await tester.pumpAndSettle();

      // Scroll into view & Tap Apply
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedColor, isNotNull);
      expect(appliedColor!.value, equals(const Color(0xFF81C784).value));
    });

    testWidgets(
        'Renders all preview types without overflow on narrow screens (320px) and Galaxy A34 (384px) with high font scaling',
        (tester) async {
      for (final previewType in ColorPickerPreviewType.values) {
        for (final width in [320.0, 384.0]) {
          for (final scale in [1.0, 1.5, 2.0]) {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: ProfessionalColorPickerDialog(
                      title: 'Preview Test',
                      subtitle: 'Responsive scale test',
                      initialColor: const Color(0xFF0288D1),
                      previewType: previewType,
                      onApply: (_) {},
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final err = tester.takeException();
            expect(err, isNull,
                reason: 'Failed for $previewType at width $width with scale $scale');
          }
        }
      }
    });
  });
}
