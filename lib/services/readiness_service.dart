import '../models/daily_check_in.dart';
import '../models/enums.dart';
import '../models/readiness_result.dart';

class ReadinessService {
  const ReadinessService();

  ReadinessResult calculate(DailyCheckIn checkIn) {
    final riskFlags = <String>[];

    final clampedEnergy = checkIn.energy.clamp(1, 10);
    final clampedPuffiness = checkIn.puffiness.clamp(1, 5);

    var score = 50;
    score += (clampedEnergy - 5) * 7;

    final sleep = checkIn.sleepHours;
    if (sleep >= 8) {
      score += 10;
    } else if (sleep >= 7) {
      score += 6;
    } else if (sleep >= 6) {
      score += 2;
    } else if (sleep >= 5) {
      score -= 8;
    } else {
      score -= 15;
    }

    score += checkIn.mood.scoreModifier;
    score -= (clampedPuffiness - 1) * 4;

    final chain = checkIn.disciplineChain;
    if (chain >= 14) {
      score += 4;
    } else if (chain >= 7) {
      score += 2;
    } else if (chain == 0) {
      score -= 2;
    }

    score = score.clamp(0, 100);

    var lane = _laneFromScore(score);

    if (checkIn.sleepHours < 6 ||
        checkIn.energy <= 3 ||
        checkIn.puffiness >= 4) {
      if (lane == TrainingLane.hard) {
        lane = TrainingLane.moderate;
        riskFlags.add('Hard lane restricted due to recovery risk markers.');
      }
    }

    if (checkIn.energy <= 2) {
      lane = TrainingLane.recovery;
      riskFlags.add('Very low energy: recovery-only protocol enforced.');
    }

    if (checkIn.sleepHours < 6) {
      riskFlags.add('Low sleep detected (<6h).');
    }
    if (checkIn.puffiness >= 4) {
      riskFlags.add('High puffiness detected. Reduce intensity.');
    }

    final focus = _focusForLane(lane, checkIn);
    final duration =
        _durationForLane(lane, checkIn.disciplineChain, checkIn.energy);

    return ReadinessResult(
      readinessScore: score,
      lane: lane,
      focus: focus,
      durationMinutes: duration,
      riskFlags: riskFlags,
    );
  }

  TrainingLane _laneFromScore(int score) {
    if (score <= 29) return TrainingLane.recovery;
    if (score <= 49) return TrainingLane.light;
    if (score <= 74) return TrainingLane.moderate;
    return TrainingLane.hard;
  }

  WorkoutFocus _focusForLane(TrainingLane lane, DailyCheckIn checkIn) {
    switch (lane) {
      case TrainingLane.recovery:
        return WorkoutFocus.mobility;
      case TrainingLane.light:
        return checkIn.puffiness >= 4
            ? WorkoutFocus.mobility
            : WorkoutFocus.mixed;
      case TrainingLane.moderate:
        if (checkIn.puffiness >= 4) return WorkoutFocus.cardio;
        return checkIn.sleepHours < 6.5
            ? WorkoutFocus.mixed
            : WorkoutFocus.strength;
      case TrainingLane.hard:
        return WorkoutFocus.mixed;
    }
  }

  int _durationForLane(TrainingLane lane, int disciplineChain, int energy) {
    var duration = switch (lane) {
      TrainingLane.recovery => energy <= 2 ? 15 : 20,
      TrainingLane.light => 25,
      TrainingLane.moderate => 35,
      TrainingLane.hard => 45,
    };

    if (disciplineChain <= 2 &&
        (lane == TrainingLane.light || lane == TrainingLane.moderate)) {
      duration -= 10;
    }

    if (energy <= 2 && duration > 20) {
      duration = 20;
    }

    return duration;
  }
}
