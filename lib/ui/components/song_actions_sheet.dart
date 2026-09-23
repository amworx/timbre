import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';
import '../navigation/app_navigator.dart';
import 'song_selection.dart';

/// Long-press / overflow quick actions for a song.
Future<void> showSongActions(BuildContext context, Song song) {
  return showModalBottomSheet(
    context: context,
    // Full-height-capable sheet: the action list scrolls instead of
    // clipping its last row off-screen on short displays.
    isScrollControlled: true,
    builder: (sheetContext) =>
        _SongActionsSheet(song: song, parentContext: context),
  );
}

/// Bulk "add to playlist" for songs selected in a list.
Future<void> showPlaylistPickerForSongs(
    BuildContext context, List<Song> songs) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PlaylistPicker(songs: songs, parentContext: context),
  );
}

/// Frames sheet content so it never runs past the screen: capped at 85%
/// of the display height and scrollable past that point.
class _SheetFrame extends StatelessWidget {
  final Widget child;

  const _SheetFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _SongActionsSheet extends StatelessWidget {
  final Song song;
  final BuildContext parentContext;

  const _SongActionsSheet({required this.song, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final strings = t(context);
    final fav = state.favoriteIds.contains(song.id);

    return _SheetFrame(
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
            title: Text(strings.playNext),
            onTap: () {
              final app = parentContext.read<AppState>();
              Navigator.pop(context);
              app.playNextInQueue(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_rounded),
            title: Text(strings.addToQueue),
            onTap: () {
              final app = parentContext.read<AppState>();
              Navigator.pop(context);
              app.addToQueue(song);
            },
          ),
          ListTile(
            leading: Icon(fav ? Icons.heart_broken_rounded : Icons.favorite_outline_rounded),
            title: Text(fav ? strings.tipRemoveFav : strings.tipAddFav),
            onTap: () {
              final app = parentContext.read<AppState>();
              Navigator.pop(context);
              app.toggleFavorite(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_circle_outlined),
            title: Text(strings.addToPlaylist),
            onTap: () {
              Navigator.pop(context);
              showPlaylistPickerForSongs(parentContext, [song]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.album_outlined),
            title: Text(strings.goToAlbum),
            onTap: () {
              Navigator.pop(context);
              AppNavigator.openAlbum(parentContext, song.albumId, song.album);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(strings.goToArtist),
            onTap: () {
              Navigator.pop(context);
              AppNavigator.openArtist(parentContext, song.artistId, song.artist);
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(strings.shareAudioFile),
            onTap: () async {
              final app = parentContext.read<AppState>();
              final messenger = ScaffoldMessenger.of(parentContext);
              final strings = t(parentContext);
              Navigator.pop(context);
              final outcome = await app.shareSongs([song], strings);
              if (outcome.attached == 0) {
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(
                          outcome.message ?? strings.nothingToShare)),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error),
            title: Text(strings.deleteFromDevice,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              final app = parentContext.read<AppState>();
              final messenger = ScaffoldMessenger.of(parentContext);
              final strings = t(parentContext);
              Navigator.pop(context);
              final confirmed = await confirmDeviceDelete(
                parentContext,
                strings,
                count: 1,
                songTitle: song.title,
              );
              if (!confirmed) return;
              final summary = await app.deleteSongs([song], strings);
              if (summary.deleted != 1) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        summary.message ?? strings.couldNotDeleteSong),
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
    final strings = t(context);
    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                songs.length == 1
                    ? strings.addToPlaylistTitle
                    : strings.addCountToPlaylist(songs.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: Text(strings.newPlaylistTitle),
            onTap: () async {
              Navigator.pop(context);
              final name = await _askPlaylistName(
                  parentContext, strings.newPlaylistTitle);
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
                        subtitle: Text(strings.songsCount(pl.songCount)),
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
    builder: (context) {
      final strings = t(context);
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: strings.playlistNameHint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.create),
          ),
        ],
      );
    },
  );
}
