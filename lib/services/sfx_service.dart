import 'haptics_service.dart';
import 'sound_service.dart';

class SfxService {
  const SfxService._();

  static void configure({
    required bool soundEnabled,
    required bool hapticsOn,
  }) {
    SoundService.instance.setEnabled(soundEnabled);
    HapticsService.instance.setEnabled(hapticsOn);
  }

  static Future<void> play(
    String fileName, {
    double volume = 0.7,
  }) {
    return SoundService.instance.play(fileName, volume: volume);
  }

  static Future<void> tap() async {
    await SoundService.instance.play('changing.wav');
    await HapticsService.instance.selection();
  }

  static Future<void> alert() async {
    await SoundService.instance.play('alert.wav', volume: 0.8);
    await HapticsService.instance.medium();
  }

  static Future<void> selection() => HapticsService.instance.selection();
  static Future<void> light() => HapticsService.instance.light();
  static Future<void> medium() => HapticsService.instance.medium();
  static Future<void> heavy() => HapticsService.instance.heavy();
  static Future<void> success() => HapticsService.instance.success();
}
