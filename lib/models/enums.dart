import 'package:equatable/equatable.dart';

enum Mood { great, good, neutral, low, stressed }

enum TrainingLane { recovery, light, moderate, hard }

enum WorkoutFocus { strength, cardio, mobility, mixed }

extension MoodX on Mood {
  String get label {
    switch (this) {
      case Mood.great:
        return 'Great';
      case Mood.good:
        return 'Good';
      case Mood.neutral:
        return 'Neutral';
      case Mood.low:
        return 'Low';
      case Mood.stressed:
        return 'Stressed';
    }
  }

  int get scoreModifier {
    switch (this) {
      case Mood.great:
        return 4;
      case Mood.good:
        return 2;
      case Mood.neutral:
        return 0;
      case Mood.low:
        return -4;
      case Mood.stressed:
        return -6;
    }
  }

  String toJsonValue() => name;

  static Mood fromJsonValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'great':
      case 'locked in':
        return Mood.great;
      case 'good':
      case 'focused':
        return Mood.good;
      case 'neutral':
        return Mood.neutral;
      case 'low':
      case 'tired':
        return Mood.low;
      case 'stressed':
        return Mood.stressed;
      default:
        return Mood.neutral;
    }
  }
}

extension TrainingLaneX on TrainingLane {
  String get label => name[0].toUpperCase() + name.substring(1);

  String toJsonValue() => name;

  static TrainingLane fromJsonValue(String value) {
    return TrainingLane.values.firstWhere(
      (lane) => lane.name == value,
      orElse: () => TrainingLane.recovery,
    );
  }
}

extension WorkoutFocusX on WorkoutFocus {
  String get label => name[0].toUpperCase() + name.substring(1);

  String toJsonValue() => name;

  static WorkoutFocus fromJsonValue(String value) {
    return WorkoutFocus.values.firstWhere(
      (focus) => focus.name == value,
      orElse: () => WorkoutFocus.mobility,
    );
  }
}

abstract class JsonEquatable extends Equatable {
  const JsonEquatable();

  Map<String, dynamic> toMap();
}
