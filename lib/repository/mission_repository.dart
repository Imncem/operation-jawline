import '../models/daily_check_in.dart';
import '../models/mission_snapshot.dart';

abstract class MissionRepository {
  Future<MissionSnapshot> loadSnapshot();
  Future<MissionSnapshot> submitCheckIn(DailyCheckIn checkIn);
}
