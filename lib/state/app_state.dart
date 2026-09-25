import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:share_plus/share_plus.dart' as share;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_repository.dart';
import '../domain/flow_queue.dart';
import '../domain/models.dart';
import '../library/library_filter.dart';
import '../l10n/app_localizations.dart';
import '../media/media_files.dart';
import '../playback/timbre_audio_handler.dart';
import 'notification_permission.dart';

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

  // Library filters (Settings → Library filters) ----------------------
  // [songs]/groups below are the FILTERED view. [_unfilteredSongs] and
  // [allFolders] keep the full picture so the folder editor can offer
  // hidden folders back and toggles apply instantly without rescanning.
  List<Song> _unfilteredSongs = const [];
  List<FolderRef> allFolders = const [];
  Set<String> excludedFolders = {};
  int minDurationMs = 0;

  LibraryFilter get filter => LibraryFilter(
        excludedFolders: excludedFolders,
        minDurationMs: minDurationMs,
      );

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
    await refreshNotificationState();
    await loadFilters();
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
      _unfilteredSongs = await library.loadSongs();
      allFolders = library.foldersOf(_unfilteredSongs);
      await _rebuildFilteredLists();
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

  /// Re-derives the visible library from [_unfilteredSongs] + [filter].
  Future<void> _rebuildFilteredLists() async {
    final visible = filter.apply(_unfilteredSongs);
    songs = visible;
    albums = library.albumsOf(visible);
    artists = library.artistsOf(visible);
    genres = library.genresOf(visible);
    folders = library.foldersOf(visible);
  }

  // Library filter controls (persisted, applied without rescanning) -----

  static const _filterMinKey = 'filters.minDurationMs';
  static const _filterExcludedKey = 'filters.excludedFolders';

  Future<void> loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    minDurationMs = prefs.getInt(_filterMinKey) ?? 0;
    excludedFolders =
        (prefs.getStringList(_filterExcludedKey) ?? const []).toSet();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_filterMinKey, minDurationMs);
    await prefs.setStringList(
        _filterExcludedKey, excludedFolders.toList(growable: false));
  }

  Future<void> setMinDuration(int ms) async {
    minDurationMs = ms < 0 ? 0 : ms;
    await _saveFilters();
    await _rebuildFilteredLists();
    await _loadContinueEntry();
    notifyListeners();
  }

  Future<void> setFolderExcluded(String folder, bool excluded) async {
    if (excluded) {
      excludedFolders = Set.of(excludedFolders)..add(folder);
    } else {
      excludedFolders = Set.of(excludedFolders)..remove(folder);
    }
    await _saveFilters();
    await _rebuildFilteredLists();
    await _loadContinueEntry();
    notifyListeners();
  }

  /// Hides every detected messaging-audio folder (WhatsApp/Telegram voice
  /// notes…). Returns how many folders were hidden.
  Future<int> hideMessagingAudio() async {
    final matches = messagingAudioFolders(allFolders.map((f) => f.path));
    if (matches.isEmpty) return 0;
    excludedFolders = Set.of(excludedFolders)..addAll(matches);
    await _saveFilters();
    await _rebuildFilteredLists();
    await _loadContinueEntry();
    notifyListeners();
    return matches.length;
  }

  Future<void> showAllFolders() async {
    if (excludedFolders.isEmpty) return;
    excludedFolders = {};
    await _saveFilters();
    await _rebuildFilteredLists();
    await _loadContinueEntry();
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
  // Notification permission (Android 13+): playback never depends on it,
  // but background/lock-screen controls do — so ask once on first play
  // without ever blocking the music, and reflect the state in Settings.
  // ------------------------------------------------------------------

  NotificationPhase notificationPhase = NotificationPhase.unknown;

  Future<void> refreshNotificationState() async {
    notificationPhase =
        notificationPhaseOf(await ph.Permission.notification.status);
    notifyListeners();
  }

  /// System prompt for notifications. Returns true when controls can show.
  Future<bool> requestNotifications() async {
    final status = await ph.Permission.notification.request();
    notificationPhase = notificationPhaseOf(status);
    notifyListeners();
    return notificationPhase == NotificationPhase.granted;
  }

  /// One-time prompt on first playback. Fire-and-forget on purpose:
  /// the music starts immediately either way.
  Future<void> promptNotificationsOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notifications.prompted') == true) return;
      await prefs.setBool('notifications.prompted', true);
      await refreshNotificationState();
      if (notificationPhase == NotificationPhase.denied) {
        await requestNotifications();
      }
    } catch (_) {
      // Permission plumbing must never break playback.
    }
  }

  // ------------------------------------------------------------------
  // Playback facade (thin wrappers over the handler)
  // ------------------------------------------------------------------

  Future<void> playQueue(QueueSpec spec) {
    unawaited(promptNotificationsOnce());
    return player.playQueue(spec);
  }

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
  /// The UI passes its locale strings ([t]) so queue titles translate.
  Future<void> startFlow(Song song, AppLocalizations t) async {
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
      title: t.flowQueueTitle(song.title),
      subtitle: FlowQueue.explanation(song, snapshot, t),
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
  // Share & delete (device files)
  // ------------------------------------------------------------------

  final MediaFiles mediaFiles = MediaFiles();

  /// Shares the audio [songs] as files through the system sheet.
  /// Returns how many were attached; [ShareOutcome.attached] == 0 means
  /// none of the files were reachable (message explains why).
  Future<ShareOutcome> shareSongs(
      List<Song> songs, AppLocalizations t) async {
    final files = <share.XFile>[];
    for (final s in songs) {
      final path = s.filePath;
      if (path.isEmpty) continue;
      try {
        if (!File(path).existsSync()) continue;
      } catch (_) {
        continue;
      }
      files.add(share.XFile(
        path,
        mimeType: mimeForPath(path),
        name: _shareFileName(s, path),
      ));
    }
    if (files.isEmpty) {
      return ShareOutcome(
        attached: 0,
        message: t.audioNotAvailable,
      );
    }
    await share.SharePlus.instance.share(share.ShareParams(
      files: files,
      text: songs.length == 1
          ? t.shareOneText(songs.first.title, songs.first.artist)
          : t.shareManyText(songs.length),
    ));
    return ShareOutcome(attached: files.length);
  }

  String _shareFileName(Song song, String path) {
    final ext = path.contains('.') ? path.split('.').last : 'mp3';
    final base = '${song.artist} - ${song.title}'
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final trimmed = base.isEmpty ? 'timbre-audio' : base;
    return '$trimmed.$ext';
  }

  /// Deletes [songs] from device storage via the MediaStore consent flow,
  /// then purges every app-owned trace and refreshes the in-memory library.
  /// Never throws: per-file problems are counted in the returned summary.
  Future<DeleteSummary> deleteSongs(
      List<Song> targets, AppLocalizations t) async {
    var deleted = 0;
    var denied = 0;
    var failed = 0;
    final deletedIds = <int>{};

    for (final song in targets) {
      final outcome = await mediaFiles.deleteSong(song);
      switch (outcome.status) {
        case MediaDeleteStatus.deleted:
          deleted++;
          deletedIds.add(song.id);
        case MediaDeleteStatus.denied:
          denied++;
        case MediaDeleteStatus.unavailable:
        case MediaDeleteStatus.failed:
          failed++;
      }
    }

    if (deletedIds.isNotEmpty) {
      final currentDeleted =
          currentSong != null && deletedIds.contains(currentSong!.id);
      _unfilteredSongs = _unfilteredSongs
          .where((s) => !deletedIds.contains(s.id))
          .toList(growable: false);
      allFolders = library.foldersOf(_unfilteredSongs);
      final remaining =
          songs.where((s) => !deletedIds.contains(s.id)).toList();
      songs = remaining;
      albums = library.albumsOf(remaining);
      artists = library.artistsOf(remaining);
      genres = library.genresOf(remaining);
      folders = library.foldersOf(remaining);
      favoriteIds = favoriteIds.difference(deletedIds);
      playlists = await library.loadPlaylists();
      await library.purgeSongs(deletedIds);
      await _loadContinueEntry();
      if (currentDeleted) {
        if (hasNext) {
          await next();
        } else {
          await player.pause();
          await clearQueue();
        }
      }
      notifyListeners();
    }

    return DeleteSummary(
      deleted: deleted,
      denied: denied,
      failed: failed,
      message: denied > 0
          ? t.deleteNotAllowed
          : (failed > 0 ? t.couldNotDeleteSong : null),
    );
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

/// Result of [AppState.shareSongs].
class ShareOutcome {
  final int attached;
  final String? message;

  const ShareOutcome({required this.attached, this.message});
}

/// Result of [AppState.deleteSongs]. Amounts always add up to the number
/// of songs passed in.
class DeleteSummary {
  final int deleted;
  final int denied;
  final int failed;
  final String? message;

  const DeleteSummary({
    required this.deleted,
    required this.denied,
    required this.failed,
    this.message,
  });

  bool get allDeleted => denied == 0 && failed == 0;
}

/// Notes: no cloud, no accounts, no analytics. Only local files are read;
/// only app-owned preferences and small metadata tables are written.
