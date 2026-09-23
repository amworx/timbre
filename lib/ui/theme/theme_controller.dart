import 'package:flutter/material.dart';

/// Theme-mode controller exposed through provider; Settings updates it and
/// the root widget applies it. Persisted by the caller (SharedPreferences).
class ThemeController extends ChangeNotifier {
  ThemeMode mode;

  ThemeController(this.mode);

  void update(String persistedValue) {
    mode = switch (persistedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }
}
