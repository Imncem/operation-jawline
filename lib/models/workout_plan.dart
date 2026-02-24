import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'workout_item.dart';

class WorkoutPlan extends Equatable {
  const WorkoutPlan({
    required this.warmup,
    required this.main,
    this.finisher,
    required this.cooldown,
    required this.safetyNotes,
    required this.explanations,
  });

  final List<WorkoutItem> warmup;
  final List<WorkoutItem> main;
  final WorkoutItem? finisher;
  final List<WorkoutItem> cooldown;
  final List<String> safetyNotes;
  final List<String> explanations;

  Map<String, dynamic> toMap() {
    return {
      'warmup': warmup.map((item) => item.toMap()).toList(),
      'main': main.map((item) => item.toMap()).toList(),
      'finisher': finisher?.toMap(),
      'cooldown': cooldown.map((item) => item.toMap()).toList(),
      'safetyNotes': safetyNotes,
      'explanations': explanations,
    };
  }

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    List<WorkoutItem> parseList(dynamic value) {
      final list = (value ?? const []) as List<dynamic>;
      return list
          .map((item) => WorkoutItem.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return WorkoutPlan(
      warmup: parseList(map['warmup']),
      main: parseList(map['main']),
      finisher: map['finisher'] == null
          ? null
          : WorkoutItem.fromMap(map['finisher'] as Map<String, dynamic>),
      cooldown: parseList(map['cooldown']),
      safetyNotes: List<String>.from((map['safetyNotes'] ?? const []) as List),
      explanations:
          List<String>.from((map['explanations'] ?? const []) as List),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkoutPlan.fromJson(String source) =>
      WorkoutPlan.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        warmup,
        main,
        finisher,
        cooldown,
        safetyNotes,
        explanations,
      ];
}
