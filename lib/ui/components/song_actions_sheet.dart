import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share;

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../navigation/app_navigator.dart';

/// Long-press / overflow quick actions for a song (MVP quick actions list).
Future<void> showSongActions(BuildContext context, Song song) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => _SongActionsSheet(song: song),
  );
}

class _SongActionsSheet extends StatelessWidget {
  final Song song;

  const _SongActionsSheet({required this.song});

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
              _showPlaylistPicker(context, song);
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
            title: const Text('Share song'),
            onTap: () {
              Navigator.pop(context);
              final text = '${song.title} — ${song.artist}';
              share.SharePlus.instance.share(share.ShareParams(text: text));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> _showPlaylistPicker(BuildContext context, Song song) {
  final state = context.read<AppState>();
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('Add to playlist',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New playlist'),
              onTap: () async {
                Navigator.pop(context);
                final name = await _askPlaylistName(context, 'New playlist');
                if (name != null && name.trim().isNotEmpty) {
                  await state.createPlaylist(name.trim());
                  final playlists = state.playlists;
                  if (playlists.isNotEmpty) {
                    // Add to the freshly created (most recently updated) list.
                    await state.addSongToPlaylist(playlists.first.id, song);
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
                          onTap: () {
                            Navigator.pop(context);
                            state.addSongToPlaylist(pl.id, song);
                          },
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
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
