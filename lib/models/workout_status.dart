enum WorkoutStatus {
  notStarted,
  inProgress,
  completed,
  aborted,
  skipped,
}

extension WorkoutStatusX on WorkoutStatus {
  String get label {
    switch (this) {
      case WorkoutStatus.notStarted:
        return 'Not started';
      case WorkoutStatus.inProgress:
        return 'In progress';
      case WorkoutStatus.completed:
        return 'Completed';
      case WorkoutStatus.aborted:
        return 'Aborted';
      case WorkoutStatus.skipped:
        return 'Skipped';
    }
  }

  String toJsonValue() => name;

  static WorkoutStatus fromJsonValue(String? raw) {
    final value = raw?.trim();
    return WorkoutStatus.values.firstWhere(
      (it) => it.name == value,
      orElse: () => WorkoutStatus.notStarted,
    );
  }
}
