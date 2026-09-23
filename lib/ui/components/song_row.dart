import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';
import '../theme/timbre_theme.dart';
import 'artwork.dart';
import 'formatters.dart';
import 'song_actions_sheet.dart';

/// One song row. Tap = play (with [queueContext] as the queue), long-press =
/// contextual actions. Used in Library, Album, Artist, Genre, Folder, Queue,
/// Playlist and search results.
///
/// When [selected] is true the row shows a checked state instead of artwork.
/// [onTapOverride]/[onLongPressOverride] replace the default gestures, which
/// is how bulk-selection mode hijacks taps without touching playback.
class SongRow extends StatelessWidget {
  final Song song;
  final List<Song> queueContext;
  final bool showArtwork;
  final int? queueIndex;
  final bool selected;
  final VoidCallback? onTapOverride;
  final VoidCallback? onLongPressOverride;

  const SongRow({
    super.key,
    required this.song,
    required this.queueContext,
    this.showArtwork = true,
    this.queueIndex,
    this.selected = false,
    this.onTapOverride,
    this.onLongPressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final strings = t(context);
    final isCurrent = state.currentSong?.id == song.id;
    final fav = state.favoriteIds.contains(song.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
      minLeadingWidth: 0,
      horizontalTitleGap: 14,
      tileColor: selected ? cs.primary.withValues(alpha: 0.10) : null,
      shape: selected
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          : null,
      leading: selected
          ? AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 160),
              child: Icon(Icons.check_circle_rounded,
                  size: 32, color: cs.primary),
            )
          : (showArtwork ? SongArtwork(song: song, size: 48) : null),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
          color: isCurrent ? cs.primary : cs.onSurface,
        ),
      ),
      subtitle: Text(
        '${displayArtist(song, strings)} · ${formatDurationMs(song.durationMs)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (queueIndex != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${queueIndex! + 1}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ),
          IconButton(
            tooltip: fav ? strings.tipRemoveFav : strings.tipAddFav,
            icon: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: 22,
              color: fav ? cs.primary : cs.onSurfaceVariant,
            ),
            onPressed: () =>
                context.read<AppState>().toggleFavorite(song),
          ),
          IconButton(
            tooltip: strings.tipMore,
            icon: Icon(Icons.more_vert_rounded,
                size: 22, color: cs.onSurfaceVariant),
            onPressed: () => showSongActions(context, song),
          ),
        ],
      ),
      onTap: onTapOverride ??
          () {
            final app = context.read<AppState>();
            if (isCurrent) {
              app.togglePlayPause();
            } else {
              app.playSong(song, context: queueContext);
            }
          },
      onLongPress: onLongPressOverride ?? () => showSongActions(context, song),
    );
  }
}
