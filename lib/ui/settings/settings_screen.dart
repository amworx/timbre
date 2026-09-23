import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';
import '../../state/notification_permission.dart';
import '../../update/app_updater.dart';
import '../theme/locale_controller.dart';
import '../theme/theme_controller.dart';

/// Settings: theme, history management, updates, notifications, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
  String _localeMode = LocaleController.keySystem;
  bool _busy = false;

  final AppUpdater _updater = AppUpdater();
  String _currentVersion = '…';
  bool _checking = false;
  UpdateCheckResult? _checkResult;
  bool _downloading = false;
  double? _downloadProgress;
  String _downloadStatus = '';
  bool _needsInstallPermission = false;
  StreamSubscription<OtaEvent>? _otaSub;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _themeMode = prefs.getString('settings.themeMode') ?? 'system';
          _localeMode = prefs.getString('settings.localeMode') ??
              LocaleController.keySystem;
        });
      }
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _currentVersion = '${info.version}+${info.buildNumber}');
      }
    }).catchError((_) {
      if (mounted) setState(() => _currentVersion = 'unknown');
    });
  }

  @override
  void dispose() {
    // Stop listening, but leave a running native download alone so
    // navigating away never kills (or crashes) an in-flight update.
    _otaSub?.cancel();
    super.dispose();
  }

  Future<void> _setTheme(String mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings.themeMode', mode);
    if (mounted) {
      context.read<ThemeController>().update(mode);
    }
  }

  Future<void> _setLocale(String mode) async {
    setState(() => _localeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings.localeMode', mode);
    if (mounted) {
      context.read<LocaleController>().update(mode);
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checking || _downloading) return;
    setState(() {
      _checking = true;
      _checkResult = null;
      _needsInstallPermission = false;
    });
    final result = await _updater.checkForUpdate(t(context));
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = result;
    });
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (_downloading) return;
    final strings = t(context);
    setState(() {
      _downloading = true;
      _downloadProgress = null;
      _downloadStatus = strings.startingDownload;
      _needsInstallPermission = false;
    });
    late Stream<OtaEvent> stream;
    try {
      stream = _updater.downloadAndInstall(info);
    } on UpdaterException catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloadStatus = e.message;
      });
      return;
    }
    await _otaSub?.cancel();
    _otaSub = stream.listen(
      (event) {
        if (!mounted) return;
        final strings = t(context);
        setState(() {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final pct = double.tryParse((event.value ?? '').trim());
              _downloadProgress = pct == null ? null : pct / 100;
              _downloadStatus = describeOtaEvent(event, strings);
            case OtaStatus.INSTALLING:
              // The system installer takes over from here; the user taps
              // "Install" there to finish. Keep the message, stop the bar.
              _downloadProgress = 1;
              _downloadStatus = strings.downloadDoneInstaller;
            case OtaStatus.INSTALLATION_DONE:
              _downloading = false;
              _downloadProgress = 1;
              _downloadStatus = strings.installedRestart;
            case OtaStatus.CANCELED:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus = describeOtaEvent(event, strings);
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus = strings.installBlocked;
              _needsInstallPermission = true;
            case OtaStatus.ALREADY_RUNNING_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            case OtaStatus.INSTALLATION_ERROR:
            case OtaStatus.INTERNAL_ERROR:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus = describeOtaEvent(event, strings);
          }
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _downloading = false;
          _downloadProgress = null;
          _downloadStatus = '${t(context).evtInternal} ($e)';
        });
      },
    );
  }

  Future<void> _cancelDownload() async {
    await _updater.cancel();
    // The native side reports CANCELED through the stream, which resets
    // the UI; this is only a fallback in case it never arrives.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || !_downloading) return;
    setState(() {
      _downloading = false;
      _downloadProgress = null;
      _downloadStatus = t(context).downloadCanceled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = t(context);

    String themeLabel(String mode) => switch (mode) {
          'light' => strings.light,
          'dark' => strings.dark,
          _ => strings.followSystem,
        };
    String localeLabel(String mode) => switch (mode) {
          LocaleController.keyEnglish => strings.langEnglish,
          LocaleController.keyArabic => strings.langArabic,
          _ => strings.langSystem,
        };

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        children: [
          _SectionLabel(strings.appearance),
          RadioGroup<String>(
            groupValue: _themeMode,
            onChanged: (v) => _setTheme(v!),
            child: Column(
              children: [
                for (final mode in const ['system', 'light', 'dark'])
                  RadioListTile<String>(
                    title: Text(themeLabel(mode)),
                    value: mode,
                  ),
              ],
            ),
          ),
          const Divider(),
          _SectionLabel(strings.languageSection),
          RadioGroup<String>(
            groupValue: _localeMode,
            onChanged: (v) => _setLocale(v!),
            child: Column(
              children: [
                for (final mode in const [
                  LocaleController.keySystem,
                  LocaleController.keyEnglish,
                  LocaleController.keyArabic,
                ])
                  RadioListTile<String>(
                    title: Text(localeLabel(mode)),
                    value: mode,
                  ),
              ],
            ),
          ),
          const Divider(),
          _SectionLabel(strings.listeningMemory),
          ListTile(
            enabled: !_busy,
            leading: const Icon(Icons.history_rounded),
            title: Text(strings.clearHistory),
            subtitle: Text(strings.clearHistoryBody),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  final strings = t(context);
                  return AlertDialog(
                    title: Text(strings.clearHistoryTitle),
                    content: Text(strings.clearHistoryContent),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(strings.cancel)),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(strings.clear)),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                setState(() => _busy = true);
                await state.library.clearHistory();
                await state.scanLibrary();
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
          const Divider(),
          _SectionLabel(strings.librarySection),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: Text(strings.rescanDevice),
            subtitle: Text(state.hasMusic
                ? strings.songsFound(state.songs.length)
                : strings.songsFound(0)),
            onTap: () => state.scanLibrary(),
          ),
          const Divider(),
          _SectionLabel(strings.updatesSection),
          ListTile(
            leading: const Icon(Icons.smartphone_rounded),
            title: Text(strings.timbreVersion),
            subtitle: Text(strings.installedVersion(_currentVersion)),
          ),
          ListTile(
            enabled: !_checking && !_downloading,
            leading: _checking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.system_update_rounded),
            title: Text(strings.checkUpdates),
            subtitle: Text(strings.checkUpdatesSub),
            onTap: _checkForUpdates,
          ),
          _UpdateResultView(
            result: _checkResult,
            checking: _checking,
            downloading: _downloading,
            downloadProgress: _downloadProgress,
            downloadStatus: _downloadStatus,
            needsInstallPermission: _needsInstallPermission,
            onDownload: _downloadAndInstall,
            onCancel: _cancelDownload,
          ),
          const Divider(),
          _SectionLabel(strings.notificationsSection),
          const _NotificationTile(),
          const Divider(),
          _SectionLabel(strings.aboutSection),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: Text(strings.musicStaysTitle),
            subtitle: Text(strings.musicStaysBody),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(strings.aboutTimbre),
            subtitle: Text(strings.versionLine(_currentVersion)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Shows the notification permission state and lets the user fix it.
/// Playback works regardless — this only gates background/lock-screen
/// controls, which is exactly what the copy says.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = t(context);
    final (icon, title, subtitle) = switch (state.notificationPhase) {
      NotificationPhase.granted => (
          Icons.notifications_active_outlined,
          strings.notifOnTitle,
          strings.notifOnBody,
        ),
      NotificationPhase.permanentlyDenied => (
          Icons.notifications_off_outlined,
          strings.notifOffTitle,
          strings.notifOffBodyDenied,
        ),
      _ => (
          Icons.notifications_outlined,
          strings.notifOffTitle,
          strings.notifOffBody,
        ),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: state.notificationPhase == NotificationPhase.granted
          ? const Icon(Icons.check_circle_outline_rounded)
          : const Icon(Icons.chevron_right_rounded),
      onTap: () async {
        if (state.notificationPhase ==
            NotificationPhase.permanentlyDenied) {
          await state.openAppSettings();
          await state.refreshNotificationState();
        } else {
          await state.requestNotifications();
        }
      },
    );
  }
}

/// Renders the outcome of the last update check plus download progress.
class _UpdateResultView extends StatelessWidget {
  final UpdateCheckResult? result;
  final bool checking;
  final bool downloading;
  final double? downloadProgress;
  final String downloadStatus;
  final bool needsInstallPermission;
  final Future<void> Function(UpdateInfo) onDownload;
  final Future<void> Function() onCancel;

  const _UpdateResultView({
    required this.result,
    required this.checking,
    required this.downloading,
    required this.downloadProgress,
    required this.downloadStatus,
    required this.needsInstallPermission,
    required this.onDownload,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final res = result;
    final strings = t(context);
    if (checking) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(72, 0, 24, 8),
        child: Text(strings.checking),
      );
    }
    if (res == null) {
      if (downloadStatus.isEmpty) return const SizedBox.shrink();
      return _StatusLine(text: downloadStatus);
    }
    switch (res) {
      case UpdateNotAvailable():
        return _StatusLine(
          icon: Icons.check_circle_outline_rounded,
          text: strings.upToDate,
        );
      case UpdateCheckFailed(:final message):
        return _StatusLine(text: message);
      case UpdateAvailable(:final info, :final currentVersion):
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.new_releases_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.updateAvailable(info.version),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.installedTo(currentVersion, info.version),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (info.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      info.notes.trim(),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (downloading) ...[
                    if (downloadProgress != null)
                      LinearProgressIndicator(value: downloadProgress),
                    if (downloadProgress == null)
                      const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(downloadStatus),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(strings.cancel),
                    ),
                  ] else ...[
                    if (downloadStatus.isNotEmpty) ...[
                      Text(downloadStatus),
                      const SizedBox(height: 8),
                    ],
                    if (needsInstallPermission) ...[
                      FilledButton.tonalIcon(
                        onPressed: openAppSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(strings.allowInstalls),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () => onDownload(info),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(strings.downloadInstall),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _StatusLine extends StatelessWidget {
  final IconData? icon;
  final String text;

  const _StatusLine({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 24, 8),
      child: Row(
        children: [
          const SizedBox(width: 56),
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
