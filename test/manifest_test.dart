import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the hard-won Android manifest rules (see handoff.md + AGENTS.md):
/// audio_service 0.18.x ships an empty manifest, so dropping any of these
/// lines reintroduces the launch-crash ANR or breaks updates/installs.
void main() {
  late String manifest;

  setUpAll(() {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(file.existsSync(), isTrue,
        reason: 'run from the package root (flutter test)');
    manifest = file.readAsStringSync();
  });

  group('foreground-service permissions (launch-crash ANR guard)', () {
    test('all four FGS permissions are declared', () {
      for (final perm in [
        'android.permission.WAKE_LOCK',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
        'android.permission.POST_NOTIFICATIONS',
      ]) {
        expect(manifest, contains(perm), reason: 'missing $perm');
      }
    });

    test('AudioService stays a mediaPlayback foreground service', () {
      expect(manifest, contains('com.ryanheise.audioservice.AudioService'));
      expect(manifest, contains('foregroundServiceType="mediaPlayback"'));
      expect(
          manifest, contains('com.ryanheise.audioservice.MediaButtonReceiver'));
    });
  });

  group('in-app updates plumbing', () {
    test('install + network permissions are declared', () {
      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('android.permission.REQUEST_INSTALL_PACKAGES'));
    });

    test('ota_update FileProvider is wired to filepaths.xml', () {
      expect(manifest, contains('sk.fourq.otaupdate.OtaUpdateFileProvider'));
      expect(manifest,
          contains(r'${applicationId}.ota_update_provider'));
      expect(manifest, contains('@xml/filepaths'));

      final paths =
          File('android/app/src/main/res/xml/filepaths.xml');
      expect(paths.existsSync(), isTrue);
      final xml = paths.readAsStringSync();
      expect(xml, contains('internal_apk_storage'));
      expect(xml, contains('ota_update/'));
    });
  });

  group('device-specific renderer rule', () {
    test('Impeller stays disabled (Mali red-screen guard)', () {
      expect(manifest,
          contains('io.flutter.embedding.android.EnableImpeller'));
      expect(manifest, contains('"false"'));
    });
  });
}
