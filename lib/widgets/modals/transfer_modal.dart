import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';
import '../player_avatar.dart';

Future<void> showBoardgameTransferModal(
  BuildContext context, {
  required BoardgameCalcPlayer targetPlayer,
  required int myPoints,
  required String currencyUnit,
  required List<int> quickAdjustUnits,
  required void Function(String toPlayerId, int amount, {String? memo})
      onTransfer,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _TransferDialog(
      targetPlayer: targetPlayer,
      myPoints: myPoints,
      currencyUnit: currencyUnit,
      quickAdjustUnits: quickAdjustUnits,
      onTransfer: onTransfer,
    ),
  );
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({
    required this.targetPlayer,
    required this.myPoints,
    required this.currencyUnit,
    required this.quickAdjustUnits,
    required this.onTransfer,
  });

  final BoardgameCalcPlayer targetPlayer;
  final int myPoints;
  final String currencyUnit;
  final List<int> quickAdjustUnits;
  final void Function(String toPlayerId, int amount, {String? memo}) onTransfer;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String? _errorMsg;

  List<int> get _quickUnits {
    final pos = widget.quickAdjustUnits
        .map((u) => u.abs())
        .where((u) => u > 0)
        .toSet()
        .toList()
      ..sort();
    if (pos.isNotEmpty) return pos.take(6).toList();
    return BoardgameCalcConstants.defaultQuickTransferUnits;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  void _quickAdd(int val) {
    final safeMy = widget.myPoints < 0 ? 0 : widget.myPoints;
    if (safeMy <= 0) return;
    final cur = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final next = (cur + val).clamp(0, safeMy);
    setState(() {
      _amountCtrl.text = '$next';
      _errorMsg = null;
    });
  }

  void _submit() {
    final safeMy = widget.myPoints < 0 ? 0 : widget.myPoints;
    final numAmount = int.tryParse(_amountCtrl.text.trim());
    if (numAmount == null || numAmount <= 0) {
      setState(() => _errorMsg = '1 이상의 정수를 입력해주세요.');
      return;
    }
    if (numAmount > safeMy) {
      setState(() => _errorMsg =
          '보유 잔액(${formatCommaNumber(safeMy)}${widget.currencyUnit})보다 큰 금액은 보낼 수 없습니다.');
      return;
    }
    widget.onTransfer(
      widget.targetPlayer.id,
      numAmount,
      memo: _memoCtrl.text.trim().isNotEmpty ? _memoCtrl.text.trim() : null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final safeMy = widget.myPoints < 0 ? 0 : widget.myPoints;
    final currentInput = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final isOverBalance = currentInput > safeMy;

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
                      child: const Icon(Icons.send_rounded,
                          color: BoardgameColors.goldLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '포인트 송금',
                            style: TextStyle(
                              color: BoardgameColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '상대방 합의 후 전달됩니다',
                            style: TextStyle(
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
                Divider(
                    color: BoardgameColors.gold.withValues(alpha: 0.25),
                    height: 1),
                const SizedBox(height: 14),
                const Text(
                  '받는 플레이어',
                  style: TextStyle(
                    color: BoardgameColors.creamMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
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
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '현재 잔액: ${formatCompactNumber(widget.targetPlayer.points)} ${widget.currencyUnit}',
                              style: const TextStyle(
                                color: BoardgameColors.creamMuted,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_outline,
                          color: BoardgameColors.goldBright, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '송금 금액',
                      style: TextStyle(
                        color: BoardgameColors.creamText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '내 잔액: ${formatCompactNumber(widget.myPoints)} ${widget.currencyUnit}',
                      style: const TextStyle(
                        color: BoardgameColors.creamMuted,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                  onChanged: (_) => setState(() => _errorMsg = null),
                  decoration: InputDecoration(
                    hintText: '보낼 금액 입력',
                    hintStyle: const TextStyle(color: Color(0xFF8A684B)),
                    filled: true,
                    fillColor: BoardgameColors.walnutDeep,
                    suffixText: widget.currencyUnit,
                    suffixStyle: const TextStyle(
                      color: BoardgameColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isOverBalance
                            ? BoardgameColors.crimsonBright
                            : BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isOverBalance
                            ? BoardgameColors.crimsonBright
                            : BoardgameColors.amberBright,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickUnits.map((u) {
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
                const SizedBox(height: 12),
                TextField(
                  controller: _memoCtrl,
                  maxLength: 30,
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: '메모 (선택, 예: 통행료, 거래 대금)',
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BoardgameColors.crimsonBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BoardgameColors.crimsonBright),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: BoardgameColors.crimsonText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(
                              color: BoardgameColors.crimsonText,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      '송금 요청 보내기',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: BoardgameColors.goldBright,
                      foregroundColor: BoardgameColors.walnutDarkest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
