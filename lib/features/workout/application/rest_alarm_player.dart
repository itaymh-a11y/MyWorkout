import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// מנגן צליל סיום מנוחה (~3 שניות) בין סטים.
class RestAlarmPlayer {
  AudioPlayer? _player;
  static Uint8List? _wavCache;
  bool _isConfigured = false;

  Future<void> _ensureReady() async {
    if (_isConfigured) return;

    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    _player ??= AudioPlayer(playerId: 'rest-alarm-player');
    await _player!.setReleaseMode(ReleaseMode.stop);
    _wavCache ??= _buildAlarmWav();
    _isConfigured = true;
  }

  Future<void> play() async {
    try {
      await _ensureReady();
      await _player!.stop();
      await _player!.play(BytesSource(_wavCache!));
    } catch (e, st) {
      debugPrint('RestAlarmPlayer: $e\n$st');
    }
  }

  Future<void> stop() async {
    await _player?.stop();
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _isConfigured = false;
  }

  /// WAV מונו 16-bit, ~3 שניות — צליל צ'יים רגוע ולא חד.
  static Uint8List _buildAlarmWav() {
    const sampleRate = 22050;
    const durationSec = 3.0;
    const amplitude = 0.24;
    final sampleCount = (sampleRate * durationSec).round();
    final pcm = ByteData(sampleCount * 2);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      // Three soft chimes over ~3 seconds, each with smooth attack/decay.
      const starts = <double>[0.0, 1.0, 2.0];
      var env = 0.0;
      for (final start in starts) {
        final dt = t - start;
        if (dt < 0 || dt > 0.55) continue;
        final attack = dt < 0.03 ? (dt / 0.03) : 1.0;
        final decay = math.exp(-3.8 * dt);
        env += attack * decay;
      }
      env = env.clamp(0.0, 1.0);

      // Gentle two-tone musical blend (C5 + E5) instead of siren-like sweep.
      final freq1 = 523.25;
      final freq2 = 659.25;
      final sample =
          (32767 *
                  amplitude *
                  env *
                  (0.68 * math.sin(2 * math.pi * freq1 * t) +
                      0.32 * math.sin(2 * math.pi * freq2 * t)))
              .round();
      pcm.setInt16(i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    final dataSize = sampleCount * 2;
    final fileSize = 36 + dataSize;
    final header = ByteData(44);
    void writeStr(int offset, String s) {
      for (var j = 0; j < s.length; j++) {
        header.setUint8(offset + j, s.codeUnitAt(j));
      }
    }

    writeStr(0, 'RIFF');
    header.setUint32(4, fileSize, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final out = Uint8List(44 + dataSize);
    out.setRange(0, 44, header.buffer.asUint8List());
    out.setRange(44, 44 + dataSize, pcm.buffer.asUint8List());
    return out;
  }
}
