import '../data/workout_templates.dart';
import '../models/daily_check_in.dart';
import '../models/enums.dart';
import '../models/recommendation_response.dart';
import '../models/readiness_result.dart';
import '../models/workout_item.dart';
import '../models/workout_plan.dart';
import 'readiness_service.dart';

class WorkoutRecommender {
  WorkoutRecommender({ReadinessService? readinessService})
      : _readinessService = readinessService ?? const ReadinessService();

  final ReadinessService _readinessService;

  RecommendationResponse recommend(DailyCheckIn? checkIn) {
    if (checkIn == null || !_isValid(checkIn)) {
      return _fallbackRecommendation();
    }

    final readiness = _readinessService.calculate(checkIn);
    final explanations = _buildExplanations(checkIn, readiness);

    final templateKey = _pickTemplate(checkIn, readiness);
    final plan = _planFromTemplate(
      templateKey,
      explanations: explanations,
      includeWeightNote: checkIn.weightKg != null,
      addStrengthSafety: readiness.focus == WorkoutFocus.strength ||
          readiness.focus == WorkoutFocus.mixed,
    );

    return RecommendationResponse(readiness: readiness, workoutPlan: plan);
  }

  bool _isValid(DailyCheckIn checkIn) {
    if (checkIn.energy < 1 || checkIn.energy > 10) return false;
    if (checkIn.puffiness < 1 || checkIn.puffiness > 5) return false;
    if (checkIn.sleepHours <= 0 || checkIn.waterLiters < 0) return false;
    if (checkIn.disciplineChain < 0) return false;
    return true;
  }

  RecommendationResponse _fallbackRecommendation() {
    const readiness = ReadinessResult(
      readinessScore: 20,
      lane: TrainingLane.recovery,
      focus: WorkoutFocus.mobility,
      durationMinutes: 15,
      riskFlags: ['Invalid or missing input. Safe recovery fallback applied.'],
    );

    final plan = _planFromTemplate(
      templateMobilityRecovery,
      explanations: const [
        'Input was incomplete or invalid, so a safe mobility recovery plan was selected.',
      ],
      includeWeightNote: false,
      addStrengthSafety: false,
    );

    return RecommendationResponse(readiness: readiness, workoutPlan: plan);
  }

  String _pickTemplate(DailyCheckIn checkIn, ReadinessResult readiness) {
    if (checkIn.puffiness >= 4) {
      if (readiness.focus == WorkoutFocus.mobility) {
        return templateMobilityRecovery;
      }
      return templateZone2;
    }

    switch (readiness.focus) {
      case WorkoutFocus.mobility:
        return templateMobilityRecovery;
      case WorkoutFocus.cardio:
        return templateZone2;
      case WorkoutFocus.mixed:
        return readiness.lane == TrainingLane.hard
            ? templateStrengthB
            : templateMixedLight;
      case WorkoutFocus.strength:
        return checkIn.disciplineChain.isEven
            ? templateStrengthA
            : templateStrengthB;
    }
  }

  List<String> _buildExplanations(
      DailyCheckIn checkIn, ReadinessResult readiness) {
    final explanations = <String>[
      'Readiness score ${readiness.readinessScore} computed from energy, sleep, mood, puffiness, and discipline chain.',
      'Training lane set to ${readiness.lane.label.toLowerCase()} based on readiness mapping and safety guardrails.',
    ];

    if (checkIn.sleepHours < 6 ||
        checkIn.energy <= 3 ||
        checkIn.puffiness >= 4) {
      explanations.add('Intensity was capped due to recovery risk markers.');
    }

    if (checkIn.disciplineChain <= 2 &&
        (readiness.lane == TrainingLane.light ||
            readiness.lane == TrainingLane.moderate)) {
      explanations.add(
          'Session duration reduced to reinforce consistency early in your chain.');
    }

    switch (readiness.focus) {
      case WorkoutFocus.mobility:
        explanations.add(
            'Focus selected: mobility to support recovery and reduce fatigue load.');
      case WorkoutFocus.strength:
        explanations.add(
            'Focus selected: strength as readiness supports progressive resistance work.');
      case WorkoutFocus.cardio:
        explanations.add(
            'Focus selected: low-impact cardio due to puffiness/recovery profile.');
      case WorkoutFocus.mixed:
        explanations.add(
            'Focus selected: mixed work to balance strength and conditioning safely.');
    }

    return explanations;
  }

  WorkoutPlan _planFromTemplate(
    String templateKey, {
    required List<String> explanations,
    required bool includeWeightNote,
    required bool addStrengthSafety,
  }) {
    final template = workoutTemplates[templateKey] ??
        workoutTemplates[templateMobilityRecovery]!;

    List<WorkoutItem> toItems(String key) {
      final raw = (template[key] as List<dynamic>? ?? const []);
      return raw
          .map((item) => WorkoutItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    final finisherMap = template['finisher'] as Map<String, dynamic>?;
    final safetyNotes = <String>[
      'Always complete warm-up and cooldown.',
      'Stop if pain, dizziness, or unusual shortness of breath occurs.',
    ];

    if (addStrengthSafety) {
      safetyNotes.add('For strength sets, keep 1-2 reps in reserve.');
    }
    if (includeWeightNote) {
      safetyNotes.add(
          'Use recent bodyweight trend as context, not a single-day signal.');
    }

    return WorkoutPlan(
      warmup: toItems('warmup'),
      main: toItems('main'),
      finisher: finisherMap == null ? null : WorkoutItem.fromMap(finisherMap),
      cooldown: toItems('cooldown'),
      safetyNotes: safetyNotes,
      explanations: explanations,
    );
  }
}
