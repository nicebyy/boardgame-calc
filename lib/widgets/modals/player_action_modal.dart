import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';
import '../player_avatar.dart';

Future<void> showBoardgamePlayerActionModal(
  BuildContext context, {
  required BoardgameCalcPlayer player,
  required BoardgameCalcSettings settings,
  required bool isHost,
  required String? myId,
  required String? mySessionId,
  required VoidCallback onSelectTransfer,
  required VoidCallback onSelectAdjust,
  VoidCallback? onSelectRename,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _PlayerActionDialog(
      player: player,
      settings: settings,
      isHost: isHost,
      myId: myId,
      mySessionId: mySessionId,
      onSelectTransfer: onSelectTransfer,
      onSelectAdjust: onSelectAdjust,
      onSelectRename: onSelectRename,
    ),
  );
}

class _PlayerActionDialog extends StatelessWidget {
  const _PlayerActionDialog({
    required this.player,
    required this.settings,
    required this.isHost,
    required this.myId,
    required this.mySessionId,
    required this.onSelectTransfer,
    required this.onSelectAdjust,
    this.onSelectRename,
  });

  final BoardgameCalcPlayer player;
  final BoardgameCalcSettings settings;
  final bool isHost;
  final String? myId;
  final String? mySessionId;
  final VoidCallback onSelectTransfer;
  final VoidCallback onSelectAdjust;
  final VoidCallback? onSelectRename;

  @override
  Widget build(BuildContext context) {
    final displayMode = settings.resolvedDisplayMode;
    final showCurrency = displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.currency;
    final showScore = displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.score;
    final isMe = player.matchesIdentity(myId: myId, mySessionId: mySessionId);
    final canTransfer = !isMe && settings.allowP2P && showCurrency;
    final canAdjust = isHost || isMe;
    final canRename = onSelectRename != null && (isHost || isMe);

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
                BoardgameColors.walnutCard,
                BoardgameColors.walnutDarkest,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: BoardgameColors.goldBright.withValues(alpha: 0.65),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoardgameCalcAvatar(
                    nickname: player.nickname,
                    avatarUrl: player.avatarUrl,
                    avatarColor: player.avatarColor,
                    size: 48,
                    isOnline: player.isOnline,
                    showOnlineDot: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: BoardgameColors.creamText,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            if (isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x332563EB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0x803B82F6)),
                                ),
                                child: const Text(
                                  '나',
                                  style: TextStyle(
                                    color: Color(0xFF93C5FD),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (player.isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BoardgameColors.amberBright
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: BoardgameColors.amberBright
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  '👑 방장',
                                  style: TextStyle(
                                    color: Color(0xFFFCD34D),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (showCurrency)
                              Text(
                                '${formatCompactNumber(player.points)} ${settings.currencyUnit}',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            if (showScore)
                              Text(
                                '🏆 ${formatCompactNumber(player.score)} ${settings.scoreUnit}',
                                style: const TextStyle(
                                  color: BoardgameColors.amberBright,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                          ],
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
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
              const SizedBox(height: 14),
              Text(
                isMe ? '내 계정 작업을 선택하세요' : '수행할 작업을 선택하세요',
                style: const TextStyle(
                  color: BoardgameColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              if (!isMe) ...[
                _ActionTile(
                  icon: Icons.send_rounded,
                  title: '송금하기',
                  subtitle: canTransfer
                      ? '${player.nickname}님에게 ${settings.currencyUnit} 송금'
                      : 'P2P 송금 비활성화됨',
                  enabled: canTransfer,
                  bg: const Color(0xFF331A0E),
                  iconBg: const Color(0xFF5A2F18),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelectTransfer();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (canAdjust) ...[
                _ActionTile(
                  icon: Icons.tune_rounded,
                  title: isMe ? '내 잔액 / 점수 조율' : '포인트 / 점수 조율',
                  subtitle: isMe
                      ? '내 잔액 및 점수를 직접 수정합니다'
                      : '${player.nickname}님의 포인트/점수를 즉시 조율합니다',
                  enabled: true,
                  bg: const Color(0xFF2A170D),
                  iconBg: const Color(0xFF4A2612),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelectAdjust();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (canRename)
                _ActionTile(
                  icon: Icons.edit_rounded,
                  title: isMe ? '내 프로필 / 색상 편집' : '닉네임 변경 (방장)',
                  subtitle: isMe
                      ? '닉네임 및 플레이어 테마 색상 변경'
                      : '${player.nickname}님의 닉네임 변경',
                  enabled: true,
                  bg: const Color(0xFF26140B),
                  iconBg: const Color(0xFF3F2112),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelectRename!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.bg,
    required this.iconBg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color bg;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BoardgameColors.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BoardgameColors.goldBright.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFFDE68A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: BoardgameColors.creamText,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: BoardgameColors.goldBright.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
