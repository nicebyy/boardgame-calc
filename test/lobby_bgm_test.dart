import 'package:boardgame_calc/services/lobby_bgm_service.dart';
import 'package:boardgame_calc/state/boardgame_calc_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLobbyBgmPlayer implements LobbyBgmPlayer {
  FakeLobbyBgmPlayer({this.assetPresent = true, this.throwOnPlay = false});

  bool assetPresent;
  bool throwOnPlay;
  int playCount = 0;
  int stopCount = 0;
  int disposeCount = 0;
  String? lastAssetPath;
  double? lastVolume;

  @override
  Future<bool> hasAsset(String bundlePath) async => assetPresent;

  @override
  Future<void> playAsset(
    String assetSourcePath, {
    required double volume,
  }) async {
    if (throwOnPlay) {
      throw StateError('NotAllowedError: play blocked without user gesture');
    }
    playCount += 1;
    lastAssetPath = assetSourcePath;
    lastVolume = volume;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('plays lobby BGM when asset exists, pauses in-game, and resumes on leave',
      () async {
    final fake = FakeLobbyBgmPlayer(assetPresent: true);
    final controller = BoardgameCalcController(bgmPlayer: fake);

    await controller.init();
    expect(controller.bgmEnabled, isTrue);
    expect(controller.bgmStatus, LobbyBgmStatus.playing);
    expect(fake.playCount, 1);
    expect(fake.lastAssetPath, 'audio/lobby_bgm.mp3');
    expect(fake.lastVolume, 0.35);

    // Entering a game room pauses BGM
    controller.createRoom(nickname: '호스트');
    await pumpEventQueue();
    expect(controller.bgmStatus, LobbyBgmStatus.pausedInGame);
    expect(fake.stopCount, greaterThanOrEqualTo(1));

    // Leaving the room resumes lobby BGM
    controller.leaveRoom();
    await pumpEventQueue();
    expect(controller.bgmStatus, LobbyBgmStatus.playing);
    expect(fake.playCount, 2);

    controller.dispose();
    expect(fake.disposeCount, 1);
  });

  test('reports missingAsset gracefully when lobby_bgm.mp3 is absent',
      () async {
    final fake = FakeLobbyBgmPlayer(assetPresent: false);
    final controller = BoardgameCalcController(bgmPlayer: fake);

    await controller.init();
    expect(controller.bgmStatus, LobbyBgmStatus.missingAsset);
    expect(fake.playCount, 0);

    controller.dispose();
  });

  test('handles autoplay restriction and recovers on user gesture', () async {
    final fake = FakeLobbyBgmPlayer(assetPresent: true, throwOnPlay: true);
    final controller = BoardgameCalcController(bgmPlayer: fake);

    await controller.init();
    expect(controller.bgmStatus, LobbyBgmStatus.needsUserGesture);

    fake.throwOnPlay = false;
    await controller.resumeBgmOnGesture();
    expect(controller.bgmStatus, LobbyBgmStatus.playing);
    expect(fake.playCount, 1);

    controller.dispose();
  });

  test('persists toggleBgm and setBgmVolume preferences', () async {
    final fake = FakeLobbyBgmPlayer(assetPresent: true);
    final controller = BoardgameCalcController(bgmPlayer: fake);

    await controller.init();
    await controller.setBgmVolume(0.7);
    expect(controller.bgmVolume, 0.7);
    expect(fake.lastVolume, 0.7);

    await controller.toggleBgm();
    expect(controller.bgmEnabled, isFalse);
    expect(controller.bgmStatus, LobbyBgmStatus.disabled);

    // Re-create controller -> verifies persisted preferences restore cleanly
    controller.dispose();
    final fake2 = FakeLobbyBgmPlayer(assetPresent: true);
    final controller2 = BoardgameCalcController(bgmPlayer: fake2);
    await controller2.init();
    expect(controller2.bgmEnabled, isFalse);
    expect(controller2.bgmVolume, 0.7);
    expect(controller2.bgmStatus, LobbyBgmStatus.disabled);
    controller2.dispose();
  });
}
