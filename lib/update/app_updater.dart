import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// In-app updates for the sideloaded Timbre APK (no Play Store).
///
/// Source of truth is GitHub Releases on `amworx/timbre`:
/// the "latest" release must carry one `.apk` asset (built with
/// `flutter build apk --release --target-platform android-arm64`).
/// [AppUpdater.checkForUpdate] compares the release tag against the
/// installed version; [AppUpdater.downloadAndInstall] fetches the APK
/// and fires the system installer, which takes over automatically once
/// the download finishes.

/// GitHub API endpoint for the latest (non-prerelease) Timbre release.
const updaterLatestReleaseUrl =
    'https://api.github.com/repos/amworx/timbre/releases/latest';

/// Info about an available update. Parsed from a GitHub release object.
class UpdateInfo {
  /// Release tag, e.g. `v1.0.1`.
  final String tag;

  /// Direct download URL of the APK asset.
  final String apkUrl;

  /// Sanitized file name used for the download.
  final String fileName;

  /// Release notes (may be empty).
  final String notes;

  /// Optional SHA-256 hex of the APK, extracted from the release notes
  /// when the publisher includes a `sha256: <hex>` line. Used by
  /// `ota_update` to verify the download before installing.
  final String? sha256;

  const UpdateInfo({
    required this.tag,
    required this.apkUrl,
    required this.fileName,
    this.notes = '',
    this.sha256,
  });

  /// Human version without a leading `v`, e.g. `1.0.1`.
  String get version => tag.startsWith('v') || tag.startsWith('V')
      ? tag.substring(1)
      : tag;
}

/// Result of [AppUpdater.checkForUpdate].
sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

/// No newer release than [currentVersion].
class UpdateNotAvailable extends UpdateCheckResult {
  final String currentVersion;
  const UpdateNotAvailable(this.currentVersion);
}

/// A newer release [info] is available; [currentVersion] is installed.
class UpdateAvailable extends UpdateCheckResult {
  final UpdateInfo info;
  final String currentVersion;
  const UpdateAvailable(this.info, this.currentVersion);
}

/// The check itself failed (offline, rate-limited, malformed release…).
/// [message] is safe to show in the UI.
class UpdateCheckFailed extends UpdateCheckResult {
  final String message;
  const UpdateCheckFailed(this.message);
}

/// Friendly error thrown by [AppUpdater.downloadAndInstall].
class UpdaterException implements Exception {
  final String message;
  const UpdaterException(this.message);

  @override
  String toString() => 'UpdaterException: $message';
}

/// Parses the leading numeric `1.2.3` core of a version string into parts.
/// Tolerates a leading `v`, surrounding whitespace, and `+build`/`-suffix`
/// tails. Returns `[0]` when nothing numeric is found.
List<int> parseVersionParts(String raw) {
  final cleaned = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final match = RegExp(r'^\d+(?:\.\d+)*').firstMatch(cleaned);
  if (match == null) return const [0];
  return match.group(0)!.split('.').map(int.parse).toList();
}

/// Compares two version strings by numeric core: `-1` if [a] < [b],
/// `0` if equal, `1` if [a] > [b]. Missing parts count as zero, so
/// `1.0 == 1.0.0` and build metadata (`+7`) is ignored.
int compareVersions(String a, String b) {
  final pa = parseVersionParts(a);
  final pb = parseVersionParts(b);
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va < vb ? -1 : 1;
  }
  return 0;
}

/// Picks the APK asset to install from a GitHub release `assets` list.
/// Each entry must have `name` and `browser_download_url`.
/// Prefers arm64 builds, then `app-release.apk`, then any `.apk`.
/// Returns `null` when no APK asset exists.
Map<String, dynamic>? selectApkAsset(List<dynamic> assets) {
  final apks = <Map<String, dynamic>>[];
  for (final entry in assets) {
    if (entry is! Map<String, dynamic>) continue;
    final name = (entry['name'] ?? '').toString();
    final url = (entry['browser_download_url'] ?? '').toString();
    if (url.isEmpty || !name.toLowerCase().endsWith('.apk')) continue;
    apks.add(entry);
  }
  if (apks.isEmpty) return null;

  Map<String, dynamic>? firstWhere(bool Function(String) test) {
    for (final apk in apks) {
      if (test((apk['name'] ?? '').toString().toLowerCase())) return apk;
    }
    return null;
  }

  return firstWhere((n) => n.contains('arm64')) ??
      firstWhere((n) => n.contains('app-release')) ??
      apks.first;
}

/// Extracts a `sha256: <64 hex>` checksum from release notes, if present.
String? extractSha256(String? body) {
  if (body == null || body.isEmpty) return null;
  final match = RegExp(r'sha256\s*[:=]\s*([0-9a-fA-F]{64})',
          caseSensitive: false)
      .firstMatch(body);
  return match?.group(1)?.toLowerCase();
}

/// Builds a safe download file name from an asset URL. Falls back to
/// `timbre-<tag>.apk` and always keeps the `.apk` extension.
String apkFileNameFor(String assetUrl, String tag) {
  var base = assetUrl.split('?').first.split('/').last.trim();
  base = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final safeTag = tag.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (base.isEmpty || !base.toLowerCase().endsWith('.apk')) {
    base = 'timbre-$safeTag.apk';
  }
  return base;
}

/// Parses a decoded GitHub release JSON object into [UpdateInfo].
/// Returns `null` when the release carries no installable APK asset.
UpdateInfo? updateInfoFromRelease(Map<String, dynamic> json) {
  final tag = (json['tag_name'] ?? '').toString().trim();
  if (tag.isEmpty) return null;
  final assets = json['assets'];
  if (assets is! List) return null;
  final apk = selectApkAsset(assets);
  if (apk == null) return null;
  final body = (json['body'] ?? '').toString();
  return UpdateInfo(
    tag: tag,
    apkUrl: (apk['browser_download_url'] ?? '').toString(),
    fileName: apkFileNameFor(
        (apk['browser_download_url'] ?? '').toString(), tag),
    notes: body,
    sha256: extractSha256(body),
  );
}

/// User-facing one-liner for an [OtaEvent] status, used by Settings.
String describeOtaEvent(OtaEvent event) {
  switch (event.status) {
    case OtaStatus.DOWNLOADING:
      final pct = event.value?.trim() ?? '';
      return pct.isEmpty ? 'Downloading update…' : 'Downloading update… $pct%';
    case OtaStatus.INSTALLING:
      return 'Download complete — opening installer…';
    case OtaStatus.ALREADY_RUNNING_ERROR:
      return 'An update is already running.';
    case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
      return 'Install permission was denied.';
    case OtaStatus.DOWNLOAD_ERROR:
      return 'Download failed. Check your connection and retry.';
    case OtaStatus.CHECKSUM_ERROR:
      return 'Downloaded file failed integrity check. Retry.';
    case OtaStatus.CANCELED:
      return 'Download canceled.';
    case OtaStatus.INSTALLATION_ERROR:
      return 'Installation reported an error.';
    case OtaStatus.INSTALLATION_DONE:
      return 'Installed.';
    case OtaStatus.INTERNAL_ERROR:
      final detail = event.value?.trim() ?? '';
      return detail.isEmpty
          ? 'Something went wrong. Please retry.'
          : 'Something went wrong: $detail';
  }
}

/// Checks GitHub Releases for a newer Timbre build and installs it.
class AppUpdater {
  final http.Client _http;
  final Future<String> Function() _currentVersion;

  AppUpdater({http.Client? httpClient, Future<String> Function()? currentVersion})
      : _http = httpClient ?? http.Client(),
        _currentVersion = currentVersion ??
            (() async => (await PackageInfo.fromPlatform()).version);

  /// Returns whether a newer release exists. Never throws: transport,
  /// protocol, and payload problems become [UpdateCheckFailed] with a
  /// message safe to display.
  Future<UpdateCheckResult> checkForUpdate() async {
    final current = await _currentVersion();
    late http.Response res;
    try {
      res = await _http.get(
        Uri.parse(updaterLatestReleaseUrl),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'timbre-app',
        },
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      return const UpdateCheckFailed(
          'Update check timed out. Check your connection and retry.');
    } on SocketException {
      return const UpdateCheckFailed(
          'No connection. Connect to the internet and retry.');
    } on HttpException {
      return const UpdateCheckFailed(
          'Network error. Check your connection and retry.');
    } catch (_) {
      return const UpdateCheckFailed(
          'Could not check for updates. Please retry.');
    }

    if (res.statusCode == 404) {
      return const UpdateCheckFailed('No releases published yet.');
    }
    if (res.statusCode == 403) {
      return const UpdateCheckFailed(
          'GitHub rate limit reached. Try again later.');
    }
    if (res.statusCode != 200) {
      return UpdateCheckFailed(
          'Update check failed (HTTP ${res.statusCode}). Please retry.');
    }

    late Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const UpdateCheckFailed(
            'Unexpected update response. Please retry.');
      }
      json = decoded;
    } catch (_) {
      return const UpdateCheckFailed(
          'Unexpected update response. Please retry.');
    }

    final info = updateInfoFromRelease(json);
    if (info == null) {
      return const UpdateCheckFailed(
          'Latest release has no installable APK.');
    }
    if (compareVersions(info.version, current) <= 0) {
      return UpdateNotAvailable(current);
    }
    return UpdateAvailable(info, current);
  }

  /// Downloads [info]'s APK and fires the Android system installer the
  /// moment the download finishes (legacy `ota_update` flow, which shows
  /// the familiar install UI). Throws [UpdaterException] with a
  /// display-safe message on any failure.
  Stream<OtaEvent> downloadAndInstall(UpdateInfo info) {
    if (!Platform.isAndroid) {
      throw const UpdaterException(
          'In-app updates are only available on Android.');
    }
    try {
      return OtaUpdate().execute(
        info.apkUrl,
        destinationFilename: info.fileName,
        sha256checksum: info.sha256,
      );
    } catch (e) {
      throw UpdaterException('Could not start download: $e');
    }
  }

  /// Cancels an in-flight download, if any. Never throws.
  Future<void> cancel() async {
    try {
      await OtaUpdate().cancel();
    } catch (_) {
      // No active download — nothing to cancel.
    }
  }
}
