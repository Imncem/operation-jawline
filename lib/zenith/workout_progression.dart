import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/readiness_result.dart';
import '../models/workout_item.dart';
import '../models/workout_plan.dart';

class WorkoutProgressMemory {
  const WorkoutProgressMemory({
    required this.templateId,
    required this.completed,
    required this.hadSafetyFlags,
  });

  final String templateId;
  final bool completed;
  final bool hadSafetyFlags;

  Map<String, dynamic> toMap() => {
        'templateId': templateId,
        'completed': completed,
        'hadSafetyFlags': hadSafetyFlags,
      };

  factory WorkoutProgressMemory.fromMap(Map<String, dynamic> map) {
    return WorkoutProgressMemory(
      templateId: map['templateId'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
      hadSafetyFlags: map['hadSafetyFlags'] as bool? ?? false,
    );
  }
}

class WorkoutProgressionRepository {
  static const _key = 'zenith_workout_memory_v1';

  Future<WorkoutProgressMemory?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return WorkoutProgressMemory.fromMap(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(WorkoutProgressMemory memory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(memory.toMap()));
  }
}

class WorkoutProgressionEngine {
  const WorkoutProgressionEngine();

  WorkoutPlan apply({
    required WorkoutPlan plan,
    required ReadinessResult readiness,
    required String templateId,
    required WorkoutProgressMemory? memory,
  }) {
    final repeated = memory?.templateId == templateId;
    final safeForProgress = readiness.riskFlags.isEmpty &&
        readiness.lane.index >= TrainingLane.moderate.index &&
        (memory?.completed ?? false);

    if (!repeated) return plan;

    if (!safeForProgress || (memory?.hadSafetyFlags ?? false)) {
      return _regress(plan);
    }

    switch (readiness.focus) {
      case WorkoutFocus.strength:
      case WorkoutFocus.mixed:
        return _progressStrength(plan);
      case WorkoutFocus.cardio:
        return _progressConditioning(plan);
      case WorkoutFocus.mobility:
        return plan;
    }
  }

  WorkoutPlan _progressStrength(WorkoutPlan plan) {
    final main = plan.main.map((item) {
      if (item.sets == null) return item;
      final nextSets = item.sets! >= 4 ? item.sets : item.sets! + 1;
      return WorkoutItem(
        name: item.name,
        sets: nextSets,
        reps: _bumpRepRange(item.reps),
        time: item.time,
        restSec: (item.restSec ?? 60) > 40
            ? (item.restSec ?? 60) - 10
            : item.restSec,
        note: item.note,
      );
    }).toList();
    return WorkoutPlan(
      warmup: plan.warmup,
      main: main,
      finisher: plan.finisher,
      cooldown: plan.cooldown,
      safetyNotes: plan.safetyNotes,
      explanations: [
        ...plan.explanations,
        'Progression applied from last successful protocol.'
      ],
    );
  }

  WorkoutPlan _progressConditioning(WorkoutPlan plan) {
    final main = plan.main.map((item) {
      if (item.time == null) return item;
      return WorkoutItem(
        name: item.name,
        sets: item.sets,
        reps: item.reps,
        time: _bumpDuration(item.time!),
        restSec: item.restSec,
        note: item.note,
      );
    }).toList();
    return WorkoutPlan(
      warmup: plan.warmup,
      main: main,
      finisher: plan.finisher,
      cooldown: plan.cooldown,
      safetyNotes: plan.safetyNotes,
      explanations: [
        ...plan.explanations,
        'Conditioning duration increased slightly from prior completion.'
      ],
    );
  }

  WorkoutPlan _regress(WorkoutPlan plan) {
    final main = plan.main.map((item) {
      if (item.restSec == null) return item;
      return WorkoutItem(
        name: item.name,
        sets: item.sets,
        reps: item.reps,
        time: item.time,
        restSec: item.restSec! + 10,
        note: item.note,
      );
    }).toList();
    return WorkoutPlan(
      warmup: plan.warmup,
      main: main,
      finisher: plan.finisher,
      cooldown: plan.cooldown,
      safetyNotes: plan.safetyNotes,
      explanations: [
        ...plan.explanations,
        'Recovery-sensitive adjustment applied to maintain safety.'
      ],
    );
  }

  String? _bumpRepRange(String? reps) {
    if (reps == null) return null;
    final range = RegExp(r'(\d+)-(\d+)').firstMatch(reps);
    if (range == null) return reps;
    final low = int.parse(range.group(1)!);
    final high = int.parse(range.group(2)!);
    return '${low + 1}-${high + 1}';
  }

  String _bumpDuration(String value) {
    final minMatch = RegExp(r'(\d+)\s*-\s*(\d+)\s*min', caseSensitive: false)
        .firstMatch(value);
    if (minMatch != null) {
      final low = int.parse(minMatch.group(1)!);
      final high = int.parse(minMatch.group(2)!);
      return '${low + 2}-${high + 2} min';
    }
    final single =
        RegExp(r'(\d+)\s*min', caseSensitive: false).firstMatch(value);
    if (single != null) {
      final mins = int.parse(single.group(1)!);
      return '${mins + 2} min';
    }
    return value;
  }
}
