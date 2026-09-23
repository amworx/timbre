import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Arabic catalog must carry exactly the same keys as the English
/// template — a missing key silently falls back to English in the UI.
void main() {
  test('ar catalog matches en keys, with real translations', () {
    final en = jsonDecode(
        File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final ar = jsonDecode(
        File('lib/l10n/app_ar.arb').readAsStringSync()) as Map<String, dynamic>;

    final enKeys =
        en.keys.where((k) => !k.startsWith('@')).toSet();
    final arKeys =
        ar.keys.where((k) => !k.startsWith('@')).toSet();

    expect(arKeys.difference(enKeys), isEmpty,
        reason: 'ar has keys missing from en');
    expect(enKeys.difference(arKeys), isEmpty,
        reason: 'ar is missing keys (UI would fall back to English)');

    // Spot-check that translations are not just copies of the source.
    var translated = 0;
    for (final k in enKeys) {
      if (en[k] != ar[k]) translated++;
    }
    expect(translated, greaterThan(enKeys.length ~/ 2));
  });
}
