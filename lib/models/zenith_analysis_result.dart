import 'dart:convert';

enum ZenithLaneBias { none, recovery, light, moderate, hard }

enum ZenithFocusBias { none, mobility, strength, mixed, conditioning }

extension ZenithLaneBiasX on ZenithLaneBias {
  String get label => name[0].toUpperCase() + name.substring(1);

  String toJsonValue() => name;

  static ZenithLaneBias fromJsonValue(String? value) {
    return ZenithLaneBias.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ZenithLaneBias.none,
    );
  }
}

extension ZenithFocusBiasX on ZenithFocusBias {
  String get label => name == 'none'
      ? 'None'
      : name[0].toUpperCase() + name.substring(1);

  String toJsonValue() => name;

  static ZenithFocusBias fromJsonValue(String? value) {
    return ZenithFocusBias.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ZenithFocusBias.none,
    );
  }
}

class ZenithAnalysisResult {
  const ZenithAnalysisResult({
    required this.summaryTitle,
    required this.summaryText,
    required this.bulletInsights,
    required this.recommendedActionTitle,
    required this.recommendedActionText,
    required this.laneBias,
    required this.focusBias,
    required this.durationModifierMin,
    required this.cautionFlags,
    required this.confidenceScore,
    required this.sourceSignals,
  });

  final String summaryTitle;
  final String summaryText;
  final List<String> bulletInsights;
  final String recommendedActionTitle;
  final String recommendedActionText;
  final ZenithLaneBias laneBias;
  final ZenithFocusBias focusBias;
  final int durationModifierMin;
  final List<String> cautionFlags;
  final double confidenceScore;
  final List<String> sourceSignals;

  String get confidenceLabel {
    if (confidenceScore >= 0.75) return 'High';
    if (confidenceScore >= 0.45) return 'Medium';
    return 'Low';
  }

  Map<String, dynamic> toMap() {
    return {
      'summaryTitle': summaryTitle,
      'summaryText': summaryText,
      'bulletInsights': bulletInsights,
      'recommendedActionTitle': recommendedActionTitle,
      'recommendedActionText': recommendedActionText,
      'laneBias': laneBias.toJsonValue(),
      'focusBias': focusBias.toJsonValue(),
      'durationModifierMin': durationModifierMin,
      'cautionFlags': cautionFlags,
      'confidenceScore': confidenceScore,
      'sourceSignals': sourceSignals,
    };
  }

  factory ZenithAnalysisResult.fromMap(Map<String, dynamic> map) {
    return ZenithAnalysisResult(
      summaryTitle: map['summaryTitle'] as String? ?? '',
      summaryText: map['summaryText'] as String? ?? '',
      bulletInsights: List<String>.from(map['bulletInsights'] as List? ?? []),
      recommendedActionTitle:
          map['recommendedActionTitle'] as String? ?? '',
      recommendedActionText: map['recommendedActionText'] as String? ?? '',
      laneBias: ZenithLaneBiasX.fromJsonValue(map['laneBias'] as String?),
      focusBias: ZenithFocusBiasX.fromJsonValue(map['focusBias'] as String?),
      durationModifierMin: map['durationModifierMin'] as int? ?? 0,
      cautionFlags: List<String>.from(map['cautionFlags'] as List? ?? []),
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0,
      sourceSignals: List<String>.from(map['sourceSignals'] as List? ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ZenithAnalysisResult.fromJson(String source) =>
      ZenithAnalysisResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
