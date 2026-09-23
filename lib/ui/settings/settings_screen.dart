import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';
import '../../update/app_updater.dart';
import '../theme/theme_controller.dart';

/// Settings: theme, history management, updates, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
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
        setState(() => _themeMode = prefs.getString('settings.themeMode') ?? 'system');
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

  Future<void> _checkForUpdates() async {
    if (_checking || _downloading) return;
    setState(() {
      _checking = true;
      _checkResult = null;
      _needsInstallPermission = false;
    });
    final result = await _updater.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = result;
    });
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _downloadProgress = null;
      _downloadStatus = 'Starting download…';
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
        setState(() {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final pct = double.tryParse((event.value ?? '').trim());
              _downloadProgress = pct == null ? null : pct / 100;
              _downloadStatus = describeOtaEvent(event);
            case OtaStatus.INSTALLING:
              // The system installer takes over from here; the user taps
              // "Install" there to finish. Keep the message, stop the bar.
              _downloadProgress = 1;
              _downloadStatus =
                  'Download complete — opening installer… Tap Install to finish.';
            case OtaStatus.INSTALLATION_DONE:
              _downloading = false;
              _downloadProgress = 1;
              _downloadStatus = 'Installed. Restart the app if it is still open.';
            case OtaStatus.CANCELED:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus = describeOtaEvent(event);
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus =
                  'Android blocked the install. Allow “Install unknown apps” for Timbre, then retry.';
              _needsInstallPermission = true;
            case OtaStatus.ALREADY_RUNNING_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            case OtaStatus.INSTALLATION_ERROR:
            case OtaStatus.INTERNAL_ERROR:
              _downloading = false;
              _downloadProgress = null;
              _downloadStatus = describeOtaEvent(event);
          }
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _downloading = false;
          _downloadProgress = null;
          _downloadStatus = 'Update failed: $e';
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
      _downloadStatus = 'Download canceled.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionLabel('Appearance'),
          RadioGroup<String>(
            groupValue: _themeMode,
            onChanged: (v) => _setTheme(v!),
            child: const Column(
              children: [
                RadioListTile<String>(
                  title: Text('Follow system'),
                  value: 'system',
                ),
                RadioListTile<String>(
                  title: Text('Light'),
                  value: 'light',
                ),
                RadioListTile<String>(
                  title: Text('Dark'),
                  value: 'dark',
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionLabel('Listening memory'),
          ListTile(
            enabled: !_busy,
            leading: const Icon(Icons.history_rounded),
            title: const Text('Clear listening history'),
            subtitle: const Text(
                'Removes play counts, resume positions and Continue Listening.'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear listening history?'),
                  content: const Text(
                      'This cannot be undone. Favorites and playlists are kept.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear')),
                  ],
                ),
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
          const _SectionLabel('Library'),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: const Text('Rescan device music'),
            subtitle: Text(state.hasMusic
                ? '${state.songs.length} songs found on this device'
                : 'No music found yet'),
            onTap: () => state.scanLibrary(),
          ),
          const Divider(),
          const _SectionLabel('Updates'),
          ListTile(
            leading: const Icon(Icons.smartphone_rounded),
            title: const Text('Timbre version'),
            subtitle: Text('Installed: $_currentVersion'),
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
            title: const Text('Check for updates'),
            subtitle: const Text('Compares with the latest GitHub release.'),
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
          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Your music stays on your device'),
            subtitle: Text(
                'Timbre reads audio files only to play them. No account, no tracking. Updates check GitHub only when you ask.'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Timbre'),
            subtitle: Text('Version $_currentVersion · A calm offline music player'),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
    if (checking) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(72, 0, 24, 8),
        child: Text('Checking…'),
      );
    }
    if (res == null) {
      if (downloadStatus.isEmpty) return const SizedBox.shrink();
      return _StatusLine(text: downloadStatus);
    }
    switch (res) {
      case UpdateNotAvailable():
        return const _StatusLine(
          icon: Icons.check_circle_outline_rounded,
          text: 'You’re up to date.',
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
                          'Update ${info.version} available',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Installed $currentVersion → ${info.version}.',
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
                      label: const Text('Cancel'),
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
                        label: const Text('Allow installs'),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () => onDownload(info),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download & Install'),
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
