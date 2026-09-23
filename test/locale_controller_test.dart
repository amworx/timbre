import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/ui/theme/locale_controller.dart';

void main() {
  group('LocaleController', () {
    test('system by default resolves to a null locale', () {
      final c = LocaleController(LocaleController.keySystem);
      expect(c.mode, LocaleController.keySystem);
      expect(c.locale, isNull);
    });

    test('en/ar modes resolve to matching locales', () {
      expect(LocaleController(LocaleController.keyEnglish).locale,
          const Locale('en'));
      expect(LocaleController(LocaleController.keyArabic).locale,
          const Locale('ar'));
    });

    test('update remaps modes and notifies', () {
      final c = LocaleController(LocaleController.keySystem);
      var notified = 0;
      c.addListener(() => notified++);

      c.update('ar');
      expect(c.mode, 'ar');
      expect(c.locale, const Locale('ar'));
      expect(notified, 1);

      c.update('nonsense');
      expect(c.mode, LocaleController.keySystem);
      expect(c.locale, isNull);
      expect(notified, 2);
    });
  });
}
