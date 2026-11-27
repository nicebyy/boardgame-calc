import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';
import '../player_avatar.dart';

Future<void> showBoardgameRenameModal(
  BuildContext context, {
  required BoardgameCalcPlayer targetPlayer,
  required List<BoardgameCalcPlayer> allPlayers,
  required String? myId,
  required String? mySessionId,
  required void Function(String targetPlayerId, String newNickname) onRename,
  void Function(String avatarColor)? onUpdateColor,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _RenameDialog(
      targetPlayer: targetPlayer,
      allPlayers: allPlayers,
      myId: myId,
      mySessionId: mySessionId,
      onRename: onRename,
      onUpdateColor: onUpdateColor,
    ),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.targetPlayer,
    required this.allPlayers,
    required this.myId,
    required this.mySessionId,
    required this.onRename,
    this.onUpdateColor,
  });

  final BoardgameCalcPlayer targetPlayer;
  final List<BoardgameCalcPlayer> allPlayers;
  final String? myId;
  final String? mySessionId;
  final void Function(String targetPlayerId, String newNickname) onRename;
  final void Function(String avatarColor)? onUpdateColor;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _nickCtrl;
  late String _selectedColor;
  String? _errorMsg;

  bool get _isSelf => widget.targetPlayer
      .matchesIdentity(myId: widget.myId, mySessionId: widget.mySessionId);

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.targetPlayer.nickname);
    _selectedColor = widget.targetPlayer.avatarColor.isNotEmpty
        ? widget.targetPlayer.avatarColor
        : playerThemePalette.first.hex;
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  bool _validate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      setState(() => _errorMsg = '변경할 닉네임을 입력해주세요.');
      return false;
    }
    if (clean.length > BoardgameCalcConstants.maxNicknameLength) {
      setState(() => _errorMsg =
          '닉네임은 최대 ${BoardgameCalcConstants.maxNicknameLength}자까지 가능합니다.');
      return false;
    }
    final isDup = widget.allPlayers.any((p) =>
        p.id != widget.targetPlayer.id &&
        !(widget.targetPlayer.sessionId.isNotEmpty &&
            p.sessionId == widget.targetPlayer.sessionId) &&
        p.nickname.trim().toLowerCase() == clean.toLowerCase());
    if (isDup) {
      setState(() => _errorMsg = "방에 이미 동일한 닉네임('$clean')이 존재합니다.");
      return false;
    }
    setState(() => _errorMsg = null);
    return true;
  }

  void _submit() {
    if (!_validate(_nickCtrl.text)) return;
    final clean = _nickCtrl.text.trim();
    if (clean != widget.targetPlayer.nickname) {
      widget.onRename(widget.targetPlayer.id, clean);
    }
    if (widget.onUpdateColor != null &&
        _selectedColor.toLowerCase() !=
            widget.targetPlayer.avatarColor.toLowerCase()) {
      widget.onUpdateColor!(_selectedColor);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewNick = _nickCtrl.text.trim().isNotEmpty
        ? _nickCtrl.text.trim()
        : widget.targetPlayer.nickname;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                BoardgameColors.walnutElevated,
                BoardgameColors.walnutSurface,
                BoardgameColors.walnutDarkest,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: BoardgameColors.gold.withValues(alpha: 0.55),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: BoardgameColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      _isSelf ? Icons.palette_outlined : Icons.edit_outlined,
                      color: BoardgameColors.goldLight,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelf ? '내 프로필 편집' : '플레이어 닉네임 편집',
                          style: const TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _isSelf ? '닉네임 및 테마 색상 실시간 변경' : '방장 전용 강제 개명',
                          style: const TextStyle(
                            color: BoardgameColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        color: BoardgameColors.gold, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BoardgameColors.walnutDarkest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BoardgameColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    BoardgameCalcAvatar(
                      nickname: previewNick,
                      avatarUrl: widget.targetPlayer.avatarUrl,
                      avatarColor: _selectedColor,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSelf ? '새 프로필 미리보기' : '현재 대상',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                          Text(
                            previewNick,
                            style: const TextStyle(
                              color: BoardgameColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '새 닉네임',
                    style: TextStyle(
                      color: BoardgameColors.creamText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_nickCtrl.text.trim().length} / 15자',
                    style: const TextStyle(
                      color: BoardgameColors.gold,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nickCtrl,
                maxLength: BoardgameCalcConstants.maxNicknameLength,
                onChanged: (v) {
                  setState(() {});
                  if (_errorMsg != null) _validate(v);
                },
                style: const TextStyle(
                  color: BoardgameColors.creamText,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '변경할 닉네임 입력 (1~15자)',
                  hintStyle: const TextStyle(color: Color(0xFF8A684B)),
                  filled: true,
                  fillColor: BoardgameColors.walnutDeep,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMsg != null
                          ? BoardgameColors.crimsonBright
                          : BoardgameColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: BoardgameColors.amberBright),
                  ),
                ),
              ),
              if (_isSelf && widget.onUpdateColor != null) ...[
                const SizedBox(height: 14),
                const Text(
                  '플레이어 테마 색상',
                  style: TextStyle(
                    color: BoardgameColors.creamText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: playerThemePalette.map((c) {
                    final selected =
                        _selectedColor.toLowerCase() == c.hex.toLowerCase();
                    return Tooltip(
                      message: c.name,
                      child: InkWell(
                        onTap: () => setState(() => _selectedColor = c.hex),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? BoardgameColors.goldLight
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? const Center(
                                  child: Icon(Icons.check,
                                      size: 16, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMsg!,
                  style: const TextStyle(
                    color: BoardgameColors.crimsonText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: BoardgameColors.goldBright,
                    foregroundColor: BoardgameColors.walnutDarkest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장하기',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
