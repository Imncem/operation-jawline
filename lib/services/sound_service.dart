import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer(playerId: 'operation_jawline_sfx');
  bool _enabled = true;
  bool _isConfigured = false;
  final Map<String, Uint8List> _assetCache = {};

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    try {
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);
      _isConfigured = true;
      debugPrint('[SoundService] player configured');
    } catch (e, st) {
      debugPrint('[SoundService] configure failed: $e');
      debugPrint('$st');
    }
  }

  void setEnabled(bool value) {
    _enabled = value;
    debugPrint('[SoundService] enabled=$_enabled');
  }

  bool get isEnabled => _enabled;

  Future<void> play(
    String fileName, {
    double volume = 0.7,
  }) async {
    if (!_enabled) {
      debugPrint('[SoundService] skipped (disabled): $fileName');
      return;
    }

    final normalized = fileName
        .replaceFirst(RegExp(r'^assets/sfx/'), '')
        .replaceFirst(RegExp(r'^sfx/'), '');
    if (normalized.isEmpty) {
      debugPrint('[SoundService] invalid filename: $fileName');
      return;
    }

    try {
      await _ensureConfigured();
      final bytes = await _loadAssetBytes(normalized);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.stop();
      await _player
          .play(BytesSource(bytes, mimeType: _mimeTypeFor(normalized)));
    } catch (e, st) {
      debugPrint('[SoundService] failed to play $fileName: $e');
      debugPrint('$st');
      await _playFallback(volume: volume);
    }
  }

  Future<Uint8List> _loadAssetBytes(String normalized) async {
    final cached = _assetCache[normalized];
    if (cached != null) return cached;

    final data = await rootBundle.load('assets/sfx/$normalized');
    final bytes = data.buffer.asUint8List();
    _assetCache[normalized] = bytes;
    debugPrint(
      '[SoundService] loaded bytes for $normalized (${bytes.length} bytes)',
    );
    return bytes;
  }

  String? _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return null;
  }

  Future<void> _playFallback({required double volume}) async {
    try {
      final bytes = await _loadAssetBytes('alert.wav');
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await _player.stop();
      await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      debugPrint('[SoundService] fallback alert.wav played');
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
      debugPrint('[SoundService] fallback SystemSound.click played');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
