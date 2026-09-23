import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_ext.dart';
import '../navigation/app_navigator.dart';

import '../../state/app_state.dart';
import '../components/empty_state.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../nowplaying/mini_player.dart';
import '../playlists/playlists_screen.dart';
import '../search/search_screen.dart';
import '../theme/timbre_theme.dart';

/// Root scaffold: permission gate, bottom navigation, mini player, routes.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _icons = [
    (icon: Icons.radio_outlined, selectedIcon: Icons.radio),
    (icon: Icons.tune, selectedIcon: Icons.tune),
    (
      icon: Icons.format_list_bulleted_outlined,
      selectedIcon: Icons.format_list_bulleted
    ),
    (icon: Icons.search_outlined, selectedIcon: Icons.search),
  ];

  void _onTabEvent() {
    final t = AppNavigator.tab.value;
    if (t != _tab && mounted) setState(() => _tab = t);
  }

  @override
  void dispose() {
    AppNavigator.tab.removeListener(_onTabEvent);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    AppNavigator.tab.addListener(_onTabEvent);
    // Bootstrap permission + first scan once.
    Future.microtask(() {
      if (!mounted) return;
      context.read<AppState>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = t(context);
    final labels = [
      strings.tabGuide,
      strings.tabArchive,
      strings.tabBank,
      strings.tabScan,
    ];
    return _PermissionGate(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Tab content.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_tab),
                child: switch (_tab) {
                  0 => const HomeScreen(),
                  1 => const LibraryScreen(),
                  2 => const PlaylistsScreen(),
                  _ => const SearchScreen(),
                },
              ),
            ),
            // Mini player sits above the navigation bar.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayer(),
                  NavigationBar(
                    height: 68,
                    selectedIndex: _tab,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    destinations: [
                      for (var i = 0; i < _icons.length; i++)
                        NavigationDestination(
                          icon: Icon(_icons[i].icon),
                          selectedIcon: Icon(_icons[i].selectedIcon),
                          label: labels[i],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Waits for permission before showing content; explains before requesting.
class _PermissionGate extends StatelessWidget {
  final Widget child;

  const _PermissionGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = t(context);

    switch (state.permissionPhase) {
      case PermissionPhase.unknown:
      case PermissionPhase.denied:
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TimbreSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TIMBRE FM', style: TimbreText.kicker(context)),
                  const SizedBox(height: TimbreSpacing.lg),
                  Text(strings.gateNoSignal,
                      style: TimbreText.dial(context, size: 30)),
                  const SizedBox(height: TimbreSpacing.md),
                  Text(
                    strings.gateBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.6),
                  ),
                  const SizedBox(height: TimbreSpacing.xl),
                  FilledButton(
                    onPressed: () async {
                      final granted = await state.requestPermission();
                      if (granted) await state.scanLibrary();
                    },
                    child: Text(strings.gateScanCta),
                  ),
                  if (state.permissionPhase == PermissionPhase.denied) ...[
                    const SizedBox(height: TimbreSpacing.sm),
                    Text(
                      strings.gateDeniedNote,
                      style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      case PermissionPhase.permanentlyDenied:
        return Scaffold(
          body: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: strings.gateAccessOff,
            body: strings.gateAccessBody,
            actionLabel: strings.gateOpenSettings,
            onAction: () => state.openAppSettings(),
          ),
        );
      case PermissionPhase.granted:
        return child;
    }
  }
}
