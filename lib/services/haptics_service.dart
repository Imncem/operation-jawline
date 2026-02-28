import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();

  static final HapticsService instance = HapticsService._();

  bool _enabled = true;

  void setEnabled(bool value) {
    _enabled = value;
    debugPrint('[HapticsService] enabled=$_enabled');
  }

  bool get isEnabled => _enabled;

  Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> light() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
    await HapticFeedback.lightImpact();
  }
}
