import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

web.AudioContext? _audioCtx;
web.AudioBuffer? _cachedNoiseBuffer;
final _rng = Random();

web.AudioContext? _getAudioContext() {
  try {
    _audioCtx ??= web.AudioContext();
    if (_audioCtx!.state == 'suspended') {
      _audioCtx!.resume();
    }
    return _audioCtx;
  } catch (_) {
    return null;
  }
}

web.AudioBuffer _getNoiseBuffer(web.AudioContext ctx) {
  if (_cachedNoiseBuffer != null &&
      _cachedNoiseBuffer!.sampleRate == ctx.sampleRate) {
    return _cachedNoiseBuffer!;
  }
  final length = (ctx.sampleRate * 0.5).floor();
  final buffer = ctx.createBuffer(1, length, ctx.sampleRate);
  final data = Float32List(length);
  for (var i = 0; i < length; i++) {
    data[i] = _rng.nextDouble() * 2 - 1;
  }
  buffer.copyToChannel(data.toJS, 0);
  _cachedNoiseBuffer = buffer;
  return buffer;
}

void playClickSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final filter = ctx.createBiquadFilter();
    final gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(440, now);
    osc.frequency.exponentialRampToValueAtTime(185, now + 0.038);
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(1400, now);
    gain.gain.setValueAtTime(0.11, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.042);
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.045);
  } catch (_) {}
}

void playTabSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(580, now);
    osc.frequency.exponentialRampToValueAtTime(790, now + 0.032);
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.036);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.038);
  } catch (_) {}
}

void playModalSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(392, now);
    osc.frequency.exponentialRampToValueAtTime(523.25, now + 0.065);
    gain.gain.setValueAtTime(0.085, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.075);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.08);
  } catch (_) {}
}

void playCoinSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc1 = ctx.createOscillator();
    final gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(1318.51, now);
    osc1.frequency.exponentialRampToValueAtTime(1567.98, now + 0.05);
    gain1.gain.setValueAtTime(0.12, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.11);
    osc1.connect(gain1);
    gain1.connect(ctx.destination);
    osc1.start(now);
    osc1.stop(now + 0.115);

    final t2 = now + 0.038;
    final osc2 = ctx.createOscillator();
    final gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(1975.53, t2);
    gain2.gain.setValueAtTime(0.11, t2);
    gain2.gain.exponentialRampToValueAtTime(0.001, t2 + 0.16);
    osc2.connect(gain2);
    gain2.connect(ctx.destination);
    osc2.start(t2);
    osc2.stop(t2 + 0.165);
  } catch (_) {}
}

void playBetChipSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;

    final thudOsc = ctx.createOscillator();
    final thudGain = ctx.createGain();
    thudOsc.type = 'triangle';
    thudOsc.frequency.setValueAtTime(320, now);
    thudOsc.frequency.exponentialRampToValueAtTime(135, now + 0.045);
    thudGain.gain.setValueAtTime(0.16, now);
    thudGain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
    thudOsc.connect(thudGain);
    thudGain.connect(ctx.destination);
    thudOsc.start(now);
    thudOsc.stop(now + 0.055);

    final noise = ctx.createBufferSource();
    noise.buffer = _getNoiseBuffer(ctx);
    final bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.setValueAtTime(2400, now);
    bp.Q.setValueAtTime(2.2, now);
    final noiseGain = ctx.createGain();
    noiseGain.gain.setValueAtTime(0.14, now);
    noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
    noise.connect(bp);
    bp.connect(noiseGain);
    noiseGain.connect(ctx.destination);
    noise.start(now);
    noise.stop(now + 0.032);

    final tCoin = now + 0.024;
    const freqs = [1567.98, 2349.32];
    for (var i = 0; i < freqs.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freqs[i], tCoin);
      gain.gain.setValueAtTime(i == 0 ? 0.09 : 0.06, tCoin);
      gain.gain.exponentialRampToValueAtTime(0.001, tCoin + 0.12);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(tCoin);
      osc.stop(tCoin + 0.125);
    }
  } catch (_) {}
}

void playBidCoinSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    const freqs = [1318.51, 1760.0, 2217.46];
    for (var i = 0; i < freqs.length; i++) {
      final start = now + i * 0.032;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freqs[i], start);
      gain.gain.setValueAtTime(0.11 - i * 0.015, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.13);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + 0.135);
    }
  } catch (_) {}
}

void playRefundSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    const notes = [
      (1567.98, 0.0, 0.09),
      (1174.66, 0.055, 0.09),
      (1318.51, 0.11, 0.15),
    ];
    for (final (freq, offset, dur) in notes) {
      final start = now + offset;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, start);
      gain.gain.setValueAtTime(0.1, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + dur);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + dur + 0.01);
    }
  } catch (_) {}
}

void playTransferSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc1 = ctx.createOscillator();
    final osc2 = ctx.createOscillator();
    final gain = ctx.createGain();
    osc1.type = 'triangle';
    osc1.frequency.setValueAtTime(523.25, now);
    osc1.frequency.exponentialRampToValueAtTime(1046.5, now + 0.15);
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(659.25, now + 0.08);
    osc2.frequency.exponentialRampToValueAtTime(1318.51, now + 0.22);
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(ctx.destination);
    osc1.start(now);
    osc1.stop(now + 0.18);
    osc2.start(now + 0.08);
    osc2.stop(now + 0.25);
  } catch (_) {}
}

void playAuctionGong(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final filter = ctx.createBiquadFilter();
    final gain = ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(220, now);
    osc.frequency.exponentialRampToValueAtTime(110, now + 0.35);
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(800, now);
    gain.gain.setValueAtTime(0.28, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.45);

    final bell = ctx.createOscillator();
    final bellGain = ctx.createGain();
    bell.type = 'sine';
    bell.frequency.setValueAtTime(660, now);
    bell.frequency.exponentialRampToValueAtTime(440, now + 0.28);
    bellGain.gain.setValueAtTime(0.07, now);
    bellGain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
    bell.connect(bellGain);
    bellGain.connect(ctx.destination);
    bell.start(now);
    bell.stop(now + 0.32);
  } catch (_) {}
}

void playWinSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    const notes = [523.25, 659.25, 783.99, 1046.5];
    final startTime = ctx.currentTime;
    for (var i = 0; i < notes.length; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = notes[i];
      final noteStart = startTime + i * 0.08;
      const noteDuration = 0.25;
      gain.gain.setValueAtTime(0.12, noteStart);
      gain.gain.exponentialRampToValueAtTime(0.001, noteStart + noteDuration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(noteStart);
      osc.stop(noteStart + noteDuration);
    }

    final sparkleStart = startTime + 0.26;
    final sparkle = ctx.createOscillator();
    final sparkleGain = ctx.createGain();
    sparkle.type = 'sine';
    sparkle.frequency.setValueAtTime(2093.0, sparkleStart);
    sparkleGain.gain.setValueAtTime(0.07, sparkleStart);
    sparkleGain.gain.exponentialRampToValueAtTime(0.001, sparkleStart + 0.22);
    sparkle.connect(sparkleGain);
    sparkleGain.connect(ctx.destination);
    sparkle.start(sparkleStart);
    sparkle.stop(sparkleStart + 0.23);
  } catch (_) {}
}

void playDiceSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    const offsets = [0.0, 0.05, 0.11, 0.18, 0.26];
    for (var i = 0; i < offsets.length; i++) {
      final t = offsets[i];
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(320 + _rng.nextDouble() * 200, now + t);
      gain.gain.setValueAtTime(0.14 - i * 0.02, now + t);
      gain.gain.exponentialRampToValueAtTime(0.001, now + t + 0.04);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + t);
      osc.stop(now + t + 0.04);
    }
  } catch (_) {}
}

void playSecretNoteFoldSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final noise = ctx.createBufferSource();
    noise.buffer = _getNoiseBuffer(ctx);
    final bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.setValueAtTime(1950, now);
    bp.frequency.exponentialRampToValueAtTime(980, now + 0.09);
    bp.Q.setValueAtTime(1.4, now);
    final nGain = ctx.createGain();
    nGain.gain.setValueAtTime(0.01, now);
    nGain.gain.linearRampToValueAtTime(0.22, now + 0.018);
    nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    noise.connect(bp);
    bp.connect(nGain);
    nGain.connect(ctx.destination);
    noise.start(now);
    noise.stop(now + 0.105);

    final tap = ctx.createOscillator();
    final tapGain = ctx.createGain();
    tap.type = 'sine';
    tap.frequency.setValueAtTime(155, now + 0.025);
    tap.frequency.exponentialRampToValueAtTime(85, now + 0.07);
    tapGain.gain.setValueAtTime(0.055, now + 0.025);
    tapGain.gain.exponentialRampToValueAtTime(0.001, now + 0.075);
    tap.connect(tapGain);
    tapGain.connect(ctx.destination);
    tap.start(now + 0.025);
    tap.stop(now + 0.08);
  } catch (_) {}
}

void playSecretNoteRevealSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final noise = ctx.createBufferSource();
    noise.buffer = _getNoiseBuffer(ctx);
    final bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.setValueAtTime(950, now);
    bp.frequency.exponentialRampToValueAtTime(2900, now + 0.13);
    bp.Q.setValueAtTime(1.1, now);
    final nGain = ctx.createGain();
    nGain.gain.setValueAtTime(0.01, now);
    nGain.gain.linearRampToValueAtTime(0.24, now + 0.03);
    nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.145);
    noise.connect(bp);
    bp.connect(nGain);
    nGain.connect(ctx.destination);
    noise.start(now);
    noise.stop(now + 0.15);

    final flick = ctx.createBufferSource();
    flick.buffer = _getNoiseBuffer(ctx);
    final hp = ctx.createBiquadFilter();
    hp.type = 'highpass';
    hp.frequency.setValueAtTime(2800, now + 0.055);
    final fGain = ctx.createGain();
    fGain.gain.setValueAtTime(0.11, now + 0.055);
    fGain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    flick.connect(hp);
    hp.connect(fGain);
    fGain.connect(ctx.destination);
    flick.start(now + 0.055);
    flick.stop(now + 0.105);
  } catch (_) {}
}

void playSecretNoteWriteSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    const strokes = [(0.0, 2400.0), (0.045, 3000.0)];
    for (final (offset, freq) in strokes) {
      final start = now + offset;
      final noise = ctx.createBufferSource();
      noise.buffer = _getNoiseBuffer(ctx);
      final bp = ctx.createBiquadFilter();
      bp.type = 'bandpass';
      bp.frequency.setValueAtTime(freq, start);
      bp.Q.setValueAtTime(2.0, start);
      final gain = ctx.createGain();
      gain.gain.setValueAtTime(0.14, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.035);
      noise.connect(bp);
      bp.connect(gain);
      gain.connect(ctx.destination);
      noise.start(start);
      noise.stop(start + 0.038);
    }
  } catch (_) {}
}

void playSecretNoteLockSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final noise = ctx.createBufferSource();
    noise.buffer = _getNoiseBuffer(ctx);
    final bp = ctx.createBiquadFilter();
    bp.type = 'bandpass';
    bp.frequency.setValueAtTime(1250, now);
    bp.Q.setValueAtTime(1.5, now);
    final nGain = ctx.createGain();
    nGain.gain.setValueAtTime(0.2, now);
    nGain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
    noise.connect(bp);
    bp.connect(nGain);
    nGain.connect(ctx.destination);
    noise.start(now);
    noise.stop(now + 0.055);

    final thud = ctx.createOscillator();
    final lp = ctx.createBiquadFilter();
    final tGain = ctx.createGain();
    thud.type = 'triangle';
    thud.frequency.setValueAtTime(210, now);
    thud.frequency.exponentialRampToValueAtTime(88, now + 0.1);
    lp.type = 'lowpass';
    lp.frequency.setValueAtTime(650, now);
    tGain.gain.setValueAtTime(0.18, now);
    tGain.gain.exponentialRampToValueAtTime(0.001, now + 0.115);
    thud.connect(lp);
    lp.connect(tGain);
    tGain.connect(ctx.destination);
    thud.start(now);
    thud.stop(now + 0.12);
  } catch (_) {}
}
