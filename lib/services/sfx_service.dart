import 'package:flutter/services.dart';

class SfxService {
  const SfxService._();

  static void tap() {
    SystemSound.play(SystemSoundType.click);
  }

  static void alert() {
    SystemSound.play(SystemSoundType.alert);
  }
}
