import 'dart:convert';

import 'zenith_analysis_result.dart';

class ZenithAdjustment {
  const ZenithAdjustment({
    this.laneOverrideSuggestion,
    required this.laneNudge,
    this.focusSuggestion,
    required this.durationDeltaMin,
    required this.restrictHighIntensity,
    required this.preferRecovery,
    required this.rationale,
  });

  final ZenithLaneBias? laneOverrideSuggestion;
  final int laneNudge;
  final ZenithFocusBias? focusSuggestion;
  final int durationDeltaMin;
  final bool restrictHighIntensity;
  final bool preferRecovery;
  final List<String> rationale;

  Map<String, dynamic> toMap() {
    return {
      'laneOverrideSuggestion': laneOverrideSuggestion?.toJsonValue(),
      'laneNudge': laneNudge,
      'focusSuggestion': focusSuggestion?.toJsonValue(),
      'durationDeltaMin': durationDeltaMin,
      'restrictHighIntensity': restrictHighIntensity,
      'preferRecovery': preferRecovery,
      'rationale': rationale,
    };
  }

  factory ZenithAdjustment.fromMap(Map<String, dynamic> map) {
    return ZenithAdjustment(
      laneOverrideSuggestion: map['laneOverrideSuggestion'] == null
          ? null
          : ZenithLaneBiasX.fromJsonValue(
              map['laneOverrideSuggestion'] as String?,
            ),
      laneNudge: map['laneNudge'] as int? ?? 0,
      focusSuggestion: map['focusSuggestion'] == null
          ? null
          : ZenithFocusBiasX.fromJsonValue(map['focusSuggestion'] as String?),
      durationDeltaMin: map['durationDeltaMin'] as int? ?? 0,
      restrictHighIntensity: map['restrictHighIntensity'] as bool? ?? false,
      preferRecovery: map['preferRecovery'] as bool? ?? false,
      rationale: List<String>.from(map['rationale'] as List? ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ZenithAdjustment.fromJson(String source) =>
      ZenithAdjustment.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
