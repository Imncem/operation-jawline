import 'package:equatable/equatable.dart';

import '../../models/mission_snapshot.dart';

enum MissionStatus { initial, loading, ready, submitting, failure }

class MissionState extends Equatable {
  const MissionState({
    required this.status,
    required this.snapshot,
    this.errorMessage,
  });

  factory MissionState.initial() {
    return MissionState(
      status: MissionStatus.initial,
      snapshot: MissionSnapshot.empty(),
    );
  }

  final MissionStatus status;
  final MissionSnapshot snapshot;
  final String? errorMessage;

  MissionState copyWith({
    MissionStatus? status,
    MissionSnapshot? snapshot,
    String? errorMessage,
  }) {
    return MissionState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}
