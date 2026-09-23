import '../../l10n/app_localizations.dart';

/// Formatting helpers shared across screens. Durations are plain numbers
/// (locale-independent); every word around them comes from [AppLocalizations].
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

String formatDurationMs(int ms) => formatDuration(Duration(milliseconds: ms));

String remainingLabel(AppLocalizations t, int remainingMs) =>
    '${formatDurationMs(remainingMs)} ${t.remainingWord}';

/// Album/queue totals, e.g. "2 h 30 min" / "٩ دقيقة" equivalents.
String formatTotalDuration(AppLocalizations t, int ms) {
  final d = Duration(milliseconds: ms);
  return t.totalDuration(d.inHours, d.inMinutes.remainder(60));
}

String songsLabel(AppLocalizations t, int count) => t.songsCount(count);
