import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';
import '../components/artwork.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/song_actions_sheet.dart';
import '../components/song_selection.dart';
import '../components/swipe_song_row.dart';

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
  final SongSelection _selection = SongSelection();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  List<Song> get _selectedSongs =>
      _songs.where((s) => _selection.isSelected(s.id)).toList(growable: false);

  Future<void> _shareSelected() async {
    final songs = _selectedSongs;
    if (songs.isEmpty) return;
    setState(() => _busy = true);
    final outcome =
        await context.read<AppState>().shareSongs(songs, t(context));
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.attached == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(outcome.message ?? t(context).nothingToShare)),
      );
    } else {
      _selection.clear();
    }
  }

  Future<void> _deleteSelected() async {
    final songs = _selectedSongs;
    if (songs.isEmpty) return;
    final strings = t(context);
    final confirmed =
        await confirmDeviceDelete(context, strings, count: songs.length);
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final summary =
        await context.read<AppState>().deleteSongs(songs, strings);
    if (!mounted) return;
    setState(() => _busy = false);
    _selection.clear();
    await _resolve();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleteResultText(strings, summary, songs.length)),
      ),
    );
  }

  Future<void> _resolve() async {
    final state = context.read<AppState>();
    if (!mounted) return;
    final strings = t(context);
    List<Song> songs;
    String? subtitle;

    String artistName(String name) =>
        name == kUnknownArtist ? strings.unknownArtist : name;

    switch (widget.kind) {
      case DetailKind.album:
        songs = state.albumSongs(widget.id!);
        final album = state.albums.where((a) => a.id == widget.id).firstOrNull;
        subtitle = [
          album == null ? null : artistName(album.artist),
          album == null ? null : songsLabel(strings, album.songCount),
          album == null
              ? null
              : formatTotalDuration(strings, album.totalDurationMs),
        ].whereType<String>().join(' · ');
      case DetailKind.artist:
        songs = state.artistSongs(widget.id!);
        subtitle = songsLabel(strings, songs.length);
      case DetailKind.genre:
        songs = state.genreSongs(widget.title);
        subtitle = songsLabel(strings, songs.length);
      case DetailKind.folder:
        songs = state.folderSongs(widget.id!);
        subtitle = songsLabel(strings, songs.length);
      case DetailKind.playlist:
        _playlistId = int.tryParse(widget.id ?? '');
        if (_playlistId == -1) {
          songs = state.favoriteSongs;
          subtitle = songsLabel(strings, songs.length);
        } else if (_playlistId != null) {
          songs = await state.playlistSongs(_playlistId!);
          subtitle = songsLabel(strings, songs.length);
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
    final strings = t(context);
    final isFavorites = widget.kind == DetailKind.playlist && _playlistId == -1;
    final barBottom = selectionBarBottom(
      systemBottom: MediaQuery.paddingOf(context).bottom,
      miniVisible: state.currentSong != null,
    );

    return Scaffold(
      // Back exits selection mode first (Gmail behavior), not the screen.
      body: ListenableBuilder(
        listenable: _selection,
        builder: (context, _) => PopScope(
          canPop: !_selection.isSelecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _selection.clear();
          },
          child: Stack(
            children: [
              CustomScrollView(
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
                        label: Text(strings.play),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _songs.isEmpty ? null : () => _play(state, shuffle: true),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: Text(strings.shuffle),
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
                title: strings.noSongsHere,
                body: strings.songsWillShow,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _SongTile(
                  song: _songs[i],
                  songs: _songs,
                  playlistId: isFavorites ? null : _playlistId,
                  selection: _selection,
                  onChanged: _resolve,
                ),
                childCount: _songs.length,
              ),
            ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                // Above the navigation bar (+ mini player when showing).
                bottom: barBottom,
                child: SelectionActionBar(
                  visible: _selection.isSelecting,
                  selectedCount: _selection.count,
                  totalCount: _songs.length,
                  busy: _busy,
                  onClose: _selection.clear,
                  onSelectAll: () =>
                      _selection.selectAll(_songs.map((s) => s.id)),
                  onShare: _shareSelected,
                  onAddToPlaylist: () async {
                    final selected = _selectedSongs;
                    if (selected.isEmpty) return;
                    await showPlaylistPickerForSongs(context, selected);
                    _selection.clear();
                  },
                  onDelete: _deleteSelected,
                ),
              ),
            ],
          ),
        ),
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

/// Swipeable song row with bulk-selection support. [onChanged] refreshes the
/// snapshot-based list after a delete (the global library updates itself).
class _SongTile extends StatelessWidget {
  final Song song;
  final List<Song> songs;
  final int? playlistId;
  final SongSelection selection;
  final VoidCallback onChanged;

  const _SongTile({
    required this.song,
    required this.songs,
    required this.playlistId,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeSongRow(
      song: song,
      queueContext: songs,
      selection: selection,
      keySuffix: 'detail',
      onAfterDelete: onChanged,
    );
  }
}
