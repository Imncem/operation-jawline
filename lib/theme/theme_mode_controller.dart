import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._mode);

  static const _prefKey = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  static Future<ThemeModeController> create() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);

    final mode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };

    return ThemeModeController(mode);
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
