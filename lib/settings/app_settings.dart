class AppSettings {
  const AppSettings({
    required this.soundEnabled,
    required this.hapticsEnabled,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      soundEnabled: true,
      hapticsEnabled: true,
    );
  }

  final bool soundEnabled;
  final bool hapticsEnabled;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}
