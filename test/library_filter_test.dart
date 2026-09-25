import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/domain/models.dart';
import 'package:timbre/library/library_filter.dart';

Song song({int id = 1, int durationMs = 200000, String folder = '/music'}) =>
    Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      album: 'Album',
      durationMs: durationMs,
      uri: 'content://media/$id',
      filePath: '/music/s$id.mp3',
      fileSize: 1,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
      folder: folder,
      albumId: 'a',
      artistId: 'ar',
    );

void main() {
  group('LibraryFilter.apply', () {
    test('off filter keeps everything', () {
      final songs = [song(id: 1), song(id: 2, durationMs: 3000)];
      expect(const LibraryFilter().apply(songs), hasLength(2));
    });

    test('drops clips shorter than the minimum', () {
      const f = LibraryFilter(minDurationMs: 30000);
      final songs = [
        song(id: 1, durationMs: 29999),
        song(id: 2, durationMs: 30000),
        song(id: 3, durationMs: 120000),
      ];
      final out = f.apply(songs);
      expect(out.map((s) => s.id), [2, 3]);
    });

    test('drops excluded folders by exact path', () {
      const f = LibraryFilter(excludedFolders: {'/wa/notes'});
      final songs = [
        song(id: 1, folder: '/wa/notes'),
        song(id: 2, folder: '/wa/audio'),
        song(id: 3, folder: '/music'),
      ];
      expect(f.apply(songs).map((s) => s.id), [2, 3]);
    });

    test('combines both rules', () {
      const f = LibraryFilter(
          excludedFolders: {'/wa/notes'}, minDurationMs: 30000);
      final songs = [
        song(id: 1, folder: '/wa/notes', durationMs: 90000),
        song(id: 2, folder: '/music', durationMs: 5000),
        song(id: 3, folder: '/music', durationMs: 90000),
      ];
      expect(f.apply(songs).map((s) => s.id), [3]);
    });
  });

  group('isMessagingAudioFolder', () {
    test('spots WhatsApp and Telegram voice/audio dirs', () {
      expect(
          isMessagingAudioFolder(
              '/storage/WhatsApp/Media/WhatsApp Voice Notes'),
          isTrue);
      expect(
          isMessagingAudioFolder('/storage/WhatsApp/Media/WhatsApp Audio'),
          isTrue);
      expect(
          isMessagingAudioFolder('/storage/Telegram/Telegram Audio'),
          isTrue);
      expect(isMessagingAudioFolder('/Music'), isFalse);
      expect(isMessagingAudioFolder('/Telegram/Music Channel'), isFalse);
      expect(isMessagingAudioFolder('/Ringtones'), isFalse);
    });

    test('messagingAudioFolders picks matches only', () {
      expect(
        messagingAudioFolders(['/Music', '/WhatsApp/Media/WhatsApp Audio']),
        ['/WhatsApp/Media/WhatsApp Audio'],
      );
    });
  });
}
