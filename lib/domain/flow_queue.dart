import 'dart:math';

import '../l10n/app_localizations.dart';
import 'models.dart';

/// Local listening-memory snapshot used to score Flow candidates.
class ListeningSnapshot {
  final Map<int, PlayStat> stats; // songId -> stat
  final Set<int> favoriteIds;

  const ListeningSnapshot({required this.stats, required this.favoriteIds});

  static const empty = ListeningSnapshot(stats: {}, favoriteIds: {});
}

/// Per-song aggregate from the local history tables.
class PlayStat {
  final int playCount;
  final int completedCount;
  final int lastPlayedAtMs;
  final int lastPositionMs;

  const PlayStat({
    required this.playCount,
    required this.completedCount,
    required this.lastPlayedAtMs,
    this.lastPositionMs = 0,
  });
}

/// The Flow Queue algorithm.
///
/// Score candidates by:
///   1. same artist        +5
///   2. same album         +3
///   3. same genre         +2
///   4. favorite           +2
///   5. frequently played  +1 (playCount >= 3)
///   6. not played recently +1 (never played or idle > 14 days)
///   7. exclude current song, exclude duplicates
/// Then shuffle within same-score groups (seeded => deterministic).
/// Deterministic, explainable, local — no cloud anything.
class FlowQueue {
  static const artistScore = 5;
  static const albumScore = 3;
  static const genreScore = 2;
  static const favoriteScore = 2;
  static const frequentScore = 1;
  static const freshScore = 1;
  static const recentPlayedWindowMs = 14 * 24 * 3600 * 1000;

  /// Returns [count] songs scored and ordered for a Flow queue.
  static List<Song> build({
    required Song current,
    required List<Song> library,
    required ListeningSnapshot snapshot,
    required int nowMs,
    int count = 50,
    int seed = 0,
  }) {
    final now = nowMs;
    int scoreOf(Song s) {
      var score = 0;
      if (s.artistId == current.artistId) score += artistScore;
      if (s.albumId == current.albumId) score += albumScore;
      final g = s.genre;
      if (g != null && g.isNotEmpty && g == current.genre) score += genreScore;
      if (snapshot.favoriteIds.contains(s.id)) score += favoriteScore;
      final stat = snapshot.stats[s.id];
      if (stat != null) {
        if (stat.playCount >= 3) score += frequentScore;
        if (now - stat.lastPlayedAtMs > recentPlayedWindowMs) score += freshScore;
      } else {
        // Never played: counts as fresh.
        score += freshScore;
      }
      return score;
    }

    final candidates = library
        .where((s) => s.id != current.id)
        .map((s) => (song: s, score: scoreOf(s)))
        .toList();

    // Group by score, shuffle within each group with a seeded RNG so the
    // result is reproducible for a given (song, library, history) input.
    final rng = Random(seed);
    final byScore = <int, List<Song>>{};
    for (final c in candidates) {
      byScore.putIfAbsent(c.score, () => []).add(c.song);
    }
    final scores = byScore.keys.toList()..sort((a, b) => b - a);
    final result = <Song>[];
    for (final score in scores) {
      result.addAll(shuffleSeeded(byScore[score]!, rng));
    }
    return result.take(count).toList();
  }

  /// Human-readable explanation shown under the Flow title.
  /// Takes the locale's strings so the UI owns the language.
  static String explanation(
      Song current, ListeningSnapshot snapshot, AppLocalizations t) {
    final hasFavorites = snapshot.favoriteIds.isNotEmpty;
    final stat = snapshot.stats[current.id];
    final known = stat != null && stat.playCount > 0;
    if (hasFavorites && known) return t.flowRecent;
    if (hasFavorites) return t.flowSocial;
    if (known) return t.flowArtist;
    return t.flowPlain;
  }
}
