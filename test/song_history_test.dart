import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timbre/data/library_repository.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE song_history(
        song_id INTEGER PRIMARY KEY,
        last_played_at INTEGER NOT NULL,
        play_count INTEGER NOT NULL DEFAULT 0,
        last_position_ms INTEGER NOT NULL DEFAULT 0,
        completed_count INTEGER NOT NULL DEFAULT 0
      )''');
  });

  tearDown(() async {
    await db.close();
  });

  Future<LibraryRepository> repo() async => LibraryRepository.forTest(db);

  test('recordPlay inserts then increments play counts', () async {
    final r = await repo();
    await r.recordPlay(songId: 42, positionMs: 1000, completed: true);
    await r.recordPlay(songId: 42, positionMs: 2000, completed: false);

    final stats = await r.loadPlayStats();
    expect(stats[42]!.playCount, 2);
    expect(stats[42]!.completedCount, 1);
    expect(stats[42]!.lastPositionMs, 2000);
  });

  test('saveResumePosition updates position without counting a play', () async {
    final r = await repo();
    await r.saveResumePosition(7, 5000);
    await r.saveResumePosition(7, 9000);

    final stats = await r.loadPlayStats();
    expect(stats[7]!.playCount, 0);
    expect(stats[7]!.lastPositionMs, 9000);
  });

  test('continue listening picks the most recent played song', () async {
    final r = await repo();
    await r.recordPlay(songId: 1, positionMs: 100, completed: false);
    // Fake an older timestamp for song 2.
    await db.insert('song_history', {
      'song_id': 2,
      'last_played_at': DateTime.now().millisecondsSinceEpoch - 100000,
      'play_count': 1,
      'last_position_ms': 200,
      'completed_count': 0,
    });

    final row = await r.loadContinueListening();
    expect(row!['song_id'], 1);
    expect(await r.loadRecentSongIds(limit: 5), [1, 2]);
  });

  test('clearHistory wipes resume data', () async {
    final r = await repo();
    await r.recordPlay(songId: 3, positionMs: 1000, completed: true);
    await r.clearHistory();
    expect(await r.loadPlayStats(), isEmpty);
    expect(await r.loadContinueListening(), isNull);
  });
}
