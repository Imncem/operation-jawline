import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'readiness_result.dart';
import 'workout_plan.dart';
import 'zenith_adjustment.dart';
import 'zenith_analysis_result.dart';

class RecommendationResponse extends Equatable {
  const RecommendationResponse({
    required this.readiness,
    required this.workoutPlan,
    this.intelAnalysis,
    this.intelAdjustment,
  });

  final ReadinessResult readiness;
  final WorkoutPlan workoutPlan;
  final ZenithAnalysisResult? intelAnalysis;
  final ZenithAdjustment? intelAdjustment;

  Map<String, dynamic> toMap() {
    return {
      'readiness': readiness.toMap(),
      'workoutPlan': workoutPlan.toMap(),
      'intelAnalysis': intelAnalysis?.toMap(),
      'intelAdjustment': intelAdjustment?.toMap(),
    };
  }

  factory RecommendationResponse.fromMap(Map<String, dynamic> map) {
    return RecommendationResponse(
      readiness:
          ReadinessResult.fromMap(map['readiness'] as Map<String, dynamic>),
      workoutPlan:
          WorkoutPlan.fromMap(map['workoutPlan'] as Map<String, dynamic>),
      intelAnalysis: map['intelAnalysis'] == null
          ? null
          : ZenithAnalysisResult.fromMap(
              map['intelAnalysis'] as Map<String, dynamic>,
            ),
      intelAdjustment: map['intelAdjustment'] == null
          ? null
          : ZenithAdjustment.fromMap(
              map['intelAdjustment'] as Map<String, dynamic>,
            ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RecommendationResponse.fromJson(String source) =>
      RecommendationResponse.fromMap(
          jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props =>
      [readiness, workoutPlan, intelAnalysis, intelAdjustment];
}
