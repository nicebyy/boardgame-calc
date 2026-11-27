import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'lobby_bgm_guard_stub.dart'
    if (dart.library.js_interop) 'lobby_bgm_guard_web.dart' as guard;

/// 로비 배경음악(BGM) 재생 상태.
enum LobbyBgmStatus {
  disabled,
  playing,
  pausedInGame,
  missingAsset,
  needsUserGesture,
}

/// 플랫폼 독립적 로비 BGM 플레이어 추상화 (테스트 대역 주입 지원).
abstract class LobbyBgmPlayer {
  Future<bool> hasAsset(String bundlePath);
  Future<void> playAsset(String assetSourcePath, {required double volume});
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// `audioplayers` 기반 Web / Android 공용 로비 BGM 플레이어.
class AudioplayersLobbyBgmPlayer implements LobbyBgmPlayer {
  static const String defaultBundlePath = 'assets/audio/lobby_bgm.mp3';
  static const String defaultAssetSourcePath = 'audio/lobby_bgm.mp3';

  AudioPlayer? _player;

  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer(playerId: 'boardgame_calc_lobby_bgm');
  }

  @override
  Future<bool> hasAsset(String bundlePath) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(bundlePath);
    } catch (_) {
      try {
        await rootBundle.load(bundlePath);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<void> playAsset(
    String assetSourcePath, {
    required double volume,
  }) async {
    if (guard.isFlutterTestEnvironment) return;
    final player = _ensurePlayer();
    final safeVolume = volume.clamp(0.0, 1.0).toDouble();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(safeVolume);
    await player.play(AssetSource(assetSourcePath));
  }

  @override
  Future<void> setVolume(double volume) async {
    if (guard.isFlutterTestEnvironment) return;
    final player = _player;
    if (player == null) return;
    try {
      await player.setVolume(volume.clamp(0.0, 1.0).toDouble());
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    if (guard.isFlutterTestEnvironment) return;
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    if (guard.isFlutterTestEnvironment || player == null) return;
    try {
      await player.dispose();
    } catch (_) {}
  }
}
