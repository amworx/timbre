import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../theme/timbre_theme.dart';
import 'artwork.dart';
import 'formatters.dart';
import 'song_actions_sheet.dart';

/// One song row. Tap = play (with [queueContext] as the queue), long-press =
/// contextual actions. Used in Library, Album, Artist, Genre, Folder, Queue,
/// Playlist and search results.
class SongRow extends StatelessWidget {
  final Song song;
  final List<Song> queueContext;
  final bool showArtwork;
  final int? queueIndex;

  const SongRow({
    super.key,
    required this.song,
    required this.queueContext,
    this.showArtwork = true,
    this.queueIndex,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isCurrent = state.currentSong?.id == song.id;
    final fav = state.favoriteIds.contains(song.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
      minLeadingWidth: 0,
      horizontalTitleGap: 14,
      leading: showArtwork ? SongArtwork(song: song, size: 48) : null,
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
        '${song.artist} · ${formatDurationMs(song.durationMs)}',
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
            tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              fav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              size: 22,
              color: fav ? cs.primary : cs.onSurfaceVariant,
            ),
            onPressed: () =>
                context.read<AppState>().toggleFavorite(song),
          ),
          IconButton(
            tooltip: 'More actions',
            icon: Icon(Icons.more_vert_rounded,
                size: 22, color: cs.onSurfaceVariant),
            onPressed: () => showSongActions(context, song),
          ),
        ],
      ),
      onTap: () {
        final app = context.read<AppState>();
        if (isCurrent) {
          app.togglePlayPause();
        } else {
          app.playSong(song, context: queueContext);
        }
      },
      onLongPress: () => showSongActions(context, song),
    );
  }
}
