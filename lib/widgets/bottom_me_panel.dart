import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../services/boardgame_audio.dart';
import '../theme/boardgame_theme.dart';
import 'player_avatar.dart';

class BoardgameCalcBottomMe extends StatelessWidget {
  const BoardgameCalcBottomMe({
    super.key,
    required this.me,
    required this.settings,
    required this.onAdjustMyPoints,
    required this.onAdjustMyScore,
    required this.onOpenCustomAdjust,
    required this.onEditProfile,
  });

  final BoardgameCalcPlayer me;
  final BoardgameCalcSettings settings;
  final void Function(int delta, {int? unitValue}) onAdjustMyPoints;
  final void Function(int delta, {int? unitValue}) onAdjustMyScore;
  final VoidCallback onOpenCustomAdjust;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final canAdjustPoints =
        settings.permissionMode == PermissionMode.all || me.isHost;
    final canAdjustScore =
        settings.resolvedScorePermissionMode == PermissionMode.all || me.isHost;
    final currencyDenoms = settings.effectiveCurrencyDenoms;
    final scoreDenoms = settings.scoreDenominations;
    final displayMode = settings.resolvedDisplayMode;
    final showCurrency = displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.currency;
    final showScore = displayMode == ScoreDisplayMode.all ||
        displayMode == ScoreDisplayMode.score;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BoardgameColors.lightWoodTop,
            BoardgameColors.lightWoodMid,
            BoardgameColors.lightWoodEdge,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BoardgameColors.lightWoodBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3E2310).withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 0. 내 프로필 헤더
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: BoardgameColors.lightWoodDivider,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Tooltip(
                  message: '프로필 사진을 클릭하여 이름 및 색상 변경',
                  child: InkWell(
                    onTap: () {
                      BoardgameAudio.playModal();
                      onEditProfile();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        BoardgameCalcAvatar(
                          nickname: me.nickname,
                          avatarUrl: me.avatarUrl,
                          avatarColor: me.avatarColor,
                          size: 42,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: BoardgameColors.walnutHeader,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 10,
                              color: BoardgameColors.creamText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      BoardgameAudio.playModal();
                      onEditProfile();
                    },
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          me.nickname,
                          style: const TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x262563EB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0x4D3B82F6),
                            ),
                          ),
                          child: const Text(
                            '나',
                            style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (me.isHost)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BoardgameColors.amberBright
                                  .withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0x73B45309),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  size: 11,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '방장',
                                  style: TextStyle(
                                    color: Color(0xFF6E3A06),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 1. 내 잔액 & 내 점수 바
          Column(
            children: [
              if (showCurrency)
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: BoardgameColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: BoardgameColors.walnutPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '내 잔액:',
                      style: TextStyle(
                        color: BoardgameColors.inkMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Tooltip(
                        message:
                            '${formatCommaNumber(me.points)} ${settings.currencyUnit}',
                        child: Text(
                          '${formatCompactNumber(me.points)} ${settings.currencyUnit}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BoardgameColors.inkPrimary,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    if (canAdjustPoints && currencyDenoms.isEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          BoardgameAudio.playModal();
                          onOpenCustomAdjust();
                        },
                        icon: const Icon(Icons.monetization_on_outlined,
                            size: 14),
                        label: const Text(
                          '직접 금액 입력',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: BoardgameColors.lightWoodChipBg,
                          foregroundColor: BoardgameColors.inkSecondary,
                          side: BorderSide(
                            color: BoardgameColors.lightWoodBorder
                                .withValues(alpha: 0.8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              if (showCurrency && showScore) const SizedBox(height: 8),
              if (showScore)
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: BoardgameColors.amberBright
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: BoardgameColors.amberScoreText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '내 점수:',
                      style: TextStyle(
                        color: BoardgameColors.inkMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Tooltip(
                        message:
                            '${formatCommaNumber(me.score)} ${settings.scoreUnit}',
                        child: Text(
                          '${formatCompactNumber(me.score)} ${settings.scoreUnit}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BoardgameColors.amberScoreText,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    if (canAdjustScore && scoreDenoms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC201007),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: BoardgameColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MiniStepperButton(
                              icon: Icons.remove,
                              bg: BoardgameColors.crimsonBright
                                  .withValues(alpha: 0.2),
                              fg: BoardgameColors.crimsonText,
                              onTap: () => onAdjustMyScore(-1),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: BoardgameColors.creamText,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            _MiniStepperButton(
                              icon: Icons.add,
                              bg: BoardgameColors.amberBright
                                  .withValues(alpha: 0.2),
                              fg: BoardgameColors.amberBadgeText,
                              onTap: () => onAdjustMyScore(1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // 2. 빠른 화폐 증감 단위 스테퍼
          if (canAdjustPoints && showCurrency && currencyDenoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: BoardgameColors.lightWoodDivider, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '내 포인트 빠른 증감',
                  style: TextStyle(
                    color: BoardgameColors.inkMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                InkWell(
                  onTap: () {
                    BoardgameAudio.playModal();
                    onOpenCustomAdjust();
                  },
                  child: const Text(
                    '직접 금액 입력',
                    style: TextStyle(
                      color: BoardgameColors.walnutPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currencyDenoms
                  .map(
                    (d) => _DenomStepperChip(
                      denom: d,
                      unitLabel: '',
                      isScore: false,
                      onMinus: () =>
                          onAdjustMyPoints(-d.value, unitValue: d.value),
                      onPlus: () =>
                          onAdjustMyPoints(d.value, unitValue: d.value),
                    ),
                  )
                  .toList(),
            ),
          ],

          // 3. 빠른 점수 증감 단위 스테퍼
          if (canAdjustScore && showScore && scoreDenoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: BoardgameColors.lightWoodDivider, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '내 점수 빠른 증감',
                  style: TextStyle(
                    color: BoardgameColors.amberScoreText,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '단위: ${settings.scoreUnit}',
                  style: TextStyle(
                    color: BoardgameColors.walnutPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: scoreDenoms
                  .map(
                    (d) => _DenomStepperChip(
                      denom: d,
                      unitLabel: settings.scoreUnit,
                      isScore: true,
                      onMinus: () =>
                          onAdjustMyScore(-d.value, unitValue: d.value),
                      onPlus: () =>
                          onAdjustMyScore(d.value, unitValue: d.value),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStepperButton extends StatelessWidget {
  const _MiniStepperButton({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: fg),
      ),
    );
  }
}

class _DenomStepperChip extends StatelessWidget {
  const _DenomStepperChip({
    required this.denom,
    required this.unitLabel,
    required this.isScore,
    required this.onMinus,
    required this.onPlus,
  });

  final BoardgameCalcDenomination denom;
  final String unitLabel;
  final bool isScore;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final isNegative = denom.value < 0;
    final isDepleted = denom.isDepleted;
    final plusBg = isScore
        ? BoardgameColors.amberBadgeBg
        : BoardgameColors.emeraldBg;
    final plusFg = isScore
        ? BoardgameColors.amberBadgeText
        : BoardgameColors.emeraldText;
    final plusBorder = isScore
        ? const Color(0x66A16207)
        : BoardgameColors.emeraldBorder.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCC201007),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BoardgameColors.gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionBox(
            icon: isNegative ? Icons.add : Icons.remove,
            bg: isNegative ? plusBg : BoardgameColors.crimsonBg,
            fg: isNegative ? plusFg : BoardgameColors.crimsonText,
            border: isNegative
                ? plusBorder
                : BoardgameColors.crimsonBorder.withValues(alpha: 0.45),
            onTap: onMinus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${formatCompactNumber(denom.value.abs())}$unitLabel',
                  style: const TextStyle(
                    color: BoardgameColors.creamText,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                ),
                if (denom.maxCount != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isDepleted
                          ? BoardgameColors.crimsonBright.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${denom.remainingCount ?? 0}/${denom.maxCount}',
                      style: TextStyle(
                        color: isDepleted
                            ? BoardgameColors.crimsonText
                            : BoardgameColors.emeraldText,
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _ActionBox(
            icon: isNegative ? Icons.remove : Icons.add,
            bg: isDepleted
                ? const Color(0xFF1E293B)
                : (isNegative ? BoardgameColors.crimsonBg : plusBg),
            fg: isDepleted
                ? const Color(0xFF64748B)
                : (isNegative ? BoardgameColors.crimsonText : plusFg),
            border: isDepleted
                ? const Color(0xFF334155)
                : (isNegative
                    ? BoardgameColors.crimsonBorder.withValues(alpha: 0.45)
                    : plusBorder),
            onTap: isDepleted ? null : onPlus,
          ),
        ],
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 15, color: fg),
        ),
      ),
    );
  }
}
