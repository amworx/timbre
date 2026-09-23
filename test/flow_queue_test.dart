import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/domain/flow_queue.dart';
import 'package:timbre/domain/models.dart';

Song _song(int id, {String? artistId, String? albumId, String? genre}) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist ${artistId ?? id}',
      album: 'Album ${albumId ?? id}',
      genre: genre,
      durationMs: 200000,
      uri: 'file:///song$id.mp3',
      fileSize: 1,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
      folder: '/music',
      albumId: albumId ?? 'a$id',
      artistId: artistId ?? 'ar$id',
    );

void main() {
  const now = 1000000000000;

  test('excludes the current song and deduplicates', () {
    final current = _song(1, artistId: 'ar1');
    final library = [current, _song(1, artistId: 'ar1'), _song(2, artistId: 'ar1')];
    final result = FlowQueue.build(
      current: current,
      library: library,
      snapshot: ListeningSnapshot.empty,
      nowMs: now,
    );
    expect(result.every((s) => s.id != 1), isTrue);
    expect(result.map((s) => s.id).toSet().length, result.length);
  });

  test('ranks same-artist songs above unrelated songs', () {
    final current = _song(1, artistId: 'ar1', genre: 'Rock');
    final sameArtist = _song(2, artistId: 'ar1', genre: 'Rock');
    final unrelated = _song(3, artistId: 'ar9', genre: 'Jazz');
    final result = FlowQueue.build(
      current: current,
      library: [unrelated, sameArtist],
      snapshot: ListeningSnapshot.empty,
      nowMs: now,
    );
    expect(result.first.id, sameArtist.id);
  });

  test('favorites rank above identical non-favorites', () {
    final current = _song(1, artistId: 'ar1');
    final fav = _song(2, artistId: 'ar1');
    final plain = _song(3, artistId: 'ar1');
    final result = FlowQueue.build(
      current: current,
      library: [plain, fav],
      snapshot: const ListeningSnapshot(stats: {}, favoriteIds: {2}),
      nowMs: now,
    );
    expect(result.first.id, fav.id);
  });

  test('is deterministic for the same inputs', () {
    final current = _song(1, artistId: 'ar1');
    final library = List.generate(20, (i) => _song(i + 2, artistId: 'ar${i % 4}'));
    final a = FlowQueue.build(
      current: current,
      library: library,
      snapshot: ListeningSnapshot.empty,
      nowMs: now,
      seed: 7,
    );
    final b = FlowQueue.build(
      current: current,
      library: library,
      snapshot: ListeningSnapshot.empty,
      nowMs: now,
      seed: 7,
    );
    expect(a.map((s) => s.id).toList(), b.map((s) => s.id).toList());
  });

  test('caps the queue length', () {
    final current = _song(1);
    final library = List.generate(100, (i) => _song(i + 2));
    final result = FlowQueue.build(
      current: current,
      library: library,
      snapshot: ListeningSnapshot.empty,
      nowMs: now,
      count: 25,
    );
    expect(result.length, 25);
  });

  test('recently-played frequent songs lose the freshness bonus', () {
    final current = _song(1, artistId: 'ar1');
    final stale = _song(2, artistId: 'ar1');
    final fresh = _song(3, artistId: 'ar1');
    final result = FlowQueue.build(
      current: current,
      library: [stale, fresh],
      snapshot: ListeningSnapshot(stats: {
        2: const PlayStat(playCount: 5, completedCount: 5, lastPlayedAtMs: now),
        3: const PlayStat(playCount: 5, completedCount: 5, lastPlayedAtMs: now - 30 * 24 * 3600 * 1000),
      }, favoriteIds: {}),
      nowMs: now,
    );
    expect(result.first.id, fresh.id);
  });

  test('explanation reflects listening state', () {
    final song = _song(1);
    expect(
      FlowQueue.explanation(song, ListeningSnapshot.empty),
      'Built from your library',
    );
    expect(
      FlowQueue.explanation(
        song,
        const ListeningSnapshot(stats: {}, favoriteIds: {5}),
      ),
      'Similar artist + your favorites',
    );
  });
}
