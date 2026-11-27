import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');
final Map<String, Uint8List> _wavCache = {};
final List<AudioPlayer> _sfxPool = [];
var _poolCursor = 0;

/// 22050Hz 모노 16-bit PCM WAV 바이너리 합성 (Android/네이티브 저지연 효과음용).
Uint8List buildBoardgamePcmWav({
  required double startFreq,
  required double endFreq,
  required double durationSec,
  double volume = 0.25,
  bool triangle = false,
  double noiseMix = 0.0,
  int sampleRate = 22050,
}) {
  final sampleCount = max(1, (sampleRate * durationSec).round());
  final dataSize = sampleCount * 2;
  final byteData = ByteData(44 + dataSize);

  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      byteData.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  // RIFF / WAVE header
  writeAscii(0, 'RIFF');
  byteData.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little); // PCM chunk size
  byteData.setUint16(20, 1, Endian.little); // PCM format
  byteData.setUint16(22, 1, Endian.little); // mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  byteData.setUint32(40, dataSize, Endian.little);

  var phase = 0.0;
  var prevNoise = 0.0;
  final rng = Random(42);
  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleCount;
    final freq = startFreq + (endFreq - startFreq) * t;
    phase += (2 * pi * freq) / sampleRate;
    final attack = i < 40 ? i / 40.0 : 1.0;
    final decay = pow(1.0 - t, 1.8).toDouble();
    final rawOsc = triangle ? (2 / pi) * asin(sin(phase)) : sin(phase);
    final white = rng.nextDouble() * 2 - 1;
    // 간단한 1차 고역/대역 통과 근사로 종이 바스락 질감 생성
    final crispNoise = (white - prevNoise * 0.7).clamp(-1.0, 1.0);
    prevNoise = white;
    final mixed = rawOsc * (1.0 - noiseMix) + crispNoise * noiseMix;
    final sample = (mixed * volume * attack * decay * 32767.0)
        .round()
        .clamp(-32768, 32767);
    byteData.setInt16(44 + i * 2, sample, Endian.little);
  }

  return byteData.buffer.asUint8List();
}

Uint8List _getCachedWav(String key) {
  return _wavCache.putIfAbsent(key, () {
    switch (key) {
      case 'click':
        return buildBoardgamePcmWav(
          startFreq: 440,
          endFreq: 190,
          durationSec: 0.042,
          volume: 0.28,
          triangle: true,
        );
      case 'tab':
        return buildBoardgamePcmWav(
          startFreq: 580,
          endFreq: 780,
          durationSec: 0.036,
          volume: 0.20,
        );
      case 'modal':
        return buildBoardgamePcmWav(
          startFreq: 392,
          endFreq: 523.25,
          durationSec: 0.075,
          volume: 0.22,
          triangle: true,
        );
      case 'coin':
        return buildBoardgamePcmWav(
          startFreq: 1318.51,
          endFreq: 1975.53,
          durationSec: 0.14,
          volume: 0.26,
        );
      case 'bet_chip':
        return buildBoardgamePcmWav(
          startFreq: 1567.98,
          endFreq: 2349.32,
          durationSec: 0.11,
          volume: 0.25,
          noiseMix: 0.35,
        );
      case 'bid_coin':
        return buildBoardgamePcmWav(
          startFreq: 1318.51,
          endFreq: 2217.46,
          durationSec: 0.14,
          volume: 0.26,
        );
      case 'refund':
        return buildBoardgamePcmWav(
          startFreq: 1567.98,
          endFreq: 1174.66,
          durationSec: 0.15,
          volume: 0.24,
        );
      case 'transfer':
        return buildBoardgamePcmWav(
          startFreq: 523.25,
          endFreq: 1046.5,
          durationSec: 0.18,
          volume: 0.24,
          triangle: true,
        );
      case 'auction':
        return buildBoardgamePcmWav(
          startFreq: 220,
          endFreq: 110,
          durationSec: 0.32,
          volume: 0.34,
          triangle: true,
        );
      case 'win':
        return buildBoardgamePcmWav(
          startFreq: 523.25,
          endFreq: 1046.5,
          durationSec: 0.28,
          volume: 0.28,
          triangle: true,
        );
      case 'dice':
        return buildBoardgamePcmWav(
          startFreq: 360,
          endFreq: 240,
          durationSec: 0.10,
          volume: 0.25,
          triangle: true,
        );
      case 'secret_fold':
        return buildBoardgamePcmWav(
          startFreq: 160,
          endFreq: 85,
          durationSec: 0.095,
          volume: 0.24,
          noiseMix: 0.85,
        );
      case 'secret_reveal':
        return buildBoardgamePcmWav(
          startFreq: 220,
          endFreq: 320,
          durationSec: 0.14,
          volume: 0.26,
          noiseMix: 0.90,
        );
      case 'secret_write':
        return buildBoardgamePcmWav(
          startFreq: 260,
          endFreq: 300,
          durationSec: 0.06,
          volume: 0.20,
          noiseMix: 0.92,
        );
      case 'secret_lock':
      default:
        return buildBoardgamePcmWav(
          startFreq: 210,
          endFreq: 88,
          durationSec: 0.11,
          volume: 0.28,
          triangle: true,
          noiseMix: 0.45,
        );
    }
  });
}

void _playNativeSfx(bool enabled, String key) {
  if (!enabled || _isFlutterTest) return;
  try {
    if (_sfxPool.length < 3) {
      _sfxPool.add(
        AudioPlayer(
          playerId: 'bgcalc_sfx_${_sfxPool.length}',
        ),
      );
    }
    final player = _sfxPool[_poolCursor % _sfxPool.length];
    _poolCursor = (_poolCursor + 1) % 3;
    final bytes = _getCachedWav(key);
    unawaited(() async {
      try {
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.play(BytesSource(bytes));
      } catch (_) {}
    }());
  } catch (_) {}
}

void playClickSound(bool enabled) => _playNativeSfx(enabled, 'click');
void playTabSound(bool enabled) => _playNativeSfx(enabled, 'tab');
void playModalSound(bool enabled) => _playNativeSfx(enabled, 'modal');
void playCoinSound(bool enabled) => _playNativeSfx(enabled, 'coin');
void playBetChipSound(bool enabled) => _playNativeSfx(enabled, 'bet_chip');
void playBidCoinSound(bool enabled) => _playNativeSfx(enabled, 'bid_coin');
void playRefundSound(bool enabled) => _playNativeSfx(enabled, 'refund');
void playTransferSound(bool enabled) => _playNativeSfx(enabled, 'transfer');
void playAuctionGong(bool enabled) => _playNativeSfx(enabled, 'auction');
void playWinSound(bool enabled) => _playNativeSfx(enabled, 'win');
void playDiceSound(bool enabled) => _playNativeSfx(enabled, 'dice');
void playSecretNoteFoldSound(bool enabled) =>
    _playNativeSfx(enabled, 'secret_fold');
void playSecretNoteRevealSound(bool enabled) =>
    _playNativeSfx(enabled, 'secret_reveal');
void playSecretNoteWriteSound(bool enabled) =>
    _playNativeSfx(enabled, 'secret_write');
void playSecretNoteLockSound(bool enabled) =>
    _playNativeSfx(enabled, 'secret_lock');
