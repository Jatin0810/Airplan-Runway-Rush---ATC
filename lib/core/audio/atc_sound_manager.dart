import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pure Dart procedural in-memory WAV audio synthesizer.
class WavToneGenerator {
  static Uint8List createTone({
    required double frequency,
    required double durationMs,
    double volume = 0.45,
    int sampleRate = 22050,
  }) {
    final int numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final int dataSize = numSamples * 2;
    final int fileSize = 44 + dataSize;
    final ByteData byteData = ByteData(fileSize);

    // RIFF Header
    byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    byteData.setUint32(4, fileSize - 8, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // "fmt " Chunk
    byteData.setUint32(12, 0x666d7420, Endian.big);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);

    // "data" Chunk
    byteData.setUint32(36, 0x64617461, Endian.big);
    byteData.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = 1.0 - (i / numSamples); // Linear fade-out
      final double sample = sin(2 * pi * frequency * t) * volume * envelope;
      final int sampleInt16 = (sample * 32767.0).clamp(-32768.0, 32767.0).toInt();
      byteData.setInt16(44 + i * 2, sampleInt16, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static Uint8List createDualTone({
    required double freq1,
    required double freq2,
    required double durationMs1,
    required double durationMs2,
    double volume = 0.45,
    int sampleRate = 22050,
  }) {
    final int s1 = (sampleRate * (durationMs1 / 1000.0)).round();
    final int s2 = (sampleRate * (durationMs2 / 1000.0)).round();
    final int totalSamples = s1 + s2;
    final int dataSize = totalSamples * 2;
    final int fileSize = 44 + dataSize;
    final ByteData byteData = ByteData(fileSize);

    byteData.setUint32(0, 0x52494646, Endian.big);
    byteData.setUint32(4, fileSize - 8, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big);
    byteData.setUint32(12, 0x666d7420, Endian.big);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint32(36, 0x64617461, Endian.big);
    byteData.setUint32(40, dataSize, Endian.little);

    int idx = 0;
    for (int i = 0; i < s1; i++, idx++) {
      final double t = i / sampleRate;
      final double env = 1.0 - (i / s1) * 0.3;
      final double sample = sin(2 * pi * freq1 * t) * volume * env;
      byteData.setInt16(44 + idx * 2, (sample * 32767.0).clamp(-32768.0, 32767.0).toInt(), Endian.little);
    }
    for (int i = 0; i < s2; i++, idx++) {
      final double t = i / sampleRate;
      final double env = 1.0 - (i / s2);
      final double sample = sin(2 * pi * freq2 * t) * volume * env;
      byteData.setInt16(44 + idx * 2, (sample * 32767.0).clamp(-32768.0, 32767.0).toInt(), Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static Uint8List createTouchdownChord({int sampleRate = 22050}) {
    const double noteDuration = 90.0;
    final int samplesPerNote = (sampleRate * (noteDuration / 1000.0)).round();
    final int totalSamples = samplesPerNote * 3;
    final int dataSize = totalSamples * 2;
    final int fileSize = 44 + dataSize;
    final ByteData byteData = ByteData(fileSize);

    byteData.setUint32(0, 0x52494646, Endian.big);
    byteData.setUint32(4, fileSize - 8, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big);
    byteData.setUint32(12, 0x666d7420, Endian.big);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint32(36, 0x64617461, Endian.big);
    byteData.setUint32(40, dataSize, Endian.little);

    final freqs = [523.25, 659.25, 783.99];
    int idx = 0;
    for (final f in freqs) {
      for (int i = 0; i < samplesPerNote; i++, idx++) {
        final double t = i / sampleRate;
        final double env = 1.0 - (i / samplesPerNote) * 0.4;
        final double sample = sin(2 * pi * f * t) * 0.5 * env;
        byteData.setInt16(44 + idx * 2, (sample * 32767.0).clamp(-32768.0, 32767.0).toInt(), Endian.little);
      }
    }

    return byteData.buffer.asUint8List();
  }
}

/// Central audio and Text-to-Speech manager.
/// Actually speaks out realistic ATC voice clearances and plays radar radio sound effects.
class AtcSoundManager {
  static final AtcSoundManager _instance = AtcSoundManager._internal();
  factory AtcSoundManager() => _instance;
  AtcSoundManager._internal() {
    _initTts();
    _precomputeAudioBytes();
  }

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();
  final AudioPlayer _touchdownPlayer = AudioPlayer();

  bool isMuted = false;
  bool isHindiVoice = false;
  bool _isTtsSpeaking = false;

  late final Uint8List _selectBeepBytes;
  late final Uint8List _vectorAssignedBytes;
  late final Uint8List _tcasWarningBytes;
  late final Uint8List _touchdownBytes;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.52); // Natural ATC cadence
      _tts.setCompletionHandler(() {
        _isTtsSpeaking = false;
      });
      _tts.setErrorHandler((_) {
        _isTtsSpeaking = false;
      });
    } catch (_) {}
  }

  void _precomputeAudioBytes() {
    _selectBeepBytes = WavToneGenerator.createTone(
      frequency: 920.0,
      durationMs: 45.0,
      volume: 0.4,
    );
    _vectorAssignedBytes = WavToneGenerator.createDualTone(
      freq1: 587.33,
      freq2: 880.0,
      durationMs1: 65.0,
      durationMs2: 95.0,
      volume: 0.45,
    );
    _tcasWarningBytes = WavToneGenerator.createDualTone(
      freq1: 880.0,
      freq2: 587.0,
      durationMs1: 90.0,
      durationMs2: 90.0,
      volume: 0.6,
    );
    _touchdownBytes = WavToneGenerator.createTouchdownChord();
  }

  void setMuted(bool muted) {
    isMuted = muted;
    if (isMuted) {
      _tts.stop();
      _sfxPlayer.stop().catchError((_) {});
      _alertPlayer.stop().catchError((_) {});
      _touchdownPlayer.stop().catchError((_) {});
    }
  }

  void toggleLanguage() {
    isHindiVoice = !isHindiVoice;
    try {
      _tts.setLanguage(isHindiVoice ? 'hi-IN' : 'en-IN');
    } catch (_) {}
  }

  /// Speaks the given ATC message aloud using synthetic speech engine!
  Future<void> speakAtcCallout(String text) async {
    if (isMuted) return;
    try {
      // Don't interrupt if already speaking
      if (_isTtsSpeaking) {
        await _tts.stop();
      }
      _isTtsSpeaking = true;
      await _tts.speak(text);
    } catch (_) {
      _isTtsSpeaking = false;
    }
  }

  /// Plays crisp ATC radio selection blip.
  void playAircraftSelected() {
    if (isMuted) return;
    HapticFeedback.lightImpact();
    _playSafe(_sfxPlayer, _selectBeepBytes);
  }

  /// Plays confirmation chime when vector / route is assigned.
  void playVectorAssigned() {
    if (isMuted) return;
    HapticFeedback.mediumImpact();
    _playSafe(_sfxPlayer, _vectorAssignedBytes);
  }

  /// Plays urgent TCAS proximity warning alarm.
  void playTcasWarning() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
    _playSafe(_alertPlayer, _tcasWarningBytes);
  }

  /// Plays touchdown victory chord on successful landing.
  void playTouchdownSuccess() {
    if (isMuted) return;
    HapticFeedback.vibrate();
    _playSafe(_touchdownPlayer, _touchdownBytes);
  }

  void _playSafe(AudioPlayer player, Uint8List bytes) {
    try {
      player.play(BytesSource(bytes)).catchError((_) {
        // Gracefully ignore web promise aborts
      });
    } catch (_) {}
  }

  /// Builds a dynamic bilingual radio phrase for ATC clearance.
  String buildClearanceCallout({
    required String airline,
    required String flightNumber,
    required String runway,
  }) {
    if (isHindiVoice) {
      return '$airline $flightNumber, रनवे $runway पर लैंडिंग की अनुमति दी गई।';
    } else {
      return '$airline $flightNumber, cleared to land Runway $runway.';
    }
  }

  String buildArrivalCallout({
    required String airline,
    required String flightNumber,
  }) {
    if (isHindiVoice) {
      return '$airline $flightNumber, रडार संपर्क स्थापित हुआ।';
    } else {
      return '$airline $flightNumber, radar contact established.';
    }
  }

  String buildTouchdownCallout({
    required String airline,
    required String flightNumber,
  }) {
    if (isHindiVoice) {
      return '$airline $flightNumber, सफल लैंडिंग। स्वागत है।';
    } else {
      return '$airline $flightNumber, touchdown confirmed. Welcome to Mumbai!';
    }
  }

  void dispose() {
    _tts.stop();
    _sfxPlayer.dispose();
    _alertPlayer.dispose();
    _touchdownPlayer.dispose();
  }
}
