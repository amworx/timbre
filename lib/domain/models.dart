/// Domain models for Timbre.
///
/// These are plain Dart types independent from plugin models, so the rest of
/// the app (UI, playback, Flow queue) never depends on on_audio_query shapes.
library;

import 'dart:math';

/// Fallbacks stored when MediaStore has no value. Kept in English in the
/// model; UI translates them at display time via `displayArtist`/`displayAlbum`.
const kUnknownArtist = 'Unknown artist';
const kUnknownAlbum = 'Unknown album';

/// A single track from the device library.
class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int durationMs;
  final int? trackNumber;
  final String uri;
  final String? mimeType;
  final String filePath;
  final int fileSize;
  final DateTime dateAdded;
  final String folder;
  final String albumId;
  final String artistId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.genre,
    required this.durationMs,
    this.trackNumber,
    required this.uri,
    this.mimeType,
    this.filePath = '',
    required this.fileSize,
    required this.dateAdded,
    required this.folder,
    required this.albumId,
    required this.artistId,
  });

  String get displayArtist => artist;
  String get displayAlbum => album;
}

/// An album grouped from songs.
class Album {
  final String id;
  final String name;
  final String artist;
  final int songCount;
  final int totalDurationMs;
  final int firstSongId;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.songCount,
    required this.totalDurationMs,
    required this.firstSongId,
  });
}

/// An artist grouped from songs.
class Artist {
  final String id;
  final String name;
  final int songCount;
  final int albumCount;
  final int firstSongId;

  const Artist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.albumCount,
    required this.firstSongId,
  });
}

/// A genre grouped from songs.
class Genre {
  final String name;
  final int songCount;
  final int firstSongId;

  const Genre({required this.name, required this.songCount, required this.firstSongId});
}

/// A folder that contains music files.
class FolderRef {
  final String path;
  final int songCount;

  const FolderRef({required this.path, required this.songCount});

  String get name => path.split('/').where((p) => p.isNotEmpty).last;
}

/// A user-created playlist (Favorites and Recently Played are views, not rows).
class Playlist {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int songCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.songCount,
  });
}

/// Deterministic Flow queue flavors (MVP keeps a single default flavor).
enum FlowKind { fresh }

/// A fully resolved queue to hand to the player.
class QueueSpec {
  final List<Song> songs;
  final int startIndex;
  final String title;
  final String subtitle;
  final FlowKind kind;

  const QueueSpec({
    required this.songs,
    required this.startIndex,
    required this.title,
    required this.subtitle,
    this.kind = FlowKind.fresh,
  });
}

/// Deterministic shuffling so queues are debuggable and reproducible.
List<T> shuffleSeeded<T>(List<T> items, Random rng) {
  final list = List<T>.of(items);
  for (var i = list.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}
