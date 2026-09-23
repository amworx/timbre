import 'package:flutter/services.dart';

import '../domain/models.dart';

/// Outcome of a single MediaStore delete request.
enum MediaDeleteStatus {
  /// The file is gone.
  deleted,

  /// The user denied the system "allow delete?" dialog.
  denied,

  /// The song has no usable MediaStore URI (not a library file).
  unavailable,

  /// Anything else (platform error, unexpected exception).
  failed,
}

class MediaDeleteOutcome {
  final MediaDeleteStatus status;
  final String? message;

  const MediaDeleteOutcome(this.status, [this.message]);
}

/// Returns the `content://` MediaStore URI for [song], or null when the
/// song only has a `file://` fallback that the delete bridge cannot use.
String? songContentUri(Song song) {
  final uri = song.uri.trim();
  if (uri.toLowerCase().startsWith('content://')) return uri;
  return null;
}

/// Returns true when [song] points at a real file on disk that can be
/// attached to a share sheet.
bool songHasShareableFile(Song song) => song.filePath.trim().isNotEmpty;

/// Guesses an audio MIME type from a file path for share-sheet previews.
/// Falls back to a generic binary type for unknown extensions.
String mimeForPath(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'mp3' => 'audio/mpeg',
    'm4a' || 'aac' => 'audio/mp4',
    'flac' => 'audio/flac',
    'ogg' || 'oga' => 'audio/ogg',
    'opus' => 'audio/opus',
    'wav' => 'audio/wav',
    'wma' => 'audio/x-ms-wma',
    'mid' || 'midi' => 'audio/midi',
    _ => 'application/octet-stream',
  };
}

/// Thin bridge over the native MediaStore delete flow
/// (`MainActivity.deleteMedia`): shows the system consent dialog on
/// Android 11+ and reports what happened. Never throws — transport and
/// platform problems become [MediaDeleteStatus.failed].
class MediaFiles {
  final MethodChannel _channel;

  MediaFiles({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('app.timbre.timbre/media');

  Future<MediaDeleteOutcome> deleteSong(Song song) async {
    final uri = songContentUri(song);
    if (uri == null) {
      return const MediaDeleteOutcome(
        MediaDeleteStatus.unavailable,
        'This song cannot be deleted from here.',
      );
    }
    try {
      final ok = await _channel.invokeMethod<bool>(
        'deleteMedia',
        {'contentUri': uri},
      );
      if (ok == true) {
        return const MediaDeleteOutcome(MediaDeleteStatus.deleted);
      }
      return const MediaDeleteOutcome(
        MediaDeleteStatus.denied,
        'Delete was not allowed.',
      );
    } on PlatformException catch (e) {
      return MediaDeleteOutcome(
        MediaDeleteStatus.failed,
        e.message ?? 'Delete failed.',
      );
    } catch (e) {
      // No native bridge (tests, desktop): report, never crash.
      return MediaDeleteOutcome(MediaDeleteStatus.failed, e.toString());
    }
  }
}
