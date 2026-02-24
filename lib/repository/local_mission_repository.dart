import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_check_in.dart';
import '../models/mission_snapshot.dart';
import 'mission_repository.dart';

class LocalMissionRepository implements MissionRepository {
  static const _latestCheckInKey = 'latest_check_in';
  static const _disciplineChainKey = 'discipline_chain';
  static const _lastCheckInDateKey = 'last_check_in_date';

  @override
  Future<MissionSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();

    final latestJson = prefs.getString(_latestCheckInKey);
    final latest =
        latestJson == null ? null : DailyCheckIn.fromJson(latestJson);
    var chain = prefs.getInt(_disciplineChainKey) ?? 0;
    final lastDateRaw = prefs.getString(_lastCheckInDateKey);

    var chainCompromised = false;

    if (lastDateRaw != null) {
      final lastDate = DateTime.parse(lastDateRaw);
      final inactiveDays = _calendarDayDifference(lastDate, DateTime.now());

      if (inactiveDays >= 2 && chain > 0) {
        chain = 0;
        chainCompromised = true;
        await prefs.setInt(_disciplineChainKey, chain);
      }
    }

    return MissionSnapshot(
      latestCheckIn: latest?.copyWith(disciplineChain: chain),
      disciplineChain: chain,
      chainCompromised: chainCompromised,
      recommendation:
          latest == null ? null : _buildRecommendation(latest.energy),
    );
  }

  @override
  Future<MissionSnapshot> submitCheckIn(DailyCheckIn checkIn) async {
    final prefs = await SharedPreferences.getInstance();
    var chain = prefs.getInt(_disciplineChainKey) ?? 0;
    final lastDateRaw = prefs.getString(_lastCheckInDateKey);

    var chainCompromised = false;

    if (lastDateRaw == null) {
      chain = 1;
    } else {
      final lastDate = DateTime.parse(lastDateRaw);
      final dayDiff = _calendarDayDifference(lastDate, checkIn.lastCheckIn);

      if (dayDiff == 0) {
        chain = chain == 0 ? 1 : chain;
      } else if (dayDiff == 1) {
        chain += 1;
      } else {
        chain = 1;
        chainCompromised = true;
      }
    }

    final updatedCheckIn = checkIn.copyWith(disciplineChain: chain);

    await prefs.setString(_latestCheckInKey, updatedCheckIn.toJson());
    await prefs.setInt(_disciplineChainKey, chain);
    await prefs.setString(
      _lastCheckInDateKey,
      updatedCheckIn.lastCheckIn.toIso8601String(),
    );

    return MissionSnapshot(
      latestCheckIn: updatedCheckIn,
      disciplineChain: chain,
      chainCompromised: chainCompromised,
      recommendation: _buildRecommendation(updatedCheckIn.energy),
    );
  }

  int _calendarDayDifference(DateTime from, DateTime to) {
    final startFrom = DateTime(from.year, from.month, from.day);
    final startTo = DateTime(to.year, to.month, to.day);
    return startTo.difference(startFrom).inDays;
  }

  String _buildRecommendation(int energy) {
    if (energy <= 4) {
      return 'Mobility / Light Walk';
    }
    if (energy <= 7) {
      return 'Standard Training';
    }
    return 'Aggressive Protocol';
  }
}
