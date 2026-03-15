import 'dart:convert';

enum TrendDirection {
  rising,
  falling,
  stable,
  volatile,
  insufficientData,
}

extension TrendDirectionX on TrendDirection {
  String toJsonValue() => name;

  static TrendDirection fromJsonValue(String? value) {
    return TrendDirection.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TrendDirection.insufficientData,
    );
  }
}

class TrendSnapshot {
  const TrendSnapshot({
    required this.metricKey,
    required this.latestValue,
    required this.averageValue,
    required this.minValue,
    required this.maxValue,
    required this.delta7,
    required this.delta30,
    required this.trendDirection,
    required this.volatilityScore,
    required this.sampleCount,
  });

  final String metricKey;
  final double latestValue;
  final double averageValue;
  final double minValue;
  final double maxValue;
  final double delta7;
  final double delta30;
  final TrendDirection trendDirection;
  final double volatilityScore;
  final int sampleCount;

  Map<String, dynamic> toMap() {
    return {
      'metricKey': metricKey,
      'latestValue': latestValue,
      'averageValue': averageValue,
      'minValue': minValue,
      'maxValue': maxValue,
      'delta7': delta7,
      'delta30': delta30,
      'trendDirection': trendDirection.toJsonValue(),
      'volatilityScore': volatilityScore,
      'sampleCount': sampleCount,
    };
  }

  factory TrendSnapshot.fromMap(Map<String, dynamic> map) {
    return TrendSnapshot(
      metricKey: map['metricKey'] as String? ?? '',
      latestValue: (map['latestValue'] as num?)?.toDouble() ?? 0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0,
      minValue: (map['minValue'] as num?)?.toDouble() ?? 0,
      maxValue: (map['maxValue'] as num?)?.toDouble() ?? 0,
      delta7: (map['delta7'] as num?)?.toDouble() ?? 0,
      delta30: (map['delta30'] as num?)?.toDouble() ?? 0,
      trendDirection:
          TrendDirectionX.fromJsonValue(map['trendDirection'] as String?),
      volatilityScore: (map['volatilityScore'] as num?)?.toDouble() ?? 0,
      sampleCount: map['sampleCount'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TrendSnapshot.fromJson(String source) =>
      TrendSnapshot.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
