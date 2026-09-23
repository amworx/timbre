import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_repository.dart';
import '../domain/flow_queue.dart';
import '../domain/models.dart';
import '../playback/timbre_audio_handler.dart';

/// Library load state for the whole app.
enum LoadState { loading, ready, error }

/// Runtime audio permission phase.
enum PermissionPhase { unknown, granted, denied, permanentlyDenied }

/// A "continue listening" suggestion for the Home screen.
class ContinueEntry {
  final Song song;
  final int remainingMs;

  const ContinueEntry({required this.song, required this.remainingMs});
}

/// Single source of truth for the UI. Wraps the repository and the audio
/// handler; UI widgets only ever see this class.
class AppState extends ChangeNotifier {
  final LibraryRepository library;
  final TimbreAudioHandler player;

  AppState({required this.library, required this.player}) {
    player.currentSongStream.listen((_) => notifyListeners());
    player.sleepRemainingStream.listen((_) => notifyListeners());
    player.playbackState.listen((_) => notifyListeners());
    player.changes.listen((_) => notifyListeners());
  }

  // ------------------------------------------------------------------
  // Library & permission state
  // ------------------------------------------------------------------

  LoadState loadState = LoadState.loading;
  PermissionPhase permissionPhase = PermissionPhase.unknown;
  String? loadError;

  List<Song> songs = const [];
  List<Album> albums = const [];
  List<Artist> artists = const [];
  List<Genre> genres = const [];
  List<FolderRef> folders = const [];

  Set<int> favoriteIds = {};
  List<Playlist> playlists = [];

  /// Continue-listening entry (null when there is nothing to resume).
  ContinueEntry? continueEntry;

  // Derived convenience getters ---------------------------------------

  bool get hasMusic => songs.isNotEmpty;
  bool get isPlaying => player.isPlaying;
  Song? get currentSong => player.currentSong;
  List<Song> get queue => player.queueSongs;
  int? get queueIndex => player.player.currentIndex;
  String? get queueTitle => player.mediaItem.valueOrNull?.title;
  bool get queueIsFlow => queueTitle?.startsWith('Flow') ?? false;

  Duration get position => player.player.position;
  Duration get duration => player.player.duration ?? Duration.zero;
  bool get hasNext => player.player.hasNext;
  bool get hasPrevious => player.player.hasPrevious;

  int get repeatMode => player.repeatMode;
  bool get shuffleEnabled => player.shuffleEnabled;
  double get speed => player.speed;
  int? get sleepRemainingMs => player.sleepRemainingMs;

  // ------------------------------------------------------------------
  // Permission + scan
  // ------------------------------------------------------------------

  Future<void> bootstrap() async {
    await refreshPermissionState();
    if (permissionPhase == PermissionPhase.granted) {
      await scanLibrary();
    } else {
      loadState = LoadState.ready; // show permission/empty UI
      notifyListeners();
    }
  }

  Future<void> refreshPermissionState() async {
    final status = await ph.Permission.audio.status;
    if (status.isGranted) {
      permissionPhase = PermissionPhase.granted;
    } else if (status.isPermanentlyDenied) {
      permissionPhase = PermissionPhase.permanentlyDenied;
    } else {
      permissionPhase = PermissionPhase.denied;
    }
    notifyListeners();
  }

  /// Requests audio permission; on 32 and below also accepts storage.
  Future<bool> requestPermission() async {
    final status = await ph.Permission.audio.request();
    if (status.isGranted) {
      permissionPhase = PermissionPhase.granted;
      notifyListeners();
      return true;
    }
    await refreshPermissionState();
    return false;
  }

  Future<void> scanLibrary() async {
    loadState = LoadState.loading;
    notifyListeners();
    try {
      final loaded = await library.loadSongs();
      songs = loaded;
      albums = library.albumsOf(loaded);
      artists = library.artistsOf(loaded);
      genres = library.genresOf(loaded);
      folders = library.foldersOf(loaded);
      favoriteIds = await library.loadFavoriteIds();
      playlists = await library.loadPlaylists();
      await _loadContinueEntry();
      loadState = LoadState.ready;
    } catch (e) {
      loadError = e.toString();
      loadState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> _loadContinueEntry() async {
    final row = await library.loadContinueListening();
    if (row == null) {
      continueEntry = null;
      return;
    }
    final song = _songById(row['song_id'] as int);
    if (song == null) {
      continueEntry = null;
      return;
    }
    final position = row['position_ms'] as int;
    final duration = song.durationMs;
    continueEntry = (duration > 0 && position >= duration - 3000)
        ? null // effectively finished
        : ContinueEntry(song: song, remainingMs: duration - position);
  }

  Song? _songById(int id) {
    for (final s in songs) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Playback facade (thin wrappers over the handler)
  // ------------------------------------------------------------------

  Future<void> playQueue(QueueSpec spec) => player.playQueue(spec);

  Future<void> playSong(Song song, {List<Song>? context}) {
    final list = context ?? [song];
    final index = list.indexWhere((s) => s.id == song.id);
    return playQueue(QueueSpec(
      songs: list,
      startIndex: index < 0 ? 0 : index,
      title: song.title,
      subtitle: song.artist,
    ));
  }

  Future<void> playAlbum(Album album) async {
    final songs = albumSongs(album.id);
    if (songs.isEmpty) return;
    await playQueue(QueueSpec(
      songs: songs,
      startIndex: 0,
      title: album.name,
      subtitle: album.artist,
    ));
  }

  Future<void> playArtist(Artist artist) async {
    final songs = artistSongs(artist.id);
    if (songs.isEmpty) return;
    await playQueue(QueueSpec(
      songs: songs,
      startIndex: 0,
      title: artist.name,
      subtitle: '${artist.songCount} songs',
    ));
  }

  Future<void> togglePlayPause() async {
    if (player.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> next() => player.skipToNext();
  Future<void> previous() => player.skipToPrevious();
  Future<void> seekTo(Duration d) => player.seek(d);

  Future<void> cycleRepeatMode() =>
      player.updateRepeatMode((player.repeatMode + 1) % 3);

  Future<void> toggleShuffle() => player.setShuffleEnabled(!player.shuffleEnabled);

  Future<void> setSpeed(double s) => player.setSpeed(s);

  Future<void> playNextInQueue(Song song) => player.playNext(song);
  Future<void> addToQueue(Song song) => player.addToQueue(song);
  Future<void> removeFromQueue(int index) => player.removeAt(index);
  Future<void> moveInQueue(int from, int to) => player.moveInQueue(from, to);
  Future<void> clearQueue() => player.clearQueue();

  Future<void> skipToQueueItem(int index) => player.skipToQueueItem(index);

  // ------------------------------------------------------------------
  // Flow Queue
  // ------------------------------------------------------------------

  /// Starts a deterministic Flow queue seeded from [song].
  Future<void> startFlow(Song song) async {
    final stats = await library.loadPlayStats();
    final snapshot = ListeningSnapshot(stats: stats, favoriteIds: favoriteIds);
    final candidates = FlowQueue.build(
      current: song,
      library: songs,
      snapshot: snapshot,
      nowMs: DateTime.now().millisecondsSinceEpoch,
      seed: song.id * 31 + DateTime.now().millisecondsSinceEpoch ~/ 3600000,
    );
    final queue = [song, ...candidates];
    await playQueue(QueueSpec(
      songs: queue,
      startIndex: 0,
      title: 'Flow · ${song.title}',
      subtitle: FlowQueue.explanation(song, snapshot),
    ));
  }

  // ------------------------------------------------------------------
  // Favorites
  // ------------------------------------------------------------------

  bool isFavorite(Song song) => favoriteIds.contains(song.id);

  Future<void> toggleFavorite(Song song) async {
    final isFav = favoriteIds.contains(song.id);
    if (isFav) {
      favoriteIds = Set.of(favoriteIds)..remove(song.id);
    } else {
      favoriteIds = Set.of(favoriteIds)..add(song.id);
    }
    notifyListeners();
    try {
      await library.setFavorite(song.id, !isFav);
    } catch (e) {
      // Roll back on failure so UI and DB stay consistent.
      favoriteIds = Set.of(favoriteIds);
      if (isFav) {
        favoriteIds.add(song.id);
      } else {
        favoriteIds.remove(song.id);
      }
      notifyListeners();
      rethrow;
    }
  }

  List<Song> get favoriteSongs =>
      songs.where((s) => favoriteIds.contains(s.id)).toList(growable: false);

  // ------------------------------------------------------------------
  // Playlists
  // ------------------------------------------------------------------

  Future<void> createPlaylist(String name) async {
    await library.createPlaylist(name);
    playlists = await library.loadPlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(int id, String name) async {
    await library.renamePlaylist(id, name);
    playlists = await library.loadPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(int id) async {
    await library.deletePlaylist(id);
    playlists = await library.loadPlaylists();
    notifyListeners();
  }

  Future<List<Song>> playlistSongs(int playlistId) async {
    final ids = await library.loadPlaylistSongIds(playlistId);
    return ids.map(_songById).whereType<Song>().toList();
  }

  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    await library.addSongToPlaylist(playlistId, song.id);
    playlists = await library.loadPlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(int playlistId, Song song) async {
    await library.removeSongFromPlaylist(playlistId, song.id);
    playlists = await library.loadPlaylists();
    notifyListeners();
  }

  Future<void> reorderPlaylistSong(int playlistId, Song song, int newPosition) async {
    await library.reorderPlaylistSong(playlistId, song.id, newPosition);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Grouping lookups for detail screens
  // ------------------------------------------------------------------

  List<Song> albumSongs(String albumId) =>
      songs.where((s) => s.albumId == albumId).toList(growable: false);

  List<Song> artistSongs(String artistId) =>
      songs.where((s) => s.artistId == artistId).toList(growable: false);

  List<Song> genreSongs(String genre) =>
      songs.where((s) => s.genre == genre).toList(growable: false);

  List<Song> folderSongs(String folder) =>
      songs.where((s) => s.folder == folder).toList(growable: false);

  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  // ------------------------------------------------------------------
  // Recently played
  // ------------------------------------------------------------------

  Future<List<Song>> recentlyPlayed({int limit = 12}) async {
    final ids = await library.loadRecentSongIds(limit: limit);
    return ids.map(_songById).whereType<Song>().toList();
  }

  // ------------------------------------------------------------------
  // Sleep timer
  // ------------------------------------------------------------------

  Future<void> startSleepTimer(int minutes) async => player.startSleepTimer(minutes);
  Future<void> sleepAtEndOfTrack() async => player.sleepAtEndOfTrack();
  Future<void> cancelSleepTimer() async => player.cancelSleepTimer();
  bool get sleepActive => player.sleepActive;

  // ------------------------------------------------------------------
  // Artwork
  // ------------------------------------------------------------------

  /// Artwork for [albumId]; returns cached file if available, else queries
  /// MediaStore once and caches. Null when the file has no embedded art.
  Future<File?> artwork(String albumId) => player.artworkFile(albumId);

  // ---------------------------------------------------------------- AppState
  // Settings (DataStore-equivalent, via SharedPreferences)
  // ---------------------------------------------------------------- AppState

  static const _prefKeyPrefix = 'settings.';
  static const _lastTabKey = 'settings.libraryTab';

  Future<Object?> _getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get('$_prefKeyPrefix$key');
  }

  Future<void> _setSetting(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt('$_prefKeyPrefix$key', value);
    } else if (value is double) {
      await prefs.setDouble('$_prefKeyPrefix$key', value);
    } else if (value is bool) {
      await prefs.setBool('$_prefKeyPrefix$key', value);
    } else if (value is String) {
      await prefs.setString('$_prefKeyPrefix$key', value);
    } else if (value is List<String>) {
      await prefs.setStringList('$_prefKeyPrefix$key', value);
    }
  }

  /// Last non-Flow tab the user had open (restore on app start).
  Future<String> loadLastLibraryTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastTabKey) ?? 'songs';
  }

  Future<void> saveLastLibraryTab(String tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTabKey, tab);
  }

  /// Whether Home should show the full onboarding card.
  Future<bool> loadShowOnboarding() async {
    return await _getSetting('showOnboarding') as bool? ?? true;
  }

  Future<void> saveShowOnboarding(bool value) => _setSetting('showOnboarding', value);
}

/// Notes: no cloud, no accounts, no analytics. Only local files are read;
/// only app-owned preferences and small metadata tables are written.
