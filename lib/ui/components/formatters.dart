/// Formatting helpers shared across screens.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

String formatDurationMs(int ms) => formatDuration(Duration(milliseconds: ms));

String remainingLabel(int remainingMs) =>
    '${formatDurationMs(remainingMs)} remaining';

/// "2 h 14 min" style total duration for albums/queues.
String formatTotalDuration(int ms) {
  final d = Duration(milliseconds: ms);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '$h h $m min';
  return '$m min';
}

String songsLabel(int count) =>
    '$count ${count == 1 ? 'song' : 'songs'}';
