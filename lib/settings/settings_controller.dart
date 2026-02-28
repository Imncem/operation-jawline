import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/haptics_service.dart';
import '../services/sound_service.dart';
import 'app_settings.dart';
import 'settings_repo.dart';

final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo());

class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsController(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  final SettingsRepo _repo;

  Future<void> _load() async {
    final settings = await _repo.load();
    _applyServices(settings);
    state = AsyncValue.data(settings);
  }

  Future<void> setSoundEnabled(bool value) async {
    final current = state.value ?? AppSettings.defaults();
    final next = current.copyWith(soundEnabled: value);
    await _repo.save(next);
    _applyServices(next);
    state = AsyncValue.data(next);
  }

  Future<void> setHapticsEnabled(bool value) async {
    final current = state.value ?? AppSettings.defaults();
    final next = current.copyWith(hapticsEnabled: value);
    await _repo.save(next);
    _applyServices(next);
    state = AsyncValue.data(next);
  }

  void _applyServices(AppSettings settings) {
    SoundService.instance.setEnabled(settings.soundEnabled);
    HapticsService.instance.setEnabled(settings.hapticsEnabled);
  }
}

final feedbackSettingsProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  return SettingsController(ref.watch(settingsRepoProvider));
});
