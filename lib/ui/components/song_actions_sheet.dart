import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../navigation/app_navigator.dart';
import 'song_selection.dart';

/// Long-press / overflow quick actions for a song.
Future<void> showSongActions(BuildContext context, Song song) {
  return showModalBottomSheet(
    context: context,
    builder: (sheetContext) =>
        _SongActionsSheet(song: song, parentContext: context),
  );
}

/// Bulk "add to playlist" for songs selected in a list.
Future<void> showPlaylistPickerForSongs(
    BuildContext context, List<Song> songs) {
  return showModalBottomSheet(
    context: context,
    builder: (_) => _PlaylistPicker(songs: songs, parentContext: context),
  );
}

class _SongActionsSheet extends StatelessWidget {
  final Song song;
  final BuildContext parentContext;

  const _SongActionsSheet({required this.song, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final fav = state.favoriteIds.contains(song.id);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    song.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  song.artist,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: const Text('Play next'),
            onTap: () {
              Navigator.pop(context);
              context.read<AppState>().playNextInQueue(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_rounded),
            title: const Text('Add to queue'),
            onTap: () {
              Navigator.pop(context);
              context.read<AppState>().addToQueue(song);
            },
          ),
          ListTile(
            leading: Icon(fav ? Icons.heart_broken_rounded : Icons.favorite_outline_rounded),
            title: Text(fav ? 'Remove from favorites' : 'Add to favorites'),
            onTap: () {
              Navigator.pop(context);
              context.read<AppState>().toggleFavorite(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_circle_outlined),
            title: const Text('Add to playlist…'),
            onTap: () {
              Navigator.pop(context);
              showPlaylistPickerForSongs(parentContext, [song]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.album_outlined),
            title: const Text('Go to album'),
            onTap: () {
              Navigator.pop(context);
              AppNavigator.openAlbum(context, song.albumId, song.album);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Go to artist'),
            onTap: () {
              Navigator.pop(context);
              AppNavigator.openArtist(context, song.artistId, song.artist);
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Share audio file'),
            onTap: () async {
              final app = parentContext.read<AppState>();
              final messenger = ScaffoldMessenger.of(parentContext);
              Navigator.pop(context);
              final outcome = await app.shareSongs([song]);
              if (outcome.attached == 0) {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(outcome.message ?? 'Nothing to share.')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error),
            title: Text('Delete from device',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              final app = parentContext.read<AppState>();
              final messenger = ScaffoldMessenger.of(parentContext);
              Navigator.pop(context);
              final confirmed = await confirmDeviceDelete(
                parentContext,
                count: 1,
                songTitle: song.title,
              );
              if (!confirmed) return;
              final summary = await app.deleteSongs([song]);
              if (summary.deleted != 1) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        summary.message ?? 'Could not delete this song.'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PlaylistPicker extends StatelessWidget {
  final List<Song> songs;
  final BuildContext parentContext;

  const _PlaylistPicker({required this.songs, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                songs.length == 1
                    ? 'Add to playlist'
                    : 'Add ${songs.length} songs to playlist',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('New playlist'),
            onTap: () async {
              Navigator.pop(context);
              final name =
                  await _askPlaylistName(parentContext, 'New playlist');
              if (name != null && name.trim().isNotEmpty) {
                await state.createPlaylist(name.trim());
                final playlists = state.playlists;
                if (playlists.isNotEmpty) {
                  // Add to the freshly created (most recently updated) list.
                  for (final song in songs) {
                    await state.addSongToPlaylist(playlists.first.id, song);
                  }
                }
              }
            },
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: state.playlists
                  .map((pl) => ListTile(
                        leading: const Icon(Icons.queue_music_rounded),
                        title: Text(pl.name),
                        subtitle: Text('${pl.songCount} songs'),
                        onTap: () async {
                          Navigator.pop(context);
                          for (final song in songs) {
                            await state.addSongToPlaylist(pl.id, song);
                          }
                        },
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<String?> _askPlaylistName(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
