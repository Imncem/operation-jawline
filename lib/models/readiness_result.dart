import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'enums.dart';

class ReadinessResult extends Equatable {
  const ReadinessResult({
    required this.readinessScore,
    required this.lane,
    required this.focus,
    required this.durationMinutes,
    required this.riskFlags,
  });

  final int readinessScore;
  final TrainingLane lane;
  final WorkoutFocus focus;
  final int durationMinutes;
  final List<String> riskFlags;

  ReadinessResult copyWith({
    int? readinessScore,
    TrainingLane? lane,
    WorkoutFocus? focus,
    int? durationMinutes,
    List<String>? riskFlags,
  }) {
    return ReadinessResult(
      readinessScore: readinessScore ?? this.readinessScore,
      lane: lane ?? this.lane,
      focus: focus ?? this.focus,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      riskFlags: riskFlags ?? this.riskFlags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'readinessScore': readinessScore,
      'lane': lane.toJsonValue(),
      'focus': focus.toJsonValue(),
      'durationMinutes': durationMinutes,
      'riskFlags': riskFlags,
    };
  }

  factory ReadinessResult.fromMap(Map<String, dynamic> map) {
    return ReadinessResult(
      readinessScore: (map['readinessScore'] ?? 0) as int,
      lane: TrainingLaneX.fromJsonValue((map['lane'] ?? 'recovery') as String),
      focus:
          WorkoutFocusX.fromJsonValue((map['focus'] ?? 'mobility') as String),
      durationMinutes: (map['durationMinutes'] ?? 15) as int,
      riskFlags: List<String>.from((map['riskFlags'] ?? const []) as List),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReadinessResult.fromJson(String source) =>
      ReadinessResult.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        readinessScore,
        lane,
        focus,
        durationMinutes,
        riskFlags,
      ];
}
