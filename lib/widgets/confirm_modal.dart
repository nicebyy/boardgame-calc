import 'package:material_ui/material_ui.dart';

import '../theme/boardgame_theme.dart';

enum ConfirmDialogType { danger, warning, info }

Future<bool?> showBoardgameConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? subMessage,
  String confirmText = '확인',
  String cancelText = '취소',
  ConfirmDialogType type = ConfirmDialogType.warning,
  bool hideCancel = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => BoardgameConfirmDialog(
      title: title,
      message: message,
      subMessage: subMessage,
      confirmText: confirmText,
      cancelText: cancelText,
      type: type,
      hideCancel: hideCancel,
    ),
  );
}

class BoardgameConfirmDialog extends StatelessWidget {
  const BoardgameConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.subMessage,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.type = ConfirmDialogType.warning,
    this.hideCancel = false,
  });

  final String title;
  final String message;
  final String? subMessage;
  final String confirmText;
  final String cancelText;
  final ConfirmDialogType type;
  final bool hideCancel;

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (type) {
      ConfirmDialogType.danger => BoardgameColors.crimsonBright,
      ConfirmDialogType.warning => BoardgameColors.amberBright,
      ConfirmDialogType.info => BoardgameColors.goldBright,
    };

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      type == ConfirmDialogType.danger
                          ? Icons.warning_amber_rounded
                          : type == ConfirmDialogType.warning
                              ? Icons.help_outline_rounded
                              : Icons.info_outline_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: BoardgameColors.creamText,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BoardgameColors.walnutDarkest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: BoardgameColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: BoardgameColors.creamWarmWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    if (subMessage != null && subMessage!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subMessage!,
                        style: const TextStyle(
                          color: BoardgameColors.creamMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (!hideCancel) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: BoardgameColors.walnutCard,
                          foregroundColor: BoardgameColors.creamText,
                          side: BorderSide(
                            color: BoardgameColors.gold.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: type == ConfirmDialogType.danger
                            ? BoardgameColors.crimsonBright
                            : BoardgameColors.goldBright,
                        foregroundColor: type == ConfirmDialogType.danger
                            ? Colors.white
                            : BoardgameColors.walnutDarkest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
