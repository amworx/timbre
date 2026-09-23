import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/ui/components/formatters.dart';

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

  test('formats totals and counts', () {
    expect(formatTotalDuration(150 * 60 * 1000), '2 h 30 min');
    expect(formatTotalDuration(9 * 60 * 1000), '9 min');
    expect(songsLabel(1), '1 song');
    expect(songsLabel(12), '12 songs');
    expect(remainingLabel(161000), '2:41 remaining');
  });
}
