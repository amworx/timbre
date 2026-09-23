import 'package:permission_handler/permission_handler.dart' as ph;

/// How the system notification permission (Android 13+) currently stands.
/// Media playback works in every state — without the permission there is
/// just no background notification / lock-screen controls, so the app
/// explains instead of breaking.
enum NotificationPhase { unknown, granted, denied, permanentlyDenied }

/// Maps a platform permission status onto a [NotificationPhase].
/// `limited`/`provisional` count as granted (the system shows notifications);
/// anything else restrictive counts as denied until proven otherwise.
NotificationPhase notificationPhaseOf(ph.PermissionStatus status) {
  if (status.isGranted ||
      status == ph.PermissionStatus.limited ||
      status == ph.PermissionStatus.provisional) {
    return NotificationPhase.granted;
  }
  if (status.isPermanentlyDenied) {
    return NotificationPhase.permanentlyDenied;
  }
  return NotificationPhase.denied;
}
