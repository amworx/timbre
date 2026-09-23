import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/ui/components/song_selection.dart';

void main() {
  group('selectionBarBottom', () {
    test('clears the nav bar plus gesture inset without a mini player', () {
      // 68 (nav) + 0 (no mini) + 12 (gap), plus the system inset.
      expect(selectionBarBottom(systemBottom: 0, miniVisible: false), 80);
      expect(selectionBarBottom(systemBottom: 24, miniVisible: false), 104);
    });

    test('adds mini-player height when one is showing', () {
      expect(
        selectionBarBottom(systemBottom: 24, miniVisible: true),
        greaterThan(
            selectionBarBottom(systemBottom: 24, miniVisible: false)),
      );
      expect(selectionBarBottom(systemBottom: 24, miniVisible: true), 174);
    });
  });
}
