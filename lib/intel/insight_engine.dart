import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';

class InsightEngine {
  const InsightEngine();

  List<String> buildInsights({
    required List<DailyCheckIn> checkIns,
    required List<DailyMissionRecord> missionRecords,
  }) {
    final out = <String>[];
    if (checkIns.length < 2) {
      return const ['Not enough data for trend detection yet.'];
    }

    double slope(List<double> values) {
      if (values.length < 2) return 0;
      return values.last - values.first;
    }

    final energyTrend =
        slope(checkIns.map((e) => e.energy.toDouble()).toList());
    if (energyTrend >= 1) out.add('Energy trending upward');
    if (energyTrend <= -1) out.add('Energy trending downward');

    final hydrationValues = checkIns.map((e) => e.waterLiters).toList();
    final hydrationRange = hydrationValues.reduce((a, b) => a > b ? a : b) -
        hydrationValues.reduce((a, b) => a < b ? a : b);
    if (hydrationRange > 1.2) out.add('Hydration inconsistent');

    final puffinessTrend =
        slope(checkIns.map((e) => e.puffiness.toDouble()).toList());
    if (puffinessTrend <= -1) out.add('Puffiness decreasing');
    if (puffinessTrend >= 1) out.add('Puffiness increasing');

    if (missionRecords.length >= 2) {
      final completionTrend =
          missionRecords.last.completion - missionRecords.first.completion;
      if (completionTrend > 0.1) out.add('Mission consistency improving');
      if (completionTrend < -0.1) out.add('Mission consistency slipping');
    }

    return out.isEmpty
        ? const ['Performance stable across recent reports.']
        : out;
  }
}
