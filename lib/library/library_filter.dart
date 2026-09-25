import '../domain/models.dart';

/// What the library shows. Everything is opt-out: by default the whole
/// device library is listed; the user hides folders or short clips in
/// Settings → Library filters. Pure and fully unit-tested.
class LibraryFilter {
  final Set<String> excludedFolders;
  final int minDurationMs;

  const LibraryFilter({
    this.excludedFolders = const {},
    this.minDurationMs = 0,
  });

  bool get isOff => excludedFolders.isEmpty && minDurationMs <= 0;

  List<Song> apply(List<Song> songs) => songs.where((s) {
        if (minDurationMs > 0 && s.durationMs < minDurationMs) return false;
        if (excludedFolders.contains(s.folder)) return false;
        return true;
      }).toList(growable: false);
}

/// True for chat-app audio folders (voice notes, received clips), e.g.
/// `…/WhatsApp/Media/WhatsApp Voice Notes` or `…/Telegram/Telegram Audio`.
/// Powers the one-tap "hide messaging audio" button — matching is by folder
/// name only and never deletes anything.
bool isMessagingAudioFolder(String path) {
  final p = path.toLowerCase();
  if (p.contains('whatsapp')) return true;
  if (!p.contains('telegram')) return false;
  return p.contains('voice') || p.contains('audio');
}

/// Subset of [folders] that look like messaging audio.
List<String> messagingAudioFolders(Iterable<String> folders) =>
    folders.where(isMessagingAudioFolder).toList(growable: false);
