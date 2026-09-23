import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ota_update/ota_update.dart';
import 'package:timbre/update/app_updater.dart';

Map<String, dynamic> release({
  String tag = 'v1.0.1',
  String body = '',
  List<Map<String, dynamic>> assets = const [
    {'name': 'app-release.apk', 'browser_download_url': 'https://example.com/app-release.apk'},
  ],
}) =>
    {'tag_name': tag, 'body': body, 'assets': assets};

MockClient clientFor(Object Function(http.Request) handler) =>
    MockClient((req) async => handler(req) as http.Response);

void main() {
  group('parseVersionParts', () {
    test('parses plain versions', () {
      expect(parseVersionParts('1.0.0'), [1, 0, 0]);
      expect(parseVersionParts('2.10.3'), [2, 10, 3]);
    });

    test('tolerates v prefix, whitespace, and build tails', () {
      expect(parseVersionParts('v1.2.3'), [1, 2, 3]);
      expect(parseVersionParts('  V2.0 '), [2, 0]);
      expect(parseVersionParts('1.0.0+7'), [1, 0, 0]);
      expect(parseVersionParts('1.4.0-beta'), [1, 4, 0]);
    });

    test('returns [0] for garbage', () {
      expect(parseVersionParts(''), [0]);
      expect(parseVersionParts('abc'), [0]);
    });
  });

  group('compareVersions', () {
    test('orders versions numerically, not lexically', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.9', '1.0.10'), -1);
      expect(compareVersions('1.0.10', '1.0.9'), 1);
      expect(compareVersions('2.0', '1.9.9'), 1);
    });

    test('treats missing parts as zero and ignores v/build', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('v1.0.1', '1.0.1+9'), 0);
      expect(compareVersions('1.0', '1.0.1'), -1);
    });
  });

  group('selectApkAsset', () {
    test('returns null when no APK present', () {
      expect(selectApkAsset([]), isNull);
      expect(
        selectApkAsset([
          {'name': 'notes.txt', 'browser_download_url': 'https://x/notes.txt'},
        ]),
        isNull,
      );
    });

    test('prefers arm64, then app-release, then first apk', () {
      const apk = 'https://x/f.apk';
      final assets = [
        {'name': 'timbre.apk', 'browser_download_url': apk},
        {'name': 'app-release.apk', 'browser_download_url': '$apk-r'},
        {'name': 'timbre-arm64.apk', 'browser_download_url': '$apk-a'},
      ];
      expect(selectApkAsset(assets)!['name'], 'timbre-arm64.apk');
      expect(selectApkAsset(assets.sublist(0, 2))!['name'], 'app-release.apk');
      expect(selectApkAsset(assets.sublist(0, 1))!['name'], 'timbre.apk');
    });

    test('skips entries without a download url', () {
      expect(
        selectApkAsset([
          {'name': 'a.apk'},
        ]),
        isNull,
      );
    });
  });

  group('extractSha256', () {
    test('finds checksum lines case-insensitively', () {
      const hex = 'd6da28451a1e15cf7a75f2c3f151befad3b80ad0bb232ab15c20897e54f21478';
      expect(extractSha256('sha256: $hex'), hex);
      expect(extractSha256('SHA256=$hex'.toUpperCase()), hex);
    });

    test('returns null when absent', () {
      expect(extractSha256(null), isNull);
      expect(extractSha256(''), isNull);
      expect(extractSha256('no checksum here'), isNull);
    });
  });

  group('apkFileNameFor', () {
    test('keeps the asset name and strips query strings', () {
      expect(
        apkFileNameFor('https://x/timbre-v1.0.1.apk?x=1', 'v1.0.1'),
        'timbre-v1.0.1.apk',
      );
    });

    test('falls back when the url has no apk name', () {
      expect(apkFileNameFor('https://x/', 'v1.0.1'), 'timbre-v1.0.1.apk');
      expect(apkFileNameFor('', 'v1.0.1'), 'timbre-v1.0.1.apk');
    });
  });

  group('updateInfoFromRelease', () {
    test('parses tag, apk, notes, and checksum', () {
      const hex = '28cff8632531859634c4142ec704e86c5345244bddd6433b6160edaabc9b646a';
      final info = updateInfoFromRelease(
        release(body: 'Fixes.\nsha256: $hex'),
      )!;
      expect(info.tag, 'v1.0.1');
      expect(info.version, '1.0.1');
      expect(info.apkUrl, 'https://example.com/app-release.apk');
      expect(info.sha256, hex);
    });

    test('returns null without a tag or apk', () {
      expect(updateInfoFromRelease(release(tag: '')), isNull);
      expect(
        updateInfoFromRelease(release(assets: [
          {'name': 'x.zip', 'browser_download_url': 'https://x/x.zip'},
        ])),
        isNull,
      );
    });
  });

  group('checkForUpdate', () {
    AppUpdater updater(MockClient client, String current) => AppUpdater(
          httpClient: client,
          currentVersion: () async => current,
        );

    test('reports available when the tag is newer', () async {
      final u = updater(
        clientFor((_) => http.Response(jsonEncode(release()), 200)),
        '1.0.0',
      );
      final res = await u.checkForUpdate();
      expect(res, isA<UpdateAvailable>());
      expect((res as UpdateAvailable).info.version, '1.0.1');
    });

    test('reports up-to-date when installed is equal or newer', () async {
      for (final current in ['1.0.1', '1.0.2', '1.0.1+5', 'v1.0.1']) {
        final u = updater(
          clientFor((_) => http.Response(jsonEncode(release()), 200)),
          current,
        );
        expect(await u.checkForUpdate(), isA<UpdateNotAvailable>());
      }
    });

    test('maps HTTP failures to friendly messages', () async {
      final cases = {
        404: 'No releases published yet.',
        403: 'GitHub rate limit reached. Try again later.',
        500: 'Update check failed (HTTP 500). Please retry.',
      };
      for (final entry in cases.entries) {
        final u = updater(
          clientFor((_) => http.Response('x', entry.key)),
          '1.0.0',
        );
        final res = await u.checkForUpdate();
        expect(res, isA<UpdateCheckFailed>());
        expect((res as UpdateCheckFailed).message, entry.value);
      }
    });

    test('fails gracefully on bad payloads', () async {
      final bad = [
        clientFor((_) => http.Response('not json', 200)),
        clientFor((_) => http.Response(jsonEncode(['list']), 200)),
        clientFor((_) => http.Response(
            jsonEncode(release(assets: const [])),
            200)),
      ];
      for (final c in bad) {
        final res = await updater(c, '1.0.0').checkForUpdate();
        expect(res, isA<UpdateCheckFailed>());
      }
    });

    test('fails gracefully offline', () async {
      final u = updater(
        MockClient((_) => throw const SocketException('down')),
        '1.0.0',
      );
      final res = await u.checkForUpdate();
      expect(res, isA<UpdateCheckFailed>());
      expect((res as UpdateCheckFailed).message, contains('No connection'));
    });
  });

  group('describeOtaEvent', () {
    test('narrates download/install progress without crashing', () {
      expect(
        describeOtaEvent(OtaEvent(OtaStatus.DOWNLOADING, '42')),
        contains('42%'),
      );
      expect(
        describeOtaEvent(OtaEvent(OtaStatus.INSTALLING, null)),
        contains('installer'),
      );
      expect(
        describeOtaEvent(OtaEvent(OtaStatus.PERMISSION_NOT_GRANTED_ERROR, null)),
        isNotEmpty,
      );
      expect(
        describeOtaEvent(OtaEvent(OtaStatus.INTERNAL_ERROR, 'boom')),
        contains('boom'),
      );
    });
  });
}
