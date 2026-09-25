import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';
import '../components/artwork.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/responsive.dart';
import '../components/song_row.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

/// One global search across songs, artists, albums and genres.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _query = _controller.text.trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final strings = t(context);
    final results = _query.isEmpty ? null : _search(state, _query);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TimbreSpacing.md, TimbreSpacing.sm, TimbreSpacing.md, TimbreSpacing.sm),
              child: SearchBar(
                controller: _controller,
                focusNode: _focus,
                hintText: strings.searchHint,
                leading: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: strings.tipClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        _focus.requestFocus();
                      },
                    ),
                ],
                backgroundColor:
                    WidgetStatePropertyAll(cs.surfaceContainerHighest.withValues(alpha: 0.7)),
                elevation: const WidgetStatePropertyAll(0),
                constraints: const BoxConstraints(minHeight: 52),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
              ),
            ),
            Expanded(
              child: results == null
                  ? _IdleSuggestions(state: state)
                  : _Results(results: results, query: _query),
            ),
          ],
        ),
      ),
    );
  }

  _SearchResults _search(AppState state, String query) {
    final q = query.toLowerCase();
    bool contains(String? s) => s != null && s.toLowerCase().contains(q);

    final songs =
        state.songs.where((s) => contains(s.title) || contains(s.artist)).toList(growable: false);
    final artists =
        state.artists.where((a) => contains(a.name)).toList(growable: false);
    final albums =
        state.albums.where((a) => contains(a.name) || contains(a.artist)).toList(growable: false);
    final genres = state.genres.where((g) => contains(g.name)).toList(growable: false);
    return _SearchResults(songs: songs, artists: artists, albums: albums, genres: genres);
  }
}

class _SearchResults {
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Genre> genres;

  const _SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.genres,
  });

  bool get isEmpty =>
      songs.isEmpty && artists.isEmpty && albums.isEmpty && genres.isEmpty;
}

class _IdleSuggestions extends StatelessWidget {
  final AppState state;

  const _IdleSuggestions({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.songs.isEmpty) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: t(context).nothingToSearchTitle,
        body: t(context).nothingToSearchBody,
      );
    }
    final suggestions = state.songs.take(6).toList(growable: false);
    final listBottom = TimbreOverlay.listBottomPadding(context,
        miniVisible: state.currentSong != null);
    return ListView(
      padding:
          EdgeInsets.only(top: TimbreSpacing.sm, bottom: listBottom),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
          child: Text(t(context).browseLibrary,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: TimbreSpacing.sm),
        for (final s in suggestions)
          SongRow(key: ValueKey(s.id), song: s, queueContext: suggestions),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  final _SearchResults results;
  final String query;

  const _Results({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: t(context).nothingFoundTitle,
        body: t(context).nothingFoundBody,
      );
    }
    final listBottom = TimbreOverlay.listBottomPadding(context,
        miniVisible:
            context.select<AppState, bool>((a) => a.currentSong != null));
    return ListView(
      padding:
          EdgeInsets.only(top: TimbreSpacing.sm, bottom: listBottom),
      children: [
        if (results.artists.isNotEmpty) ...[
          _SectionTitle(t(context).secArtists),
          for (final a in results.artists.take(4))
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(a.name.isNotEmpty ? a.name.characters.first : '?'),
              ),
              title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(songsLabel(t(context), a.songCount)),
              onTap: () => AppNavigator.openArtist(context, a.id, a.name),
            ),
        ],
        if (results.albums.isNotEmpty) ...[
          _SectionTitle(t(context).secAlbums),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
              itemCount: results.albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: TimbreSpacing.md),
              itemBuilder: (context, i) {
                final album = results.albums[i];
                return SizedBox(
                  width: 116,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TimbreRadii.artwork),
                    onTap: () =>
                        AppNavigator.openAlbum(context, album.id, album.name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Artwork(albumId: album.id, title: album.name, size: 116),
                        const SizedBox(height: 6),
                        Text(album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (results.genres.isNotEmpty) ...[
          _SectionTitle(t(context).secGenres),
          for (final g in results.genres.take(4))
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
              leading: Icon(Icons.piano_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text(g.name),
              subtitle: Text(songsLabel(t(context), g.songCount)),
              onTap: () => AppNavigator.openGenre(context, g.name),
            ),
        ],
        if (results.songs.isNotEmpty) ...[
          _SectionTitle(t(context).secSongs),
          for (final s in results.songs.take(30))
            SongRow(key: ValueKey(s.id), song: s, queueContext: results.songs),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(TimbreSpacing.md, TimbreSpacing.md, TimbreSpacing.md, TimbreSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
