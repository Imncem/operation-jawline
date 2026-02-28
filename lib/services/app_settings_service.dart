import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.units,
    required this.equipmentPreference,
    required this.workoutDurationPreference,
    required this.onboardingShown,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      soundEnabled: true,
      hapticsEnabled: true,
      units: 'kg',
      equipmentPreference: 'minimal',
      workoutDurationPreference: 'standard',
      onboardingShown: false,
    );
  }

  final bool soundEnabled;
  final bool hapticsEnabled;
  final String units;
  final String equipmentPreference;
  final String workoutDurationPreference;
  final bool onboardingShown;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    String? units,
    String? equipmentPreference,
    String? workoutDurationPreference,
    bool? onboardingShown,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      units: units ?? this.units,
      equipmentPreference: equipmentPreference ?? this.equipmentPreference,
      workoutDurationPreference:
          workoutDurationPreference ?? this.workoutDurationPreference,
      onboardingShown: onboardingShown ?? this.onboardingShown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'units': units,
      'equipmentPreference': equipmentPreference,
      'workoutDurationPreference': workoutDurationPreference,
      'onboardingShown': onboardingShown,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      soundEnabled: map['soundEnabled'] as bool? ?? defaults.soundEnabled,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      units: map['units'] as String? ?? defaults.units,
      equipmentPreference:
          map['equipmentPreference'] as String? ?? defaults.equipmentPreference,
      workoutDurationPreference: map['workoutDurationPreference'] as String? ??
          defaults.workoutDurationPreference,
      onboardingShown:
          map['onboardingShown'] as bool? ?? defaults.onboardingShown,
    );
  }
}

class AppSettingsService {
  static const _key = 'app_settings_v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return AppSettings.defaults();
    return AppSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  return AppSettingsService();
});

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  AppSettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  final AppSettingsService _service;

  Future<void> _load() async {
    state = AsyncValue.data(await _service.load());
  }

  Future<void> update(AppSettings Function(AppSettings current) mutate) async {
    final current = state.value ?? AppSettings.defaults();
    final next = mutate(current);
    await _service.save(next);
    state = AsyncValue.data(next);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return AppSettingsNotifier(ref.watch(appSettingsServiceProvider));
});
