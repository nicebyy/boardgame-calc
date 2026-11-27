import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../services/boardgame_audio.dart';
import '../theme/boardgame_theme.dart';
import 'player_avatar.dart';
import 'secret_note_panel.dart';

class BoardgameCalcMiddleAuction extends StatefulWidget {
  const BoardgameCalcMiddleAuction({
    super.key,
    required this.room,
    required this.me,
    required this.activeTool,
    required this.viewMode,
    required this.onViewModeChange,
    required this.sortOption,
    required this.onSortOptionChange,
    required this.onSelectTool,
    required this.onTapPlayer,
    required this.onStartAuction,
    required this.onPlaceBid,
    required this.onDesignateWinner,
    required this.onResetAuction,
    required this.onPlaceBet,
    required this.onResolveBettingWinner,
    required this.onResetBettingPot,
    required this.onRollDice,
    required this.onStartSecretNote,
    required this.onUpdateSecretNote,
    required this.onLockSecretNote,
    required this.onRevealSecretNote,
    required this.onResetSecretNote,
    this.auctionConflictToast,
    this.onClearConflictToast,
    this.soundEnabled = true,
  });

  final BoardgameCalcRoom room;
  final BoardgameCalcPlayer me;
  final CenterToolType activeTool;
  final TopPlayersViewMode viewMode;
  final ValueChanged<TopPlayersViewMode> onViewModeChange;
  final TopPlayersSortOption sortOption;
  final ValueChanged<TopPlayersSortOption> onSortOptionChange;
  final ValueChanged<CenterToolType> onSelectTool;
  final ValueChanged<BoardgameCalcPlayer> onTapPlayer;

  final void Function({String? title, int? minIncrement, int? timeLimit})
      onStartAuction;
  final void Function(int amount,
      {int? expectedHighestBid,
      void Function(Map<String, dynamic>)? callback}) onPlaceBid;
  final void Function(
      {String? winnerId,
      String potAction,
      int? expectedHighestBid,
      void Function(Map<String, dynamic>)? callback}) onDesignateWinner;
  final VoidCallback onResetAuction;

  final void Function(int amount,
      {void Function(Map<String, dynamic>)? callback}) onPlaceBet;
  final void Function(String winnerId,
      {String action,
      void Function(Map<String, dynamic>)? callback}) onResolveBettingWinner;
  final void Function({void Function(Map<String, dynamic>)? callback})
      onResetBettingPot;

  final void Function(int count, int sides,
      {void Function(Map<String, dynamic>)? callback}) onRollDice;

  final void Function({int? timeLimit, String? title, bool? autoReveal})
      onStartSecretNote;
  final void Function(String content, {bool? isFolded}) onUpdateSecretNote;
  final VoidCallback onLockSecretNote;
  final VoidCallback onRevealSecretNote;
  final void Function({int? timeLimit, String? title, bool? autoReveal})
      onResetSecretNote;

  final String? auctionConflictToast;
  final VoidCallback? onClearConflictToast;
  final bool soundEnabled;

  @override
  State<BoardgameCalcMiddleAuction> createState() =>
      _BoardgameCalcMiddleAuctionState();
}

class _BoardgameCalcMiddleAuctionState
    extends State<BoardgameCalcMiddleAuction> {
  final _rng = Random();

  // Dice state
  late TextEditingController _diceCountCtrl;
  late TextEditingController _diceSidesCtrl;
  List<int> _animDiceValues = [];
  bool _isRolling = false;
  Timer? _rollTimer;
  Timer? _flashTimer;
  bool _justRolledFlash = false;
  int? _lastSeenRolledAt;

  // Betting state
  final _customBetCtrl = TextEditingController();
  bool _isSubmittingBet = false;
  String? _bettingToast;
  Timer? _betToastTimer;

  // Auction state
  final _customBidCtrl = TextEditingController();
  bool _isSubmittingBid = false;
  String? _localConflictError;
  int? _auctionTimeLeft;
  Timer? _auctionTimer;

  @override
  void initState() {
    super.initState();
    final d = widget.room.dice;
    _diceCountCtrl = TextEditingController(text: '${d?.count ?? 2}');
    _diceSidesCtrl = TextEditingController(text: '${d?.sides ?? 6}');
    _lastSeenRolledAt = d?.rolledAt;
    _setupAuctionTimer();
  }

  @override
  void didUpdateWidget(covariant BoardgameCalcMiddleAuction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingDice = widget.room.dice;
    if (incomingDice != null &&
        incomingDice.rolledAt != null &&
        incomingDice.rolledAt != _lastSeenRolledAt) {
      _lastSeenRolledAt = incomingDice.rolledAt;
      _diceCountCtrl.text = '${incomingDice.count}';
      _diceSidesCtrl.text = '${incomingDice.sides}';
      if (!_isRolling) {
        _triggerFlash();
      }
    }

    if (oldWidget.room.auction.isActive != widget.room.auction.isActive ||
        oldWidget.room.auction.endsAt != widget.room.auction.endsAt) {
      _setupAuctionTimer();
    }
  }

  void _setupAuctionTimer() {
    _auctionTimer?.cancel();
    final auction = widget.room.auction;
    if (!auction.isActive || auction.endsAt == null) {
      _auctionTimeLeft = null;
      return;
    }
    void tick() {
      final left =
          ((auction.endsAt! - DateTime.now().millisecondsSinceEpoch) / 1000)
              .ceil();
      final clamped = left < 0 ? 0 : left;
      if (mounted && _auctionTimeLeft != clamped) {
        setState(() => _auctionTimeLeft = clamped);
      }
    }

    tick();
    _auctionTimer =
        Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  void _triggerFlash() {
    setState(() => _justRolledFlash = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _justRolledFlash = false);
    });
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _flashTimer?.cancel();
    _betToastTimer?.cancel();
    _auctionTimer?.cancel();
    _diceCountCtrl.dispose();
    _diceSidesCtrl.dispose();
    _customBetCtrl.dispose();
    _customBidCtrl.dispose();
    super.dispose();
  }

  void _showBetToast(String msg) {
    setState(() => _bettingToast = msg);
    _betToastTimer?.cancel();
    _betToastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bettingToast = null);
    });
  }

  void _handleRollDice() {
    if (_isRolling) return;
    final count = (int.tryParse(_diceCountCtrl.text.trim()) ?? 2).clamp(1, 12);
    final sides =
        (int.tryParse(_diceSidesCtrl.text.trim()) ?? 6).clamp(2, 1000);
    setState(() {
      _isRolling = true;
      _animDiceValues = List.generate(count, (_) => _rng.nextInt(sides) + 1);
    });
    BoardgameAudio.playDiceSound(enabled: widget.soundEnabled);
    widget.onRollDice(count, sides);

    var ticks = 0;
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      ticks++;
      if (!mounted) {
        t.cancel();
        return;
      }
      if (ticks >= 6) {
        t.cancel();
        setState(() {
          _isRolling = false;
          _animDiceValues = [];
        });
        _triggerFlash();
      } else {
        setState(() {
          _animDiceValues =
              List.generate(count, (_) => _rng.nextInt(sides) + 1);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.activeTool) {
      case CenterToolType.empty:
        return _buildPlayerBoard();
      case CenterToolType.dice:
        return _buildDiceRoller();
      case CenterToolType.betting:
        return _buildBettingBoard();
      case CenterToolType.auction:
        return _buildAuctionBoard();
      case CenterToolType.secretNote:
        return BoardgameCalcSecretNote(
          secretNote: widget.room.secretNote,
          players: widget.room.players,
          myId: widget.me.id,
          mySessionId: widget.me.sessionId,
          isHost: widget.me.isHost,
          onStartSecretNote: widget.onStartSecretNote,
          onUpdateSecretNote: widget.onUpdateSecretNote,
          onLockSecretNote: widget.onLockSecretNote,
          onRevealSecretNote: widget.onRevealSecretNote,
          onResetSecretNote: widget.onResetSecretNote,
        );
    }
  }

  // ===========================================================================
  // CASE 0: 플레이어 보드 (기본 상태)
  // ===========================================================================
  Widget _buildPlayerBoard() {
    final sorted = sortTopPlayers(widget.room.players, widget.sortOption);
    final settings = widget.room.settings;
    final displayMode = settings.resolvedDisplayMode;
    final showCurrency = displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.currency;
    final isScoreEnabled = displayMode == ScoreDisplayMode.all ||
        (displayMode != ScoreDisplayMode.currency && settings.enableScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: BoardgameColors.inkPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BoardgameColors.amberBright.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      size: 16, color: Color(0xFFFCD34D)),
                ),
                const SizedBox(width: 8),
                const Text(
                  '플레이어 보드',
                  style: TextStyle(
                    color: BoardgameColors.inkPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 뷰 모드 토글
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: BoardgameColors.walnutCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BoardgameColors.inkSecondary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BoardViewPill(
                        icon: Icons.grid_view_rounded,
                        label: '카드형',
                        active: widget.viewMode == TopPlayersViewMode.card,
                        onTap: () =>
                            widget.onViewModeChange(TopPlayersViewMode.card),
                      ),
                      _BoardViewPill(
                        icon: Icons.view_list_rounded,
                        label: '리스트형',
                        active: widget.viewMode == TopPlayersViewMode.list,
                        onTap: () =>
                            widget.onViewModeChange(TopPlayersViewMode.list),
                      ),
                    ],
                  ),
                ),

                // 테이블 판돈 배지
                if (widget.room.betting.currentPot > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BoardgameColors.walnutSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🪙 판돈: ',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          formatCompactNumber(widget.room.betting.currentPot),
                          style: const TextStyle(
                            color: BoardgameColors.amberBright,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                        if (widget.me.isHost) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () =>
                                widget.onSelectTool(CenterToolType.betting),
                            child: const Text(
                              '보기',
                              style: TextStyle(
                                color: BoardgameColors.amberBright,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 진행 중 경매 배지
                if (settings.enableAuction && widget.room.auction.isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A2610),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            BoardgameColors.amberBright.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🔥 경매 진행 중!',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        if (widget.me.isHost) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () =>
                                widget.onSelectTool(CenterToolType.auction),
                            child: const Text(
                              '열기',
                              style: TextStyle(
                                color: Color(0xFFFCD34D),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 정렬 드롭다운
                PopupMenuButton<TopPlayersSortOption>(
                  initialValue: widget.sortOption,
                  color: BoardgameColors.walnutCard,
                  onSelected: widget.onSortOptionChange,
                  itemBuilder: (context) => TopPlayersSortOption.values
                      .where((opt) =>
                          isScoreEnabled ||
                          (opt != TopPlayersSortOption.scoreDesc &&
                              opt != TopPlayersSortOption.scoreAsc))
                      .map((opt) {
                    final selected = opt == widget.sortOption;
                    return PopupMenuItem<TopPlayersSortOption>(
                      value: opt,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                color: selected
                                    ? BoardgameColors.goldLight
                                    : BoardgameColors.creamText,
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check,
                                size: 14, color: BoardgameColors.goldLight),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: BoardgameColors.walnutCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            widget.sortOption != TopPlayersSortOption.defaultOrder
                                ? BoardgameColors.gold
                                : BoardgameColors.inkSecondary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert,
                            size: 13, color: Color(0xFFFEF3C7)),
                        const SizedBox(width: 4),
                        Text(
                          widget.sortOption.shortLabel,
                          style: const TextStyle(
                            color: Color(0xFFFEF3C7),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 13, color: Color(0xFFFEF3C7)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.viewMode == TopPlayersViewMode.list)
          Column(
            children: sorted.map((p) {
              final isMe = p.matchesIdentity(
                  myId: widget.me.id, mySessionId: widget.me.sessionId);
              final pTheme = getPlayerTheme(p.avatarColor);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: isMe ? null : () => widget.onTapPlayer(p),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: pTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pTheme.cardBorder, width: 1.8),
                    ),
                    child: Row(
                      children: [
                        BoardgameCalcAvatar(
                          nickname: p.nickname,
                          avatarUrl: p.avatarUrl,
                          avatarColor: p.avatarColor,
                          size: 38,
                          isOnline: p.isOnline,
                          showOnlineDot: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                p.nickname,
                                style: const TextStyle(
                                  color: BoardgameColors.inkPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              if (isMe) _BoardSmallMeBadge(),
                              if (p.isHost)
                                const Icon(Icons.workspace_premium,
                                    size: 14,
                                    color: BoardgameColors.amberBright),
                            ],
                          ),
                        ),
                        if (showCurrency)
                          _ValuePill(
                            icon: Icons.account_balance_wallet_outlined,
                            text:
                                '${formatCompactNumber(p.points)} ${settings.currencyUnit}',
                            bg: pTheme.innerBoxBg,
                            border: pTheme.innerBoxBorder,
                            textColor: BoardgameColors.inkPrimary,
                            fullTooltip:
                                '${formatCommaNumber(p.points)} ${settings.currencyUnit}',
                          ),
                        if (isScoreEnabled) ...[
                          const SizedBox(width: 6),
                          _ValuePill(
                            icon: Icons.emoji_events_outlined,
                            text:
                                '${formatCompactNumber(p.score)} ${settings.scoreUnit}',
                            bg: pTheme.innerBoxBg,
                            border: pTheme.innerBoxBorder,
                            textColor: BoardgameColors.amberScoreText,
                            iconColor: BoardgameColors.amberBright,
                            fullTooltip:
                                '${formatCommaNumber(p.score)} ${settings.scoreUnit}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = sorted.length <= 1
                  ? 1
                  : (constraints.maxWidth >= 680 && sorted.length > 4)
                      ? 3
                      : (constraints.maxWidth >= 460 ? 2 : 1);
              const spacing = 10.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: sorted.map((p) {
                  final isMe = p.matchesIdentity(
                      myId: widget.me.id, mySessionId: widget.me.sessionId);
                  final pTheme = getPlayerTheme(p.avatarColor);

                  return SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      onTap: isMe ? null : () => widget.onTapPlayer(p),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: pTheme.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border:
                              Border.all(color: pTheme.cardBorder, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF32190A)
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom:
                                      BorderSide(color: pTheme.innerBoxBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  BoardgameCalcAvatar(
                                    nickname: p.nickname,
                                    avatarUrl: p.avatarUrl,
                                    avatarColor: p.avatarColor,
                                    size: 38,
                                    isOnline: p.isOnline,
                                    showOnlineDot: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 5,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          p.nickname,
                                          style: const TextStyle(
                                            color: BoardgameColors.inkPrimary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (isMe) _BoardSmallMeBadge(),
                                        if (p.isHost)
                                          const Icon(Icons.workspace_premium,
                                              size: 14,
                                              color:
                                                  BoardgameColors.amberBright),
                                      ],
                                    ),
                                  ),
                                  if (!isMe)
                                    const Icon(Icons.touch_app_outlined,
                                        size: 15,
                                        color: BoardgameColors.inkMuted),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (showCurrency)
                              Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: BoardgameColors.walnutPrimary
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 15,
                                      color: BoardgameColors.walnutPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '보유:',
                                    style: TextStyle(
                                      color: BoardgameColors.inkMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Tooltip(
                                      message:
                                          '${formatCommaNumber(p.points)} ${settings.currencyUnit}',
                                      child: Text(
                                        '${formatCompactNumber(p.points)} ${settings.currencyUnit}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BoardgameColors.inkPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (showCurrency && isScoreEnabled)
                              const SizedBox(height: 6),
                            if (isScoreEnabled)
                              Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: BoardgameColors.amberBright
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_outlined,
                                      size: 15,
                                      color: BoardgameColors.amberScoreText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '점수:',
                                    style: TextStyle(
                                      color: BoardgameColors.inkMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Tooltip(
                                      message:
                                          '${formatCommaNumber(p.score)} ${settings.scoreUnit}',
                                      child: Text(
                                        '${formatCompactNumber(p.score)} ${settings.scoreUnit}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BoardgameColors.amberScoreText,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // CASE 1: 중앙 주사위 롤러
  // ===========================================================================
  Widget _buildDiceRoller() {
    final propDice = widget.room.dice;
    final diceCount =
        (int.tryParse(_diceCountCtrl.text.trim()) ?? propDice?.count ?? 2)
            .clamp(1, 12);
    final diceSides =
        (int.tryParse(_diceSidesCtrl.text.trim()) ?? propDice?.sides ?? 6)
            .clamp(2, 1000);
    final displayed = _isRolling && _animDiceValues.isNotEmpty
        ? _animDiceValues
        : (propDice?.values.isNotEmpty == true
            ? propDice!.values
            : const [3, 4]);
    final sum = propDice?.sum ?? displayed.fold<int>(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Color(0xFF2A160C),
            BoardgameColors.walnutPanel,
            Color(0xFF120703),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF78350F).withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xCC140B05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF451A03)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.casino_rounded,
                        color: BoardgameColors.amberBright, size: 22),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎲 중앙 주사위 롤러',
                          style: TextStyle(
                            color: Color(0xFFFEF3C7),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '실시간 모든 플레이어 화면 동기화',
                          style: TextStyle(
                            color: Color(0xB3F59E0B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _DiceNumInput(
                      label: '개수:',
                      suffix: '개',
                      ctrl: _diceCountCtrl,
                      onChanged: () => setState(() {}),
                    ),
                    _DiceNumInput(
                      label: '면수(D):',
                      suffix: '면',
                      ctrl: _diceSidesCtrl,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _justRolledFlash
                  ? const Color(0x40451A03)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: _justRolledFlash
                  ? Border.all(color: BoardgameColors.amberBright, width: 2)
                  : null,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < displayed.length; i++) ...[
                  if (i > 0)
                    const Text(
                      '+',
                      style: TextStyle(
                        color: Color(0xB3D97706),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  _DiceFaceWidget(
                    value: displayed[i],
                    sides: diceSides,
                    size: displayed.length > 4
                        ? 42
                        : (displayed.length > 2 ? 52 : 64),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isRolling ? null : _handleRollDice,
            icon: const Icon(Icons.casino_rounded, size: 20),
            label: Text(
              _isRolling
                  ? '주사위 굴리는 중...'
                  : '🎲 $diceCount개 D$diceSides 굴리기 (Roll!)',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BoardgameColors.amberBright,
              foregroundColor: const Color(0xFF451A03),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (propDice != null && propDice.sum != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF451A03),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: BoardgameColors.amberBright.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                propDice.comboName != null
                    ? '${propDice.comboName} // 합계: $sum'
                    : '합계: $sum',
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ),
            if (propDice.rolledBy != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _justRolledFlash
                      ? BoardgameColors.amberBright.withValues(alpha: 0.22)
                      : BoardgameColors.walnutDarkest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _justRolledFlash
                        ? BoardgameColors.amberBright
                        : const Color(0xFF78350F),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _justRolledFlash
                            ? BoardgameColors.amberBright
                            : BoardgameColors.amberBright.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _justRolledFlash ? '⚡ 방금 굴림' : '최근 굴린 사람',
                        style: TextStyle(
                          color: _justRolledFlash
                              ? const Color(0xFF451A03)
                              : const Color(0xFFFCD34D),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BoardgameCalcAvatar(
                      nickname: propDice.rolledBy!,
                      avatarUrl: propDice.rolledByAvatarUrl,
                      avatarColor: propDice.rolledByAvatarColor,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      propDice.rolledBy!,
                      style: const TextStyle(
                        color: BoardgameColors.creamText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // CASE 2: 배팅 & 테이블 판돈 집중 모드
  // ===========================================================================
  Widget _buildBettingBoard() {
    final betting = widget.room.betting;
    final settings = widget.room.settings;
    final posUnits = settings.effectiveCurrencyDenoms
        .map((d) => d.value.abs())
        .where((v) => v > 0)
        .toSet()
        .toList()
      ..sort();
    final quickSteps = posUnits.isNotEmpty
        ? posUnits.take(4).toList()
        : [
            settings.auctionMinBid,
            settings.auctionMinBid * 2,
            settings.auctionMinBid * 5,
            settings.auctionMinBid * 10
          ];

    final playerBets = betting.playerBets.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Color(0xFF2A160C),
            BoardgameColors.walnutPanel,
            Color(0xFF120703),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BoardgameColors.gold.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: BoardgameColors.amberBright, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '💰 배팅 판돈 & 모인 돈',
                  style: TextStyle(
                    color: Color(0xFFFEF3C7),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '단위: ${settings.currencyUnit}',
                style: const TextStyle(
                  color: BoardgameColors.amberBright,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
              if (widget.me.isHost) ...[
                if (betting.currentPot > 0) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openBettingWinnerDialog(betting),
                    icon: const Icon(Icons.emoji_events_outlined, size: 15),
                    label: const Text('판돈 지급',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BoardgameColors.amberBright,
                      foregroundColor: const Color(0xFF451A03),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '다음 배팅을 위한 초기화 (전액 환불)',
                  onPressed: () {
                    widget.onResetBettingPot(callback: (res) {
                      if (res['success'] == true) {
                        _showBetToast('배팅이 취소되고 배팅금이 전액 환불되었습니다.');
                      }
                    });
                  },
                  icon: const Icon(Icons.refresh,
                      color: BoardgameColors.creamText, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PotSummaryCard(
                  label: '🔥 현재 최고 배팅액',
                  badge: '최고가',
                  amountText:
                      '${formatCompactNumber(betting.highestBet)} ${settings.currencyUnit}',
                  footerLeft: '최고 배팅자',
                  footerRight: betting.highestBetterName ?? '없음',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PotSummaryCard(
                  label: '🪙 현재 모인 판돈',
                  badge: '모인 판돈',
                  amountText:
                      '${formatCompactNumber(betting.currentPot)} ${settings.currencyUnit}',
                  amountColor: BoardgameColors.amberBright,
                  footerLeft: '테이블 참가자',
                  footerRight: '${widget.room.players.length}명 참여 중',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xE6140B05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BoardgameColors.goldBright.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🪙 플레이어별 배팅 집계',
                      style: TextStyle(
                        color: BoardgameColors.creamMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      playerBets.isNotEmpty
                          ? '총 ${playerBets.length}명 배팅 중'
                          : '배팅 대기 중',
                      style: const TextStyle(
                        color: BoardgameColors.creamSubtle,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (playerBets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        '아직 배팅한 플레이어가 없습니다.',
                        style: TextStyle(
                          color: BoardgameColors.creamSubtle,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < playerBets.length; i++) ...[
                        () {
                          final bet = playerBets[i];
                          final potTotal =
                              betting.currentPot > 0 ? betting.currentPot : 1;
                          final pct = ((bet.totalAmount / potTotal) * 100)
                              .round()
                              .clamp(0, 100);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? BoardgameColors.walnutSurface
                                  : BoardgameColors.walnutDarkest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: i == 0
                                    ? BoardgameColors.gold
                                        .withValues(alpha: 0.6)
                                    : BoardgameColors.walnutSoft,
                              ),
                            ),
                            child: Row(
                              children: [
                                BoardgameCalcAvatar(
                                  nickname: bet.nickname,
                                  avatarUrl: bet.avatarUrl,
                                  avatarColor: bet.avatarColor,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${bet.nickname}${bet.betCount > 1 ? ' (${bet.betCount}회)' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BoardgameColors.creamText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${formatCompactNumber(bet.totalAmount)} ${settings.currencyUnit} ($pct%)',
                                  style: const TextStyle(
                                    color: BoardgameColors.amberBright,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (_bettingToast != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xB3451A03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BoardgameColors.amberBright),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '⚠️ $_bettingToast',
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _bettingToast = null),
                    child: const Text('닫기',
                        style: TextStyle(
                            color: BoardgameColors.creamMuted,
                            fontSize: 11,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '빠른 배팅',
                style: TextStyle(
                  color: BoardgameColors.creamMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '내 보유: ${formatCompactNumber(widget.me.points)}${settings.currencyUnit}',
                style: const TextStyle(
                  color: BoardgameColors.creamSubtle,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: quickSteps.map((step) {
              final disabled = _isSubmittingBet || step > widget.me.points;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Opacity(
                    opacity: disabled ? 0.4 : 1.0,
                    child: InkWell(
                      onTap: disabled
                          ? null
                          : () {
                              setState(() => _isSubmittingBet = true);
                              widget.onPlaceBet(step, callback: (res) {
                                if (mounted) {
                                  setState(() => _isSubmittingBet = false);
                                  if (res['success'] != true &&
                                      res['error'] != null) {
                                    _showBetToast(res['error'] as String);
                                  }
                                }
                              });
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BoardgameColors.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '+${formatCompactNumber(step)}',
                          style: const TextStyle(
                            color: BoardgameColors.goldLight,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customBetCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '직접 배팅할 금액 입력',
                    hintStyle: const TextStyle(
                        color: Color(0xFF8A684B), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF100703),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: BoardgameColors.walnutBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: BoardgameColors.gold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmittingBet
                    ? null
                    : () {
                        final amount =
                            int.tryParse(_customBetCtrl.text.trim());
                        if (amount == null || amount <= 0) {
                          _showBetToast('1 이상의 정수 금액을 입력해주세요.');
                          return;
                        }
                        if (amount > widget.me.points) {
                          _showBetToast(
                              '보유 잔액(${formatCommaNumber(widget.me.points)}${settings.currencyUnit})이 부족합니다.');
                          return;
                        }
                        setState(() => _isSubmittingBet = true);
                        widget.onPlaceBet(amount, callback: (res) {
                          if (mounted) {
                            setState(() => _isSubmittingBet = false);
                            if (res['success'] == true) {
                              _customBetCtrl.clear();
                            } else if (res['error'] != null) {
                              _showBetToast(res['error'] as String);
                            }
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoardgameColors.amberBright,
                  foregroundColor: const Color(0xFF451A03),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isSubmittingBet ? '배팅 중...' : '배팅하기',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBettingWinnerDialog(BoardgameCalcBetting betting) async {
    var selectedId = betting.highestBetterId ??
        (widget.room.players.isNotEmpty ? widget.room.players.first.id : '');
    var action = 'transfer';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BoardgameColors.walnutSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: BoardgameColors.gold, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 테이블 판돈 정산 (${formatCompactNumber(betting.currentPot)} ${widget.room.settings.currencyUnit})',
                      style: const TextStyle(
                        color: BoardgameColors.creamText,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('승자에게 지급'),
                            selected: action == 'transfer',
                            onSelected: (_) =>
                                setDialogState(() => action = 'transfer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('참여자 전액 환불'),
                            selected: action == 'burn',
                            onSelected: (_) =>
                                setDialogState(() => action = 'burn'),
                          ),
                        ),
                      ],
                    ),
                    if (action == 'transfer') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: widget.room.players
                                .any((p) => p.id == selectedId)
                            ? selectedId
                            : null,
                        dropdownColor: BoardgameColors.walnutCard,
                        style: const TextStyle(
                          color: BoardgameColors.creamText,
                          fontWeight: FontWeight.w800,
                        ),
                        items: widget.room.players
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.nickname),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedId = v);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('취소',
                                style: TextStyle(
                                    color: BoardgameColors.creamText)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onResolveBettingWinner(
                                action == 'burn' ? '' : selectedId,
                                action: action,
                              );
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BoardgameColors.goldBright,
                              foregroundColor: BoardgameColors.walnutDarkest,
                            ),
                            child: const Text('확정',
                                style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // CASE 3: 실시간 경매 집중 모드
  // ===========================================================================
  Widget _buildAuctionBoard() {
    final auction = widget.room.auction;
    final settings = widget.room.settings;
    final currentHighest = auction.highestBid;
    final minIncrement = auction.minIncrement > 0
        ? auction.minIncrement
        : settings.auctionMinBid;
    final minNextBid = currentHighest + minIncrement;

    final isMeHighest = auction.highestBidderId == widget.me.id ||
        (widget.me.sessionId.isNotEmpty &&
            (auction.highestBidderId == widget.me.sessionId ||
                auction.highestBidderSessionId == widget.me.sessionId));
    final isTimeExpired =
        auction.isActive && auction.endsAt != null && (_auctionTimeLeft ?? 1) <= 0;

    final posUnits = settings.effectiveCurrencyDenoms
        .map((d) => d.value.abs())
        .where((v) => v > 0)
        .toSet()
        .toList()
      ..sort();
    final quickBidUnits = posUnits.isNotEmpty
        ? posUnits
        : [minIncrement, minIncrement * 2, minIncrement * 5, minIncrement * 10];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Color(0xFF2A160C),
            BoardgameColors.walnutPanel,
            Color(0xFF120703),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BoardgameColors.gold.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: BoardgameColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.gavel_rounded,
                        color: BoardgameColors.amberBright, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '실시간 경매 시스템',
                        style: TextStyle(
                          color: Color(0xFFFEF3C7),
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            auction.isActive ? '● 경매 진행 중' : '대기 상태',
                            style: TextStyle(
                              color: auction.isActive
                                  ? const Color(0xFF34D399)
                                  : BoardgameColors.creamSubtle,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '최소단위 +${formatCompactNumber(minIncrement)}${settings.currencyUnit}',
                            style: const TextStyle(
                              color: BoardgameColors.gold,
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.me.isHost)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!auction.isActive)
                      ElevatedButton.icon(
                        onPressed: () => widget.onStartAuction(
                          minIncrement: settings.auctionMinBid,
                          timeLimit: settings.auctionTimeLimit,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('경매 시작',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoardgameColors.amberBright,
                          foregroundColor: const Color(0xFF451A03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          if (auction.highestBidderId == null) {
                            setState(() => _localConflictError =
                                '아직 입찰자가 없습니다. 입찰이 진행된 후 즉시 낙찰할 수 있습니다.');
                            return;
                          }
                          widget.onDesignateWinner(
                            winnerId: auction.highestBidderId,
                            potAction: 'burn_pot',
                            expectedHighestBid: currentHighest,
                          );
                        },
                        icon: const Icon(Icons.emoji_events_rounded, size: 15),
                        label: const Text('즉시 낙찰',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoardgameColors.amberBright,
                          foregroundColor: const Color(0xFF451A03),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: '경매 리셋',
                        onPressed: widget.onResetAuction,
                        icon: const Icon(Icons.refresh,
                            color: BoardgameColors.gold, size: 18),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!auction.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xCC140B05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: BoardgameColors.walnutBorder.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                widget.me.isHost
                    ? '위 [경매 시작] 버튼을 눌러 새로운 경매를 시작할 수 있습니다.'
                    : '방장이 경매를 시작하면 즉시 입찰 컨트롤러가 활성화됩니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BoardgameColors.creamSubtle,
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            if (auction.highestBidderName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF241308),
                      Color(0xFF331C0E),
                      Color(0xFF241308),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BoardgameColors.goldBright.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: [
                    BoardgameCalcAvatar(
                      nickname: auction.highestBidderName!,
                      avatarUrl: auction.highestBidderAvatarUrl,
                      avatarColor: auction.highestBidderAvatarColor,
                      size: 40,
                      ringColor: BoardgameColors.goldBright,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMeHighest ? '👑 현재 최고 입찰자 (내가 1등)' : '👑 현재 최고 입찰자',
                            style: const TextStyle(
                              color: Color(0xFFFCD34D),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                          Text(
                            auction.highestBidderName!,
                            style: const TextStyle(
                              color: Color(0xFFFFF5E3),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '입찰 금액',
                          style: TextStyle(
                            color: BoardgameColors.creamSubtle,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${formatCompactNumber(currentHighest)}${settings.currencyUnit}',
                          style: const TextStyle(
                            color: Color(0xFFFCD34D),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BoardgameColors.walnutDarkest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BoardgameColors.walnutBorder),
                ),
                child: const Text(
                  '아직 입찰자가 없습니다. 첫 번째 입찰자가 되어보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: BoardgameColors.creamSubtle,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (auction.endsAt != null && _auctionTimeLeft != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _auctionTimeLeft! <= 5
                      ? BoardgameColors.crimsonBg.withValues(alpha: 0.45)
                      : BoardgameColors.amberBright.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _auctionTimeLeft! <= 5
                        ? BoardgameColors.crimsonBright.withValues(alpha: 0.5)
                        : BoardgameColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _auctionTimeLeft! <= 5
                          ? BoardgameColors.crimsonText
                          : BoardgameColors.goldLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _auctionTimeLeft! <= 0
                            ? '⏰ 시간 종료 (낙찰 대기)'
                            : _auctionTimeLeft! <= 5
                                ? '⏱️ 마감 임박: $_auctionTimeLeft초 남음!'
                                : '⏱️ 남은 시간: $_auctionTimeLeft초',
                        style: TextStyle(
                          color: _auctionTimeLeft! <= 5
                              ? BoardgameColors.crimsonText
                              : BoardgameColors.goldLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (auction.timeLimit != null &&
                        auction.timeLimit! > 0 &&
                        _auctionTimeLeft! > 0)
                      SizedBox(
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (_auctionTimeLeft! / auction.timeLimit!)
                                .clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: Colors.black.withValues(alpha: 0.4),
                            color: _auctionTimeLeft! <= 5
                                ? BoardgameColors.crimsonBright
                                : BoardgameColors.amberBright,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_localConflictError != null ||
                widget.auctionConflictToast != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xB3451A03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BoardgameColors.amberBright),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '⚠️ ${_localConflictError ?? widget.auctionConflictToast}',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _localConflictError = null);
                        widget.onClearConflictToast?.call();
                      },
                      child: const Text('닫기',
                          style: TextStyle(
                              color: BoardgameColors.gold,
                              fontSize: 11,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '빠른 배팅',
                  style: TextStyle(
                    color: BoardgameColors.creamMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '내 보유: ${formatCompactNumber(widget.me.points)}${settings.currencyUnit}',
                  style: const TextStyle(
                    color: BoardgameColors.creamSubtle,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: quickBidUnits.map((step) {
                final nextTotal = currentHighest + step;
                final disabled = isMeHighest ||
                    _isSubmittingBid ||
                    isTimeExpired ||
                    nextTotal > widget.me.points;
                return Opacity(
                  opacity: disabled ? 0.4 : 1.0,
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () {
                            setState(() {
                              _isSubmittingBid = true;
                              _localConflictError = null;
                            });
                            widget.onPlaceBid(
                              nextTotal,
                              expectedHighestBid: currentHighest,
                              callback: (res) {
                                if (mounted) {
                                  setState(() {
                                    _isSubmittingBid = false;
                                    if (res['success'] != true &&
                                        res['error'] != null) {
                                      _localConflictError =
                                          res['error'] as String;
                                    }
                                  });
                                }
                              },
                            );
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: BoardgameColors.walnutSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: BoardgameColors.gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '+${formatCompactNumber(step)}',
                        style: const TextStyle(
                          color: BoardgameColors.goldLight,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customBidCtrl,
                    enabled: !isMeHighest && !_isSubmittingBid && !isTimeExpired,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: BoardgameColors.creamText,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: isTimeExpired
                          ? '경매 시간이 종료되었습니다'
                          : isMeHighest
                              ? '이미 최고 입찰자입니다'
                              : '직접 입찰 (최소 ${formatCompactNumber(minNextBid)})',
                      hintStyle: const TextStyle(
                          color: Color(0xFF8A684B), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF100703),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: BoardgameColors.walnutBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: BoardgameColors.gold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (isMeHighest || _isSubmittingBid || isTimeExpired)
                      ? null
                      : () {
                          final amount =
                              int.tryParse(_customBidCtrl.text.trim());
                          if (amount == null || amount < minNextBid) {
                            setState(() => _localConflictError =
                                '최소 ${formatCommaNumber(minNextBid)}${settings.currencyUnit} 이상으로 입찰해야 합니다.');
                            return;
                          }
                          if (amount > widget.me.points) {
                            setState(() => _localConflictError =
                                '보유 포인트(${formatCommaNumber(widget.me.points)})가 부족합니다.');
                            return;
                          }
                          setState(() {
                            _isSubmittingBid = true;
                            _localConflictError = null;
                          });
                          widget.onPlaceBid(
                            amount,
                            expectedHighestBid: currentHighest,
                            callback: (res) {
                              if (mounted) {
                                setState(() {
                                  _isSubmittingBid = false;
                                  if (res['success'] == true) {
                                    _customBidCtrl.clear();
                                  } else if (res['error'] != null) {
                                    _localConflictError =
                                        res['error'] as String;
                                  }
                                });
                              }
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoardgameColors.amberBright,
                    foregroundColor: const Color(0xFF451A03),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isSubmittingBid
                        ? '입찰 중...'
                        : isTimeExpired
                            ? '시간 종료'
                            : isMeHighest
                                ? '최고 입찰 중'
                                : '입찰하기',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BoardViewPill extends StatelessWidget {
  const _BoardViewPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? BoardgameColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? const Color(0xFF1C0D05)
                  : BoardgameColors.amberBright.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF1C0D05)
                    : BoardgameColors.amberBright.withValues(alpha: 0.85),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardSmallMeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0x262563EB),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0x663B82F6)),
      ),
      child: const Text(
        '나',
        style: TextStyle(
          color: Color(0xFF1E40AF),
          fontWeight: FontWeight.w900,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.border,
    required this.textColor,
    this.iconColor,
    required this.fullTooltip,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color border;
  final Color textColor;
  final Color? iconColor;
  final String fullTooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: fullTooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor ?? textColor),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiceNumInput extends StatelessWidget {
  const _DiceNumInput({
    required this.label,
    required this.suffix,
    required this.ctrl,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final TextEditingController ctrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xE6FCD34D),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 68,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              color: Color(0xFFFEF3C7),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF0F0703),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: const Color(0xFF78350F).withValues(alpha: 0.7),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: BoardgameColors.amberBright),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          suffix,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      ],
    );
  }
}

class _DiceFaceWidget extends StatelessWidget {
  const _DiceFaceWidget({
    required this.value,
    required this.sides,
    required this.size,
  });

  final int value;
  final int sides;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isD6 = sides == 6 && value >= 1 && value <= 6;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF8EF), Color(0xFFEDE2CF)],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: const Color(0xFFD5C3A7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isD6
          ? CustomPaint(painter: _D6PipsPainter(value))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: const Color(0xFF2E1608),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.34,
                  ),
                ),
                Text(
                  'D$sides',
                  style: TextStyle(
                    color: const Color(0xFF6E4624),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.16,
                  ),
                ),
              ],
            ),
    );
  }
}

class _D6PipsPainter extends CustomPainter {
  const _D6PipsPainter(this.value);
  final int value;

  static const Map<int, List<Offset>> _dots = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.26, 0.26), Offset(0.74, 0.74)],
    3: [Offset(0.26, 0.26), Offset(0.5, 0.5), Offset(0.74, 0.74)],
    4: [
      Offset(0.26, 0.26),
      Offset(0.74, 0.26),
      Offset(0.26, 0.74),
      Offset(0.74, 0.74),
    ],
    5: [
      Offset(0.26, 0.26),
      Offset(0.74, 0.26),
      Offset(0.5, 0.5),
      Offset(0.26, 0.74),
      Offset(0.74, 0.74),
    ],
    6: [
      Offset(0.26, 0.24),
      Offset(0.74, 0.24),
      Offset(0.26, 0.5),
      Offset(0.74, 0.5),
      Offset(0.26, 0.76),
      Offset(0.74, 0.76),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2E1608);
    final pts = _dots[value] ?? _dots[1]!;
    final r = size.width * 0.095;
    for (final p in pts) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _D6PipsPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _PotSummaryCard extends StatelessWidget {
  const _PotSummaryCard({
    required this.label,
    required this.badge,
    required this.amountText,
    this.amountColor,
    required this.footerLeft,
    required this.footerRight,
  });

  final String label;
  final String badge;
  final String amountText;
  final Color? amountColor;
  final String footerLeft;
  final String footerRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE6140B05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BoardgameColors.goldBright.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BoardgameColors.creamMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: BoardgameColors.goldBright.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: BoardgameColors.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: amountColor ?? BoardgameColors.goldLight,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
              color: BoardgameColors.walnutBorder.withValues(alpha: 0.6),
              height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footerLeft,
                style: const TextStyle(
                  color: BoardgameColors.creamSubtle,
                  fontSize: 10.5,
                ),
              ),
              Flexible(
                child: Text(
                  footerRight,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
