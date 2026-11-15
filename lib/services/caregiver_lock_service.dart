import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service providing device-level caregiver authentication (Fingerprint, Face Unlock,
/// Pattern, or Device PIN), with an in-app 4-digit PIN fallback when device lock is not set.
class CaregiverLockService {
  static const String prefEnabled = 'pref_caregiver_lock_enabled';
  static const String prefFallbackPin = 'pref_caregiver_fallback_pin';
  static const String defaultFallbackPin = '1234';

  static const MethodChannel _channel = MethodChannel('aac_auth');

  static CaregiverLockService? _instance;
  static CaregiverLockService get instance => _instance ??= CaregiverLockService._();

  static void resetForTesting() {
    _instance = null;
  }

  CaregiverLockService._();

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(prefEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefEnabled, value);
  }

  Future<bool> isDeviceSecure() async {
    try {
      final secure = await _channel.invokeMethod<bool>('isDeviceSecure');
      return secure ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> getFallbackPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefFallbackPin) ?? defaultFallbackPin;
  }

  Future<void> setFallbackPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefFallbackPin, pin);
  }

  /// Authenticates the caregiver.
  /// If [isEnabled] is false, immediately returns true.
  /// First attempts the device's native screen lock (Fingerprint, Face, Pattern, PIN).
  /// If device screen lock is absent or cancelled, presents the in-app Caregiver PIN dialog.
  Future<bool> authenticate(
    BuildContext context, {
    String title = 'Caregiver Verification',
    String reason = 'Confirm phone lock to continue',
  }) async {
    if (!_isEnabled) return true;

    // 1. Try native device screen lock (Biometrics / Pattern / PIN)
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'authenticate',
        {'title': title, 'description': reason},
      );
      if (res != null) {
        if (res['success'] == true) {
          return true;
        }
        if (res['reason'] == 'canceled') {
          return false;
        }
      }
    } catch (_) {
      // Native auth unavailable (e.g. tests or unsupported platform)
    }

    // 2. Fallback to in-app 4-digit Caregiver PIN dialog
    if (!context.mounted) return false;
    return await _showFallbackPinDialog(context, title: title, reason: reason);
  }

  Future<bool> _showFallbackPinDialog(
    BuildContext context, {
    required String title,
    required String reason,
  }) async {
    final expectedPin = await getFallbackPin();
    if (!context.mounted) return false;

    final controller = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF0369A1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      letterSpacing: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      errorText: errorMessage,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (val) {
                      if (val == expectedPin) {
                        Navigator.of(dialogCtx).pop(true);
                      } else {
                        setDialogState(() {
                          errorMessage = 'Incorrect PIN. Try again.';
                          controller.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text == expectedPin) {
                      Navigator.of(dialogCtx).pop(true);
                    } else {
                      setDialogState(() {
                        errorMessage = 'Incorrect PIN. Try again.';
                        controller.clear();
                      });
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }
}
