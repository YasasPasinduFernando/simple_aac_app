import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/backup_service.dart';
import '../widgets/styled_dialog_header.dart';

/// Centralized runtime permission helper for Camera, Microphone, legacy Android <=9
/// storage, and the Settings Drawer "Request All Permissions" panel.
class AppPermissionsHelper {
  @visibleForTesting
  static Future<PermissionStatus> Function(Permission) statusReader =
      (p) => p.status;

  @visibleForTesting
  static Future<PermissionStatus> Function(Permission) permissionRequester =
      (p) => p.request();

  @visibleForTesting
  static Future<bool> Function() settingsOpener = openAppSettings;

  /// Public entry point to open app settings, respecting test overrides.
  static Future<bool> openSettings() => settingsOpener();

  @visibleForTesting
  static Future<int> Function() sdkVersionReader = BackupService.getSdkVersion;

  @visibleForTesting
  static void resetTestHooks() {
    statusReader = (p) => p.status;
    permissionRequester = (p) => p.request();
    settingsOpener = openAppSettings;
    sdkVersionReader = BackupService.getSdkVersion;
  }

  static bool _isAllowed(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  /// Requests Camera permission whenever it is not yet granted. Re-prompts cleanly
  /// after a single denial and guides to App Settings if Android blocks re-prompting.
  static Future<bool> ensureCameraPermission(BuildContext context) {
    return _ensurePermission(
      context,
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      title: 'Camera Permission Needed',
      blockedMessage:
          'Camera access is turned off in Android settings. Open App Settings to allow Camera so you can take card photos.',
      deniedSnackText: 'Camera permission needed to take photos. Tap Camera again to allow.',
    );
  }

  /// Requests Microphone permission whenever voice recording is started without access.
  static Future<bool> ensureMicrophonePermission(BuildContext context) {
    return _ensurePermission(
      context,
      permission: Permission.microphone,
      icon: Icons.mic_rounded,
      title: 'Microphone Permission Needed',
      blockedMessage:
          'Microphone access is turned off in Android settings. Open App Settings to allow Microphone for custom voice recording.',
      deniedSnackText: 'Microphone permission needed to record audio. Tap Record again to allow.',
    );
  }

  /// Ensures both Camera and Microphone permissions are granted before video recording.
  static Future<bool> ensureVideoRecordingPermissions(BuildContext context) async {
    final cameraAllowed = await ensureCameraPermission(context);
    if (!cameraAllowed || !context.mounted) return false;
    final micAllowed = await ensureMicrophonePermission(context);
    return micAllowed;
  }

  /// Gallery and backup picks use the Android System Photo Picker / SAF on Android 10+
  /// (API 29+) and require zero storage permissions. Only legacy Android 9 (<= 28) needs it.
  static Future<bool> ensureLegacyStorageIfNeeded(BuildContext context) async {
    final sdk = await sdkVersionReader();
    if (sdk <= 0 || sdk > 28) return true;
    if (!context.mounted) return false;
    return _ensurePermission(
      context,
      permission: Permission.storage,
      icon: Icons.folder_rounded,
      title: 'Storage Permission Needed',
      blockedMessage:
          'Storage access is required on Android 9 and older to pick photos or save backups. Open App Settings to allow Storage.',
      deniedSnackText: 'Storage permission needed on Android 9 and older. Try again to allow.',
    );
  }

  static Future<bool> _ensurePermission(
    BuildContext context, {
    required Permission permission,
    required IconData icon,
    required String title,
    required String blockedMessage,
    required String deniedSnackText,
  }) async {
    var status = await statusReader(permission);
    if (_isAllowed(status)) return true;

    if (!status.isPermanentlyDenied) {
      status = await permissionRequester(permission);
      if (_isAllowed(status)) return true;
    }

    if (!context.mounted) return false;

    final isInsideDialog = ModalRoute.of(context) is PopupRoute;
    if (status.isPermanentlyDenied || status.isRestricted || isInsideDialog) {
      await _showOpenSettingsDialog(
        context,
        icon: icon,
        title: title,
        message: blockedMessage,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deniedSnackText),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: settingsOpener,
          ),
        ),
      );
    }
    return false;
  }

  static Future<void> _showOpenSettingsDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: StyledDialogHeader(
          icon: icon,
          title: title,
          subtitle: 'Required to use this feature',
          accentColor: Theme.of(ctx).colorScheme.error,
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(ctx);
              settingsOpener();
            },
          ),
        ],
      ),
    );
  }

  /// Checks all required app permissions, requests any missing ones in one flow,
  /// or confirms clearly when all permissions are already granted.
  static Future<void> requestAllAndShowStatus(BuildContext context) async {
    final sdk = await sdkVersionReader();
    final needsLegacyStorage = sdk > 0 && sdk <= 28;
    final requiredPermissions = <Permission>[
      Permission.camera,
      Permission.microphone,
      if (needsLegacyStorage) Permission.storage,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final perm in requiredPermissions) {
      statuses[perm] = await statusReader(perm);
    }

    for (final perm in requiredPermissions) {
      final current = statuses[perm]!;
      if (!_isAllowed(current) && !current.isPermanentlyDenied) {
        statuses[perm] = await permissionRequester(perm);
      }
    }

    if (!context.mounted) return;

    final allGranted = statuses.values.every(_isAllowed);
    final anyBlocked = statuses.values.any(
      (s) => s.isPermanentlyDenied || s.isRestricted,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          title: StyledDialogHeader(
            icon: allGranted
                ? Icons.verified_user_rounded
                : Icons.admin_panel_settings_rounded,
            accentColor: allGranted ? Colors.green.shade600 : colorScheme.primary,
            title: allGranted ? 'All Permissions Granted' : 'App Permissions',
            subtitle: allGranted
                ? 'All required permissions are already active'
                : 'Allow missing permissions for full features',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PermissionStatusRow(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  subtitle: 'Take photos directly for cards',
                  status: statuses[Permission.camera]!,
                ),
                const SizedBox(height: 8),
                _PermissionStatusRow(
                  icon: Icons.mic_rounded,
                  label: 'Microphone',
                  subtitle: 'Record custom card voices',
                  status: statuses[Permission.microphone]!,
                ),
                const SizedBox(height: 8),
                if (needsLegacyStorage)
                  _PermissionStatusRow(
                    icon: Icons.folder_rounded,
                    label: 'Storage (Android 9)',
                    subtitle: 'Pick gallery photos & save backups',
                    status: statuses[Permission.storage]!,
                  )
                else
                  const _PermissionStatusRow(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery & Backups',
                    subtitle: 'Ready via Android System Photo Picker',
                    status: PermissionStatus.granted,
                    statusLabelOverride: 'Ready',
                  ),
              ],
            ),
          ),
          actions: allGranted
              ? [
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                  if (anyBlocked)
                    FilledButton.icon(
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Open Settings'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        settingsOpener();
                      },
                    )
                  else
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Request Again'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        requestAllAndShowStatus(context);
                      },
                    ),
                ],
        );
      },
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final PermissionStatus status;
  final String? statusLabelOverride;

  const _PermissionStatusRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.status,
    this.statusLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allowed = status.isGranted || status.isLimited;
    final blocked = status.isPermanentlyDenied || status.isRestricted;

    final badgeColor = allowed
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (blocked ? colorScheme.error : Colors.amber.shade700);
    final statusText = statusLabelOverride ??
        (allowed ? 'Granted' : (blocked ? 'Blocked' : 'Denied'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allowed
              ? badgeColor.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: badgeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allowed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: 13,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
