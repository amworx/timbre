import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/domain/models.dart';
import 'package:timbre/media/media_files.dart';
import 'package:timbre/ui/components/song_selection.dart';

Song song({
  int id = 1,
  String uri = 'content://media/external/audio/media/1',
  String filePath = '/music/song.mp3',
}) =>
    Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      album: 'Album',
      durationMs: 200000,
      uri: uri,
      filePath: filePath,
      fileSize: 1,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(0),
      folder: '/music',
      albumId: 'a',
      artistId: 'ar',
    );

void main() {
  group('songContentUri', () {
    test('accepts content URIs case-insensitively', () {
      expect(songContentUri(song()), startsWith('content://'));
      expect(
        songContentUri(song(uri: 'CONTENT://media/1')),
        'CONTENT://media/1',
      );
    });

    test('rejects file fallbacks and blanks', () {
      expect(songContentUri(song(uri: 'file:///music/s.mp3')), isNull);
      expect(songContentUri(song(uri: '  ')), isNull);
    });
  });

  group('songHasShareableFile', () {
    test('needs a non-blank path', () {
      expect(songHasShareableFile(song()), isTrue);
      expect(songHasShareableFile(song(filePath: '')), isFalse);
      expect(songHasShareableFile(song(filePath: '   ')), isFalse);
    });
  });

  group('mimeForPath', () {
    test('maps common audio extensions', () {
      expect(mimeForPath('a.mp3'), 'audio/mpeg');
      expect(mimeForPath('a.M4A'), 'audio/mp4');
      expect(mimeForPath('a.flac'), 'audio/flac');
      expect(mimeForPath('a.ogg'), 'audio/ogg');
      expect(mimeForPath('a.opus'), 'audio/opus');
      expect(mimeForPath('a.wav'), 'audio/wav');
    });

    test('falls back for unknown extensions', () {
      expect(mimeForPath('a.xyz'), 'application/octet-stream');
      expect(mimeForPath('noext'), 'application/octet-stream');
    });
  });

  group('SongSelection', () {
    test('toggle / clear / selectAll round-trip', () {
      final sel = SongSelection();
      expect(sel.isSelecting, isFalse);

      sel.toggle(1);
      sel.toggle(2);
      expect(sel.isSelecting, isTrue);
      expect(sel.count, 2);
      expect(sel.isSelected(1), isTrue);

      sel.toggle(1);
      expect(sel.isSelected(1), isFalse);
      expect(sel.count, 1);

      sel.selectAll([1, 2, 3]);
      expect(sel.count, 3);

      sel.clear();
      expect(sel.isSelecting, isFalse);
      expect(sel.ids, isEmpty);
    });

    test('ids are an unmodifiable snapshot', () {
      final sel = SongSelection()..toggle(7);
      expect(() => sel.ids.add(8), throwsUnsupportedError);
    });
  });

  group('MediaFiles.deleteSong', () {
    test('unavailable without a content URI — never throws', () async {
      final outcome = await MediaFiles()
          .deleteSong(song(uri: 'file:///music/s.mp3'));
      expect(outcome.status, MediaDeleteStatus.unavailable);
    });

    test('failed without a native bridge — never throws', () async {
      // flutter_test has no platform channels: must degrade gracefully.
      final outcome = await MediaFiles().deleteSong(song());
      expect(outcome.status, MediaDeleteStatus.failed);
      expect(outcome.message, isNotEmpty);
    });
  });
}
