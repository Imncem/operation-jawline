import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/recommendation_response.dart';
import 'package:operation_jawline/services/readiness_service.dart';
import 'package:operation_jawline/services/workout_recommender.dart';

void main() {
  group('ReadinessService', () {
    test('calculates readiness score using configured formula', () {
      final checkIn = DailyCheckIn(
        energy: 8,
        sleepHours: 7.5,
        waterLiters: 2.2,
        weightKg: 78,
        mood: Mood.good,
        puffiness: 2,
        disciplineChain: 8,
        lastCheckIn: DateTime(2026, 2, 23),
      );

      const service = ReadinessService();
      final result = service.calculate(checkIn);

      expect(result.readinessScore, 77);
      expect(result.lane, TrainingLane.hard);
      expect(result.durationMinutes, 45);
    });

    test('guardrail prevents hard lane when sleep is below 6h', () {
      final checkIn = DailyCheckIn(
        energy: 10,
        sleepHours: 5.5,
        waterLiters: 2.4,
        weightKg: null,
        mood: Mood.great,
        puffiness: 1,
        disciplineChain: 14,
        lastCheckIn: DateTime(2026, 2, 23),
      );

      const service = ReadinessService();
      final result = service.calculate(checkIn);

      expect(result.readinessScore, 85);
      expect(result.lane, isNot(TrainingLane.hard));
      expect(result.lane, TrainingLane.moderate);
    });
  });

  group('WorkoutRecommender', () {
    test('falls back to safe mobility plan for invalid inputs', () {
      final invalid = DailyCheckIn(
        energy: 11,
        sleepHours: -1,
        waterLiters: -1,
        weightKg: null,
        mood: Mood.neutral,
        puffiness: 7,
        disciplineChain: -3,
        lastCheckIn: DateTime(2026, 2, 23),
      );

      final recommender = WorkoutRecommender();
      final RecommendationResponse result = recommender.recommend(invalid);

      expect(result.readiness.lane, TrainingLane.recovery);
      expect(result.readiness.focus, WorkoutFocus.mobility);
      expect(result.readiness.durationMinutes, 15);
      expect(result.workoutPlan.warmup, isNotEmpty);
      expect(result.workoutPlan.cooldown, isNotEmpty);
    });
  });
}
