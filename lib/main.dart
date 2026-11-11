import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'pages/home_page.dart';
import 'services/network_policy_service.dart';
import 'utils/theme_accessibility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Strict offline requirement: Prevent GoogleFonts from ever making runtime network requests
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize application offline gate (default: false/offline) and theme state in parallel
  await Future.wait([
    NetworkPolicyService.instance.init(),
    ThemeAccessibility.initDarkMode(),
  ]);

  // Cap decoded image memory at 64 MiB for smooth scrolling without OOM on high-res photos.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024;

  // Android Photo Picker enablement
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  runApp(const AACApp());
}

class AACApp extends StatelessWidget {
  const AACApp({Key? key}) : super(key: key);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0288D1);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: isDark ? const Color(0xFF161A20) : null,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF111418) : colorScheme.surface,
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? const Color(0xFF161A20) : null,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 2,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 4,
        backgroundColor: isDark ? const Color(0xFF1C2128) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isDark ? Colors.grey.shade500 : Colors.grey.shade400;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeAccessibility.darkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Simple AAC Sri Lanka',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const HomePage(),
        );
      },
    );
  }
}
