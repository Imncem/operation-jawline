class ReminderSettings {
  const ReminderSettings({
    required this.workoutReminderEnabled,
    required this.checkInReminderEnabled,
    required this.workoutReminderHour,
    required this.workoutReminderMinute,
    required this.checkInReminderHour,
    required this.checkInReminderMinute,
  });

  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      workoutReminderEnabled: false,
      checkInReminderEnabled: false,
      workoutReminderHour: 18,
      workoutReminderMinute: 0,
      checkInReminderHour: 21,
      checkInReminderMinute: 0,
    );
  }

  final bool workoutReminderEnabled;
  final bool checkInReminderEnabled;
  final int workoutReminderHour;
  final int workoutReminderMinute;
  final int checkInReminderHour;
  final int checkInReminderMinute;

  ReminderSettings copyWith({
    bool? workoutReminderEnabled,
    bool? checkInReminderEnabled,
    int? workoutReminderHour,
    int? workoutReminderMinute,
    int? checkInReminderHour,
    int? checkInReminderMinute,
  }) {
    return ReminderSettings(
      workoutReminderEnabled:
          workoutReminderEnabled ?? this.workoutReminderEnabled,
      checkInReminderEnabled:
          checkInReminderEnabled ?? this.checkInReminderEnabled,
      workoutReminderHour: workoutReminderHour ?? this.workoutReminderHour,
      workoutReminderMinute:
          workoutReminderMinute ?? this.workoutReminderMinute,
      checkInReminderHour: checkInReminderHour ?? this.checkInReminderHour,
      checkInReminderMinute:
          checkInReminderMinute ?? this.checkInReminderMinute,
    );
  }
}
