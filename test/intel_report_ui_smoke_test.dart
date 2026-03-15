import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operation_jawline/models/daily_check_in.dart';
import 'package:operation_jawline/models/daily_mission_record.dart';
import 'package:operation_jawline/models/enums.dart';
import 'package:operation_jawline/models/workout_status.dart';
import 'package:operation_jawline/screens/intel_report_screen.dart';
import 'package:operation_jawline/services/mission_progress_service.dart';

void main() {
  testWidgets('intel report renders zenith analysis section', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkInHistoryProvider.overrideWith((ref) async => [
                DailyCheckIn(
                  energy: 7,
                  sleepHours: 7,
                  waterLiters: 2.2,
                  weightKg: 80,
                  mood: Mood.good,
                  puffiness: 2,
                  disciplineChain: 5,
                  lastCheckIn: DateTime(2026, 3, 12),
                ),
                DailyCheckIn(
                  energy: 8,
                  sleepHours: 7.5,
                  waterLiters: 2.3,
                  weightKg: 79.8,
                  mood: Mood.good,
                  puffiness: 2,
                  disciplineChain: 6,
                  lastCheckIn: DateTime(2026, 3, 13),
                ),
              ]),
          missionHistoryProvider.overrideWith((ref) async => [
                DailyMissionRecord(
                  dateKey: '2026-03-12',
                  checkInDone: true,
                  xpAwarded: 0,
                  completion: 0.9,
                  plannedWorkoutSec: 1800,
                  actualWorkoutSec: 1800,
                  workoutEffortRatio: 1.0,
                  workoutStatus: WorkoutStatus.completed,
                  lastWorkoutUpdateTs: 0,
                  workoutLane: TrainingLane.moderate,
                ),
                DailyMissionRecord(
                  dateKey: '2026-03-13',
                  checkInDone: true,
                  xpAwarded: 0,
                  completion: 1.0,
                  plannedWorkoutSec: 1800,
                  actualWorkoutSec: 1800,
                  workoutEffortRatio: 1.0,
                  workoutStatus: WorkoutStatus.completed,
                  lastWorkoutUpdateTs: 0,
                  workoutLane: TrainingLane.moderate,
                ),
              ]),
        ],
        child: const MaterialApp(
          home: IntelReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ZENITH ANALYSIS'), findsOneWidget);
    expect(find.text('RECOMMENDED ADJUSTMENT'), findsOneWidget);
  });
}
