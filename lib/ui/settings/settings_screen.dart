import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_state.dart';
import '../theme/theme_controller.dart';

/// Settings: theme, history management, about. Deliberately short —
/// the MVP avoids a settings dashboard.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() => _themeMode = prefs.getString('settings.themeMode') ?? 'system');
      }
    });
  }

  Future<void> _setTheme(String mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings.themeMode', mode);
    if (mounted) {
      context.read<ThemeController>().update(mode);
    }
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
          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Your music stays on your device'),
            subtitle: Text(
                'Timbre reads audio files only to play them. No account, no tracking, no network access.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Timbre'),
            subtitle: Text('Version 1.0.0 · A calm offline music player'),
          ),
          const SizedBox(height: 24),
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
