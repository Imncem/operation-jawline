import '../data/workout_templates.dart';
import '../intel/zenith_intelligence_engine.dart';
import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/enums.dart';
import '../models/recommendation_response.dart';
import '../models/readiness_result.dart';
import '../models/workout_item.dart';
import '../models/workout_plan.dart';
import '../models/zenith_adjustment.dart';
import '../models/zenith_analysis_result.dart';
import '../zenith/workout_progression.dart';
import 'mission_progress_service.dart';
import 'readiness_service.dart';

class WorkoutRecommender {
  WorkoutRecommender({
    ReadinessService? readinessService,
    MissionProgressService? missionProgressService,
    WorkoutProgressionRepository? progressionRepository,
    WorkoutProgressionEngine? progressionEngine,
    ZenithIntelligenceEngine? intelligenceEngine,
    Future<List<DailyCheckIn>> Function()? checkInHistoryLoader,
    Future<List<DailyMissionRecord>> Function()? missionHistoryLoader,
  })  : _readinessService = readinessService ?? const ReadinessService(),
        _missionProgressService = missionProgressService ??
            MissionProgressService(storage: SharedPrefsMissionStorageAdapter()),
        _progressionRepository =
            progressionRepository ?? WorkoutProgressionRepository(),
        _progressionEngine =
            progressionEngine ?? const WorkoutProgressionEngine(),
        _intelligenceEngine =
            intelligenceEngine ?? const ZenithIntelligenceEngine(),
        _checkInHistoryLoader = checkInHistoryLoader,
        _missionHistoryLoader = missionHistoryLoader;

  final ReadinessService _readinessService;
  final MissionProgressService _missionProgressService;
  final WorkoutProgressionRepository _progressionRepository;
  final WorkoutProgressionEngine _progressionEngine;
  final ZenithIntelligenceEngine _intelligenceEngine;
  final Future<List<DailyCheckIn>> Function()? _checkInHistoryLoader;
  final Future<List<DailyMissionRecord>> Function()? _missionHistoryLoader;

  RecommendationResponse recommend(DailyCheckIn? checkIn) {
    if (checkIn == null || !_isValid(checkIn)) {
      return _fallbackRecommendation();
    }

    final readiness = _readinessService.calculate(checkIn);
    final explanations = _buildExplanations(checkIn, readiness);

    final templateKey = _pickTemplate(checkIn, readiness, null);
    final plan = _planFromTemplate(
      templateKey,
      explanations: explanations,
      includeWeightNote: checkIn.weightKg != null,
      addStrengthSafety: readiness.focus == WorkoutFocus.strength ||
          readiness.focus == WorkoutFocus.mixed,
    );

    return RecommendationResponse(readiness: readiness, workoutPlan: plan);
  }

  Future<RecommendationResponse> recommendWithProgress(
      DailyCheckIn? checkIn) async {
    final base = await recommendWithIntelligence(checkIn);
    if (checkIn == null) return base;
    final memory = await _progressionRepository.load();
    final progressedPlan = _progressionEngine.apply(
      plan: base.workoutPlan,
      readiness: base.readiness,
      templateId: base.workoutPlan.templateId ?? '',
      memory: memory,
    );
    return RecommendationResponse(
      readiness: base.readiness,
      workoutPlan: progressedPlan,
      intelAnalysis: base.intelAnalysis,
      intelAdjustment: base.intelAdjustment,
    );
  }

  Future<RecommendationResponse> recommendWithIntelligence(
      DailyCheckIn? checkIn) async {
    if (checkIn == null || !_isValid(checkIn)) {
      return _fallbackRecommendation();
    }

    final readiness = _readinessService.calculate(checkIn);
    final checkInHistory =
        await (_checkInHistoryLoader?.call() ?? _missionProgressService.loadCheckInHistory());
    final missionHistory = await (_missionHistoryLoader?.call() ??
        _missionProgressService.loadMissionRecordHistory());
    final bundle = _intelligenceEngine.analyze(
      checkIns: checkInHistory,
      missionRecords: missionHistory,
      windowDays: 7,
    );
    final mergedReadiness = mergeReadinessWithAdjustment(
      readiness: readiness,
      checkIn: checkIn,
      adjustment: bundle.adjustment,
    );
    final explanations = _buildExplanations(
      checkIn,
      mergedReadiness,
      analysis: bundle.analysis,
      adjustment: bundle.adjustment,
    );

    final templateKey = _pickTemplate(checkIn, mergedReadiness, bundle.adjustment);
    final plan = _planFromTemplate(
      templateKey,
      explanations: explanations,
      includeWeightNote: checkIn.weightKg != null,
      addStrengthSafety: mergedReadiness.focus == WorkoutFocus.strength ||
          mergedReadiness.focus == WorkoutFocus.mixed,
    );

    return RecommendationResponse(
      readiness: mergedReadiness,
      workoutPlan: plan,
      intelAnalysis: bundle.analysis,
      intelAdjustment: bundle.adjustment,
    );
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

  ReadinessResult mergeReadinessWithAdjustment({
    required ReadinessResult readiness,
    required DailyCheckIn checkIn,
    required ZenithAdjustment adjustment,
  }) {
    var lane = readiness.lane;
    var focus = readiness.focus;
    var duration = readiness.durationMinutes + adjustment.durationDeltaMin;
    final riskFlags = [...readiness.riskFlags];

    if (adjustment.preferRecovery &&
        (lane.index > TrainingLane.recovery.index)) {
      lane = TrainingLane.values[lane.index - 1];
      riskFlags.add('Intel analysis favored recovery over current load.');
    }

    if (adjustment.restrictHighIntensity && lane == TrainingLane.hard) {
      lane = TrainingLane.moderate;
      riskFlags.add('Intel analysis restricted high intensity.');
    }

    if (adjustment.laneOverrideSuggestion != null) {
      final overrideLane =
          _laneFromBias(adjustment.laneOverrideSuggestion!, fallback: lane);
      if (overrideLane.index < lane.index) {
        lane = overrideLane;
      }
    }

    if (adjustment.laneNudge != 0) {
      final nextIndex = (lane.index + adjustment.laneNudge)
          .clamp(TrainingLane.recovery.index, TrainingLane.hard.index);
      lane = TrainingLane.values[nextIndex];
    }

    if (checkIn.sleepHours < 6 ||
        checkIn.energy <= 3 ||
        checkIn.puffiness >= 4) {
      if (lane == TrainingLane.hard) {
        lane = TrainingLane.moderate;
      }
    }
    if (checkIn.energy <= 2) {
      lane = TrainingLane.recovery;
      duration = duration > 20 ? 20 : duration;
    }
    if (adjustment.restrictHighIntensity && lane == TrainingLane.hard) {
      lane = TrainingLane.moderate;
    }

    final suggestedFocus = adjustment.focusSuggestion == null
        ? null
        : _focusFromBias(adjustment.focusSuggestion!, fallback: focus);
    if (suggestedFocus != null) {
      if (adjustment.preferRecovery &&
          (suggestedFocus == WorkoutFocus.mobility ||
              suggestedFocus == WorkoutFocus.mixed)) {
        focus = suggestedFocus;
      } else if (!adjustment.preferRecovery) {
        focus = suggestedFocus;
      }
    } else {
      focus = _defaultFocusForLane(lane, focus);
    }

    duration = _clampDurationForLane(lane, duration);

    return readiness.copyWith(
      lane: lane,
      focus: focus,
      durationMinutes: duration,
      riskFlags: riskFlags,
    );
  }

  String _pickTemplate(
    DailyCheckIn checkIn,
    ReadinessResult readiness,
    ZenithAdjustment? adjustment,
  ) {
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
        return readiness.lane == TrainingLane.hard &&
                !(adjustment?.restrictHighIntensity ?? false)
            ? templateStrengthB
            : templateMixedLight;
      case WorkoutFocus.strength:
        return checkIn.disciplineChain.isEven
            ? templateStrengthA
            : templateStrengthB;
    }
  }

  List<String> _buildExplanations(
    DailyCheckIn checkIn,
    ReadinessResult readiness, {
    ZenithAnalysisResult? analysis,
    ZenithAdjustment? adjustment,
  }) {
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

    if (analysis != null) {
      explanations.add('INTEL // ${analysis.summaryTitle}. ${analysis.summaryText}');
      explanations.addAll(analysis.sourceSignals.take(2).map((item) => 'INTEL SIGNAL // $item'));
    }

    if (adjustment != null && adjustment.durationDeltaMin != 0) {
      explanations.add(
        'INTEL ADJUSTMENT // Protocol duration ${adjustment.durationDeltaMin > 0 ? 'extended' : 'reduced'} by ${adjustment.durationDeltaMin.abs()} min.',
      );
    }

    return explanations;
  }

  TrainingLane _laneFromBias(
    ZenithLaneBias bias, {
    required TrainingLane fallback,
  }) {
    switch (bias) {
      case ZenithLaneBias.recovery:
        return TrainingLane.recovery;
      case ZenithLaneBias.light:
        return TrainingLane.light;
      case ZenithLaneBias.moderate:
        return TrainingLane.moderate;
      case ZenithLaneBias.hard:
        return TrainingLane.hard;
      case ZenithLaneBias.none:
        return fallback;
    }
  }

  WorkoutFocus _focusFromBias(
    ZenithFocusBias bias, {
    required WorkoutFocus fallback,
  }) {
    switch (bias) {
      case ZenithFocusBias.mobility:
        return WorkoutFocus.mobility;
      case ZenithFocusBias.strength:
        return WorkoutFocus.strength;
      case ZenithFocusBias.mixed:
        return WorkoutFocus.mixed;
      case ZenithFocusBias.conditioning:
        return WorkoutFocus.cardio;
      case ZenithFocusBias.none:
        return fallback;
    }
  }

  WorkoutFocus _defaultFocusForLane(TrainingLane lane, WorkoutFocus current) {
    switch (lane) {
      case TrainingLane.recovery:
        return WorkoutFocus.mobility;
      case TrainingLane.light:
        return current == WorkoutFocus.strength ? WorkoutFocus.mixed : current;
      case TrainingLane.moderate:
        return current;
      case TrainingLane.hard:
        return current == WorkoutFocus.mobility ? WorkoutFocus.mixed : current;
    }
  }

  int _clampDurationForLane(TrainingLane lane, int duration) {
    final min = switch (lane) {
      TrainingLane.recovery => 15,
      TrainingLane.light => 20,
      TrainingLane.moderate => 30,
      TrainingLane.hard => 40,
    };
    final max = switch (lane) {
      TrainingLane.recovery => 20,
      TrainingLane.light => 30,
      TrainingLane.moderate => 40,
      TrainingLane.hard => 50,
    };
    return duration.clamp(min, max);
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
      templateId: templateKey,
      warmup: toItems('warmup'),
      main: toItems('main'),
      finisher: finisherMap == null ? null : WorkoutItem.fromMap(finisherMap),
      cooldown: toItems('cooldown'),
      safetyNotes: safetyNotes,
      explanations: explanations,
    );
  }
}
