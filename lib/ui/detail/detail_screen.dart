import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../components/artwork.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/song_row.dart';

enum DetailKind { album, artist, genre, folder, playlist }

/// One screen for all detail contexts (album, artist, genre, folder,
/// playlist). Same layout, different header data — avoids five near-identical
/// screens.
class DetailScreen extends StatefulWidget {
  final DetailKind kind;
  final String? id; // albumId / artistId / folder path / playlist id
  final String title;

  const DetailScreen({
    super.key,
    required this.kind,
    required this.title,
    this.id,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Song> _songs = const [];
  bool _loading = true;
  int? _playlistId;
  String? _subtitle;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final state = context.read<AppState>();
    List<Song> songs;
    String? subtitle;

    switch (widget.kind) {
      case DetailKind.album:
        songs = state.albumSongs(widget.id!);
        final album = state.albums.where((a) => a.id == widget.id).firstOrNull;
        subtitle = [
          album?.artist,
          album == null ? null : songsLabel(album.songCount),
          album == null ? null : formatTotalDuration(album.totalDurationMs),
        ].whereType<String>().join(' · ');
      case DetailKind.artist:
        songs = state.artistSongs(widget.id!);
        subtitle = songsLabel(songs.length);
      case DetailKind.genre:
        songs = state.genreSongs(widget.title);
        subtitle = songsLabel(songs.length);
      case DetailKind.folder:
        songs = state.folderSongs(widget.id!);
        subtitle = songsLabel(songs.length);
      case DetailKind.playlist:
        _playlistId = int.tryParse(widget.id ?? '');
        if (_playlistId == -1) {
          songs = state.favoriteSongs;
          subtitle = songsLabel(songs.length);
        } else if (_playlistId != null) {
          songs = await state.playlistSongs(_playlistId!);
          subtitle = songsLabel(songs.length);
        } else {
          songs = const [];
        }
    }

    if (mounted) {
      setState(() {
        _songs = songs;
        _subtitle = subtitle;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isFavorites = widget.kind == DetailKind.playlist && _playlistId == -1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _HeaderArt(kind: widget.kind, title: widget.title, songs: _songs),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_subtitle != null && _subtitle!.isNotEmpty)
                    Text(_subtitle!,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _songs.isEmpty ? null : () => _play(state, shuffle: false),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _songs.isEmpty ? null : () => _play(state, shuffle: true),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                      ),
                      if (isFavorites) const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
                hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (_songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.music_off_outlined,
                title: 'No songs here yet',
                body: 'Songs you add will show up in this list.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SongTile(
                  song: _songs[i],
                  songs: _songs,
                  playlistId: isFavorites ? null : _playlistId,
                  onRemoved: _resolve,
                ),
                childCount: _songs.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Future<void> _play(AppState state, {required bool shuffle}) async {
    if (_songs.isEmpty) return;
    if (shuffle) {
      final idx = DateTime.now().millisecondsSinceEpoch % _songs.length;
      await state.playQueue(QueueSpec(
        songs: _songs,
        startIndex: idx,
        title: widget.title,
        subtitle: _subtitle ?? '',
      ));
    } else {
      await state.playQueue(QueueSpec(
        songs: _songs,
        startIndex: 0,
        title: widget.title,
        subtitle: _subtitle ?? '',
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }
}

class _HeaderArt extends StatelessWidget {
  final DetailKind kind;
  final String title;
  final List<Song> songs;

  const _HeaderArt({required this.kind, required this.title, required this.songs});

  @override
  Widget build(BuildContext context) {
    final size = 116.0;
    switch (kind) {
      case DetailKind.album:
        final albumId = songs.isNotEmpty ? songs.first.albumId : null;
        return Artwork(albumId: albumId, title: title, size: size, radius: 20);
      case DetailKind.artist:
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(title.isNotEmpty ? title.characters.first : '?',
              style: const TextStyle(fontSize: 36)),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            switch (kind) {
              DetailKind.genre => Icons.piano_rounded,
              DetailKind.folder => Icons.folder_outlined,
              DetailKind.playlist => Icons.queue_music_rounded,
              _ => Icons.music_note_rounded,
            },
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
    }
  }
}

/// Song row with optional playlist removal through the overflow menu.
class _SongTile extends StatelessWidget {
  final Song song;
  final List<Song> songs;
  final int? playlistId;
  final VoidCallback onRemoved;

  const _SongTile({
    required this.song,
    required this.songs,
    required this.playlistId,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final isFavPlaylist = playlistId != null && playlistId == -1;
    final row = SongRow(song: song, queueContext: songs);
    if (playlistId == null || isFavPlaylist) return row;
    return row;
  }
}
