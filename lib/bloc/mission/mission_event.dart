import 'package:equatable/equatable.dart';

import '../../models/daily_check_in.dart';

abstract class MissionEvent extends Equatable {
  const MissionEvent();

  @override
  List<Object?> get props => [];
}

class LoadMissionRequested extends MissionEvent {
  const LoadMissionRequested();
}

class CheckInSubmitted extends MissionEvent {
  const CheckInSubmitted(this.checkIn);

  final DailyCheckIn checkIn;

  @override
  List<Object?> get props => [checkIn];
}
