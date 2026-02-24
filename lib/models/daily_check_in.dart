import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'enums.dart';

class DailyCheckIn extends Equatable {
  const DailyCheckIn({
    required this.energy,
    required this.sleepHours,
    required this.waterLiters,
    this.weightKg,
    required this.mood,
    required this.puffiness,
    required this.disciplineChain,
    required this.lastCheckIn,
  });

  final int energy;
  final double sleepHours;
  final double waterLiters;
  final double? weightKg;
  final Mood mood;
  final int puffiness;
  final int disciplineChain;
  final DateTime lastCheckIn;

  int get energyLevel => energy;
  int get puffinessRating => puffiness;
  DateTime get date => lastCheckIn;

  DailyCheckIn copyWith({
    int? energy,
    double? sleepHours,
    double? waterLiters,
    double? weightKg,
    bool clearWeight = false,
    Mood? mood,
    int? puffiness,
    int? disciplineChain,
    DateTime? lastCheckIn,
  }) {
    return DailyCheckIn(
      energy: energy ?? this.energy,
      sleepHours: sleepHours ?? this.sleepHours,
      waterLiters: waterLiters ?? this.waterLiters,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      mood: mood ?? this.mood,
      puffiness: puffiness ?? this.puffiness,
      disciplineChain: disciplineChain ?? this.disciplineChain,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'energy': energy,
      'sleepHours': sleepHours,
      'waterLiters': waterLiters,
      'weightKg': weightKg,
      'mood': mood.toJsonValue(),
      'puffiness': puffiness,
      'disciplineChain': disciplineChain,
      'lastCheckIn': lastCheckIn.toIso8601String(),
    };
  }

  factory DailyCheckIn.fromMap(Map<String, dynamic> map) {
    return DailyCheckIn(
      energy: (map['energy'] ?? map['energyLevel'] ?? 1) as int,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0,
      waterLiters: (map['waterLiters'] as num?)?.toDouble() ?? 0,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      mood: MoodX.fromJsonValue(map['mood'] as String?),
      puffiness: (map['puffiness'] ?? map['puffinessRating'] ?? 3) as int,
      disciplineChain: (map['disciplineChain'] ?? 0) as int,
      lastCheckIn: DateTime.parse(
        (map['lastCheckIn'] ?? map['date'] ?? DateTime.now().toIso8601String())
            as String,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DailyCheckIn.fromJson(String source) =>
      DailyCheckIn.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        energy,
        sleepHours,
        waterLiters,
        weightKg,
        mood,
        puffiness,
        disciplineChain,
        lastCheckIn,
      ];
}
