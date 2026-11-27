import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../theme/boardgame_theme.dart';
import 'confirm_modal.dart';

class BoardgameCalcHamburgerMenu extends StatefulWidget {
  const BoardgameCalcHamburgerMenu({
    super.key,
    required this.room,
    required this.me,
    required this.activeTool,
    required this.onSelectTool,
    required this.onOpenLogs,
    required this.logCount,
    required this.onOpenSettings,
    required this.soundEnabled,
    required this.onToggleSound,
    required this.onUpdateSettings,
    required this.onLeaveRoom,
    required this.onDeleteRoom,
    required this.isOfflineMode,
    this.onAddLocalPlayer,
    this.onSwitchLocalPlayer,
  });

  final BoardgameCalcRoom room;
  final BoardgameCalcPlayer me;
  final CenterToolType activeTool;
  final ValueChanged<CenterToolType> onSelectTool;
  final VoidCallback onOpenLogs;
  final int logCount;
  final VoidCallback onOpenSettings;
  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final ValueChanged<BoardgameCalcSettings> onUpdateSettings;
  final VoidCallback onLeaveRoom;
  final VoidCallback onDeleteRoom;
  final bool isOfflineMode;
  final ValueChanged<String>? onAddLocalPlayer;
  final ValueChanged<BoardgameCalcPlayer>? onSwitchLocalPlayer;

  @override
  State<BoardgameCalcHamburgerMenu> createState() =>
      _BoardgameCalcHamburgerMenuState();
}

class _BoardgameCalcHamburgerMenuState
    extends State<BoardgameCalcHamburgerMenu> {
  final _newPlayerCtrl = TextEditingController();

  @override
  void dispose() {
    _newPlayerCtrl.dispose();
    super.dispose();
  }

  void _selectTool(CenterToolType tool) {
    if (!widget.me.isHost) return;
    if (tool == CenterToolType.auction && !widget.room.settings.enableAuction) {
      return;
    }
    final next = widget.activeTool == tool ? CenterToolType.empty : tool;
    widget.onSelectTool(next);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final ok = await showBoardgameConfirmDialog(
      context,
      title: '방장 권한 방 삭제 및 폭파',
      message: '방을 정말로 종료 및 삭제하시겠습니까?',
      subMessage: '⚠️ 방이 즉시 삭제되며 모든 참여 플레이어가 로비로 퇴장됩니다.',
      confirmText: '방 폭파 (삭제)',
      type: ConfirmDialogType.danger,
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop();
      widget.onDeleteRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.room.settings;
    final displayMode = settings.resolvedDisplayMode;
    final isHost = widget.me.isHost;

    return Drawer(
      width: 330,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 1.4,
            colors: [
              BoardgameColors.walnutElevated,
              BoardgameColors.walnutSurface,
              BoardgameColors.walnutDarkest,
            ],
          ),
          border: Border(
            left: BorderSide(
              color: BoardgameColors.gold.withValues(alpha: 0.45),
              width: 2.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 상단 헤더
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: BoardgameColors.gold.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: BoardgameColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BoardgameColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          '☰',
                          style: TextStyle(
                            color: BoardgameColors.goldLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '인게임 메뉴 & 설정',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: widget.onToggleSound,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.soundEnabled
                                ? BoardgameColors.emeraldBg
                                : BoardgameColors.walnutCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.soundEnabled
                                  ? BoardgameColors.emeraldBorder
                                  : BoardgameColors.walnutMutedBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                size: 14,
                                color: widget.soundEnabled
                                    ? BoardgameColors.emeraldText
                                    : BoardgameColors.crimsonText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.soundEnabled ? 'ON' : 'OFF',
                                style: TextStyle(
                                  color: widget.soundEnabled
                                      ? BoardgameColors.emeraldText
                                      : BoardgameColors.creamMuted,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: BoardgameColors.gold, size: 20),
                      ),
                    ],
                  ),
                ),

                // 스크롤 콘텐츠
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '✨ 중앙 보드판 도구 꺼내기',
                              style: TextStyle(
                                color: BoardgameColors.creamMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHost
                                    ? BoardgameColors.amberBright
                                        .withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isHost ? '👑 방장 전용 관리' : '실시간 시청 중',
                                style: TextStyle(
                                  color: isHost
                                      ? const Color(0xFFFCD34D)
                                      : BoardgameColors.creamSubtle,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!isHost)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BoardgameColors.walnutCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BoardgameColors.amberBright
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '현재 보드판: ${switch (widget.activeTool) {
                                CenterToolType.empty => '👥 플레이어 보드 (기본)',
                                CenterToolType.dice => '🎲 주사위 롤러',
                                CenterToolType.betting => '💰 배팅 판돈 & 모인 돈',
                                CenterToolType.auction => '🔨 실시간 경매',
                                CenterToolType.secretNote => '📝 비밀노트',
                              }}\n중앙 보드판은 방장이 일괄 관리합니다.',
                              style: const TextStyle(
                                color: BoardgameColors.creamMuted,
                                fontSize: 11.5,
                                height: 1.45,
                              ),
                            ),
                          )
                        else ...[
                          if (widget.activeTool != CenterToolType.empty) ...[
                            _DrawerToolTile(
                              icon: Icons.close_rounded,
                              title: '도구 닫기 (플레이어 보드로 복귀)',
                              active: false,
                              badge: '닫기',
                              isDanger: true,
                              onTap: () => _selectTool(CenterToolType.empty),
                            ),
                            const SizedBox(height: 6),
                          ],
                          _DrawerToolTile(
                            icon: Icons.casino_outlined,
                            title: '🎲 주사위 롤러',
                            active: widget.activeTool == CenterToolType.dice,
                            badge: widget.activeTool == CenterToolType.dice
                                ? '꺼냄'
                                : null,
                            onTap: () => _selectTool(CenterToolType.dice),
                          ),
                          const SizedBox(height: 6),
                          _DrawerToolTile(
                            icon: Icons.monetization_on_outlined,
                            title: widget.room.betting.currentPot > 0
                                ? '💰 배팅 판돈 (${formatCompactNumber(widget.room.betting.currentPot)}${settings.currencyUnit})'
                                : '💰 배팅 판돈 & 모인 돈',
                            active: widget.activeTool == CenterToolType.betting,
                            badge: widget.activeTool == CenterToolType.betting
                                ? '꺼냄'
                                : null,
                            onTap: () => _selectTool(CenterToolType.betting),
                          ),
                          if (settings.enableAuction) ...[
                            const SizedBox(height: 6),
                            _DrawerToolTile(
                              icon: Icons.gavel_rounded,
                              title: widget.room.auction.isActive
                                  ? '🔨 실시간 경매 (진행 중)'
                                  : '🔨 실시간 경매',
                              active:
                                  widget.activeTool == CenterToolType.auction,
                              badge: widget.activeTool == CenterToolType.auction
                                  ? '꺼냄'
                                  : null,
                              onTap: () => _selectTool(CenterToolType.auction),
                            ),
                          ],
                          const SizedBox(height: 6),
                          _DrawerToolTile(
                            icon: Icons.description_outlined,
                            title: '📝 비밀노트',
                            active:
                                widget.activeTool == CenterToolType.secretNote,
                            badge: widget.activeTool == CenterToolType.secretNote
                                ? '꺼냄'
                                : null,
                            onTap: () => _selectTool(CenterToolType.secretNote),
                          ),
                        ],

                        // 오프라인 Pass & Play 플레이어 추가/전환
                        if (widget.isOfflineMode) ...[
                          const SizedBox(height: 16),
                          Divider(
                              color:
                                  BoardgameColors.gold.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                          const Text(
                            '🎮 오프라인 테이블 (Pass & Play)',
                            style: TextStyle(
                              color: BoardgameColors.goldLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newPlayerCtrl,
                                  maxLength: 15,
                                  style: const TextStyle(
                                    color: BoardgameColors.creamText,
                                    fontSize: 12,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    isDense: true,
                                    hintText: '로컬 플레이어 추가...',
                                    hintStyle: const TextStyle(
                                        color: Color(0xFF8A684B), fontSize: 11),
                                    filled: true,
                                    fillColor: BoardgameColors.walnutDeep,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 9),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: BoardgameColors.gold
                                              .withValues(alpha: 0.35)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () {
                                  final name = _newPlayerCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  widget.onAddLocalPlayer?.call(name);
                                  _newPlayerCtrl.clear();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: BoardgameColors.gold,
                                  foregroundColor:
                                      BoardgameColors.walnutDarkest,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('추가',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '시점 전환 (현재 조작 플레이어):',
                            style: TextStyle(
                              color: BoardgameColors.creamSubtle,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.room.players.map((p) {
                              final isCurrent = p.id == widget.me.id;
                              return InkWell(
                                onTap: () =>
                                    widget.onSwitchLocalPlayer?.call(p),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? BoardgameColors.gold
                                        : BoardgameColors.walnutCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent
                                          ? BoardgameColors.goldLight
                                          : BoardgameColors.gold
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${p.isHost ? '👑 ' : ''}${p.nickname}',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? BoardgameColors.walnutDarkest
                                          : BoardgameColors.creamText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Divider(
                            color: BoardgameColors.gold.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '⚙️ 방 환경설정 & 게임 룰',
                              style: TextStyle(
                                color: BoardgameColors.creamMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              isHost ? '방장 권한' : '읽기전용',
                              style: TextStyle(
                                color: isHost
                                    ? BoardgameColors.amberBright
                                    : BoardgameColors.creamSubtle,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isHost) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BoardgameColors.walnutCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    BoardgameColors.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '포인트 증감 권한',
                                  style: TextStyle(
                                    color: BoardgameColors.creamMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RuleChip(
                                        label: '자율 (누구나)',
                                        active: settings.permissionMode ==
                                            PermissionMode.all,
                                        onTap: () => widget.onUpdateSettings(
                                            settings.copyWith(
                                                permissionMode:
                                                    PermissionMode.all)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: _RuleChip(
                                        label: '엄격 (방장만)',
                                        active: settings.permissionMode ==
                                            PermissionMode.hostOnly,
                                        onTap: () => widget.onUpdateSettings(
                                            settings.copyWith(
                                                permissionMode:
                                                    PermissionMode.hostOnly)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '화면 표기 항목',
                                  style: TextStyle(
                                    color: BoardgameColors.creamMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RuleChip(
                                        label: '둘 다',
                                        active:
                                            displayMode == ScoreDisplayMode.all,
                                        onTap: () => widget.onUpdateSettings(
                                            settings.copyWith(
                                                scoreDisplayMode:
                                                    ScoreDisplayMode.all,
                                                enableScore: true)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _RuleChip(
                                        label: '화폐만',
                                        active: displayMode ==
                                            ScoreDisplayMode.currency,
                                        onTap: () => widget.onUpdateSettings(
                                            settings.copyWith(
                                                scoreDisplayMode:
                                                    ScoreDisplayMode.currency,
                                                enableScore: false)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _RuleChip(
                                        label: '점수만',
                                        active: displayMode ==
                                            ScoreDisplayMode.score,
                                        onTap: () => widget.onUpdateSettings(
                                            settings.copyWith(
                                                scoreDisplayMode:
                                                    ScoreDisplayMode.score,
                                                enableScore: true)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onOpenSettings();
                                    },
                                    icon: const Icon(Icons.settings_outlined,
                                        size: 15),
                                    label: const Text(
                                      '방장 세부 설정 (화폐·자금·초기화)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: BoardgameColors
                                          .amberBright
                                          .withValues(alpha: 0.14),
                                      foregroundColor: const Color(0xFFFCD34D),
                                      side: BorderSide(
                                        color: BoardgameColors.amberBright
                                            .withValues(alpha: 0.45),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BoardgameColors.walnutCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    BoardgameColors.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: '포인트 권한',
                                  value: settings.permissionMode ==
                                          PermissionMode.all
                                      ? '자율 모드'
                                      : '방장 전용',
                                ),
                                _SummaryRow(
                                  label: 'P2P 송금',
                                  value: settings.allowP2P ? '허용' : '차단',
                                ),
                                _SummaryRow(
                                  label: '경매 기능',
                                  value: settings.enableAuction ? '활성' : '비활성',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),
                        _DrawerToolTile(
                          icon: Icons.history_rounded,
                          title: '📜 로그보기',
                          active: false,
                          badge: '${widget.logCount}건',
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onOpenLogs();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단: 방 삭제 & 방 나가기
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: BoardgameColors.gold.withValues(alpha: 0.25)),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isHost) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text(
                              '방 삭제 및 방 폭파 (방장)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: BoardgameColors.crimsonBg
                                  .withValues(alpha: 0.55),
                              foregroundColor: BoardgameColors.crimsonText,
                              side: BorderSide(
                                color: BoardgameColors.crimsonBright
                                    .withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onLeaveRoom();
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text(
                            '방 나가기',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: BoardgameColors.walnutCard,
                            foregroundColor: BoardgameColors.creamText,
                            side: BorderSide(
                              color: BoardgameColors.gold.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerToolTile extends StatelessWidget {
  const _DrawerToolTile({
    required this.icon,
    required this.title,
    required this.active,
    this.badge,
    this.isDanger = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool active;
  final String? badge;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDanger
              ? BoardgameColors.crimsonBg.withValues(alpha: 0.45)
              : active
                  ? BoardgameColors.gold.withValues(alpha: 0.22)
                  : BoardgameColors.walnutCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDanger
                ? BoardgameColors.crimsonBright.withValues(alpha: 0.5)
                : active
                    ? BoardgameColors.goldBright
                    : BoardgameColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDanger
                  ? BoardgameColors.crimsonText
                  : active
                      ? BoardgameColors.goldLight
                      : BoardgameColors.creamMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDanger
                      ? BoardgameColors.crimsonText
                      : active
                          ? BoardgameColors.goldLight
                          : BoardgameColors.creamText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: BoardgameColors.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.white.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? BoardgameColors.gold.withValues(alpha: 0.25)
              : BoardgameColors.walnutDarkest,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active
                ? BoardgameColors.goldBright
                : BoardgameColors.gold.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                active ? BoardgameColors.goldLight : BoardgameColors.creamMuted,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: BoardgameColors.creamMuted,
              fontSize: 11.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: BoardgameColors.goldLight,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
