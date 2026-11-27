import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';

Future<void> showBoardgameLogFeedModal(
  BuildContext context, {
  required List<BoardgameCalcLog> logs,
  required String currencyUnit,
  required String scoreUnit,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _LogFeedDialog(
      logs: logs,
      currencyUnit: currencyUnit,
      scoreUnit: scoreUnit,
    ),
  );
}

class _LogFeedDialog extends StatefulWidget {
  const _LogFeedDialog({
    required this.logs,
    required this.currencyUnit,
    required this.scoreUnit,
  });

  final List<BoardgameCalcLog> logs;
  final String currencyUnit;
  final String scoreUnit;

  @override
  State<_LogFeedDialog> createState() => _LogFeedDialogState();
}

class _LogFeedDialogState extends State<_LogFeedDialog> {
  LogFilterCategory _selectedCategory = LogFilterCategory.all;
  int _visibleLimit = 100;

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  ({String label, Color bg, Color fg, Color border, IconData icon}) _badgeFor(
      BoardgameCalcLog log) {
    switch (log.type) {
      case LogType.transfer:
        return (
          label: '송금',
          bg: BoardgameColors.gold.withValues(alpha: 0.2),
          fg: BoardgameColors.goldLight,
          border: BoardgameColors.gold.withValues(alpha: 0.45),
          icon: Icons.swap_horiz_rounded,
        );
      case LogType.transferRequest:
        return (
          label: '요청',
          bg: BoardgameColors.gold.withValues(alpha: 0.2),
          fg: BoardgameColors.goldLight,
          border: BoardgameColors.gold.withValues(alpha: 0.45),
          icon: Icons.swap_horiz_rounded,
        );
      case LogType.transferRejected:
        return (
          label: '거절',
          bg: BoardgameColors.crimsonBright.withValues(alpha: 0.2),
          fg: BoardgameColors.crimsonText,
          border: BoardgameColors.crimsonBright.withValues(alpha: 0.45),
          icon: Icons.close,
        );
      case LogType.adjust:
        final positive = (log.amount ?? 0) >= 0;
        return (
          label: positive ? '지급' : '차감',
          bg: (positive
                  ? BoardgameColors.emeraldBright
                  : BoardgameColors.crimsonBright)
              .withValues(alpha: 0.2),
          fg: positive
              ? BoardgameColors.emeraldText
              : BoardgameColors.crimsonText,
          border: (positive
                  ? BoardgameColors.emeraldBright
                  : BoardgameColors.crimsonBright)
              .withValues(alpha: 0.45),
          icon: positive
              ? Icons.add_circle_outline
              : Icons.remove_circle_outline,
        );
      case LogType.auctionStart:
      case LogType.auctionBid:
      case LogType.auctionWin:
      case LogType.auctionReset:
        return (
          label: '경매',
          bg: BoardgameColors.amberBright.withValues(alpha: 0.2),
          fg: const Color(0xFFFCD34D),
          border: BoardgameColors.amberBright.withValues(alpha: 0.45),
          icon: Icons.gavel_rounded,
        );
      case LogType.bettingBet:
      case LogType.bettingWin:
      case LogType.bettingReset:
        return (
          label: '배팅',
          bg: const Color(0x33D97706),
          fg: const Color(0xFFFCD34D),
          border: const Color(0x66D97706),
          icon: Icons.monetization_on_outlined,
        );
      case LogType.scoreAdjust:
        return (
          label: '점수',
          bg: BoardgameColors.amberBright.withValues(alpha: 0.2),
          fg: const Color(0xFFFCD34D),
          border: BoardgameColors.amberBright.withValues(alpha: 0.45),
          icon: Icons.emoji_events_outlined,
        );
      case LogType.dice:
        return (
          label: '주사위',
          bg: const Color(0x336366F1),
          fg: const Color(0xFFA5B4FC),
          border: const Color(0x666366F1),
          icon: Icons.casino_outlined,
        );
      case LogType.secretNote:
        return (
          label: '비밀노트',
          bg: const Color(0x33A855F7),
          fg: const Color(0xFFD8B4FE),
          border: const Color(0x66A855F7),
          icon: Icons.description_outlined,
        );
      default:
        return (
          label: '설정',
          bg: Colors.white.withValues(alpha: 0.08),
          fg: BoardgameColors.creamMuted,
          border: Colors.white.withValues(alpha: 0.2),
          icon: Icons.settings_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGameLogs = widget.logs
        .where((l) => l.type != LogType.join && l.type != LogType.leave)
        .toList();
    final filtered =
        allGameLogs.where((l) => l.matchesCategory(_selectedCategory)).toList();
    final displayed = filtered.take(_visibleLimit).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                    child: const Icon(Icons.history_rounded,
                        color: BoardgameColors.goldLight, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '실시간 게임 로그 (${allGameLogs.length}건)',
                          style: const TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                          ),
                        ),
                        const Text(
                          '화폐, 승점, 경매, 배팅, 주사위, 비밀노트 이력',
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
              const SizedBox(height: 10),
              // 카테고리 필터 드롭다운 / 칩
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: LogFilterCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final cat = LogFilterCategory.values[idx];
                    final count = allGameLogs
                        .where((l) => l.matchesCategory(cat))
                        .length;
                    final selected = cat == _selectedCategory;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? BoardgameColors.gold
                              : BoardgameColors.walnutCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? BoardgameColors.goldLight
                                : BoardgameColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat.label,
                              style: TextStyle(
                                color: selected
                                    ? BoardgameColors.walnutDarkest
                                    : BoardgameColors.creamText,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: selected
                                    ? BoardgameColors.walnutDarkest
                                        .withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: selected
                                      ? BoardgameColors.walnutDarkest
                                      : BoardgameColors.goldLight,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Text(
                          _selectedCategory == LogFilterCategory.all
                              ? '아직 기록된 게임 로그가 없습니다.'
                              : '${_selectedCategory.label} 로그가 없습니다.',
                          style: const TextStyle(
                            color: BoardgameColors.creamSubtle,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: displayed.length +
                            (filtered.length > displayed.length ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          if (idx >= displayed.length) {
                            return Center(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _visibleLimit += 50),
                                child: Text(
                                  '더 보기 (${filtered.length - displayed.length}건 남음)',
                                  style: const TextStyle(
                                    color: BoardgameColors.goldLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          }
                          final log = displayed[idx];
                          final badge = _badgeFor(log);
                          return Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: BoardgameColors.walnutDarkest
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BoardgameColors.gold
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badge.bg,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badge.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(badge.icon,
                                              size: 11, color: badge.fg),
                                          const SizedBox(width: 4),
                                          Text(
                                            badge.label,
                                            style: TextStyle(
                                              color: badge.fg,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatTime(log.timestamp),
                                      style: const TextStyle(
                                        color: BoardgameColors.creamSubtle,
                                        fontFamily: 'monospace',
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log.description,
                                  style: const TextStyle(
                                    color: BoardgameColors.creamText,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
