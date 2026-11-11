import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_aac_app/utils/app_permissions_helper.dart';

void main() {
  tearDown(AppPermissionsHelper.resetTestHooks);

  testWidgets('Re-requests denied Camera permission on repeated attempts until allowed',
      (tester) async {
    var currentStatus = PermissionStatus.denied;
    var requestCount = 0;

    AppPermissionsHelper.statusReader = (_) async => currentStatus;
    AppPermissionsHelper.permissionRequester = (_) async {
      requestCount++;
      // Deny first prompt, allow on retry.
      currentStatus = requestCount == 1
          ? PermissionStatus.denied
          : PermissionStatus.granted;
      return currentStatus;
    };

    late BuildContext savedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              savedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final firstTry = await AppPermissionsHelper.ensureCameraPermission(savedContext);
    await tester.pump();
    expect(firstTry, isFalse);
    expect(requestCount, 1);

    final secondTry = await AppPermissionsHelper.ensureCameraPermission(savedContext);
    await tester.pump();
    expect(secondTry, isTrue);
    expect(requestCount, 2);
  });

  testWidgets('Offers Open Settings dialog when permission is permanently denied',
      (tester) async {
    var settingsOpened = false;
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.permanentlyDenied;
    AppPermissionsHelper.settingsOpener = () async {
      settingsOpened = true;
      return true;
    };

    late BuildContext savedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              savedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final future = AppPermissionsHelper.ensureCameraPermission(savedContext);
    await tester.pumpAndSettle();

    expect(find.text('Camera Permission Needed'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    expect(settingsOpened, isTrue);
  });

  testWidgets('requestAllAndShowStatus confirms immediately when all permissions are already granted',
      (tester) async {
    var requestsMade = 0;
    AppPermissionsHelper.sdkVersionReader = () async => 34;
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.granted;
    AppPermissionsHelper.permissionRequester = (_) async {
      requestsMade++;
      return PermissionStatus.granted;
    };

    late BuildContext savedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              savedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final future = AppPermissionsHelper.requestAllAndShowStatus(savedContext);
    await tester.pumpAndSettle();

    expect(requestsMade, 0);
    expect(find.text('All Permissions Granted'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await future;
  });

  testWidgets('requestAllAndShowStatus requests all missing permissions at once including legacy storage',
      (tester) async {
    final requested = <Permission>[];
    AppPermissionsHelper.sdkVersionReader = () async => 28;
    AppPermissionsHelper.statusReader = (_) async => PermissionStatus.denied;
    AppPermissionsHelper.permissionRequester = (p) async {
      requested.add(p);
      return PermissionStatus.granted;
    };

    late BuildContext savedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              savedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final future = AppPermissionsHelper.requestAllAndShowStatus(savedContext);
    await tester.pumpAndSettle();

    expect(
      requested,
      containsAll([Permission.camera, Permission.microphone, Permission.storage]),
    );
    expect(find.text('All Permissions Granted'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await future;
  });
}
