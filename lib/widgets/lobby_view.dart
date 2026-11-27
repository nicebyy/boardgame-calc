import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../state/boardgame_calc_controller.dart';
import '../theme/boardgame_theme.dart';
import 'confirm_modal.dart';

class BoardgameCalcLobby extends StatefulWidget {
  const BoardgameCalcLobby({
    super.key,
    required this.controller,
  });

  final BoardgameCalcController controller;

  @override
  State<BoardgameCalcLobby> createState() => _BoardgameCalcLobbyState();
}

class _BoardgameCalcLobbyState extends State<BoardgameCalcLobby> {
  String _tab = 'rooms';
  late TextEditingController _nickCtrl;
  late TextEditingController _searchCtrl;
  late TextEditingController _roomTitleCtrl;
  late TextEditingController _customCurrencyCtrl;
  late TextEditingController _initialPointsCtrl;
  late TextEditingController _serverUrlCtrl;

  late String _selectedColor;
  String _currencyPreset = '원';
  PermissionMode _permissionMode = PermissionMode.all;
  PermissionMode _scorePermissionMode = PermissionMode.all;
  bool _allowP2P = true;
  bool _enableAuction = true;
  bool _showAdvancedSettings = false;
  bool _showServerConfig = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl =
        TextEditingController(text: widget.controller.savedNickname);
    _searchCtrl = TextEditingController();
    _roomTitleCtrl = TextEditingController();
    _customCurrencyCtrl = TextEditingController();
    _initialPointsCtrl = TextEditingController(text: '1000');
    _serverUrlCtrl =
        TextEditingController(text: widget.controller.serverUrl);
    _selectedColor = widget.controller.savedAvatarColor;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _searchCtrl.dispose();
    _roomTitleCtrl.dispose();
    _customCurrencyCtrl.dispose();
    _initialPointsCtrl.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  String get _resolvedCurrencyUnit {
    if (_currencyPreset == 'custom') {
      final c = _customCurrencyCtrl.text.trim();
      return c.isNotEmpty ? c : '원';
    }
    return _currencyPreset;
  }

  void _handleCreateRoom() {
    final nick = _nickCtrl.text.trim().isNotEmpty
        ? _nickCtrl.text.trim()
        : '플레이어1';
    final initialPts =
        (int.tryParse(_initialPointsCtrl.text.trim()) ?? 1000).clamp(0, 1000000000);
    widget.controller.createRoom(
      nickname: nick,
      title: _roomTitleCtrl.text.trim().isNotEmpty
          ? _roomTitleCtrl.text.trim()
          : '$nick의 보드게임방',
      avatarColor: _selectedColor,
      settings: BoardgameCalcSettings(
        currencyUnit: _resolvedCurrencyUnit,
        initialPoints: initialPts,
        permissionMode: _permissionMode,
        scorePermissionMode: _scorePermissionMode,
        allowP2P: _allowP2P,
        enableAuction: _enableAuction,
      ),
    );
  }

  Future<void> _confirmDeleteRoom(BoardgameCalcRoomSummary room) async {
    final ok = await showBoardgameConfirmDialog(
      context,
      title: '방장 권한 방 삭제',
      message: "'${room.title}' 방을 삭제하시겠습니까?",
      subMessage: '⚠️ 방이 즉시 삭제 및 정리되며, 참여 중인 모든 플레이어가 로비로 이동됩니다.',
      confirmText: '방 삭제',
      type: ConfirmDialogType.danger,
    );
    if (ok == true) {
      widget.controller.deleteRoom(room.roomCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final q = _searchCtrl.text.trim().toLowerCase();
    final filteredRooms = c.publicRooms.where((r) {
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.hostNickname.toLowerCase().contains(q) ||
          r.roomCode.toLowerCase().contains(q);
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. 실행 모드 전환 바 (오프라인 로컬 vs 온라인 Socket.IO)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BoardgameColors.canvasSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BoardgameColors.canvasBorder),
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
                          Icon(
                            c.isOfflineMode
                                ? Icons.table_restaurant_rounded
                                : Icons.wifi_tethering_rounded,
                            size: 16,
                            color: BoardgameColors.walnutPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.isOfflineMode
                                ? '오프라인 테이블 모드 (서버 없이 즉시 플레이)'
                                : '온라인 멀티플레이어 (Socket.IO 연동)',
                            style: const TextStyle(
                              color: BoardgameColors.inkSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModeSwitchPill(
                            label: '오프라인',
                            active: c.isOfflineMode,
                            onTap: () =>
                                c.setConnectionMode(ConnectionMode.offline),
                          ),
                          const SizedBox(width: 4),
                          _ModeSwitchPill(
                            label: '온라인 서버',
                            active: !c.isOfflineMode,
                            onTap: () => c.setConnectionMode(
                              ConnectionMode.online,
                              customServerUrl: _serverUrlCtrl.text,
                            ),
                          ),
                          if (!c.isOfflineMode) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: '서버 주소 설정',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                  () => _showServerConfig = !_showServerConfig),
                              icon: const Icon(Icons.settings_ethernet,
                                  size: 17,
                                  color: BoardgameColors.walnutPrimary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (!c.isOfflineMode && _showServerConfig) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serverUrlCtrl,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: BoardgameColors.inkPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Socket.IO 백엔드 URL',
                              hintText: 'http://localhost:3001',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              c.updateServerUrl(_serverUrlCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BoardgameColors.walnutPrimary,
                            foregroundColor: BoardgameColors.creamWarmWhite,
                          ),
                          child: const Text('연결',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 1. 상단 탭 전환 (공개방 로비 vs 새 공개방 만들기)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BoardgameColors.canvasChipBg.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BoardgameColors.canvasBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = 'rooms'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _tab == 'rooms'
                              ? BoardgameColors.walnutPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_esports_outlined,
                              size: 17,
                              color: _tab == 'rooms'
                                  ? BoardgameColors.creamWarmWhite
                                  : BoardgameColors.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '공개방 로비',
                              style: TextStyle(
                                color: _tab == 'rooms'
                                    ? BoardgameColors.creamWarmWhite
                                    : BoardgameColors.inkMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (c.publicRooms.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _tab == 'rooms'
                                      ? BoardgameColors.canvasSurface
                                      : const Color(0xFFD8C2AA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${c.publicRooms.length}',
                                  style: TextStyle(
                                    color: _tab == 'rooms'
                                        ? BoardgameColors.walnutPrimary
                                        : BoardgameColors.inkSecondary,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _tab = 'create'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _tab == 'create'
                              ? BoardgameColors.walnutPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 17,
                              color: _tab == 'create'
                                  ? BoardgameColors.creamWarmWhite
                                  : BoardgameColors.inkMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '새 공개방 만들기',
                              style: TextStyle(
                                color: _tab == 'create'
                                    ? BoardgameColors.creamWarmWhite
                                    : BoardgameColors.inkMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (c.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF87171)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFB91C1C), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.error!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => c.setError(null),
                      icon: const Icon(Icons.close,
                          size: 16, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 2. 내 참여 프로필 설정 바
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BoardgameColors.canvasSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BoardgameColors.canvasBorder),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32190A).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: parseHexColor(_selectedColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          getPlayerInitial(_nickCtrl.text),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '내 참여 프로필',
                        style: TextStyle(
                          color: BoardgameColors.inkSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        child: TextField(
                          controller: _nickCtrl,
                          maxLength: 15,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            isDense: true,
                            hintText: '닉네임 입력 (최대 15자)',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 6,
                          children: playerThemePalette.map((palette) {
                            final selected = _selectedColor.toLowerCase() ==
                                palette.hex.toLowerCase();
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedColor = palette.hex),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: palette.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? BoardgameColors.inkSecondary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: selected
                                    ? const Center(
                                        child: Icon(Icons.circle,
                                            size: 7, color: Colors.white),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. 탭 본문
            if (_tab == 'rooms') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: BoardgameColors.inkPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: BoardgameColors.walnutPrimary),
                        hintText: '방 제목 또는 방장 검색...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed:
                        c.isLoadingRooms ? null : () => c.fetchPublicRooms(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: BoardgameColors.canvasSurface,
                      foregroundColor: BoardgameColors.inkSecondary,
                      side:
                          const BorderSide(color: BoardgameColors.canvasBorder),
                      padding: const EdgeInsets.all(13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: c.isLoadingRooms
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredRooms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: BoardgameColors.canvasSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BoardgameColors.canvasBorder),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutPrimary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BoardgameColors.walnutPrimary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.sports_esports_outlined,
                          size: 28,
                          color: BoardgameColors.walnutPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        q.isNotEmpty
                            ? '검색 결과가 없습니다'
                            : '현재 개설된 공개방이 없습니다',
                        style: const TextStyle(
                          color: BoardgameColors.inkPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q.isNotEmpty
                            ? '다른 검색어를 입력하거나 새로고침을 진행해보세요.'
                            : '새 공개방을 만들어 친구들과 실시간 보드게임 포인트 및 경매를 즐겨보세요!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BoardgameColors.inkMuted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _tab = 'create'),
                        icon: const Icon(Icons.add_circle_outline, size: 17),
                        label: const Text('새 공개방 만들기',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoardgameColors.walnutPrimary,
                          foregroundColor: BoardgameColors.creamWarmWhite,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredRooms.map((room) {
                    final isHost = room.hostSessionId == c.mySessionId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BoardgameColors.canvasSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: BoardgameColors.canvasBorder),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF32190A).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        room.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BoardgameColors.inkPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isHost) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: const Color(0xFFFCD34D)),
                                        ),
                                        child: const Text(
                                          '내 방',
                                          style: TextStyle(
                                            color: Color(0xFF92400E),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '방장: ${room.hostNickname} • 참여 ${room.playerCount}명 • 코드 ${room.roomCode}',
                                  style: const TextStyle(
                                    color: BoardgameColors.inkMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isHost) ...[
                            IconButton(
                              tooltip: '방장 권한으로 방 삭제',
                              onPressed: () => _confirmDeleteRoom(room),
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFFDC2626), size: 20),
                            ),
                          ],
                          ElevatedButton.icon(
                            onPressed: () {
                              final nick = _nickCtrl.text.trim().isNotEmpty
                                  ? _nickCtrl.text.trim()
                                  : '플레이어';
                              c.joinRoom(
                                roomCode: room.roomCode,
                                nickname: nick,
                                avatarColor: _selectedColor,
                              );
                            },
                            icon: const Icon(Icons.login_rounded, size: 16),
                            label: const Text(
                              '바로 참여',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BoardgameColors.walnutPrimary,
                              foregroundColor: BoardgameColors.creamWarmWhite,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ] else ...[
              // 4. 새 공개방 만들기 폼
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BoardgameColors.canvasSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BoardgameColors.canvasBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF32190A).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: BoardgameColors.walnutPrimary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '새 공개방 만들기',
                          style: TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '방 제목 (선택)',
                      style: TextStyle(
                        color: BoardgameColors.inkSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _roomTitleCtrl,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '예: 오늘 밤 보드게임 결승전',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: BoardgameColors.canvasSubtleBorder),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🪙 화폐 단위 설정',
                          style: TextStyle(
                            color: BoardgameColors.inkSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          '선택: $_resolvedCurrencyUnit',
                          style: const TextStyle(
                            color: BoardgameColors.walnutPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _LobbyPresetButton(
                            label: '원 (￦)',
                            selected: _currencyPreset == '원',
                            onTap: () => setState(() => _currencyPreset = '원'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LobbyPresetButton(
                            label: '포인트 (p)',
                            selected: _currencyPreset == 'p',
                            onTap: () => setState(() => _currencyPreset = 'p'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LobbyPresetButton(
                            label: '직접 입력',
                            selected: _currencyPreset == 'custom',
                            onTap: () =>
                                setState(() => _currencyPreset = 'custom'),
                          ),
                        ),
                      ],
                    ),
                    if (_currencyPreset == 'custom') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customCurrencyCtrl,
                        maxLength: 6,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: '단위 입력 (예: 골드, 냥, \$ 등)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Divider(color: BoardgameColors.canvasSubtleBorder),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(
                          () => _showAdvancedSettings = !_showAdvancedSettings),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EBE1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8C2AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded,
                                size: 16,
                                color: BoardgameColors.walnutPrimary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '세부 설정 미리 지정하기 (시작 자금, 권한, P2P, 경매)',
                                style: TextStyle(
                                  color: BoardgameColors.inkSecondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              _showAdvancedSettings
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: BoardgameColors.inkMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showAdvancedSettings) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '기본 시작 자금',
                        style: TextStyle(
                          color: BoardgameColors.inkSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _initialPointsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: _resolvedCurrencyUnit,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🛡️ 포인트 증감 권한 설정',
                        style: TextStyle(
                          color: BoardgameColors.inkSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _LobbyRuleCard(
                              title: '자율 모드',
                              subtitle: '본인 잔액 자율 증감 + P2P',
                              selected: _permissionMode == PermissionMode.all,
                              onTap: () => setState(
                                  () => _permissionMode = PermissionMode.all),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LobbyRuleCard(
                              title: '엄격 뱅커 모드',
                              subtitle: '방장만 조율 + P2P 송금',
                              selected:
                                  _permissionMode == PermissionMode.hostOnly,
                              onTap: () => setState(() =>
                                  _permissionMode = PermissionMode.hostOnly),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🏆 점수 증감 권한 설정',
                        style: TextStyle(
                          color: BoardgameColors.inkSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _LobbyRuleCard(
                              title: '자율 모드',
                              subtitle: '본인 점수 자율 증감',
                              selected:
                                  _scorePermissionMode == PermissionMode.all,
                              onTap: () => setState(() =>
                                  _scorePermissionMode = PermissionMode.all),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LobbyRuleCard(
                              title: '엄격 뱅커 모드',
                              subtitle: '방장만 점수 조율',
                              selected: _scorePermissionMode ==
                                  PermissionMode.hostOnly,
                              onTap: () => setState(() => _scorePermissionMode =
                                  PermissionMode.hostOnly),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'P2P 플레이어 간 합의 송금 허용',
                          style: TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        value: _allowP2P,
                        onChanged: (v) =>
                            setState(() => _allowP2P = v ?? true),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '실시간 경매 및 판돈 배팅 활성화',
                          style: TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        value: _enableAuction,
                        onChanged: (v) =>
                            setState(() => _enableAuction = v ?? true),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => setState(() => _tab = 'rooms'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4EBE1),
                            foregroundColor: BoardgameColors.inkSecondary,
                            side: const BorderSide(
                                color: BoardgameColors.canvasBorder),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('목록으로',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleCreateRoom,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 17),
                            label: const Text(
                              '공개방 생성하고 게임 시작',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BoardgameColors.walnutPrimary,
                              foregroundColor: BoardgameColors.creamWarmWhite,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeSwitchPill extends StatelessWidget {
  const _ModeSwitchPill({
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? BoardgameColors.walnutPrimary
              : const Color(0xFFF4EBE1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? BoardgameColors.walnutPrimary
                : BoardgameColors.canvasBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? BoardgameColors.creamWarmWhite
                : BoardgameColors.inkMuted,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LobbyPresetButton extends StatelessWidget {
  const _LobbyPresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? BoardgameColors.walnutPrimary
              : const Color(0xFFF4EBE1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? BoardgameColors.walnutPrimary
                : const Color(0xFFD8C2AA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? BoardgameColors.creamWarmWhite
                : BoardgameColors.inkMuted,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _LobbyRuleCard extends StatelessWidget {
  const _LobbyRuleCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? BoardgameColors.walnutPrimary
              : const Color(0xFFF4EBE1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? BoardgameColors.walnutPrimary
                : const Color(0xFFD8C2AA),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? BoardgameColors.creamWarmWhite
                    : BoardgameColors.inkSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: selected
                    ? BoardgameColors.creamWarmWhite.withValues(alpha: 0.85)
                    : BoardgameColors.inkMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
