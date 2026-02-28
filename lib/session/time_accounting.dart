import '../models/workout_plan.dart';
import 'session_step.dart';

const int kEstimatedSetStepSec = 45;
const int kMaxSetStepCountedSec = 90;

int estimatePlannedWorkoutSec(
  WorkoutPlan plan,
  List<SessionStep> steps, {
  int? targetDurationMinutes,
}) {
  if (targetDurationMinutes != null && targetDurationMinutes > 0) {
    return targetDurationMinutes * 60;
  }

  var total = 0;
  for (final step in steps) {
    if (step.kind == SessionStepKind.set) {
      total += kEstimatedSetStepSec;
    } else {
      total += step.durationSec ?? 0;
    }
  }
  return total;
}

double effortRatio({
  required int plannedSec,
  required int actualSec,
}) {
  if (plannedSec <= 0) return 0;
  return (actualSec / plannedSec).clamp(0, 1);
}

String formatMmSs(int totalSec) {
  final min = (totalSec ~/ 60).toString().padLeft(2, '0');
  final sec = (totalSec % 60).toString().padLeft(2, '0');
  return '$min:$sec';
}
