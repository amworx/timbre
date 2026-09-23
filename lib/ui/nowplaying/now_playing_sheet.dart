import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../navigation/app_navigator.dart';
import '../../l10n/l10n_ext.dart';
import '../components/formatters.dart';
import '../components/song_selection.dart';
import '../theme/timbre_theme.dart';
import 'sleep_sheet.dart';
import 'speed_sheet.dart';

/// The emotional center. One strong visual idea: the album artwork anchors
/// the screen, with a very subtle artwork-derived wash behind it.
class NowPlayingSheet extends StatefulWidget {
  const NowPlayingSheet({super.key});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet> {
  File? _artFile;
  String? _loadedAlbumId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArt();
  }

  Future<void> _loadArt() async {
    final state = context.read<AppState>();
    final song = state.currentSong;
    final albumId = song?.albumId;
    if (albumId == null || albumId == _loadedAlbumId) return;
    final file = await state.artwork(albumId);
    if (mounted) {
      setState(() {
        _artFile = file;
        _loadedAlbumId = albumId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final song = state.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final strings = t(context);
    final duration = Duration(milliseconds: song.durationMs);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _CanvasBackground(
        artFile: _artFile,
        fallbackColor: cs.primary.withValues(alpha: 0.16),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar -----------------------------------------------------
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: TimbreSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: strings.tipMinimize,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 30, color: cs.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: strings.tipQueue,
                      icon: Icon(Icons.queue_music_outlined, color: cs.onSurface),
                      onPressed: () {
                        Navigator.pop(context);
                        AppNavigator.openQueue(context);
                      },
                    ),
                  ],
                ),
              ),

              // Artwork -----------------------------------------------------
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      if ((d.primaryVelocity ?? 0) < -200) state.next();
                      if ((d.primaryVelocity ?? 0) > 200) state.previous();
                    },
                    child: Hero(
                      tag: 'now-playing-art',
                      child: _ArtView(file: _artFile, title: song.album, size: 280),
                    ),
                  ),
                ),
              ),

              // Title / artist ----------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.lg),
                child: Column(
                  children: [
                    Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(displayArtist(song, strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
                    Text(displayAlbum(song, strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 13)),
                  ],
                ),
              ),

              // Seek bar ------------------------------------------------------
              _SeekBar(position: state.position, duration: duration),

              // Controls ------------------------------------------------------
              _Controls(),

              // Secondary row ---------------------------------------------------
              Padding(
                padding: const EdgeInsets.only(bottom: TimbreSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: state.favoriteIds.contains(song.id)
                          ? strings.tipRemoveFav
                          : strings.tipAddFav,
                      icon: Icon(
                        state.favoriteIds.contains(song.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: state.favoriteIds.contains(song.id)
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      onPressed: () => state.toggleFavorite(song),
                    ),
                    IconButton(
                      tooltip: strings.shareAudioFile,
                      icon: Icon(Icons.ios_share_rounded,
                          color: cs.onSurfaceVariant),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final outcome =
                            await state.shareSongs([song], strings);
                        if (outcome.attached == 0 && context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  outcome.message ?? strings.nothingToShare),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: strings.deleteFromDevice,
                      icon: Icon(Icons.delete_outline_rounded,
                          color: cs.error),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await confirmDeviceDelete(
                          context,
                          strings,
                          count: 1,
                          songTitle: song.title,
                        );
                        if (!confirmed || !context.mounted) return;
                        final summary =
                            await state.deleteSongs([song], strings);
                        if (!context.mounted) return;
                        if (summary.deleted == 1) {
                          // Playback moved on (or stopped): the sheet
                          // follows the new current song automatically.
                          // Only close when nothing is left to show.
                          if (state.currentSong == null) {
                            Navigator.pop(context);
                          }
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                summary.message ??
                                    strings.couldNotDeleteSong,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: strings.tipSleep,
                      icon: Icon(Icons.bedtime_outlined,
                          color: state.sleepActive ? cs.primary : cs.onSurfaceVariant),
                      onPressed: () => showSleepSheet(context),
                    ),
                    IconButton(
                      tooltip: strings.tipSpeed,
                      icon: Icon(Icons.speed_rounded,
                          color: state.speed != 1.0 ? cs.primary : cs.onSurfaceVariant),
                      onPressed: () => showSpeedSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Very subtle artwork-derived background: blurred artwork at low opacity
/// under the surface color. Never reduces text readability.
class _CanvasBackground extends StatelessWidget {
  final File? artFile;
  final Color fallbackColor;
  final Widget child;

  const _CanvasBackground({
    required this.artFile,
    required this.fallbackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (artFile != null)
            Opacity(
              opacity: 0.18,
              child: Image.file(
                artFile!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            )
          else
            ColoredBox(color: fallbackColor),
          // Readability scrim.
          ColoredBox(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.45),
          ),
          child,
        ],
      ),
    );
  }
}

/// (Artwork opacity handled with a plain Opacity wrapper — no animation.)

class _ArtView extends StatefulWidget {
  final File? file;
  final String title;
  final double size;

  const _ArtView({required this.file, required this.title, required this.size});

  @override
  State<_ArtView> createState() => _ArtViewState();
}

class _ArtViewState extends State<_ArtView> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.file == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(TimbreRadii.artwork + 6),
        ),
        child: Icon(Icons.music_note_rounded, size: 56, color: cs.onSurfaceVariant),
      );
    }
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TimbreRadii.artwork + 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TimbreRadii.artwork + 6),
        child: Image.file(
          widget.file!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(Icons.music_note_rounded, size: 56, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;

  const _SeekBar({required this.position, required this.duration});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final maxMs = widget.duration.inMilliseconds <= 0
        ? 1.0
        : widget.duration.inMilliseconds.toDouble();
    final value = (_dragValue ?? widget.position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Slider(
          value: value,
          max: maxMs.toDouble(),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            state.seekTo(Duration(milliseconds: v.round()));
            setState(() => _dragValue = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(Duration(milliseconds: value.round())),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text(
                  '-${formatDuration(Duration(milliseconds: (maxMs - value).round()))}',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final strings = t(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: TimbreSpacing.lg, vertical: TimbreSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: strings.tipShuffle,
            icon: Icon(Icons.shuffle_rounded,
                color: state.shuffleEnabled ? cs.primary : cs.onSurfaceVariant),
            onPressed: state.toggleShuffle,
          ),
          IconButton(
            tooltip: strings.tipPrevious,
            icon: Icon(Icons.skip_previous_rounded,
                size: 40, color: cs.onSurface),
            onPressed: state.hasPrevious ? state.previous : null,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
            ),
            child: IconButton(
              tooltip: state.isPlaying ? strings.tipPause : strings.tipPlay,
              iconSize: 34,
              color: cs.onPrimary,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey(state.isPlaying),
                ),
              ),
              onPressed: state.togglePlayPause,
            ),
          ),
          IconButton(
            tooltip: strings.tipNext,
            icon: Icon(Icons.skip_next_rounded, size: 40, color: cs.onSurface),
            onPressed: state.hasNext ? state.next : null,
          ),
          IconButton(
            tooltip: switch (state.repeatMode) {
              1 => strings.repeatAll,
              2 => strings.repeatOne,
              _ => strings.repeatOff,
            },
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.repeat_rounded,
                    color: state.repeatMode > 0
                        ? cs.primary
                        : cs.onSurfaceVariant),
                if (state.repeatMode == 2)
                  Text('1',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.primary)),
              ],
            ),
            onPressed: state.cycleRepeatMode,
          ),
        ],
      ),
    );
  }
}
