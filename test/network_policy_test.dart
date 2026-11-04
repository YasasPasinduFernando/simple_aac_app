import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_aac_app/services/network_policy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'online_features_enabled': false});
  });

  test('Default policy state is strictly offline (false)', () async {
    final policy = NetworkPolicyService.instance;
    await policy.init();
    expect(policy.isOnlineEnabled, isFalse);
    expect(policy.isOnlineEnabledNotifier.value, isFalse);
  });

  test('OfflineGatedHttpClient blocks requests when offline without touching network', () async {
    final policy = NetworkPolicyService.instance;
    await policy.setOnlineEnabled(false);

    bool innerWasCalled = false;
    final mockInner = MockClient((request) async {
      innerWasCalled = true;
      return http.Response('{"ok": true}', 200);
    });

    final gatedClient = policy.createGatedClient(mockInner);

    expect(
      () => gatedClient.get(Uri.parse('https://api.openverse.org/v1/images/?q=cat')),
      throwsA(isA<OfflineModeException>()),
    );
    expect(innerWasCalled, isFalse, reason: 'Outbound HTTP call must never reach the transport layer when offline');
  });

  test('OfflineGatedHttpClient allows requests when online features enabled', () async {
    final policy = NetworkPolicyService.instance;
    await policy.setOnlineEnabled(true);

    bool innerWasCalled = false;
    final mockInner = MockClient((request) async {
      innerWasCalled = true;
      expect(request.headers['User-Agent'], contains('SimpleAAC'));
      return http.Response('{"ok": true}', 200);
    });

    final gatedClient = policy.createGatedClient(mockInner);
    final response = await gatedClient.get(Uri.parse('https://api.openverse.org/v1/images/?q=cat'));

    expect(innerWasCalled, isTrue);
    expect(response.statusCode, 200);
  });
}
