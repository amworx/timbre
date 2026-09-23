import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';

import '../domain/flow_queue.dart' show PlayStat;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

import '../domain/models.dart';

/// Device music library via MediaStore (on_audio_query) + app-owned data (sqflite).
class LibraryRepository {
  final OnAudioQuery _query;
  final sqflite.Database db;

  LibraryRepository(this._query, this.db);

  /// Test-only constructor backed by an injected database (no MediaStore).
  LibraryRepository.forTest(this.db) : _query = OnAudioQuery();

  static const _schemaVersion = 1;

  /// Opens (or creates) the app database with a stable, simple schema.
  static Future<sqflite.Database> openDatabase() async {
    final dir = await sqflite.getDatabasesPath();
    return sqflite.openDatabase(
      p.join(dir, 'timbre.db'),
      version: _schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE song_history(
            song_id INTEGER PRIMARY KEY,
            last_played_at INTEGER NOT NULL,
            play_count INTEGER NOT NULL DEFAULT 0,
            last_position_ms INTEGER NOT NULL DEFAULT 0,
            completed_count INTEGER NOT NULL DEFAULT 0
          )''');
        await db.execute('''
          CREATE TABLE favorites(
            song_id INTEGER PRIMARY KEY,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE playlists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE playlist_songs(
            playlist_id INTEGER NOT NULL,
            song_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY(playlist_id, song_id),
            FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
          )''');
      },
    );
  }

  // ------------------------------------------------------------------
  // MediaStore (device library)
  // ------------------------------------------------------------------

  /// Loads every song MediaStore knows about, mapped to our [Song] model.
  Future<List<Song>> loadSongs() async {
    final raw = await _query.querySongs();
    return raw
        .map(_toSong)
        .whereType<Song>()
        .toList(growable: false);
  }

  Song? _toSong(SongModel m) {
    try {
      final title = m.title.trim();
      if (title.isEmpty) return null;
      final data = m.data;
      final folder = p.dirname(data);
      return Song(
        id: m.id,
        title: title,
        artist: _clean(m.artist, kUnknownArtist),
        album: _clean(m.album, kUnknownAlbum),
        albumArtist: null,
        genre: _cleanOrNull(m.genre),
        durationMs: m.duration ?? 0,
        trackNumber: m.track,
        uri: m.uri ?? _fileUri(data),
        mimeType: null,
        filePath: data,
        fileSize: m.size,
        dateAdded: DateTime.fromMillisecondsSinceEpoch(
          (m.dateAdded ?? 0) * 1000,
        ),
        folder: folder,
        albumId: '${m.albumId ?? m.album ?? 'u'}',
        artistId: '${m.artistId ?? m.artist ?? 'u'}',
      );
    } catch (_) {
      return null; // Malformed row: skip rather than fail the scan.
    }
  }

  String _fileUri(String path) => Uri.file(path).toString();

  String _clean(String? value, String fallback) {
    final v = value?.trim();
    if (v == null || v.isEmpty || v == '<unknown>') return fallback;
    return v;
  }

  String? _cleanOrNull(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty || v == '<unknown>') return null;
    return v;
  }

  /// Grouping helpers — computed in memory from the song list, which keeps
  /// MediaStore the single source of truth and avoids duplicated storage.
  List<Album> albumsOf(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      map.putIfAbsent(s.albumId, () => []).add(s);
    }
    final albums = map.entries.map((e) {
      final list = e.value..sort((a, b) {
        final t = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
        return t != 0 ? t : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return Album(
        id: e.key,
        name: list.first.album,
        artist: list.first.artist,
        songCount: list.length,
        totalDurationMs: list.fold(0, (sum, s) => sum + s.durationMs),
        firstSongId: list.first.id,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return albums;
  }

  List<Artist> artistsOf(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      map.putIfAbsent(s.artistId, () => []).add(s);
    }
    final artists = map.entries.map((e) {
      final list = e.value;
      return Artist(
        id: e.key,
        name: list.first.artist,
        songCount: list.length,
        albumCount: list.map((s) => s.albumId).toSet().length,
        firstSongId: list.first.id,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return artists;
  }

  List<Genre> genresOf(List<Song> songs) {
    final map = <String, List<Song>>{};
    for (final s in songs) {
      final g = s.genre;
      if (g == null || g.isEmpty) continue;
      map.putIfAbsent(g, () => []).add(s);
    }
    final genres = map.entries.map((e) {
      final list = e.value..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return Genre(name: e.key, songCount: list.length, firstSongId: list.first.id);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return genres;
  }

  List<FolderRef> foldersOf(List<Song> songs) {
    final map = <String, int>{};
    for (final s in songs) {
      map[s.folder] = (map[s.folder] ?? 0) + 1;
    }
    final folders = map.entries
        .map((e) => FolderRef(path: e.key, songCount: e.value))
        .toList()
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return folders;
  }

  /// Songs that belong to [folder] (exact directory match).
  List<Song> songsInFolder(List<Song> songs, String folder) =>
      songs.where((s) => s.folder == folder).toList(growable: false);

  // ------------------------------------------------------------------
  // Favorites
  // ------------------------------------------------------------------

  Future<Set<int>> loadFavoriteIds() async {
    final rows = await db.query('favorites');
    return rows.map((r) => r['song_id'] as int).toSet();
  }

  Future<void> setFavorite(int songId, bool favorite) async {
    if (favorite) {
      await db.insert('favorites', {
        'song_id': songId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
    } else {
      await db.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
    }
  }

  // ------------------------------------------------------------------
  // Listening history
  // ------------------------------------------------------------------

  /// Records a playback event: increments counts and stores the last position.
  Future<void> recordPlay({
    required int songId,
    required int positionMs,
    required bool completed,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert('''
      INSERT INTO song_history(song_id, last_played_at, play_count, last_position_ms, completed_count)
      VALUES(?, ?, 1, ?, ?)
      ON CONFLICT(song_id) DO UPDATE SET
        last_played_at = excluded.last_played_at,
        play_count = play_count + 1,
        last_position_ms = excluded.last_position_ms,
        completed_count = completed_count + excluded.completed_count
    ''', [songId, now, positionMs, completed ? 1 : 0]);
  }

  /// Stores just the resume position (frequent writes, no count changes).
  Future<void> saveResumePosition(int songId, int positionMs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert('''
      INSERT INTO song_history(song_id, last_played_at, play_count, last_position_ms, completed_count)
      VALUES(?, ?, 0, ?, 0)
      ON CONFLICT(song_id) DO UPDATE SET
        last_played_at = excluded.last_played_at,
        last_position_ms = excluded.last_position_ms
    ''', [songId, now, positionMs]);
  }

  Future<Map<int, PlayStat>> loadPlayStats() async {
    final rows = await db.query('song_history');
    return {
      for (final r in rows)
        r['song_id'] as int: PlayStat(
          playCount: r['play_count'] as int? ?? 0,
          completedCount: r['completed_count'] as int? ?? 0,
          lastPlayedAtMs: r['last_played_at'] as int? ?? 0,
          lastPositionMs: r['last_position_ms'] as int? ?? 0,
        ),
    };
  }

  /// Most recently played songs, newest first, ids only.
  Future<List<int>> loadRecentSongIds({int limit = 20}) async {
    final rows = await db.query(
      'song_history',
      where: 'play_count > 0',
      orderBy: 'last_played_at DESC',
      limit: limit,
    );
    return rows.map((r) => r['song_id'] as int).toList();
  }

  /// The single "continue listening" row: the last played, unfinished song.
  Future<Map<String, Object?>?> loadContinueListening() async {
    final rows = await db.query(
      'song_history',
      where: 'play_count > 0',
      orderBy: 'last_played_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return {
      'song_id': r['song_id'] as int,
      'position_ms': r['last_position_ms'] as int,
      'last_played_at': r['last_played_at'] as int,
    };
  }

  Future<void> clearHistory() async {
    await db.delete('song_history');
  }

  /// Removes every app-owned trace of [ids] (favorites, history, playlist
  /// entries) after the underlying files were deleted from MediaStore.
  /// Playlist positions are re-normalized so ordering stays gap-free.
  Future<void> purgeSongs(Set<int> ids) async {
    if (ids.isEmpty) return;
    final args = ids.toList(growable: false);
    final placeholders = List.filled(args.length, '?').join(',');
    await db.delete('favorites',
        where: 'song_id IN ($placeholders)', whereArgs: args);
    await db.delete('song_history',
        where: 'song_id IN ($placeholders)', whereArgs: args);
    final affected = await db.query(
      'playlist_songs',
      columns: const ['playlist_id'],
      distinct: true,
      where: 'song_id IN ($placeholders)',
      whereArgs: args,
    );
    await db.delete('playlist_songs',
        where: 'song_id IN ($placeholders)', whereArgs: args);
    for (final row in affected) {
      await _normalizePositions(row['playlist_id'] as int);
    }
  }

  // ------------------------------------------------------------------
  // Playlists
  // ------------------------------------------------------------------

  Future<List<Playlist>> loadPlaylists() async {
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.created_at, p.updated_at, COUNT(ps.song_id) AS song_count
      FROM playlists p LEFT JOIN playlist_songs ps ON ps.playlist_id = p.id
      GROUP BY p.id ORDER BY p.updated_at DESC
    ''');
    return rows.map((r) => Playlist(
      id: r['id'] as int,
      name: r['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      songCount: r['song_count'] as int? ?? 0,
    )).toList();
  }

  Future<int> createPlaylist(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('playlists', {'name': name, 'created_at': now, 'updated_at': now});
  }

  Future<void> renamePlaylist(int id, String name) async {
    await db.update('playlists', {'name': name, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(int id) async {
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final existing = await db.query('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': existing.length,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
    await _touchPlaylist(playlistId);
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await db.delete('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?', whereArgs: [playlistId, songId]);
    await _normalizePositions(playlistId);
    await _touchPlaylist(playlistId);
  }

  Future<void> reorderPlaylistSong(int playlistId, int songId, int newPosition) async {
    final rows = await db.query('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId],
        orderBy: 'position');
    final ids = rows.map((r) => r['song_id'] as int).toList();
    ids.remove(songId);
    final clamped = newPosition.clamp(0, ids.length);
    ids.insert(clamped, songId);
    await db.transaction((txn) async {
      for (var i = 0; i < ids.length; i++) {
        await txn.update('playlist_songs', {'position': i},
            where: 'playlist_id = ? AND song_id = ?',
            whereArgs: [playlistId, ids[i]]);
      }
    });
    await _touchPlaylist(playlistId);
  }

  Future<List<int>> loadPlaylistSongIds(int playlistId) async {
    final rows = await db.query('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId], orderBy: 'position');
    return rows.map((r) => r['song_id'] as int).toList();
  }

  Future<void> _touchPlaylist(int playlistId) async {
    await db.update('playlists', {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> _normalizePositions(int playlistId) async {
    final rows = await db.query('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId], orderBy: 'position');
    final ids = rows.map((r) => r['song_id'] as int).toList();
    await db.transaction((txn) async {
      for (var i = 0; i < ids.length; i++) {
        await txn.update('playlist_songs', {'position': i},
            where: 'playlist_id = ? AND song_id = ?',
            whereArgs: [playlistId, ids[i]]);
      }
    });
  }

  // ------------------------------------------------------------------
  // Artwork
  // ------------------------------------------------------------------

  /// Album artwork bytes, or null when the file has none.
  Future<Uint8List?> artwork(String albumId, {int size = 512}) async {
    final id = int.tryParse(albumId);
    if (id == null) return null;
    try {
      return await _query.queryArtwork(id, ArtworkType.ALBUM, size: size);
    } catch (_) {
      return null;
    }
  }
}
