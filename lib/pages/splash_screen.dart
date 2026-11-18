import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/child_friendly_splash.dart';
import 'home_page.dart';

/// Standalone Child-Friendly Animated Splash Screen Page.
///
/// Runs card/settings initialization in the background while displaying the child-friendly
/// animation. As soon as initialization finishes, it navigates immediately to HomePage
/// without artificial delays.
class SplashScreen extends StatefulWidget {
  final Future<void>? initializationTask;
  final VoidCallback? onComplete;
  final String? initialLanguage;

  const SplashScreen({
    Key? key,
    this.initializationTask,
    this.onComplete,
    this.initialLanguage,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? 'en';
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // 1. Read saved language preference quickly
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      if (savedLang != null && savedLang.isNotEmpty && mounted) {
        setState(() {
          _language = savedLang;
        });
      }
    } catch (_) {}

    // 2. Wait for optional initialization task or navigate to Home
    if (widget.initializationTask != null) {
      await widget.initializationTask;
    }

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChildFriendlySplash(
      language: _language,
    );
  }
}
