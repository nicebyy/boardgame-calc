import 'package:boardgame_calc/main.dart';
import 'package:boardgame_calc/models/boardgame_models.dart';
import 'package:boardgame_calc/services/boardgame_audio.dart';
import 'package:boardgame_calc/services/lobby_bgm_service.dart';
import 'package:boardgame_calc/state/boardgame_calc_controller.dart';
import 'package:boardgame_calc/widgets/middle_board_panel.dart';
import 'package:boardgame_calc/widgets/top_players_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestLobbyBgmPlayer implements LobbyBgmPlayer {
  @override
  Future<bool> hasAsset(String bundlePath) async => true;

  @override
  Future<void> playAsset(String assetSourcePath, {required double volume}) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<BoardgameCalcController> pumpInitializedApp(
    WidgetTester tester, {
    Size surfaceSize = const Size(1280, 960),
    LobbyBgmPlayer? bgmPlayer,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = BoardgameCalcController(bgmPlayer: bgmPlayer);
    await controller.init();
    addTearDown(controller.dispose);

    await tester.pumpWidget(BoardgameCalcApp(controller: controller));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('Lobby renders Offline mode toggle and creates offline room into 3-tier arena',
      (WidgetTester tester) async {
    final sfxEvents = <String>[];
    BoardgameAudio.debugObserver = sfxEvents.add;
    addTearDown(() => BoardgameAudio.debugObserver = null);

    final controller = await pumpInitializedApp(tester);

    expect(find.text('보드게임 계산기'), findsOneWidget);
    expect(controller.isOfflineMode, isTrue);
    expect(controller.serverUrl, 'https://1234banpick.me');

    // Switch to create room tab & submit -> emits tab & click SFX
    await tester.tap(find.text('새 공개방 만들기').first);
    await tester.pumpAndSettle();
    expect(sfxEvents, contains('tab'));

    final createSubmit = find.text('공개방 생성하고 게임 시작');
    await tester.ensureVisible(createSubmit);
    await tester.pumpAndSettle();
    await tester.tap(createSubmit);
    await tester.pumpAndSettle();
    expect(sfxEvents, contains('click'));

    expect(controller.room, isNotNull);
    expect(find.text('오프라인'), findsOneWidget);
    expect(find.text('메뉴'), findsOneWidget);
  });

  testWidgets('BottomMePanel adjusts points and shows denomination depletion',
      (WidgetTester tester) async {
    final controller = await pumpInitializedApp(tester);
    controller.createRoom(
      nickname: '방장테스트',
      title: '화폐 테스트방',
      settings: const BoardgameCalcSettings(
        currencyUnit: '골드',
        initialPoints: 1000,
        enableScore: true,
        initialScore: 0,
        currencyDenominations: [
          BoardgameCalcDenomination(value: 100, maxCount: 1, remainingCount: 1),
          BoardgameCalcDenomination(value: 500),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,000 골드'), findsWidgets);

    // Tap + icon inside the '100' denomination chip in BottomMePanel
    final chip100Row = find.ancestor(
      of: find.text('100'),
      matching: find.byType(Row),
    );
    expect(chip100Row, findsWidgets);
    final plus100Finder = find.descendant(
      of: chip100Row.first,
      matching: find.byIcon(Icons.add),
    );
    expect(plus100Finder, findsOneWidget);
    await tester.ensureVisible(plus100Finder);
    await tester.tap(plus100Finder);
    await tester.pumpAndSettle();

    expect(controller.me!.points, 1100);
    expect(controller.room!.settings.currencyDenominations.first.remainingCount, 0);
    // Remaining badge should now show 0/1
    expect(find.textContaining('0/1'), findsOneWidget);
  });

  testWidgets('Hamburger drawer switches center tools (Dice & SecretNote)',
      (WidgetTester tester) async {
    final controller = await pumpInitializedApp(tester);
    controller.createRoom(nickname: '호스트', title: '도구 전환 테스트');
    await tester.pumpAndSettle();

    // Open menu drawer
    await tester.tap(find.text('메뉴'));
    await tester.pumpAndSettle();

    expect(find.text('✨ 중앙 보드판 도구 꺼내기'), findsOneWidget);

    // Select Dice roller
    final diceBtn = find.text('🎲 주사위 롤러');
    await tester.ensureVisible(diceBtn);
    await tester.tap(diceBtn);
    await tester.pumpAndSettle();

    expect(controller.room!.centerTool, CenterToolType.dice);
    expect(find.textContaining('주사위'), findsWidgets);

    // Open menu again & switch to SecretNote
    await tester.tap(find.text('메뉴'));
    await tester.pumpAndSettle();
    final secretNoteBtn = find.textContaining('비밀노트').first;
    await tester.ensureVisible(secretNoteBtn);
    await tester.tap(secretNoteBtn);
    await tester.pumpAndSettle();

    expect(controller.room!.centerTool, CenterToolType.secretNote);
  });

  testWidgets('Offline Pass & Play switches players and handles P2P consent modal',
      (WidgetTester tester) async {
    final controller = await pumpInitializedApp(tester);
    controller.createRoom(
      nickname: '플레이어A',
      title: '패스앤플레이 테스트',
      settings: const BoardgameCalcSettings(
        currencyUnit: '원',
        initialPoints: 2000,
      ),
    );
    controller.addLocalPlayer('플레이어B');
    await tester.pumpAndSettle();

    expect(controller.room!.players.length, 2);
    final pA = controller.room!.players[0];
    final pB = controller.room!.players[1];

    // Switch active player to pA and request transfer to pB
    controller.switchActiveLocalPlayer(pA);
    controller.requestTransfer(pB.id, 500, memo: '월급');
    await tester.pumpAndSettle();

    expect(controller.sentTransferRequest, isNotNull);

    // Switch active player to pB -> consent modal pops up
    controller.switchActiveLocalPlayer(pB);
    await tester.pumpAndSettle();

    expect(controller.pendingConsentRequest, isNotNull);
    expect(find.text('P2P 포인트 합의 요청'), findsOneWidget);

    // Accept transfer
    await tester.tap(find.text('수락 (받기)'));
    await tester.pumpAndSettle();

    expect(controller.room!.players[0].points, 1500);
    expect(controller.room!.players[1].points, 2500);
  });

  testWidgets('Lobby BGM bundles lobby_bgm.mp3 asset and control bar toggles ON/OFF',
      (WidgetTester tester) async {
    final controller = await pumpInitializedApp(
      tester,
      bgmPlayer: _TestLobbyBgmPlayer(),
    );

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    expect(
      manifest.listAssets(),
      contains(AudioplayersLobbyBgmPlayer.defaultBundlePath),
    );

    expect(find.text('로비 BGM'), findsOneWidget);
    expect(find.text('재생 중'), findsOneWidget);
    expect(find.text('BGM ON'), findsOneWidget);

    await tester.tap(find.text('BGM ON'));
    await tester.pumpAndSettle();

    expect(controller.bgmEnabled, isFalse);
    expect(find.text('BGM OFF'), findsOneWidget);
    expect(find.text('꺼짐'), findsOneWidget);
  });

  testWidgets('Mobile portrait fits 4 top player cards without scroll and keeps middle board full height',
      (WidgetTester tester) async {
    final controller = await pumpInitializedApp(
      tester,
      surfaceSize: const Size(390, 440),
    );
    controller.createRoom(nickname: 'P1', title: '모바일 테스트방');
    controller.addLocalPlayer('P2');
    controller.addLocalPlayer('P3');
    controller.addLocalPlayer('P4');
    controller.setCenterTool(CenterToolType.secretNote);
    await tester.pumpAndSettle();

    // All 4 players in TopPlayersBar fit side-by-side within 390px viewport
    final topBar = find.byType(BoardgameCalcTopPlayers);
    expect(topBar, findsOneWidget);
    for (final name in ['P1', 'P2', 'P3', 'P4']) {
      final cardName = find.descendant(of: topBar, matching: find.text(name));
      expect(cardName, findsOneWidget);
      final rect = tester.getRect(cardName);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
    }

    // Center board keeps full height (>= 200px) even on 440px simulated keyboard height
    final middleRect = tester.getRect(find.byType(BoardgameCalcMiddleAuction));
    expect(middleRect.height, greaterThan(200));
  });
}
