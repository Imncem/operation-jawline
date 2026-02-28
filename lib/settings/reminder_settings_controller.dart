import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'reminder_settings.dart';
import 'reminder_settings_repo.dart';

final reminderSettingsRepoProvider =
    Provider<ReminderSettingsRepo>((ref) => ReminderSettingsRepo());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

class ReminderSettingsController
    extends StateNotifier<AsyncValue<ReminderSettings>> {
  ReminderSettingsController(this._repo, this._notifications)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final ReminderSettingsRepo _repo;
  final NotificationService _notifications;

  Future<void> _load() async {
    await _notifications.initialize();
    final settings = await _repo.load();
    state = AsyncValue.data(settings);
    await _notifications.syncReminders(settings);
  }

  ReminderSettings get _current => state.value ?? ReminderSettings.defaults();

  Future<bool> setWorkoutReminderEnabled(bool enabled) async {
    if (enabled && !await _notifications.requestPermission()) {
      return false;
    }

    final next = _current.copyWith(workoutReminderEnabled: enabled);
    await _repo.save(next);
    state = AsyncValue.data(next);
    if (enabled) {
      await _notifications.scheduleWorkoutReminder(next);
    } else {
      await _notifications.cancelWorkoutReminder();
    }
    return true;
  }

  Future<bool> setCheckInReminderEnabled(bool enabled) async {
    if (enabled && !await _notifications.requestPermission()) {
      return false;
    }

    final next = _current.copyWith(checkInReminderEnabled: enabled);
    await _repo.save(next);
    state = AsyncValue.data(next);
    if (enabled) {
      await _notifications.scheduleCheckInReminder(next);
    } else {
      await _notifications.cancelCheckInReminder();
    }
    return true;
  }

  Future<bool> updateWorkoutReminderTime(TimeOfDay time) async {
    if (_current.workoutReminderEnabled &&
        !await _notifications.requestPermission()) {
      return false;
    }

    final next = _current.copyWith(
      workoutReminderHour: time.hour,
      workoutReminderMinute: time.minute,
    );
    await _repo.save(next);
    state = AsyncValue.data(next);
    if (next.workoutReminderEnabled) {
      await _notifications.scheduleWorkoutReminder(next);
    }
    return true;
  }

  Future<bool> updateCheckInReminderTime(TimeOfDay time) async {
    if (_current.checkInReminderEnabled &&
        !await _notifications.requestPermission()) {
      return false;
    }

    final next = _current.copyWith(
      checkInReminderHour: time.hour,
      checkInReminderMinute: time.minute,
    );
    await _repo.save(next);
    state = AsyncValue.data(next);
    if (next.checkInReminderEnabled) {
      await _notifications.scheduleCheckInReminder(next);
    }
    return true;
  }

  Future<bool> showTestNotification() async {
    if (!await _notifications.requestPermission()) {
      return false;
    }
    await _notifications.showTestNotification();
    return true;
  }

  Future<void> rescheduleCheckInForNextDay() async {
    final current = _current;
    if (!current.checkInReminderEnabled) return;
    await _notifications.rescheduleCheckInForNextDay(current);
  }

  Future<void> rescheduleWorkoutForNextDay() async {
    final current = _current;
    if (!current.workoutReminderEnabled) return;
    await _notifications.rescheduleWorkoutForNextDay(current);
  }
}

final reminderSettingsProvider = StateNotifierProvider<
    ReminderSettingsController, AsyncValue<ReminderSettings>>((ref) {
  return ReminderSettingsController(
    ref.watch(reminderSettingsRepoProvider),
    ref.watch(notificationServiceProvider),
  );
});
