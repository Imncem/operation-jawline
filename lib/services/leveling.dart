import 'dart:math' as math;

const double kCheckInWeight = 0.50;
const double kWorkoutWeight = 0.50;
const int kBaseDailyXP = 100;
const double kStreakBonusAt7 = 0.10;
const double kStreakBonusAt14 = 0.20;
const double kWorkoutSkipPercentFloor = 0.10;
const bool kApplyWorkoutSkipFloor = true;

double computeDailyMissionCompletion({
  required bool checkInDone,
  required double workoutCompletionPercent,
  required bool workoutSkipped,
}) {
  final normalizedWorkout = workoutCompletionPercent.clamp(0.0, 1.0);
  final effectiveWorkout = (workoutSkipped && kApplyWorkoutSkipFloor)
      ? math.max(normalizedWorkout, kWorkoutSkipPercentFloor)
      : normalizedWorkout;

  final checkInPart = checkInDone ? kCheckInWeight : 0.0;
  return (checkInPart + (kWorkoutWeight * effectiveWorkout)).clamp(0.0, 1.0);
}

int computeDailyXP({
  required double dailyMissionCompletion,
  required int disciplineChain,
}) {
  final base = (dailyMissionCompletion.clamp(0.0, 1.0) * kBaseDailyXP).round();
  final bonusRate = disciplineChain >= 14
      ? kStreakBonusAt14
      : disciplineChain >= 7
          ? kStreakBonusAt7
          : 0.0;
  return (base * (1 + bonusRate)).round();
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
