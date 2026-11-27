import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'models/boardgame_models.dart';
import 'services/boardgame_audio.dart';
import 'state/boardgame_calc_controller.dart';
import 'theme/boardgame_theme.dart';
import 'widgets/bottom_me_panel.dart';
import 'widgets/hamburger_drawer.dart';
import 'widgets/lobby_view.dart';
import 'widgets/middle_board_panel.dart';
import 'widgets/modals/adjust_modal.dart';
import 'widgets/modals/consent_modal.dart';
import 'widgets/modals/log_feed_modal.dart';
import 'widgets/modals/player_action_modal.dart';
import 'widgets/modals/rename_modal.dart';
import 'widgets/modals/settings_modal.dart';
import 'widgets/modals/transfer_modal.dart';
import 'widgets/top_players_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BoardgameCalcApp());
}

class BoardgameCalcApp extends StatelessWidget {
  const BoardgameCalcApp({super.key, this.controller});

  final BoardgameCalcController? controller;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: '보드게임 계산기 | Boardgame Calculator',
      debugShowCheckedModeBanner: false,
      theme: buildBoardgameTheme(),
      home: const BoardgameCalcHomePage(),
    );

    if (controller != null) {
      return ChangeNotifierProvider<BoardgameCalcController>.value(
        value: controller!,
        child: app,
      );
    }

    return ChangeNotifierProvider<BoardgameCalcController>(
      create: (_) {
        final ctrl = BoardgameCalcController();
        ctrl.init();
        return ctrl;
      },
      child: app,
    );
  }
}

class BoardgameCalcHomePage extends StatefulWidget {
  const BoardgameCalcHomePage({super.key});

  @override
  State<BoardgameCalcHomePage> createState() => _BoardgameCalcHomePageState();
}

class _BoardgameCalcHomePageState extends State<BoardgameCalcHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _shownConsentRequestId;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BoardgameCalcController>();
    final room = c.room;
    final me = c.me;

    // P2P 수신 합의 요청이 새로 도착하면 자동으로 합의 모달 오픈
    final pendingReq = c.pendingConsentRequest;
    if (room != null &&
        pendingReq != null &&
        pendingReq.requestId != _shownConsentRequestId) {
      _shownConsentRequestId = pendingReq.requestId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showBoardgameConsentModal(
          context,
          request: pendingReq,
          currencyUnit: room.settings.currencyUnit,
          onRespond: c.respondTransfer,
        ).then((_) {
          _shownConsentRequestId = null;
        });
      });
    } else if (pendingReq == null) {
      _shownConsentRequestId = null;
    }

    final activeTool = room?.resolvedCenterTool ?? CenterToolType.empty;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: (room != null && me != null)
          ? BoardgameCalcHamburgerMenu(
              room: room,
              me: me,
              activeTool: activeTool,
              onSelectTool: c.setCenterTool,
              onOpenLogs: () => _openLogModal(c, room),
              logCount: c.gameLogs.length,
              onOpenSettings: () => _openSettingsModal(c, room),
              soundEnabled: c.soundEnabled,
              onToggleSound: c.toggleSound,
              onUpdateSettings: c.updateSettings,
              onLeaveRoom: c.leaveRoom,
              onDeleteRoom: () => c.deleteRoom(room.roomCode),
              isOfflineMode: c.isOfflineMode,
              onAddLocalPlayer: (name) => c.addLocalPlayer(name),
              onSwitchLocalPlayer: (player) => c.switchActiveLocalPlayer(player),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 상단 헤더
                  if (room != null && me != null)
                    _buildInGameHeader(c, room)
                  else
                    _buildLobbyHeader(c),

                  const SizedBox(height: 10),

                  // 2. 메인 콘텐츠
                  if (room == null || me == null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: BoardgameCalcLobby(controller: c),
                      ),
                    )
                  else
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 알림 배너 스택
                                      if (c.error != null) _buildErrorBanner(c),
                                      if (c.transferToast != null)
                                        _buildTransferBanner(c),
                                      if (c.diceToast != null)
                                        _buildDiceToastBanner(c),
                                      if (c.sentTransferRequest != null)
                                        _buildSentTransferBanner(c, room),

                                      // 1단: 도구 활성화 시 상단 플레이어 바
                                      if (activeTool !=
                                          CenterToolType.empty) ...[
                                        BoardgameCalcTopPlayers(
                                          players: room.players,
                                          myId: me.id,
                                          mySessionId: me.sessionId,
                                          settings: room.settings,
                                          isHost: me.isHost,
                                          viewMode: c.topPlayersViewMode,
                                          onViewModeChange:
                                              c.setTopPlayersViewMode,
                                          sortOption: c.topPlayersSortOption,
                                          onSortOptionChange:
                                              c.setTopPlayersSortOption,
                                          onTapPlayer: (p) =>
                                              _openPlayerActionModal(
                                                  c, room, me, p),
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // 2단: 중앙 보드판 / 도구 (빈 상태에서는 상단 바로 아래에 배치)
                                      BoardgameCalcMiddleAuction(
                                        room: room,
                                        me: me,
                                        activeTool: activeTool,
                                        viewMode: c.topPlayersViewMode,
                                        onViewModeChange:
                                            c.setTopPlayersViewMode,
                                        sortOption: c.topPlayersSortOption,
                                        onSortOptionChange:
                                            c.setTopPlayersSortOption,
                                        onSelectTool: c.setCenterTool,
                                        onTapPlayer: (p) =>
                                            _openPlayerActionModal(
                                                c, room, me, p),
                                        onStartAuction: c.startAuction,
                                        onPlaceBid: c.placeBid,
                                        onDesignateWinner:
                                            c.designateAuctionWinner,
                                        onResetAuction: c.resetAuction,
                                        onPlaceBet: c.placeBet,
                                        onResolveBettingWinner:
                                            c.resolveBettingWinner,
                                        onResetBettingPot: c.resetBettingPot,
                                        onRollDice: c.rollDice,
                                        onStartSecretNote: c.startSecretNote,
                                        onUpdateSecretNote: c.updateSecretNote,
                                        onLockSecretNote: c.lockSecretNote,
                                        onRevealSecretNote: c.revealSecretNote,
                                        onResetSecretNote: c.resetSecretNote,
                                        auctionConflictToast:
                                            c.auctionConflictToast,
                                        onClearConflictToast:
                                            c.clearAuctionConflictToast,
                                        soundEnabled: c.soundEnabled,
                                      ),
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    // 3단: 하단 내 프로필 & 잔액 카드
                                    child: BoardgameCalcBottomMe(
                                      me: me,
                                      settings: room.settings,
                                      onAdjustMyPoints: (delta, {unitValue}) =>
                                          c.adjustPoints(
                                        me.id,
                                        delta,
                                        reason:
                                            delta > 0 ? '빠른 지급' : '빠른 차감',
                                        unitValue: unitValue ?? delta.abs(),
                                      ),
                                      onAdjustMyScore: (delta, {unitValue}) =>
                                          c.adjustScore(
                                        me.id,
                                        delta,
                                        reason:
                                            delta > 0 ? '빠른 승점' : '빠른 감점',
                                        unitValue: unitValue ?? delta.abs(),
                                      ),
                                      onOpenCustomAdjust: () =>
                                          _openAdjustModal(c, room, me),
                                      onEditProfile: () =>
                                          _openRenameModal(c, room, me, me),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyHeader(BoardgameCalcController c) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '// MINIGAME // BOARDGAME',
                    style: TextStyle(
                      color: BoardgameColors.walnutPrimary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.isConnected
                          ? BoardgameColors.emeraldBright
                          : BoardgameColors.crimsonBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Text(
                '보드게임 계산기',
                style: TextStyle(
                  color: BoardgameColors.inkPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInGameHeader(
      BoardgameCalcController c, BoardgameCalcRoom room) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c.isConnected
                ? BoardgameColors.emeraldBright
                : BoardgameColors.crimsonBright,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            room.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF361E12),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        if (c.isOfflineMode)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: BoardgameColors.canvasChipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BoardgameColors.canvasBorder),
            ),
            child: const Text(
              '오프라인',
              style: TextStyle(
                color: BoardgameColors.inkSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            BoardgameAudio.playModal();
            _scaffoldKey.currentState?.openEndDrawer();
          },
          icon: const Icon(Icons.menu, size: 16),
          label: const Text('메뉴',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: BoardgameColors.walnutHeader,
            foregroundColor: BoardgameColors.creamText,
            side: const BorderSide(color: BoardgameColors.walnutMutedBorder),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BoardgameCalcController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xF23B1114),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BoardgameColors.crimsonBright.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Color(0xFFFCA5A5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.error!,
              style: const TextStyle(
                color: Color(0xFFFEE2E2),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          InkWell(
            onTap: () => c.setError(null),
            child: const Text(
              '닫기',
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferBanner(BoardgameCalcController c) {
    final toast = c.transferToast!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: toast.isWarn
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: toast.isWarn
              ? BoardgameColors.amberBright
              : BoardgameColors.emeraldBright,
        ),
      ),
      child: Text(
        toast.message,
        style: TextStyle(
          color: toast.isWarn
              ? const Color(0xFF92400E)
              : const Color(0xFF065F46),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDiceToastBanner(BoardgameCalcController c) {
    final dt = c.diceToast!;
    final d = dt.diceState;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A160C), Color(0xFF3A1F10), Color(0xFF2A160C)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BoardgameColors.amberBright.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          const Text('🎲', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dt.message,
                  style: const TextStyle(
                    color: Color(0xFFFEF3C7),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '결과: [ ${d.values.join(', ')} ] ➔ 합계: ${d.sum ?? 0}${d.comboName != null ? ' (${d.comboName})' : ''}',
                  style: const TextStyle(
                    color: Color(0xFFFCD34D),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: c.clearDiceToast,
            child: const Text(
              '닫기',
              style: TextStyle(
                color: Color(0xFFFCD34D),
                fontSize: 11,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentTransferBanner(
      BoardgameCalcController c, BoardgameCalcRoom room) {
    final req = c.sentTransferRequest!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Text(
        "⏳ '${req.toName}'님에게 ${formatCommaNumber(req.amount)} ${room.settings.currencyUnit} 송금 수락 대기 중...",
        style: const TextStyle(
          color: Color(0xFF1E40AF),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  void _openPlayerActionModal(
    BoardgameCalcController c,
    BoardgameCalcRoom room,
    BoardgameCalcPlayer me,
    BoardgameCalcPlayer target,
  ) {
    BoardgameAudio.playModal();
    showBoardgamePlayerActionModal(
      context,
      player: target,
      settings: room.settings,
      isHost: me.isHost,
      myId: me.id,
      mySessionId: me.sessionId,
      onSelectTransfer: () => _openTransferModal(c, room, me, target),
      onSelectAdjust: () => _openAdjustModal(c, room, target),
      onSelectRename: () => _openRenameModal(c, room, me, target),
    );
  }

  void _openTransferModal(
    BoardgameCalcController c,
    BoardgameCalcRoom room,
    BoardgameCalcPlayer me,
    BoardgameCalcPlayer target,
  ) {
    BoardgameAudio.playModal();
    showBoardgameTransferModal(
      context,
      targetPlayer: target,
      myPoints: me.points,
      currencyUnit: room.settings.currencyUnit,
      quickAdjustUnits: room.settings.effectiveCurrencyDenoms
          .map((d) => d.value)
          .toList(),
      onTransfer: c.requestTransfer,
    );
  }

  void _openAdjustModal(
    BoardgameCalcController c,
    BoardgameCalcRoom room,
    BoardgameCalcPlayer target,
  ) {
    BoardgameAudio.playModal();
    showBoardgameAdjustModal(
      context,
      targetPlayer: target,
      currencyUnit: room.settings.currencyUnit,
      scoreUnit: room.settings.scoreUnit,
      enableScore: room.settings.enableScore,
      quickAdjustUnits: room.settings.effectiveCurrencyDenoms
          .map((d) => d.value)
          .toList(),
      scoreQuickUnits:
          room.settings.scoreDenominations.map((d) => d.value).toList(),
      onAdjustPoints: (id, delta, {reason}) =>
          c.adjustPoints(id, delta, reason: reason),
      onAdjustScore: (id, delta, {reason}) =>
          c.adjustScore(id, delta, reason: reason),
    );
  }

  void _openRenameModal(
    BoardgameCalcController c,
    BoardgameCalcRoom room,
    BoardgameCalcPlayer me,
    BoardgameCalcPlayer target,
  ) {
    BoardgameAudio.playModal();
    showBoardgameRenameModal(
      context,
      targetPlayer: target,
      allPlayers: room.players,
      myId: me.id,
      mySessionId: me.sessionId,
      onRename: (id, newNick) => c.renamePlayer(id, newNick),
      onUpdateColor: (color) => c.updatePlayerColor(color),
    );
  }

  void _openSettingsModal(
      BoardgameCalcController c, BoardgameCalcRoom room) {
    BoardgameAudio.playModal();
    showBoardgameSettingsModal(
      context,
      settings: room.settings,
      onUpdateSettings: c.updateSettings,
      onResetPoints: (amount) => c.resetPoints(customAmount: amount),
      onResetScores: (score) => c.resetScores(customScore: score),
    );
  }

  void _openLogModal(BoardgameCalcController c, BoardgameCalcRoom room) {
    BoardgameAudio.playModal();
    showBoardgameLogFeedModal(
      context,
      logs: c.gameLogs,
      currencyUnit: room.settings.currencyUnit,
      scoreUnit: room.settings.scoreUnit,
    );
  }
}
