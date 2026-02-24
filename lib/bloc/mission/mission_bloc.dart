import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/mission_repository.dart';
import 'mission_event.dart';
import 'mission_state.dart';

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  MissionBloc({required MissionRepository missionRepository})
      : _missionRepository = missionRepository,
        super(MissionState.initial()) {
    on<LoadMissionRequested>(_onLoadMissionRequested);
    on<CheckInSubmitted>(_onCheckInSubmitted);
  }

  final MissionRepository _missionRepository;

  Future<void> _onLoadMissionRequested(
    LoadMissionRequested event,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(status: MissionStatus.loading));
    try {
      final snapshot = await _missionRepository.loadSnapshot();
      emit(
        state.copyWith(
          status: MissionStatus.ready,
          snapshot: snapshot,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MissionStatus.failure,
          errorMessage: 'Unable to load mission data.',
        ),
      );
    }
  }

  Future<void> _onCheckInSubmitted(
    CheckInSubmitted event,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(status: MissionStatus.submitting));
    try {
      final snapshot = await _missionRepository.submitCheckIn(event.checkIn);
      emit(
        state.copyWith(
          status: MissionStatus.ready,
          snapshot: snapshot,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MissionStatus.failure,
          errorMessage: 'Check-in failed. Try again.',
        ),
      );
    }
  }
}
