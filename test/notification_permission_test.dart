import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timbre/state/notification_permission.dart';

void main() {
  group('notificationPhaseOf', () {
    test('grants stay granted', () {
      expect(notificationPhaseOf(PermissionStatus.granted),
          NotificationPhase.granted);
      expect(notificationPhaseOf(PermissionStatus.limited),
          NotificationPhase.granted);
      expect(notificationPhaseOf(PermissionStatus.provisional),
          NotificationPhase.granted);
    });

    test('permanent denial is distinguished', () {
      expect(notificationPhaseOf(PermissionStatus.permanentlyDenied),
          NotificationPhase.permanentlyDenied);
    });

    test('everything else is a soft denial', () {
      for (final s in [
        PermissionStatus.denied,
        PermissionStatus.restricted,
      ]) {
        expect(notificationPhaseOf(s), NotificationPhase.denied);
      }
    });
  });
}
