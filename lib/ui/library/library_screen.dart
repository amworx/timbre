import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../components/artwork.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/song_row.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

enum _LibTab { songs, albums, artists, genres, folders }

/// Library: browse everything on the device. Calm, fast, stable keys.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _LibTab _tab = _LibTab.songs;
  bool _restoredTab = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!_restoredTab) {
      _restoredTab = true;
      state.loadLastLibraryTab().then((tab) {
        if (!mounted) return;
        setState(() {
          _tab = _LibTab.values.firstWhere(
            (t) => t.name == tab,
            orElse: () => _LibTab.songs,
          );
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              tab: _tab,
              onTabChanged: (t) {
                setState(() => _tab = t);
                context.read<AppState>().saveLastLibraryTab(t.name);
              },
            ),
            Expanded(child: _Body(tab: _tab)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _LibTab tab;
  final ValueChanged<_LibTab> onTabChanged;

  const _Header({required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TimbreSpacing.md, TimbreSpacing.sm, TimbreSpacing.sm, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Library',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh library',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<AppState>().scanLibrary(),
              ),
            ],
          ),
          const SizedBox(height: TimbreSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in _LibTab.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: TimbreSpacing.sm),
                    child: ChoiceChip(
                      label: Text(switch (t) {
                        _LibTab.songs => 'Songs',
                        _LibTab.albums => 'Albums',
                        _LibTab.artists => 'Artists',
                        _LibTab.genres => 'Genres',
                        _LibTab.folders => 'Folders',
                      }),
                      selected: tab == t,
                      onSelected: (_) => onTabChanged(t),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final _LibTab tab;

  const _Body({required this.tab});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadState == LoadState.loading && state.songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadState == LoadState.error) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load your music',
        body: state.loadError ?? 'Unknown error',
        actionLabel: 'Try again',
        onAction: () => state.scanLibrary(),
      );
    }

    if (state.permissionPhase == PermissionPhase.permanentlyDenied) {
      return EmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Music access is off',
        body: 'Timbre needs permission to read audio files. '
            'Enable it in system settings to see your library.',
        actionLabel: 'Open settings',
        onAction: () => state.openAppSettings(),
      );
    }

    if (state.songs.isEmpty) {
      return EmptyState(
        icon: Icons.music_note_outlined,
        title: 'Your music will appear here',
        body: 'Timbre reads your device\'s audio library. '
            'Once music is found, it shows up instantly.',
        actionLabel: 'Scan library',
        onAction: () => state.scanLibrary(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.scanLibrary(),
      child: switch (tab) {
        _LibTab.songs => _SongsList(songs: state.songs),
        _LibTab.albums => _AlbumsGrid(albums: state.albums),
        _LibTab.artists => _ArtistsList(artists: state.artists),
        _LibTab.genres => _GenresList(genres: state.genres),
        _LibTab.folders => _FoldersList(folders: state.folders),
      },
    );
  }
}

class _SongsList extends StatelessWidget {
  final List<Song> songs;

  const _SongsList({required this.songs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140, top: TimbreSpacing.sm),
      itemCount: songs.length,
      itemBuilder: (context, i) => SongRow(
        key: ValueKey(songs[i].id),
        song: songs[i],
        queueContext: songs,
      ),
    );
  }
}

class _AlbumsGrid extends StatelessWidget {
  final List<Album> albums;

  const _AlbumsGrid({required this.albums});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(TimbreSpacing.md).copyWith(bottom: 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: TimbreSpacing.md,
        crossAxisSpacing: TimbreSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final album = albums[i];
        return InkWell(
          borderRadius: BorderRadius.circular(TimbreRadii.artwork),
          onTap: () => AppNavigator.openAlbum(context, album.id, album.name),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Artwork(albumId: album.id, title: album.name, size: 400),
              ),
              const SizedBox(height: 6),
              Text(album.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(album.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        );
      },
    );
  }
}

class _ArtistsList extends StatelessWidget {
  final List<Artist> artists;

  const _ArtistsList({required this.artists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140, top: TimbreSpacing.sm),
      itemCount: artists.length,
      itemBuilder: (context, i) {
        final artist = artists[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              artist.name.isNotEmpty ? artist.name.characters.first : '?',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(songsLabel(artist.songCount)),
          trailing: Icon(Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => AppNavigator.openArtist(context, artist.id, artist.name),
        );
      },
    );
  }
}

class _GenresList extends StatelessWidget {
  final List<Genre> genres;

  const _GenresList({required this.genres});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140, top: TimbreSpacing.sm),
      itemCount: genres.length,
      itemBuilder: (context, i) {
        final genre = genres[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.piano_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          title: Text(genre.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(songsLabel(genre.songCount)),
          trailing: Icon(Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => AppNavigator.openGenre(context, genre.name),
        );
      },
    );
  }
}

class _FoldersList extends StatelessWidget {
  final List<FolderRef> folders;

  const _FoldersList({required this.folders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140, top: TimbreSpacing.sm),
      itemCount: folders.length,
      itemBuilder: (context, i) {
        final folder = folders[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: TimbreSpacing.md),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(Icons.folder_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(folder.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11)),
          trailing: Text(songsLabel(folder.songCount),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          onTap: () => AppNavigator.openFolder(context, folder.path),
        );
      },
    );
  }
}
