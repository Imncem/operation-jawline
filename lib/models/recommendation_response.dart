import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'readiness_result.dart';
import 'workout_plan.dart';

class RecommendationResponse extends Equatable {
  const RecommendationResponse({
    required this.readiness,
    required this.workoutPlan,
  });

  final ReadinessResult readiness;
  final WorkoutPlan workoutPlan;

  Map<String, dynamic> toMap() {
    return {
      'readiness': readiness.toMap(),
      'workoutPlan': workoutPlan.toMap(),
    };
  }

  factory RecommendationResponse.fromMap(Map<String, dynamic> map) {
    return RecommendationResponse(
      readiness:
          ReadinessResult.fromMap(map['readiness'] as Map<String, dynamic>),
      workoutPlan:
          WorkoutPlan.fromMap(map['workoutPlan'] as Map<String, dynamic>),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RecommendationResponse.fromJson(String source) =>
      RecommendationResponse.fromMap(
          jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [readiness, workoutPlan];
}
