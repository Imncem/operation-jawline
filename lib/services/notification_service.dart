import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../settings/reminder_settings.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const workoutReminderId = 1001;
  static const checkInReminderId = 1002;
  static const testNotificationId = 1999;
  static const _channelId = 'mission_jawline_reminders';
  static const _channelName = 'Mission Jawline Reminders';
  static const _channelDescription = 'Daily Mission Jawline reminder alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    tz.initializeTimeZones();
    final timezoneName = await _safeResolveTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
    debugPrint('[NotificationService] initialized timezone=$timezoneName');
    _initialized = true;
  }

  Future<String> _safeResolveTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('[NotificationService] timezone lookup failed: $e');
      return 'UTC';
    }
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    await initialize();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint('[NotificationService] permission granted=$granted');
    return granted ?? true;
  }

  Future<void> syncReminders(ReminderSettings settings) async {
    await initialize();
    if (!Platform.isAndroid) return;

    if (settings.workoutReminderEnabled) {
      await scheduleWorkoutReminder(settings);
    } else {
      await cancelWorkoutReminder();
    }

    if (settings.checkInReminderEnabled) {
      await scheduleCheckInReminder(settings);
    } else {
      await cancelCheckInReminder();
    }
  }

  Future<void> scheduleWorkoutReminder(
    ReminderSettings settings, {
    bool startTomorrow = false,
  }) async {
    await _scheduleDailyReminder(
      id: workoutReminderId,
      title: 'Protocol pending',
      body: 'Recruit, execute today\'s training protocol. Keep it steady.',
      hour: settings.workoutReminderHour,
      minute: settings.workoutReminderMinute,
      startTomorrow: startTomorrow,
    );
  }

  Future<void> scheduleCheckInReminder(
    ReminderSettings settings, {
    bool startTomorrow = false,
  }) async {
    await _scheduleDailyReminder(
      id: checkInReminderId,
      title: 'Status report due',
      body: 'Log your check-in to protect your discipline chain.',
      hour: settings.checkInReminderHour,
      minute: settings.checkInReminderMinute,
      startTomorrow: startTomorrow,
    );
  }

  Future<void> rescheduleWorkoutForNextDay(ReminderSettings settings) async {
    if (!settings.workoutReminderEnabled) return;
    await scheduleWorkoutReminder(settings, startTomorrow: true);
  }

  Future<void> rescheduleCheckInForNextDay(ReminderSettings settings) async {
    if (!settings.checkInReminderEnabled) return;
    await scheduleCheckInReminder(settings, startTomorrow: true);
  }

  Future<void> cancelWorkoutReminder() async {
    await initialize();
    await _plugin.cancel(workoutReminderId);
    debugPrint('[NotificationService] canceled workout reminder');
  }

  Future<void> cancelCheckInReminder() async {
    await initialize();
    await _plugin.cancel(checkInReminderId);
    debugPrint('[NotificationService] canceled check-in reminder');
  }

  Future<void> showTestNotification() async {
    await initialize();
    if (!Platform.isAndroid) return;

    await _plugin.show(
      testNotificationId,
      'Reminder check',
      'Mission Jawline notifications are online.',
      _details(),
    );
    debugPrint('[NotificationService] test notification shown');
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool startTomorrow,
  }) async {
    await initialize();
    if (!Platform.isAndroid) return;

    final first = _nextInstance(hour, minute, tomorrowOnly: startTomorrow);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        first,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        '[NotificationService] scheduled id=$id at $first exact=true',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] exact schedule failed for id=$id, falling back: $e',
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        first,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint(
        '[NotificationService] scheduled id=$id at $first exact=false',
      );
    }
  }

  tz.TZDateTime _nextInstance(
    int hour,
    int minute, {
    required bool tomorrowOnly,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (tomorrowOnly || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }
}
