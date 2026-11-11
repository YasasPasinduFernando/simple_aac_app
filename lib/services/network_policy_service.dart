import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OfflineModeException implements Exception {
  final String message;
  const OfflineModeException([this.message = 'Network requests are blocked because Online Features are disabled.']);

  @override
  String toString() => 'OfflineModeException: $message';
}

/// Centralized manager for application-level online/offline mode.
/// Strict requirement: When Online Features is OFF, no HTTP requests may leave the app.
class NetworkPolicyService {
  static const String _prefKey = 'online_features_enabled';
  static NetworkPolicyService? _instance;
  static NetworkPolicyService get instance => _instance ??= NetworkPolicyService._();

  NetworkPolicyService._();

  bool _isOnlineEnabled = false;
  final ValueNotifier<bool> isOnlineEnabledNotifier = ValueNotifier<bool>(false);

  bool get isOnlineEnabled => _isOnlineEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Strict default: FALSE (Offline by default)
    _isOnlineEnabled = prefs.getBool(_prefKey) ?? false;
    isOnlineEnabledNotifier.value = _isOnlineEnabled;
    debugPrint('[NetworkPolicyService] Initialized. Online features enabled: $_isOnlineEnabled');
  }

  Future<void> setOnlineEnabled(bool enabled) async {
    _isOnlineEnabled = enabled;
    isOnlineEnabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    debugPrint('[NetworkPolicyService] Online features switched to: $enabled');
  }

  /// Returns an HTTP client that is strictly guarded by the offline policy.
  http.Client createGatedClient([http.Client? innerClient]) {
    return OfflineGatedHttpClient(
      networkPolicy: this,
      inner: innerClient ?? http.Client(),
    );
  }
}

/// HTTP Client decorator that intercepts all outbound requests and enforces
/// the application offline gate at the network layer.
class OfflineGatedHttpClient extends http.BaseClient {
  final NetworkPolicyService networkPolicy;
  final http.Client inner;

  OfflineGatedHttpClient({
    required this.networkPolicy,
    required this.inner,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!networkPolicy.isOnlineEnabled) {
      debugPrint('[OfflineGatedHttpClient] BLOCKED outbound request to ${request.url} (Offline Mode Active)');
      throw const OfflineModeException();
    }

    // Set appropriate User-Agent for free Openverse API compliance
    if (!request.headers.containsKey('User-Agent')) {
      request.headers['User-Agent'] = 'SimpleAAC-SriLanka/1.1.0 (OpenAccess; Communication Support)';
    }

    return inner.send(request);
  }

  @override
  void close() {
    inner.close();
  }
}
