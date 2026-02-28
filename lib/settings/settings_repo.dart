import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepo {
  static const soundEnabledKey = 'soundEnabled';
  static const hapticsEnabledKey = 'hapticsEnabled';
  static const _legacySettingsKey = 'app_settings_v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();

    bool? sound = prefs.getBool(soundEnabledKey);
    bool? haptics = prefs.getBool(hapticsEnabledKey);

    if (sound == null || haptics == null) {
      final legacyRaw = prefs.getString(_legacySettingsKey);
      if (legacyRaw != null && legacyRaw.isNotEmpty) {
        try {
          final map = jsonDecode(legacyRaw) as Map<String, dynamic>;
          sound ??= map['soundEnabled'] as bool?;
          haptics ??= map['hapticsEnabled'] as bool?;
        } catch (e) {
          // ignore malformed legacy payload and fall back to defaults.
        }
      }
    }

    final resolved = AppSettings(
      soundEnabled: sound ?? defaults.soundEnabled,
      hapticsEnabled: haptics ?? defaults.hapticsEnabled,
    );
    await save(resolved);
    return resolved;
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(hapticsEnabledKey, settings.hapticsEnabled);
  }
}
