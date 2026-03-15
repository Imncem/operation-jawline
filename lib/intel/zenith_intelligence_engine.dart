import '../intel/zenith_intelligence_config.dart';
import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/trend_snapshot.dart';
import '../models/workout_status.dart';
import '../models/zenith_adjustment.dart';
import '../models/zenith_analysis_result.dart';

class ZenithIntelligenceBundle {
  const ZenithIntelligenceBundle({
    required this.snapshots,
    required this.analysis,
    required this.adjustment,
  });

  final List<TrendSnapshot> snapshots;
  final ZenithAnalysisResult analysis;
  final ZenithAdjustment adjustment;
}

class ZenithIntelligenceEngine {
  const ZenithIntelligenceEngine({
    this.config = const ZenithIntelligenceConfig(),
  });

  final ZenithIntelligenceConfig config;

  ZenithIntelligenceBundle analyze({
    required List<DailyCheckIn> checkIns,
    required List<DailyMissionRecord> missionRecords,
    int windowDays = 7,
  }) {
    final sortedCheckIns = [...checkIns]
      ..sort((a, b) => a.lastCheckIn.compareTo(b.lastCheckIn));
    final sortedMissions = [...missionRecords]
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final windowCheckIns = _takeLast(sortedCheckIns, windowDays);
    final windowMissions = _takeLast(sortedMissions, windowDays);

    final snapshots = <TrendSnapshot>[
      _snapshot(
        'energy',
        windowCheckIns.map((item) => item.energy.toDouble()).toList(),
        sortedCheckIns.map((item) => item.energy.toDouble()).toList(),
      ),
      _snapshot(
        'hydration',
        windowCheckIns.map((item) => item.waterLiters).toList(),
        sortedCheckIns.map((item) => item.waterLiters).toList(),
      ),
      _snapshot(
        'weight',
        windowCheckIns
            .where((item) => item.weightKg != null)
            .map((item) => item.weightKg!)
            .toList(),
        sortedCheckIns
            .where((item) => item.weightKg != null)
            .map((item) => item.weightKg!)
            .toList(),
      ),
      _snapshot(
        'puffiness',
        windowCheckIns.map((item) => item.puffiness.toDouble()).toList(),
        sortedCheckIns.map((item) => item.puffiness.toDouble()).toList(),
      ),
      _snapshot(
        'mission_completion',
        windowMissions.map((item) => item.completion * 100).toList(),
        sortedMissions.map((item) => item.completion * 100).toList(),
      ),
      _snapshot(
        'workout_effort',
        windowMissions
            .where((item) => item.actualWorkoutSec > 0)
            .map((item) => item.workoutEffortRatio * 100)
            .toList(),
        sortedMissions
            .where((item) => item.actualWorkoutSec > 0)
            .map((item) => item.workoutEffortRatio * 100)
            .toList(),
      ),
    ];

    final energySnapshot = snapshots.firstWhere((item) => item.metricKey == 'energy');
    final hydrationSnapshot =
        snapshots.firstWhere((item) => item.metricKey == 'hydration');
    final weightSnapshot = snapshots.firstWhere((item) => item.metricKey == 'weight');
    final puffinessSnapshot =
        snapshots.firstWhere((item) => item.metricKey == 'puffiness');
    final bulletInsights = <String>[];
    final cautionFlags = <String>[];
    final sourceSignals = <String>[];

    var laneBias = ZenithLaneBias.none;
    var focusBias = ZenithFocusBias.none;
    var durationModifierMin = 0;
    var summaryTitle = 'Telemetry Neutral';
    var summaryText = 'Recent telemetry is mixed. Hold a controlled training lane until clearer signals emerge.';
    var actionTitle = 'Maintain Baseline';
    var actionText = 'Keep execution steady and let the next check-ins confirm whether pressure is building or clearing.';
    var laneNudge = 0;
    var restrictHighIntensity = false;
    var preferRecovery = false;

    final energyFalling = _isEnergyFalling(windowCheckIns);
    final fatigueRisk =
        energySnapshot.delta7 <= -2 || energySnapshot.latestValue <= 3;
    final unstableEnergy =
        energySnapshot.volatilityScore >= config.energyVolatilityThreshold;
    final hydrationLow =
        hydrationSnapshot.sampleCount > 0 &&
        hydrationSnapshot.averageValue < config.hydrationTargetLiters;
    final hydrationInconsistent =
        hydrationSnapshot.volatilityScore >= config.hydrationVolatilityThreshold;
    final weightRisingRapidly =
        weightSnapshot.sampleCount > 1 &&
        weightSnapshot.delta7 > config.weightRapidChangeKg;
    final weightFallingRapidly =
        weightSnapshot.sampleCount > 1 &&
        weightSnapshot.delta7 < -config.weightRapidChangeKg;
    final puffinessConcern =
        puffinessSnapshot.sampleCount > 0 &&
        (puffinessSnapshot.averageValue >= config.puffinessConcernThreshold ||
            puffinessSnapshot.delta7 >= config.puffinessRisingThreshold);
    final puffinessImproving =
        puffinessSnapshot.sampleCount > 1 && puffinessSnapshot.delta7 <= -1;
    final highCompletionDays = windowMissions.where((item) => item.completion >= 0.8).length;
    final lowCompletionDays = windowMissions.where((item) => item.completion < 0.5).length;
    final consistencyStrong = highCompletionDays >= config.consistencyStrongDays;
    final disciplineInstability = lowCompletionDays >= 3;
    final highEffortCount = windowMissions.where((item) {
      return item.workoutEffortRatio >= 0.75 &&
          (item.workoutStatus == WorkoutStatus.completed ||
              item.workoutStatus == WorkoutStatus.aborted);
    }).length;
    final recoverySessions = windowMissions.where((item) {
      return item.workoutLane?.name == 'recovery' &&
          item.workoutStatus == WorkoutStatus.completed;
    }).length;
    final overreachSignal = highEffortCount >= 2 && energyFalling;
    final recoveryEffective = recoverySessions >= 2 && energySnapshot.delta7 >= 1;

    if (energyFalling) {
      bulletInsights.add('Recent energy trend is slipping across the current window.');
      sourceSignals.add('Energy trend falling');
      laneNudge -= 1;
    }
    if (fatigueRisk) {
      bulletInsights.add('Latest energy markers indicate fatigue pressure.');
      cautionFlags.add('Fatigue risk');
      sourceSignals.add('Energy delta or latest value below threshold');
      laneNudge -= 1;
      durationModifierMin -= 5;
    }
    if (unstableEnergy) {
      bulletInsights.add('Energy is volatile day to day, which reduces confidence in hard progression.');
      cautionFlags.add('Unstable energy');
      sourceSignals.add('Energy volatility high');
    }
    if (hydrationLow) {
      bulletInsights.add('Hydration is below target on average across recent check-ins.');
      cautionFlags.add('Hydration low');
      sourceSignals.add('Hydration average below target');
      focusBias = focusBias == ZenithFocusBias.none
          ? ZenithFocusBias.mixed
          : focusBias;
      laneNudge -= 1;
    }
    if (hydrationInconsistent) {
      bulletInsights.add('Hydration swings are wide, suggesting inconsistent recovery support.');
      cautionFlags.add('Hydration inconsistent');
      sourceSignals.add('Hydration volatility high');
    }
    if (weightRisingRapidly) {
      bulletInsights.add('Body mass is climbing faster than baseline. Review routine consistency and hydration context.');
      sourceSignals.add('Body mass delta7 rising rapidly');
    } else if (weightFallingRapidly) {
      bulletInsights.add('Body mass is dropping quickly. Keep training load controlled until the trend stabilizes.');
      sourceSignals.add('Body mass delta7 falling rapidly');
    }
    if (puffinessConcern) {
      bulletInsights.add('Puffiness markers point to elevated recovery load.');
      cautionFlags.add('Recovery concern');
      sourceSignals.add('Puffiness elevated or rising');
      laneNudge -= 1;
      focusBias = ZenithFocusBias.mobility;
    } else if (puffinessImproving) {
      bulletInsights.add('Puffiness is decreasing, which suggests recovery is improving.');
      sourceSignals.add('Puffiness improving');
    }
    if (consistencyStrong) {
      bulletInsights.add('Mission completion has stayed strong across the recent window.');
      sourceSignals.add('Mission completion strong');
      laneNudge += 1;
    }
    if (disciplineInstability) {
      bulletInsights.add('Recent mission misses suggest routine instability.');
      cautionFlags.add('Discipline instability');
      sourceSignals.add('Multiple low-completion days');
      laneNudge -= 1;
    }
    if (overreachSignal) {
      bulletInsights.add('High-effort sessions are stacking while energy trends down. Overreach risk is rising.');
      cautionFlags.add('Overreach signal');
      sourceSignals.add('High effort repeated with falling energy');
    } else if (recoveryEffective) {
      bulletInsights.add('Recovery work appears to be paying off. Energy is responding well.');
      sourceSignals.add('Recovery sessions followed by energy improvement');
    }

    if ((fatigueRisk || puffinessConcern || overreachSignal) &&
        bulletInsights.isNotEmpty) {
      summaryTitle = 'Recovery Pressure Detected';
      summaryText = 'Recent telemetry points to accumulated fatigue or poor recovery support. ZENITH should reduce load and bias restoration.';
      actionTitle = 'Shift To Recovery Control';
      actionText = 'Favor recovery or light work, reduce duration, and avoid high-intensity conditioning until markers normalize.';
      laneBias = ZenithLaneBias.recovery;
      focusBias = ZenithFocusBias.mobility;
      durationModifierMin = durationModifierMin - 5;
      restrictHighIntensity = true;
      preferRecovery = true;
    } else if (consistencyStrong &&
        !hydrationLow &&
        !puffinessConcern &&
        !disciplineInstability) {
      summaryTitle = 'Training Stability Confirmed';
      summaryText = 'Execution consistency and recovery markers support steady progression.';
      actionTitle = 'Press Controlled Progression';
      actionText = 'Maintain strength-led work and extend duration slightly if readiness is still supportive today.';
      laneBias = energySnapshot.latestValue >= 7
          ? ZenithLaneBias.hard
          : ZenithLaneBias.moderate;
      focusBias = ZenithFocusBias.strength;
      durationModifierMin = 5;
      laneNudge = laneNudge < 1 ? 1 : laneNudge;
    } else if (weightRisingRapidly &&
        hydrationInconsistent &&
        disciplineInstability) {
      summaryTitle = 'Routine Drift Detected';
      summaryText = 'Recent telemetry suggests execution drift rather than stable progression.';
      actionTitle = 'Rebuild Baseline';
      actionText = 'Use light or mixed work, re-establish hydration consistency, and stabilize mission completion before increasing load.';
      laneBias = ZenithLaneBias.light;
      focusBias = ZenithFocusBias.conditioning;
      durationModifierMin = durationModifierMin <= -5 ? durationModifierMin : -5;
    } else if (hydrationLow || hydrationInconsistent || unstableEnergy) {
      summaryTitle = 'Recovery Support Incomplete';
      summaryText = 'Readiness support variables are inconsistent, so ZENITH should hold a conservative lane.';
      actionTitle = 'Stabilize Inputs';
      actionText = 'Prioritize hydration consistency, steady sleep, and moderate training density before pushing intensity.';
      laneBias = ZenithLaneBias.light;
      focusBias =
          focusBias == ZenithFocusBias.none ? ZenithFocusBias.mixed : focusBias;
      durationModifierMin = durationModifierMin <= -5 ? durationModifierMin : -5;
    }

    if (bulletInsights.isEmpty) {
      bulletInsights.add('Recent telemetry is limited, so ZENITH is holding a neutral adjustment.');
      sourceSignals.add('Insufficient high-confidence trend signals');
    }

    final confidence = _computeConfidence(snapshots, sourceSignals.length);
    final analysis = ZenithAnalysisResult(
      summaryTitle: summaryTitle,
      summaryText: summaryText,
      bulletInsights: bulletInsights.take(4).toList(),
      recommendedActionTitle: actionTitle,
      recommendedActionText: actionText,
      laneBias: laneBias,
      focusBias: focusBias,
      durationModifierMin: durationModifierMin,
      cautionFlags: cautionFlags,
      confidenceScore: confidence,
      sourceSignals: sourceSignals,
    );

    final adjustment = ZenithAdjustment(
      laneOverrideSuggestion:
          laneBias == ZenithLaneBias.none ? null : laneBias,
      laneNudge: laneNudge.clamp(-2, 2),
      focusSuggestion:
          focusBias == ZenithFocusBias.none ? null : focusBias,
      durationDeltaMin: durationModifierMin,
      restrictHighIntensity: restrictHighIntensity,
      preferRecovery: preferRecovery,
      rationale: [
        analysis.summaryTitle,
        ...analysis.sourceSignals.take(3),
        if (durationModifierMin != 0)
          'Protocol duration ${durationModifierMin > 0 ? 'extended' : 'reduced'} by ${durationModifierMin.abs()} min.',
      ],
    );

    return ZenithIntelligenceBundle(
      snapshots: snapshots,
      analysis: analysis,
      adjustment: adjustment,
    );
  }

  TrendSnapshot _snapshot(
    String key,
    List<double> windowValues,
    List<double> allValues,
  ) {
    if (allValues.isEmpty) {
      return TrendSnapshot(
        metricKey: key,
        latestValue: 0,
        averageValue: 0,
        minValue: 0,
        maxValue: 0,
        delta7: 0,
        delta30: 0,
        trendDirection: TrendDirection.insufficientData,
        volatilityScore: 0,
        sampleCount: 0,
      );
    }

    final recentSeven = _takeLast(allValues, 7);
    final recentThirty = _takeLast(allValues, 30);
    final targetValues = windowValues.isNotEmpty ? windowValues : recentSeven;
    final latest = allValues.last;
    final avg = targetValues.reduce((a, b) => a + b) / targetValues.length;
    final min = allValues.reduce((a, b) => a < b ? a : b);
    final max = allValues.reduce((a, b) => a > b ? a : b);
    final delta7 =
        recentSeven.length < 2 ? 0.0 : recentSeven.last - recentSeven.first;
    final delta30 =
        recentThirty.length < 2 ? 0.0 : recentThirty.last - recentThirty.first;
    final volatility = _volatility(targetValues);

    return TrendSnapshot(
      metricKey: key,
      latestValue: latest,
      averageValue: avg,
      minValue: min,
      maxValue: max,
      delta7: delta7,
      delta30: delta30,
      trendDirection: _direction(delta7, volatility, targetValues.length),
      volatilityScore: volatility,
      sampleCount: allValues.length,
    );
  }

  TrendDirection _direction(double delta, double volatility, int sampleCount) {
    if (sampleCount < 2) return TrendDirection.insufficientData;
    if (volatility >= 1.5) return TrendDirection.volatile;
    if (delta >= 0.75) return TrendDirection.rising;
    if (delta <= -0.75) return TrendDirection.falling;
    return TrendDirection.stable;
  }

  bool _isEnergyFalling(List<DailyCheckIn> checkIns) {
    if (checkIns.length < 4) return false;
    final recent = _takeLast(checkIns, 6);
    if (recent.length < 4) return false;
    final split = recent.length ~/ 2;
    final previousValues =
        recent.take(split).map((item) => item.energy.toDouble()).toList();
    final latestValues =
        recent.skip(split).map((item) => item.energy.toDouble()).toList();
    if (previousValues.isEmpty || latestValues.isEmpty) return false;
    final previousAvg =
        previousValues.reduce((a, b) => a + b) / previousValues.length;
    final latestAvg = latestValues.reduce((a, b) => a + b) / latestValues.length;
    return latestAvg <= previousAvg - config.energyDropThreshold;
  }

  double _volatility(List<double> values) {
    if (values.length < 2) return 0;
    var total = 0.0;
    for (var index = 1; index < values.length; index++) {
      total += (values[index] - values[index - 1]).abs();
    }
    return total / (values.length - 1);
  }

  List<T> _takeLast<T>(List<T> items, int count) {
    if (items.length <= count) return List<T>.from(items);
    return items.sublist(items.length - count);
  }

  double _computeConfidence(List<TrendSnapshot> snapshots, int signalCount) {
    if (snapshots.isEmpty) return 0;
    final usable = snapshots.where((item) => item.sampleCount > 0).toList();
    if (usable.isEmpty) return 0.2;
    final coverage = usable
            .map((item) => ((item.sampleCount / config.minConfidenceSampleCount)
                    .clamp(0, 1))
                .toDouble())
            .reduce((a, b) => a + b) /
        usable.length;
    final signalWeight = (signalCount / 6).clamp(0, 1).toDouble();
    return (coverage * 0.7 + signalWeight * 0.3).clamp(0.0, 1.0);
  }
}
