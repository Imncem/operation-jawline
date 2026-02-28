import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_settings.dart';

class ReminderSettingsRepo {
  static const workoutReminderEnabledKey = 'workoutReminderEnabled';
  static const checkInReminderEnabledKey = 'checkInReminderEnabled';
  static const workoutReminderHourKey = 'workoutReminderHour';
  static const workoutReminderMinuteKey = 'workoutReminderMinute';
  static const checkInReminderHourKey = 'checkInReminderHour';
  static const checkInReminderMinuteKey = 'checkInReminderMinute';

  Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = ReminderSettings.defaults();
    return ReminderSettings(
      workoutReminderEnabled: prefs.getBool(workoutReminderEnabledKey) ??
          defaults.workoutReminderEnabled,
      checkInReminderEnabled: prefs.getBool(checkInReminderEnabledKey) ??
          defaults.checkInReminderEnabled,
      workoutReminderHour:
          prefs.getInt(workoutReminderHourKey) ?? defaults.workoutReminderHour,
      workoutReminderMinute: prefs.getInt(workoutReminderMinuteKey) ??
          defaults.workoutReminderMinute,
      checkInReminderHour:
          prefs.getInt(checkInReminderHourKey) ?? defaults.checkInReminderHour,
      checkInReminderMinute: prefs.getInt(checkInReminderMinuteKey) ??
          defaults.checkInReminderMinute,
    );
  }

  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      workoutReminderEnabledKey,
      settings.workoutReminderEnabled,
    );
    await prefs.setBool(
      checkInReminderEnabledKey,
      settings.checkInReminderEnabled,
    );
    await prefs.setInt(workoutReminderHourKey, settings.workoutReminderHour);
    await prefs.setInt(
      workoutReminderMinuteKey,
      settings.workoutReminderMinute,
    );
    await prefs.setInt(checkInReminderHourKey, settings.checkInReminderHour);
    await prefs.setInt(
      checkInReminderMinuteKey,
      settings.checkInReminderMinute,
    );
  }
}
