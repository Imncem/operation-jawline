import 'dart:math' as math;

import '../models/workout_status.dart';

const double kCheckInWeight = 0.50;
const double kWorkoutWeight = 0.50;
const int kBaseDailyXP = 100;
const double kStreakBonusAt7 = 0.10;
const double kStreakBonusAt14 = 0.20;
const double kMinEffortThreshold = 0.10;
const double kSkipWorkoutCredit = 0.10;
const double kAbortPenaltyMultiplier = 1.0;
const int kCompletionBonusFull = 10;
const int kCompletionBonus75 = 5;

double computeDailyMissionCompletion({
  required bool checkInDone,
  required double workoutCompletionPercent,
  required bool workoutSkipped,
}) {
  final normalizedWorkout = workoutCompletionPercent.clamp(0.0, 1.0);
  final effectiveWorkout =
      workoutSkipped ? kSkipWorkoutCredit : normalizedWorkout;

  final checkInPart = checkInDone ? kCheckInWeight : 0.0;
  return (checkInPart + (kWorkoutWeight * effectiveWorkout)).clamp(0.0, 1.0);
}

double computeWorkoutCredit({
  required WorkoutStatus status,
  required double effortRatio,
}) {
  final effort = effortRatio.clamp(0.0, 1.0);
  if (status == WorkoutStatus.skipped) return kSkipWorkoutCredit;
  if (effort < kMinEffortThreshold) return 0.0;
  return (effort * kAbortPenaltyMultiplier).clamp(0.0, 1.0);
}

int computeCompletionBonusXP({
  required WorkoutStatus status,
  required double effortRatio,
  double? dailyCompletion,
}) {
  final effort = effortRatio.clamp(0.0, 1.0);
  if (effort >= 1.0 && status == WorkoutStatus.completed) {
    return kCompletionBonusFull;
  }
  if (effort >= 0.75 || (dailyCompletion ?? 0) >= 0.75) {
    return kCompletionBonus75;
  }
  return 0;
}

double computeDailyCompletionFromWorkoutCredit({
  required bool checkInDone,
  required double workoutCredit,
}) {
  final checkInPart = checkInDone ? kCheckInWeight : 0.0;
  return (checkInPart + (kWorkoutWeight * workoutCredit.clamp(0.0, 1.0)))
      .clamp(0.0, 1.0);
}

int applyStreakBonus(int xpBeforeStreak, int disciplineChain) {
  final bonusRate = disciplineChain >= 14
      ? kStreakBonusAt14
      : disciplineChain >= 7
          ? kStreakBonusAt7
          : 0.0;
  return (xpBeforeStreak * (1 + bonusRate)).round();
}

int computeDailyXP({
  required double dailyMissionCompletion,
  required int disciplineChain,
  int completionBonusXP = 0,
}) {
  final base = (dailyMissionCompletion.clamp(0.0, 1.0) * kBaseDailyXP).round() +
      completionBonusXP;
  return applyStreakBonus(base, disciplineChain);
}

int xpThresholdForLevel(int level) {
  if (level <= 1) return 300;
  var threshold = 300;
  for (var i = 2; i <= level; i++) {
    threshold = (threshold * 1.15).round();
  }
  return threshold;
}

int computeLevelFromTotalXP(int totalXP) {
  var remaining = math.max(0, totalXP);
  var level = 1;

  while (remaining >= xpThresholdForLevel(level)) {
    remaining -= xpThresholdForLevel(level);
    level += 1;
  }
  return level;
}

int xpIntoCurrentLevel(int totalXP) {
  var remaining = math.max(0, totalXP);
  var level = 1;

  while (remaining >= xpThresholdForLevel(level)) {
    remaining -= xpThresholdForLevel(level);
    level += 1;
  }
  return remaining;
}

int xpToNextLevel(int totalXP) {
  final level = computeLevelFromTotalXP(totalXP);
  final into = xpIntoCurrentLevel(totalXP);
  return xpThresholdForLevel(level) - into;
}

double progressToNextLevel(int totalXP) {
  final level = computeLevelFromTotalXP(totalXP);
  final into = xpIntoCurrentLevel(totalXP);
  final threshold = xpThresholdForLevel(level);
  if (threshold <= 0) return 1;
  return (into / threshold).clamp(0.0, 1.0);
}
