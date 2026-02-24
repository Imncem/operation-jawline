import 'dart:convert';

import 'package:equatable/equatable.dart';

class WorkoutItem extends Equatable {
  const WorkoutItem({
    required this.name,
    this.sets,
    this.reps,
    this.time,
    this.restSec,
    this.note,
  });

  final String name;
  final int? sets;
  final String? reps;
  final String? time;
  final int? restSec;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'time': time,
      'restSec': restSec,
      'note': note,
    };
  }

  factory WorkoutItem.fromMap(Map<String, dynamic> map) {
    return WorkoutItem(
      name: (map['name'] ?? 'Movement') as String,
      sets: map['sets'] as int?,
      reps: map['reps'] as String?,
      time: map['time'] as String?,
      restSec: map['restSec'] as int?,
      note: map['note'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkoutItem.fromJson(String source) =>
      WorkoutItem.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [name, sets, reps, time, restSec, note];
}
