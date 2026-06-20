import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const _storageKey = 'binlink_theme_mode';

  ThemeMode get themeMode => _themeMode;

  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    _themeMode = switch (stored) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }
}
