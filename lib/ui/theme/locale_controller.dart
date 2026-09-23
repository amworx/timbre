import 'package:flutter/material.dart';

/// In-app language override, mirroring [ThemeController]: Settings updates
/// it, the root widget applies it to [MaterialApp.locale], and the choice
/// persists across launches. `null` locale = follow the system.
class LocaleController extends ChangeNotifier {
  static const keySystem = 'system';
  static const keyEnglish = 'en';
  static const keyArabic = 'ar';

  String _mode;

  LocaleController(String mode) : _mode = mode;

  String get mode => _mode;

  /// Null means "follow system" — [MaterialApp] then resolves the locale.
  Locale? get locale => switch (_mode) {
        keyEnglish => const Locale('en'),
        keyArabic => const Locale('ar'),
        _ => null,
      };

  void update(String persistedValue) {
    _mode = switch (persistedValue) {
      keyEnglish => keyEnglish,
      keyArabic => keyArabic,
      _ => keySystem,
    };
    notifyListeners();
  }
}
