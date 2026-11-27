import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../theme/boardgame_theme.dart';
import 'player_avatar.dart';

class BoardgameCalcTopPlayers extends StatelessWidget {
  const BoardgameCalcTopPlayers({
    super.key,
    required this.players,
    this.myId,
    this.mySessionId,
    required this.settings,
    required this.isHost,
    required this.viewMode,
    required this.onViewModeChange,
    required this.sortOption,
    required this.onSortOptionChange,
    required this.onTapPlayer,
  });

  final List<BoardgameCalcPlayer> players;
  final String? myId;
  final String? mySessionId;
  final BoardgameCalcSettings settings;
  final bool isHost;
  final TopPlayersViewMode viewMode;
  final ValueChanged<TopPlayersViewMode> onViewModeChange;
  final TopPlayersSortOption sortOption;
  final ValueChanged<TopPlayersSortOption> onSortOptionChange;
  final ValueChanged<BoardgameCalcPlayer> onTapPlayer;

  @override
  Widget build(BuildContext context) {
    final displayMode = settings.resolvedDisplayMode;
    final showCurrency =
        displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.currency;
    final isScoreEnabled =
        displayMode == ScoreDisplayMode.all ||
        (displayMode != ScoreDisplayMode.currency && settings.enableScore);
    final sorted = sortTopPlayers(players, sortOption);

    if (sorted.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: BoardgameColors.canvasSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BoardgameColors.canvasBorder.withValues(alpha: 0.8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline,
                size: 16, color: BoardgameColors.walnutPrimary),
            SizedBox(width: 6),
            Text(
              '현재 참여 중인 플레이어가 없습니다.',
              style: TextStyle(
                color: BoardgameColors.inkSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              const Text(
                '플레이어',
                style: TextStyle(
                  color: BoardgameColors.inkSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: BoardgameColors.canvasBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: BoardgameColors.canvasBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${sorted.length}명',
                  style: const TextStyle(
                    color: BoardgameColors.inkSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              _SortDropdownButton(
                sortOption: sortOption,
                isScoreEnabled: isScoreEnabled,
                onChanged: onSortOptionChange,
              ),
              const SizedBox(width: 6),
              _ViewModeToggle(
                viewMode: viewMode,
                onChanged: onViewModeChange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (viewMode == TopPlayersViewMode.list)
          Column(
            children: sorted.map((p) {
              final isMe =
                  p.matchesIdentity(myId: myId, mySessionId: mySessionId);
              final theme = getPlayerTheme(p.avatarColor);
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isMe ? null : () => onTapPlayer(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.cardBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        BoardgameCalcAvatar(
                          nickname: p.nickname,
                          avatarUrl: p.avatarUrl,
                          avatarColor: p.avatarColor,
                          size: 32,
                          isOnline: p.isOnline,
                          showOnlineDot: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.nickname,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: BoardgameColors.inkPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 5),
                                _SmallTag(
                                  label: '나',
                                  bg: const Color(0x262563EB),
                                  border: const Color(0x663B82F6),
                                  textColor: const Color(0xFF1E40AF),
                                ),
                              ],
                              if (p.isHost) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 14,
                                  color: BoardgameColors.amberBright,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showCurrency)
                          Tooltip(
                            message:
                                '${formatCommaNumber(p.points)} ${settings.currencyUnit}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.innerBoxBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.innerBoxBorder),
                              ),
                              child: Text(
                                '${formatCompactNumber(p.points)} ${settings.currencyUnit}',
                                style: const TextStyle(
                                  color: BoardgameColors.inkPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (isScoreEnabled) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message:
                                '${formatCommaNumber(p.score)} ${settings.scoreUnit}',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.innerBoxBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.innerBoxBorder),
                              ),
                              child: Text(
                                '${formatCompactNumber(p.score)} ${settings.scoreUnit}',
                                style: const TextStyle(
                                  color: BoardgameColors.amberScoreText,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
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
          SizedBox(
            height: isScoreEnabled && showCurrency ? 96 : 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final p = sorted[idx];
                final isMe =
                    p.matchesIdentity(myId: myId, mySessionId: mySessionId);
                final theme = getPlayerTheme(p.avatarColor);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isMe ? null : () => onTapPlayer(p),
                  child: Container(
                    width: 164,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            BoardgameCalcAvatar(
                              nickname: p.nickname,
                              avatarUrl: p.avatarUrl,
                              avatarColor: p.avatarColor,
                              size: 26,
                              isOnline: p.isOnline,
                              showOnlineDot: true,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p.nickname,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: BoardgameColors.inkPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (p.isHost)
                              const Icon(
                                Icons.workspace_premium,
                                size: 13,
                                color: BoardgameColors.amberBright,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (showCurrency)
                          Text(
                            '${formatCompactNumber(p.points)} ${settings.currencyUnit}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BoardgameColors.inkPrimary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        if (isScoreEnabled)
                          Text(
                            '🏆 ${formatCompactNumber(p.score)} ${settings.scoreUnit}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BoardgameColors.amberScoreText,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
  });

  final String label;
  final Color bg;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _SortDropdownButton extends StatelessWidget {
  const _SortDropdownButton({
    required this.sortOption,
    required this.isScoreEnabled,
    required this.onChanged,
  });

  final TopPlayersSortOption sortOption;
  final bool isScoreEnabled;
  final ValueChanged<TopPlayersSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = TopPlayersSortOption.values.where((opt) {
      if (!isScoreEnabled &&
          (opt == TopPlayersSortOption.scoreDesc ||
              opt == TopPlayersSortOption.scoreAsc)) {
        return false;
      }
      return true;
    }).toList();

    return PopupMenuButton<TopPlayersSortOption>(
      initialValue: sortOption,
      tooltip: '프로필 정렬 옵션 선택',
      color: BoardgameColors.walnutCard,
      onSelected: onChanged,
      itemBuilder: (context) => options.map((opt) {
        final selected = opt == sortOption;
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
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sortOption != TopPlayersSortOption.defaultOrder
              ? BoardgameColors.gold.withValues(alpha: 0.25)
              : BoardgameColors.canvasSurfaceAlt,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: sortOption != TopPlayersSortOption.defaultOrder
                ? BoardgameColors.walnutPrimary
                : BoardgameColors.canvasBorder.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert,
                size: 13, color: BoardgameColors.inkSecondary),
            const SizedBox(width: 4),
            Text(
              sortOption.shortLabel,
              style: const TextStyle(
                color: BoardgameColors.inkSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 13, color: BoardgameColors.inkSecondary),
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  final TopPlayersViewMode viewMode;
  final ValueChanged<TopPlayersViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: BoardgameColors.walnutCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: BoardgameColors.inkSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(
            icon: Icons.grid_view_rounded,
            active: viewMode == TopPlayersViewMode.card,
            tooltip: '카드형',
            onTap: () => onChanged(TopPlayersViewMode.card),
          ),
          _toggleBtn(
            icon: Icons.view_list_rounded,
            active: viewMode == TopPlayersViewMode.list,
            tooltip: '리스트형',
            onTap: () => onChanged(TopPlayersViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: active ? BoardgameColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 14,
            color: active
                ? BoardgameColors.walnutDarkest
                : BoardgameColors.creamMuted,
          ),
        ),
      ),
    );
  }
}
