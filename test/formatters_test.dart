import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/l10n/app_localizations.dart';
import 'package:timbre/ui/components/formatters.dart';

Future<AppLocalizations> english() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<AppLocalizations> arabic() =>
    AppLocalizations.delegate.load(const Locale('ar'));

void main() {
  test('formats durations as m:ss below one hour', () {
    expect(formatDuration(const Duration(seconds: 5)), '0:05');
    expect(formatDuration(const Duration(minutes: 2, seconds: 41)), '2:41');
    expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
  });

  test('formats durations as h:mm:ss at or above one hour', () {
    expect(formatDuration(const Duration(hours: 1)), '1:00:00');
    expect(formatDuration(const Duration(hours: 2, minutes: 3, seconds: 4)), '2:03:04');
  });

  test('formats totals and counts in English', () async {
    final t = await english();
    expect(formatTotalDuration(t, 150 * 60 * 1000), '2 h 30 min');
    expect(formatTotalDuration(t, 9 * 60 * 1000), '9 min');
    expect(songsLabel(t, 0), 'No songs');
    expect(songsLabel(t, 1), '1 song');
    expect(songsLabel(t, 12), '12 songs');
    expect(remainingLabel(t, 161000), '2:41 remaining');
  });

  test('formats totals and counts in Arabic', () async {
    final t = await arabic();
    expect(songsLabel(t, 0), isNotEmpty);
    expect(songsLabel(t, 1), isNot(songsLabel(t, 2)));
    expect(songsLabel(t, 2), isNot(songsLabel(t, 5)));
    expect(formatTotalDuration(t, 9 * 60 * 1000), isNotEmpty);
    expect(remainingLabel(t, 161000), contains('2:41'));
    // Arabic strings must actually differ from the English source.
    final en = await english();
    expect(songsLabel(t, 12), isNot(songsLabel(en, 12)));
  });
}
