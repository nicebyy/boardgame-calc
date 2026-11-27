import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';

Future<void> showBoardgameConsentModal(
  BuildContext context, {
  required BoardgameCalcTransferRequest request,
  required String currencyUnit,
  required void Function(String requestId, bool accept) onRespond,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ConsentDialog(
      request: request,
      currencyUnit: currencyUnit,
      onRespond: onRespond,
    ),
  );
}

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog({
    required this.request,
    required this.currencyUnit,
    required this.onRespond,
  });

  final BoardgameCalcTransferRequest request;
  final String currencyUnit;
  final void Function(String requestId, bool accept) onRespond;

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  bool _responding = false;

  void _handle(bool accept) {
    if (_responding) return;
    setState(() => _responding = true);
    widget.onRespond(widget.request.requestId, accept);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: BoardgameColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.verified_user_outlined,
                        color: BoardgameColors.goldLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'P2P 포인트 합의 요청',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '상대방이 보낸 포인트 요청',
                          style: TextStyle(
                            color: BoardgameColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                  color: BoardgameColors.gold.withValues(alpha: 0.25),
                  height: 1),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BoardgameColors.walnutDarkest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: BoardgameColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: BoardgameColors.creamMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: widget.request.fromName,
                            style: const TextStyle(
                              color: BoardgameColors.creamWarmWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                          const TextSpan(text: ' 님의 송금 요청'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message:
                          '+${formatCommaNumber(widget.request.amount)} ${widget.currencyUnit}',
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '+${formatCompactNumber(widget.request.amount)}',
                              style: const TextStyle(
                                color: BoardgameColors.amberBright,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                            TextSpan(
                              text: ' ${widget.currencyUnit}',
                              style: const TextStyle(
                                color: BoardgameColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.request.memo != null &&
                        widget.request.memo!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(
                          color: BoardgameColors.gold.withValues(alpha: 0.2),
                          height: 1),
                      const SizedBox(height: 8),
                      Text(
                        '메모: ${widget.request.memo}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BoardgameColors.creamMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _responding ? null : () => _handle(false),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: BoardgameColors.crimsonText),
                      label: const Text(
                        '거절',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: BoardgameColors.walnutCard,
                        foregroundColor: BoardgameColors.crimsonText,
                        side: BorderSide(
                          color: BoardgameColors.gold.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _responding ? null : () => _handle(true),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        _responding ? '처리 중...' : '수락 (받기)',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
