import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';
import '../player_avatar.dart';

Future<void> showBoardgameAdjustModal(
  BuildContext context, {
  required BoardgameCalcPlayer targetPlayer,
  required String currencyUnit,
  required String scoreUnit,
  required bool enableScore,
  required List<int> quickAdjustUnits,
  required List<int> scoreQuickUnits,
  required void Function(String targetPlayerId, int delta, {String? reason})
      onAdjustPoints,
  required void Function(String targetPlayerId, int delta, {String? reason})
      onAdjustScore,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _AdjustDialog(
      targetPlayer: targetPlayer,
      currencyUnit: currencyUnit,
      scoreUnit: scoreUnit,
      enableScore: enableScore,
      quickAdjustUnits: quickAdjustUnits,
      scoreQuickUnits: scoreQuickUnits,
      onAdjustPoints: onAdjustPoints,
      onAdjustScore: onAdjustScore,
    ),
  );
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({
    required this.targetPlayer,
    required this.currencyUnit,
    required this.scoreUnit,
    required this.enableScore,
    required this.quickAdjustUnits,
    required this.scoreQuickUnits,
    required this.onAdjustPoints,
    required this.onAdjustScore,
  });

  final BoardgameCalcPlayer targetPlayer;
  final String currencyUnit;
  final String scoreUnit;
  final bool enableScore;
  final List<int> quickAdjustUnits;
  final List<int> scoreQuickUnits;
  final void Function(String targetPlayerId, int delta, {String? reason})
      onAdjustPoints;
  final void Function(String targetPlayerId, int delta, {String? reason})
      onAdjustScore;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  bool _isScoreCategory = false;
  bool _isPlus = true;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _errorMsg;

  List<int> get _units {
    final source =
        _isScoreCategory ? widget.scoreQuickUnits : widget.quickAdjustUnits;
    final pos = source.map((u) => u.abs()).where((u) => u > 0).toSet().toList()
      ..sort();
    if (pos.isNotEmpty) return pos;
    return _isScoreCategory
        ? BoardgameCalcConstants.defaultScoreQuickUnits
        : [100, 500, 1000, 5000, 10000];
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _quickAdd(int val) {
    final cur = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    setState(() {
      _amountCtrl.text = '${cur + val}';
      _errorMsg = null;
    });
  }

  void _submit() {
    final val = int.tryParse(_amountCtrl.text.trim());
    if (val == null || val <= 0) {
      setState(() => _errorMsg =
          '1 이상의 정수 ${_isScoreCategory ? '점수' : '금액'}를 입력해주세요.');
      return;
    }
    final delta = _isPlus ? val : -val;
    final reason = _reasonCtrl.text.trim();
    if (_isScoreCategory) {
      widget.onAdjustScore(
        widget.targetPlayer.id,
        delta,
        reason: reason.isNotEmpty ? reason : null,
      );
    } else {
      widget.onAdjustPoints(
        widget.targetPlayer.id,
        delta,
        reason: reason.isNotEmpty ? reason : null,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isScore = widget.enableScore && _isScoreCategory;
    final activeUnit = isScore ? widget.scoreUnit : widget.currencyUnit;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
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
                        isScore
                            ? Icons.emoji_events_rounded
                            : Icons.monetization_on_rounded,
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
                            isScore ? '점수(승점) 직접 조율' : '포인트(화폐) 직접 조율',
                            style: const TextStyle(
                              color: BoardgameColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isScore ? '승점/점수 즉시 가감' : '플레이어 잔액 즉시 가감',
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
                const SizedBox(height: 12),
                if (widget.enableScore) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: BoardgameColors.walnutDarkest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabPill(
                            label: '화폐 (${widget.currencyUnit})',
                            icon: Icons.monetization_on_outlined,
                            active: !_isScoreCategory,
                            onTap: () => setState(() {
                              _isScoreCategory = false;
                              _amountCtrl.clear();
                              _errorMsg = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _TabPill(
                            label: '점수 (${widget.scoreUnit})',
                            icon: Icons.emoji_events_outlined,
                            active: _isScoreCategory,
                            onTap: () => setState(() {
                              _isScoreCategory = true;
                              _amountCtrl.clear();
                              _errorMsg = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                        nickname: widget.targetPlayer.nickname,
                        avatarUrl: widget.targetPlayer.avatarUrl,
                        avatarColor: widget.targetPlayer.avatarColor,
                        size: 36,
                        isOnline: widget.targetPlayer.isOnline,
                        showOnlineDot: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.targetPlayer.nickname,
                              style: const TextStyle(
                                color: BoardgameColors.creamText,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              '잔액: ${formatCompactNumber(widget.targetPlayer.points)} ${widget.currencyUnit} • 점수: ${formatCompactNumber(widget.targetPlayer.score)} ${widget.scoreUnit}',
                              style: const TextStyle(
                                color: BoardgameColors.creamMuted,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModeToggleButton(
                        label: '지급 / 증가 (+)',
                        active: _isPlus,
                        activeBg: BoardgameColors.emeraldBg,
                        activeBorder: BoardgameColors.emeraldBorder,
                        activeText: BoardgameColors.emeraldText,
                        onTap: () => setState(() => _isPlus = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeToggleButton(
                        label: '차감 / 감소 (-)',
                        active: !_isPlus,
                        activeBg: BoardgameColors.crimsonBg,
                        activeBorder: BoardgameColors.crimsonBorder,
                        activeText: BoardgameColors.crimsonText,
                        onTap: () => setState(() => _isPlus = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                  onChanged: (_) => setState(() => _errorMsg = null),
                  decoration: InputDecoration(
                    hintText: isScore ? '변경할 점수 입력' : '변경할 금액 입력',
                    hintStyle: const TextStyle(color: Color(0xFF8A684B)),
                    filled: true,
                    fillColor: BoardgameColors.walnutDeep,
                    suffixText: activeUnit,
                    suffixStyle: const TextStyle(
                      color: BoardgameColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: BoardgameColors.amberBright),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _units.map((u) {
                    return InkWell(
                      onTap: () => _quickAdd(u),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BoardgameColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '+${formatCompactNumber(u)}',
                          style: const TextStyle(
                            color: BoardgameColors.goldLight,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonCtrl,
                  maxLength: 30,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: '사유 메모 (선택)',
                    hintStyle: const TextStyle(color: Color(0xFF8A684B)),
                    counterText: '',
                    filled: true,
                    fillColor: BoardgameColors.walnutDeep,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: BoardgameColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: BoardgameColors.amberBright),
                    ),
                  ),
                ),
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: _isPlus
                          ? BoardgameColors.goldBright
                          : BoardgameColors.crimsonBright,
                      foregroundColor: _isPlus
                          ? BoardgameColors.walnutDarkest
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isPlus ? '+ 반영하기' : '- 차감 반영하기',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
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

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? BoardgameColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? BoardgameColors.walnutDarkest
                  : BoardgameColors.creamMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? BoardgameColors.walnutDarkest
                    : BoardgameColors.creamMuted,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  const _ModeToggleButton({
    required this.label,
    required this.active,
    required this.activeBg,
    required this.activeBorder,
    required this.activeText,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeBg;
  final Color activeBorder;
  final Color activeText;
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
          color: active ? activeBg : BoardgameColors.walnutCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? activeBorder
                : BoardgameColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeText : BoardgameColors.creamMuted,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
