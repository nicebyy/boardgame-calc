import 'package:boardgame_calc/services/boardgame_audio.dart';
import 'package:boardgame_calc/services/boardgame_audio_stub.dart';
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

  test('buildBoardgamePcmWav generates valid RIFF WAVE PCM bytes', () {
    final wav = buildBoardgamePcmWav(
      startFreq: 440,
      endFreq: 190,
      durationSec: 0.04,
      sampleRate: 22050,
    );
    expect(wav.length, 44 + (22050 * 0.04).round() * 2);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
  });

  test('BoardgameAudio UI click/tab/modal cues respect globalEnabled and controller toggle',
      () async {
    final events = <String>[];
    BoardgameAudio.debugObserver = events.add;
    addTearDown(() => BoardgameAudio.debugObserver = null);

    final fake = FakeLobbyBgmPlayer(assetPresent: false);
    final controller = BoardgameCalcController(bgmPlayer: fake);
    await controller.init();

    expect(controller.soundEnabled, isTrue);
    expect(BoardgameAudio.globalEnabled, isTrue);

    BoardgameAudio.playClick();
    BoardgameAudio.playTab();
    BoardgameAudio.playModal();
    expect(events, ['click', 'tab', 'modal']);

    controller.toggleSound();
    expect(controller.soundEnabled, isFalse);
    expect(BoardgameAudio.globalEnabled, isFalse);

    events.clear();
    BoardgameAudio.playClick();
    BoardgameAudio.playTab();
    BoardgameAudio.playModal();
    expect(events, isEmpty);

    controller.dispose();
  });

  test('BoardgameAudio emits money (bet_chip, bid_coin, refund) and paper write cues',
      () {
    final events = <String>[];
    BoardgameAudio.globalEnabled = true;
    BoardgameAudio.debugObserver = events.add;
    addTearDown(() => BoardgameAudio.debugObserver = null);

    BoardgameAudio.playBetChipSound();
    BoardgameAudio.playBidCoinSound();
    BoardgameAudio.playRefundSound();
    BoardgameAudio.playSecretNoteWriteSound();
    expect(events, ['bet_chip', 'bid_coin', 'refund', 'secret_write']);

    final paperWav = buildBoardgamePcmWav(
      startFreq: 220,
      endFreq: 320,
      durationSec: 0.08,
      noiseMix: 0.9,
    );
    expect(String.fromCharCodes(paperWav.sublist(0, 4)), 'RIFF');
  });

  test('Controller dispatches dedicated money & deduplicated paper SFX in offline actions',
      () async {
    final events = <String>[];
    BoardgameAudio.debugObserver = events.add;
    addTearDown(() => BoardgameAudio.debugObserver = null);

    final controller = BoardgameCalcController(bgmPlayer: FakeLobbyBgmPlayer(assetPresent: false));
    await controller.init();
    controller.createRoom(nickname: '호스트', title: 'SFX 테스트방');

    events.clear();
    controller.placeBet(100);
    expect(events, ['bet_chip']);

    events.clear();
    controller.resetBettingPot();
    expect(events, ['refund']);

    events.clear();
    controller.startAuction(title: '아이템', minIncrement: 100);
    expect(events, ['auction_gong']);

    events.clear();
    controller.placeBid(200);
    expect(events, ['bid_coin']);

    events.clear();
    controller.startSecretNote(title: '주제');
    expect(events, ['secret_fold']);

    events.clear();
    controller.lockSecretNote();
    expect(events, ['secret_lock']);

    events.clear();
    controller.revealSecretNote();
    expect(events, ['secret_reveal']);

    controller.dispose();
  });
}
