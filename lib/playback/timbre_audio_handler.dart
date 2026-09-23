import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_repository.dart';
import '../domain/models.dart';

/// Owns the [AudioPlayer] and exposes playback through audio_service so the
/// app gets background audio, a media notification and lock-screen controls.
///
/// UI screens never touch just_audio directly; they observe this handler.
class TimbreAudioHandler extends BaseAudioHandler with SeekHandler {
  static const _queuePrefsKey = 'playback.queue.v1';
  static const _statePrefsKey = 'playback.state.v1';
  static const _artCacheMaxEntries = 200;

  final AudioPlayer _player = AudioPlayer();
  final LibraryRepository _library;
  final OnAudioQuery _query;

  /// Songs behind the current queue, index-aligned with the audio sources.
  List<Song> queueSongs = const [];

  Song? get currentSong {
    final i = _player.currentIndex;
    if (i == null || i < 0 || i >= queueSongs.length) return null;
    return queueSongs[i];
  }

  final _currentSongSubject = TimbreSubject<Song?>(null);
  final _sleepRemainingSubject = TimbreSubject<int?>(null);
  final _changesSubject = TimbreSubject<int>(0);

  /// Current song whenever it changes (track change / restore / queue edit).
  Stream<Song?> get currentSongStream => _currentSongSubject.stream;

  /// Sleep timer remaining in ms; null = off, -1 = end-of-track mode.
  Stream<int?> get sleepRemainingStream => _sleepRemainingSubject.stream;

  /// Fires (with a counter) whenever playback settings change so UI can
  /// re-read repeatMode / shuffleEnabled / speed.
  Stream<int> get changes => _changesSubject.stream;

  Timer? _sleepTimer;
  Timer? _positionSaveTimer;
  StreamSubscription? _indexSub;
  StreamSubscription? _durationSub;
  int _sleepTimerRemainingMs = 0;
  bool _sleepAtEndOfTrack = false;
  int? _countedSongId; // song id whose play was already counted
  Directory? _artCacheDir;
  Future<Directory?>? _artCacheDirFuture;

  TimbreAudioHandler(this._library, this._query) {
    _attachListeners();
    _restoreState();
  }

  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  int get repeatMode => switch (_player.loopMode) {
        LoopMode.one => 2,
        LoopMode.all => 1,
        _ => 0,
      };
  double get speed => _player.speed;
  bool get hasQueue => queueSongs.isNotEmpty;
  bool get sleepActive =>
      _sleepTimer != null || _sleepAtEndOfTrack || _sleepTimerRemainingMs > 0;
  int? get sleepRemainingMs {
    if (_sleepTimer == null && !_sleepAtEndOfTrack) return null;
    return _sleepAtEndOfTrack ? -1 : _sleepTimerRemainingMs;
  }

  // ------------------------------------------------------------------
  // State wiring
  // ------------------------------------------------------------------

  void _attachListeners() {
    _player.sequenceStream.listen((_) => _syncQueueToSystem());

    _indexSub = _player.currentIndexStream.listen((index) {
      _pushPlaybackState();
      final song = currentSong;
      if (song != null) {
        mediaItem.add(_mediaItemFor(song));
      }
      _currentSongSubject.add(song);
      _countedSongId = null; // new track: count its play once it starts
      _persistState();
    });

    _player.playerStateStream.listen((state) {
      _pushPlaybackState();
      if (state.processingState == ProcessingState.completed) {
        _recordHistory(completed: true);
        _countedSongId = null;
        if (_sleepAtEndOfTrack) {
          _stopSleepTimer();
          _player.pause();
        }
      } else if (!state.playing &&
          state.processingState == ProcessingState.ready) {
        _savePosition();
      }
    });

    _durationSub = _player.durationStream.listen((_) {
      final song = currentSong;
      if (song != null) mediaItem.add(_mediaItemFor(song));
    });
  }

  void _syncQueueToSystem() {
    queue.add(queueSongs.map(_mediaItemFor).toList());
    playbackState.add(playbackState.value.copyWith(
      queueIndex: _player.currentIndex,
    ));
  }

  void _pushPlaybackState() {
    final state = _player.playerState;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[state.processingState]!,
      playing: state.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    ));
  }

  MediaItem _mediaItemFor(Song song) => MediaItem(
        id: '${song.id}',
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.durationMs),
        artUri: artworkFileUri(song.albumId),
      );

  // ------------------------------------------------------------------
  // Queue management
  // ------------------------------------------------------------------

  /// Replaces the queue and loads [startIndex]. Does not autoplay.
  Future<void> _setQueue(List<Song> songs, int startIndex,
      {Duration? initialPosition}) async {
    final index = startIndex.clamp(0, songs.length - 1);
    queueSongs = List.of(songs);
    final sources = songs.map(_sourceFor).toList();
    await _player.setAudioSources(
      sources,
      initialIndex: index,
      initialPosition: initialPosition ?? Duration.zero,
    );
    mediaItem.add(_mediaItemFor(queueSongs[index]));
    _currentSongSubject.add(currentSong);
    _syncQueueToSystem();
    _pushPlaybackState();
    await _persistState();
  }

  /// Starts playing [songs] at [startIndex], replacing the queue.
  Future<void> playQueue(QueueSpec spec) async {
    if (spec.songs.isEmpty) return;
    await _setQueue(spec.songs, spec.startIndex);
    await play();
  }

  AudioSource _sourceFor(Song song) {
    final uri = Uri.tryParse(song.uri);
    if (uri == null || (!uri.hasScheme || uri.scheme == 'file')) {
      return AudioSource.uri(Uri.file(song.uri.startsWith('file://')
          ? Uri.parse(song.uri).toFilePath()
          : song.uri));
    }
    return AudioSource.uri(uri);
  }

  /// Plays [song] immediately after the current item.
  Future<void> playNext(Song song) async {
    if (queueSongs.isEmpty) {
      await playQueue(QueueSpec(
        songs: [song],
        startIndex: 0,
        title: song.title,
        subtitle: song.artist,
      ));
      return;
    }
    final insertAt = (_player.currentIndex ?? -1) + 1;
    await _player.insertAudioSource(insertAt, _sourceFor(song));
    queueSongs.insert(insertAt.clamp(0, queueSongs.length), song);
    _currentSongSubject.add(currentSong);
    _syncQueueToSystem();
    _bumpChanges();
  }

  /// Appends [song] to the end of the queue.
  Future<void> addToQueue(Song song) async {
    if (queueSongs.isEmpty) {
      await playQueue(QueueSpec(
        songs: [song],
        startIndex: 0,
        title: song.title,
        subtitle: song.artist,
      ));
      return;
    }
    await _player.addAudioSource(_sourceFor(song));
    queueSongs.add(song);
    _currentSongSubject.add(currentSong);
    _syncQueueToSystem();
    _bumpChanges();
  }

  /// Removes the queue entry at [index] (never leaves the player empty here;
  /// use [clearQueue] to stop everything).
  Future<void> removeAt(int index) async {
    if (index < 0 || index >= queueSongs.length) return;
    if (queueSongs.length == 1) {
      await clearQueue();
      return;
    }
    await _player.removeAudioSourceAt(index);
    queueSongs.removeAt(index);
    _currentSongSubject.add(currentSong);
    _syncQueueToSystem();
    await _persistState();
    _bumpChanges();
  }

  /// Moves a queue entry (drag & drop in the queue screen).
  Future<void> moveInQueue(int from, int to) async {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= queueSongs.length ||
        to >= queueSongs.length) {
      return;
    }
    await _player.moveAudioSource(from, to);
    final song = queueSongs.removeAt(from);
    queueSongs.insert(to, song);
    _currentSongSubject.add(currentSong);
    _syncQueueToSystem();
    await _persistState();
  }

  /// Stops playback and empties the queue.
  Future<void> clearQueue() async {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    await _player.stop();
    queueSongs = const [];
    _countedSongId = null;
    _currentSongSubject.add(null);
    mediaItem.add(null);
    playbackState.add(PlaybackState());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queuePrefsKey);
    await prefs.remove(_statePrefsKey);
  }

  // ------------------------------------------------------------------
  // Playback controls
  // ------------------------------------------------------------------

  @override
  Future<void> play() async {
    if (queueSongs.isEmpty) return;
    await _player.play();
    _startPeriodicPositionSave();
    _persistState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _stopPeriodicPositionSave();
    _savePosition();
    _recordHistory(completed: false);
    _persistState();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queueSongs.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    if (!_player.hasNext) return;
    await _player.seekToNext();
    await _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      await _player.play();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _savePosition();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _persistState();
    _bumpChanges();
  }

  /// 0 = off, 1 = repeat all, 2 = repeat one.
  Future<void> updateRepeatMode(int mode) async {
    await _player.setLoopMode(switch (mode) {
      1 => LoopMode.all,
      2 => LoopMode.one,
      _ => LoopMode.off,
    });
    _persistState();
    _bumpChanges();
  }

  /// System repeat toggles (lock screen / headset) map to our int mode.
  Future<void> onSystemRepeatMode(AudioServiceRepeatMode audioMode) async {
    await updateRepeatMode(switch (audioMode) {
      AudioServiceRepeatMode.one => 2,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => 1,
      _ => 0,
    });
  }

  Future<void> setShuffleEnabled(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
    _persistState();
    _bumpChanges();
  }

  void _bumpChanges() => _changesSubject.add((_changesSubject.value) + 1);

  // ------------------------------------------------------------------
  // Sleep timer (with fade)
  // ------------------------------------------------------------------

  /// Countdown sleep timer; volume fades over the final 30 seconds.
  void startSleepTimer(int minutes) {
    _stopSleepTimer();
    _sleepTimerRemainingMs = minutes * 60 * 1000;
    _sleepRemainingSubject.add(_sleepTimerRemainingMs);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _sleepTimerRemainingMs -= 1000;
      _sleepRemainingSubject.add(max(0, _sleepTimerRemainingMs));
      if (_sleepTimerRemainingMs <= 0) {
        _player.setVolume(1.0);
        _player.pause();
        _stopSleepTimer();
      } else if (_sleepTimerRemainingMs <= 30 * 1000) {
        final volume = (_sleepTimerRemainingMs / (30 * 1000)).clamp(0.0, 1.0);
        _player.setVolume(volume);
      }
    });
  }

  /// Pauses when the current track finishes.
  void sleepAtEndOfTrack() {
    _stopSleepTimer();
    _sleepAtEndOfTrack = true;
    _sleepRemainingSubject.add(-1);
  }

  void cancelSleepTimer() => _stopSleepTimer();

  void _stopSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerRemainingMs = 0;
    _sleepAtEndOfTrack = false;
    _sleepRemainingSubject.add(null);
  }

  // ------------------------------------------------------------------
  // History
  // ------------------------------------------------------------------

  /// Counts the play for the current song once playback actually starts.
  void _recordHistory({required bool completed}) {
    final song = currentSong;
    if (song == null) return;
    if (_countedSongId == song.id && !completed) return;
    _countedSongId = song.id;
    _library
        .recordPlay(
          songId: song.id,
          positionMs: _player.position.inMilliseconds,
          completed: completed,
        )
        .catchError((Object e) {
      debugPrint('Timbre: history write failed for song ${song.id}: $e');
    });
  }

  void _savePosition() {
    final song = currentSong;
    if (song == null) return;
    _library
        .saveResumePosition(song.id, _player.position.inMilliseconds)
        .catchError((Object e) {
      debugPrint('Timbre: resume save failed for song ${song.id}: $e');
    });
  }

  void _startPeriodicPositionSave() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _savePosition();
      _recordHistory(completed: false);
    });
  }

  void _stopPeriodicPositionSave() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  // ------------------------------------------------------------------
  // Persistence (survives process death; restored on next launch)
  // ------------------------------------------------------------------

  Map<String, Object?> _songToJson(Song s) => {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'album': s.album,
        'genre': s.genre,
        'duration': s.durationMs,
        'track': s.trackNumber,
        'uri': s.uri,
        'filePath': s.filePath,
        'size': s.fileSize,
        'dateAdded': s.dateAdded.millisecondsSinceEpoch,
        'folder': s.folder,
        'albumId': s.albumId,
        'artistId': s.artistId,
      };

  Song _songFromJson(Map<String, Object?> m) => Song(
        id: m['id'] as int,
        title: m['title'] as String,
        artist: m['artist'] as String,
        album: m['album'] as String,
        genre: m['genre'] as String?,
        durationMs: m['duration'] as int,
        trackNumber: m['track'] as int?,
        uri: m['uri'] as String,
        filePath: m['filePath'] as String? ?? '',
        fileSize: m['size'] as int,
        dateAdded: DateTime.fromMillisecondsSinceEpoch(m['dateAdded'] as int),
        folder: m['folder'] as String,
        albumId: m['albumId'] as String,
        artistId: m['artistId'] as String,
      );

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (queueSongs.isEmpty) return;
      await prefs.setString(
          _queuePrefsKey, jsonEncode(queueSongs.map(_songToJson).toList()));
      await prefs.setString(_statePrefsKey, jsonEncode({
        'index': _player.currentIndex ?? 0,
        'position': _player.position.inMilliseconds,
        'playing': false, // never auto-play after process death
        'speed': _player.speed,
        'repeat': repeatMode,
        'shuffle': shuffleEnabled,
      }));
    } catch (e) {
      debugPrint('Timbre: queue persist failed: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueRaw = prefs.getString(_queuePrefsKey);
      if (queueRaw == null) return;
      final list = (jsonDecode(queueRaw) as List).cast<Map<String, Object?>>();
      if (list.isEmpty) return;
      final songs = list.map(_songFromJson).toList();
      final state =
          jsonDecode(prefs.getString(_statePrefsKey) ?? '{}') as Map<String, Object?>;
      final index = ((state['index'] as num?)?.toInt() ?? 0).clamp(0, songs.length - 1);
      await _setQueue(
        songs,
        index,
        initialPosition: Duration(milliseconds: (state['position'] as num?)?.toInt() ?? 0),
      );
      await updateRepeatMode((state['repeat'] as num?)?.toInt() ?? 0);
      await setSpeed((state['speed'] as num?)?.toDouble() ?? 1.0);
      if (state['shuffle'] as bool? ?? false) {
        await _player.setShuffleModeEnabled(true);
      }
    } catch (e) {
      debugPrint('Timbre: queue restore failed: $e');
    }
  }

  // ------------------------------------------------------------------
  // Artwork (disk cache in app documents; falls back to query on demand)
  // ------------------------------------------------------------------

  Future<Directory?> _resolveArtCacheDir() {
    return _artCacheDirFuture ??= getApplicationDocumentsDirectory()
        .then<Directory?>((dir) {
      final cacheDir = Directory(p.join(dir.path, 'art_cache'));
      if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
      _artCacheDir = cacheDir;
      return cacheDir;
    }).catchError((Object e) {
      debugPrint('Timbre: art cache dir unavailable: $e');
      return null;
    });
  }

  /// Cached artwork file for [albumId], downloading from MediaStore if needed.
  Future<File?> artworkFile(String albumId, {int size = 512}) async {
    final cacheDir = await _resolveArtCacheDir();
    if (cacheDir == null) return null;
    final file = File(p.join(cacheDir.path, '$albumId.jpg'));
    if (file.existsSync()) return file;
    final id = int.tryParse(albumId);
    if (id == null) return null;
    try {
      final bytes = await _query.queryArtwork(id, ArtworkType.ALBUM, size: size);
      if (bytes == null || bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      unawaited(_pruneArtCache(cacheDir));
      return file;
    } catch (e) {
      debugPrint('Timbre: artwork load failed for album $albumId: $e');
      return null;
    }
  }

  /// Known cache location for [albumId] without any I/O beyond existsSync,
  /// used for MediaItem artUri (system UIs may pick it up when it appears).
  Uri? artworkFileUri(String albumId) {
    final dir = _artCacheDir;
    if (dir == null) return null;
    final file = File(p.join(dir.path, '$albumId.jpg'));
    return file.existsSync() ? file.uri : null;
  }

  Future<void> _pruneArtCache(Directory cacheDir) async {
    try {
      final files = cacheDir.listSync().whereType<File>().toList();
      if (files.length <= _artCacheMaxEntries) return;
      files.sort((a, b) =>
          a.statSync().modified.compareTo(b.statSync().modified));
      for (final f in files.take(files.length - _artCacheMaxEntries)) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // audio_service overrides
  // ------------------------------------------------------------------

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    return queueSongs.map(_mediaItemFor).toList();
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'setSpeed':
        await setSpeed((extras?['speed'] as num?)?.toDouble() ?? 1.0);
      case 'sleepTimer':
        final minutes = (extras?['minutes'] as num?)?.toInt() ?? 0;
        if (minutes <= 0) {
          cancelSleepTimer();
        } else {
          startSleepTimer(minutes);
        }
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing in background; stop the service only when idle.
    if (!_player.playing) {
      await _player.stop();
    }
  }

  void dispose() {
    _stopSleepTimer();
    _stopPeriodicPositionSave();
    _indexSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    _currentSongSubject.close();
    _sleepRemainingSubject.close();
    _changesSubject.close();
  }
}

/// Minimal value-holding broadcast stream, avoiding an rxdart dependency.
class TimbreSubject<T> {
  final _controller = StreamController<T>.broadcast();
  T _value;

  TimbreSubject(this._value);

  T get value => _value;

  void add(T value) {
    _value = value;
    _controller.add(value);
  }

  Stream<T> get stream => _controller.stream;

  void close() {
    _controller.close();
  }
}
