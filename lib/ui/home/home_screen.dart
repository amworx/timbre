import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../components/artwork.dart';
import '../icons/broadcast_icons.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

/// Home = the program guide of your listening day.
///
/// A tuner dial (Archive / Flow / Favorites), memory presets (playlists),
/// the guide list (on-air + recently played), and a tuner bar that opens
/// the receiver (Now Playing).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _recent = const [];

  static const _stations = [
    (freq: '89.1', label: 'ARCHIVE'),
    (freq: '98.4', label: 'FLOW'),
    (freq: '104.7', label: 'FAVORITES'),
  ];

  int get _stationForState {
    final state = context.read<AppState>();
    if (state.queueTitle != null && state.queueTitle!.startsWith('Flow')) return 1;
    if (state.queue.isNotEmpty &&
        state.favoriteIds.containsAll(state.queue.map((s) => s.id)) &&
        state.queue.length == state.favoriteSongs.length) {
      return 2;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await context.read<AppState>().recentlyPlayed(limit: 8);
    if (mounted) setState(() => _recent = recent);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.loadState == LoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadState == LoadState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SIGNAL LOST', style: TimbreText.kicker(context, color: cs.error)),
            const SizedBox(height: TimbreSpacing.sm),
            Text('Could not read your library.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: TimbreSpacing.md),
            OutlinedButton(
              onPressed: () => state.scanLibrary(),
              child: const Text('RETRY SCAN'),
            ),
          ],
        ),
      );
    }

    final station = _stationForState;

    return RefreshIndicator(
      onRefresh: () async {
        await state.scanLibrary();
        await _loadRecent();
      },
      // Keep the header row clear of the system status bar (clock, battery,
      // SIM icons) on edge-to-edge Android; bottom inset is handled by the
      // shell's navigation bar.
      child: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              TimbreSpacing.md, TimbreSpacing.sm, TimbreSpacing.md, 150),
        children: [
          // Status row — date, archive, scanner, service menu, clock.
          Row(
            children: [
              Text(_dateLabel(), style: TimbreText.kicker(context)),
              const Spacer(),
              IconButton(
                tooltip: 'Archive',
                onPressed: () => AppNavigator.openLibraryTab(context),
                icon: const BIcon(BIcons.libraryTune, size: 19),
              ),
              IconButton(
                tooltip: 'Scanner',
                onPressed: () => AppNavigator.openSearchTab(context),
                icon: const BIcon(BIcons.search, size: 19),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => AppNavigator.openSettings(context),
                icon: const Icon(Icons.settings_outlined, size: 22),
              ),
            ],
          ),

          // Wordmark.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(top: TimbreSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('TIMBRE',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(letterSpacing: 5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('FM',
                      style: TimbreText.kicker(context)
                          .copyWith(fontSize: 12, letterSpacing: 4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: TimbreSpacing.md),

          // Tuner dial.
          _TunerDial(
            stations: _stations,
            selected: station,
            onSelect: (i) => _tuneTo(state, i),
          ),
          const SizedBox(height: TimbreSpacing.sm),

          // Big frequency + tuned label.
          Center(
            child: Column(
              children: [
                Text(_stations[station].freq, style: TimbreText.dial(context, size: 34)),
                const SizedBox(height: 2),
                Text('${_stations[station].label} · TUNED',
                    style: TimbreText.kicker(context)),
              ],
            ),
          ),
          const SizedBox(height: TimbreSpacing.md),

          // Memory presets = playlists.
          if (state.playlists.isNotEmpty) ...[
            _PresetsRow(),
            const SizedBox(height: TimbreSpacing.xs),
            Text('MEMORY BANK · PLAYLISTS', style: TimbreText.section(context)),
            const SizedBox(height: TimbreSpacing.md),
          ],

          // Program guide.
          Text('PROGRAM GUIDE', style: TimbreText.section(context)),
          const SizedBox(height: TimbreSpacing.sm),

          if (state.hasMusic) _GuideOnAir(entry: state.continueEntry),

          _GuideFlowRow(),

          if (_recent.isNotEmpty) ...[
            const SizedBox(height: TimbreSpacing.sm),
            for (var i = 0; i < _recent.length; i++)
              _GuideHistoryRow(index: i, song: _recent[i], queue: _recent),
          ],

          if (!state.hasMusic) ...[
            const SizedBox(height: TimbreSpacing.xl),
            Text(
              'No transmissions found.\nAdd music to your device and pull to scan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.7),
            ),
          ],
        ],
        ),
      ),
    );
  }

  String _dateLabel() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    final day = days[now.weekday - 1];
    final dd = now.day.toString().padLeft(2, '0');
    return '$day $dd ${months[now.month - 1]}';
  }

  Future<void> _tuneTo(AppState state, int i) async {
    switch (i) {
      case 0:
        if (state.songs.isEmpty) return;
        await state.playQueue(QueueSpec(
          songs: state.songs,
          startIndex: 0,
          title: 'Archive',
          subtitle: '${state.songs.length} tracks',
        ));
        break;
      case 1:
        await _startFlow(state);
        break;
      case 2:
        final favs = state.favoriteSongs;
        if (favs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No favorites yet — tap the heart on any track')));
          return;
        }
        await state.playQueue(QueueSpec(
          songs: favs,
          startIndex: 0,
          title: 'Favorites',
          subtitle: '${favs.length} tracks',
        ));
        break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _startFlow(AppState state) async {
    final pool = state.favoriteSongs.isNotEmpty
        ? state.favoriteSongs
        : (state.songs.isEmpty ? null : state.songs);
    if (pool == null || pool.isEmpty) return;
    final seedSong = pool[Random().nextInt(pool.length)];
    await state.startFlow(seedSong);
  }
}

// ---------------------------------------------------------------- dial

class _TunerDial extends StatelessWidget {
  final List<({String freq, String label})> stations;
  final int selected;
  final ValueChanged<int> onSelect;

  const _TunerDial({required this.stations, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: [
            // Base line.
            PositionedDirectional(
              bottom: 16,
              start: 0,
              end: 0,
              child: Container(height: 1.5, color: cs.outline),
            ),
            for (var i = 0; i < stations.length; i++)
              PositionedDirectional(
                bottom: 0,
                start: (w - 64) * i / (stations.length - 1),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: SizedBox(
                    width: 64,
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          stations[i].freq,
                          style: TextStyle(
                            fontFamily: TimbreText.family,
                            fontSize: 9.5,
                            letterSpacing: 1,
                            color: i == selected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: i == selected ? 2.5 : 1.5,
                          height: i == selected ? 18 : 12,
                          color: i == selected ? cs.primary : cs.outline,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------- presets

class _PresetsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      children: [
        for (var i = 0; i < state.playlists.length && i < 3; i++)
          Expanded(child: _Preset(index: i, playlist: state.playlists[i])),
      ],
    );
  }
}

class _Preset extends StatelessWidget {
  final int index;
  final Playlist playlist;

  const _Preset({required this.index, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: TimbreSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(TimbreRadii.chip),
        onTap: () => AppNavigator.openPlaylist(context, playlist.id, playlist.name),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TimbreRadii.chip),
            border: Border.all(color: cs.primary, width: 1.2),
          ),
          child: Column(
            children: [
              Text('P${index + 1}', style: TimbreText.kicker(context)),
              const SizedBox(height: 2),
              Text(playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: TimbreText.family,
                      fontSize: 9.5,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- guide rows

class _GuideOnAir extends StatelessWidget {
  final ContinueEntry? entry;

  const _GuideOnAir({required this.entry});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final song = state.currentSong ?? entry?.song;
    if (song == null) return const SizedBox.shrink();

    return _GuideRow(
      leading: 'NOW',
      title: song.title,
      subtitle: '${song.artist} · on air',
      live: true,
      art: Artwork(albumId: song.albumId, title: song.album, size: 34, radius: 6),
      onTap: () => AppNavigator.openNowPlaying(context),
    );
  }
}

class _GuideFlowRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GuideRow(
      leading: 'FLOW',
      title: 'Flow Queue',
      subtitle: 'A fresh mix from your library',
      art: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.primary, width: 1.2),
        ),
        child: const BIcon(BIcons.wave, size: 18),
      ),
      onTap: () {},
    );
  }
}

class _GuideHistoryRow extends StatelessWidget {
  final int index;
  final Song song;
  final List<Song> queue;

  const _GuideHistoryRow({required this.index, required this.song, required this.queue});

  @override
  Widget build(BuildContext context) {
    return _GuideRow(
      leading: (index + 1).toString().padLeft(2, '0'),
      title: song.title,
      subtitle: song.artist,
      art: Artwork(albumId: song.albumId, title: song.album, size: 34, radius: 6),
      onTap: () => context.read<AppState>().playSong(song, context: queue),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final String leading;
  final String title;
  final String subtitle;
  final Widget art;
  final bool live;
  final VoidCallback onTap;

  const _GuideRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.onTap,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              child: live
                  ? Row(children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(leading,
                          style: TextStyle(
                              fontFamily: TimbreText.family,
                              fontSize: 10.5,
                              letterSpacing: 1,
                              color: cs.primary)),
                    ])
                  : Text(leading,
                      style: TextStyle(
                          fontFamily: TimbreText.family,
                          fontSize: 11,
                          letterSpacing: 1,
                          color: cs.onSurfaceVariant)),
            ),
            art,
            const SizedBox(width: TimbreSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              live ? FontWeight.w700 : FontWeight.w500,
                          color: live ? cs.primary : cs.onSurface)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
