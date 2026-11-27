import 'dart:math';
import 'package:web/web.dart' as web;

web.AudioContext? _audioCtx;
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

void playCoinSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(987.77, now);
    osc.frequency.exponentialRampToValueAtTime(1318.51, now + 0.08);
    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.18);
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
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.45);
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
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(440, now);
    osc.frequency.exponentialRampToValueAtTime(220, now + 0.1);
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.1);
  } catch (_) {}
}

void playSecretNoteRevealSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    const freqs = [523.25, 659.25, 783.99, 1046.5];
    for (var i = 0; i < freqs.length; i++) {
      final start = now + i * 0.04;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freqs[i], start);
      gain.gain.setValueAtTime(0.1, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + 0.22);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(start);
      osc.stop(start + 0.22);
    }
  } catch (_) {}
}

void playSecretNoteLockSound(bool enabled) {
  if (!enabled) return;
  final ctx = _getAudioContext();
  if (ctx == null) return;
  try {
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(260, now);
    osc.frequency.exponentialRampToValueAtTime(110, now + 0.12);
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + 0.14);
  } catch (_) {}
}
