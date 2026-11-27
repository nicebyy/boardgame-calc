import 'package:material_ui/material_ui.dart';

import '../../models/boardgame_models.dart';
import '../../theme/boardgame_theme.dart';
import '../confirm_modal.dart';

Future<void> showBoardgameSettingsModal(
  BuildContext context, {
  required BoardgameCalcSettings settings,
  required ValueChanged<BoardgameCalcSettings> onUpdateSettings,
  required void Function(int? customAmount) onResetPoints,
  required void Function(int? customScore) onResetScores,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SettingsDialog(
      initialSettings: settings,
      onUpdateSettings: onUpdateSettings,
      onResetPoints: onResetPoints,
      onResetScores: onResetScores,
    ),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.initialSettings,
    required this.onUpdateSettings,
    required this.onResetPoints,
    required this.onResetScores,
  });

  final BoardgameCalcSettings initialSettings;
  final ValueChanged<BoardgameCalcSettings> onUpdateSettings;
  final void Function(int? customAmount) onResetPoints;
  final void Function(int? customScore) onResetScores;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late BoardgameCalcSettings _settings;
  late String _currencyPreset;
  late TextEditingController _customCurrencyCtrl;
  late TextEditingController _newUnitCtrl;
  late TextEditingController _newUnitCountCtrl;
  late TextEditingController _newScoreUnitCtrl;
  late TextEditingController _newScoreUnitCountCtrl;
  late TextEditingController _minBidCtrl;
  late TextEditingController _extendSecCtrl;
  late TextEditingController _secretLimitCtrl;
  late TextEditingController _resetPointsCtrl;
  late TextEditingController _resetScoreCtrl;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _currencyPreset = _settings.currencyUnit == '원'
        ? '원'
        : (_settings.currencyUnit == 'p' || _settings.currencyUnit == '포인트')
            ? 'p'
            : 'custom';
    _customCurrencyCtrl = TextEditingController(
        text: _currencyPreset == 'custom' ? _settings.currencyUnit : '');
    _newUnitCtrl = TextEditingController();
    _newUnitCountCtrl = TextEditingController();
    _newScoreUnitCtrl = TextEditingController();
    _newScoreUnitCountCtrl = TextEditingController();
    _minBidCtrl = TextEditingController(text: '${_settings.auctionMinBid}');
    _extendSecCtrl =
        TextEditingController(text: '${_settings.auctionExtendSeconds}');
    _secretLimitCtrl =
        TextEditingController(text: '${_settings.secretNoteTimeLimit}');
    _resetPointsCtrl =
        TextEditingController(text: '${_settings.initialPoints}');
    _resetScoreCtrl = TextEditingController(text: '${_settings.initialScore}');
  }

  @override
  void dispose() {
    _customCurrencyCtrl.dispose();
    _newUnitCtrl.dispose();
    _newUnitCountCtrl.dispose();
    _newScoreUnitCtrl.dispose();
    _newScoreUnitCountCtrl.dispose();
    _minBidCtrl.dispose();
    _extendSecCtrl.dispose();
    _secretLimitCtrl.dispose();
    _resetPointsCtrl.dispose();
    _resetScoreCtrl.dispose();
    super.dispose();
  }

  void _apply(BoardgameCalcSettings next) {
    setState(() => _settings = next);
    widget.onUpdateSettings(next);
  }

  void _addCurrencyDenom(int value, int? maxCount) {
    if (value == 0) return;
    final cleanMax = (maxCount != null && maxCount > 0) ? maxCount : null;
    final list = [
      ..._settings.effectiveCurrencyDenoms.where((d) => d.value != value),
      BoardgameCalcDenomination(
          value: value, maxCount: cleanMax, remainingCount: cleanMax),
    ]..sort((a, b) => a.value.abs().compareTo(b.value.abs()));
    _apply(_settings.copyWith(
      currencyDenominations: list,
      quickAdjustUnits: list.map((d) => d.value).toList(),
    ));
  }

  void _removeCurrencyDenom(int value) {
    final list =
        _settings.effectiveCurrencyDenoms.where((d) => d.value != value).toList();
    _apply(_settings.copyWith(
      currencyDenominations: list,
      quickAdjustUnits: list.map((d) => d.value).toList(),
    ));
  }

  void _addScoreDenom(int value, int? maxCount) {
    if (value == 0) return;
    final cleanMax = (maxCount != null && maxCount > 0) ? maxCount : null;
    final list = [
      ..._settings.scoreDenominations.where((d) => d.value != value),
      BoardgameCalcDenomination(
          value: value, maxCount: cleanMax, remainingCount: cleanMax),
    ]..sort((a, b) => a.value.abs().compareTo(b.value.abs()));
    _apply(_settings.copyWith(scoreDenominations: list));
  }

  void _removeScoreDenom(int value) {
    final list =
        _settings.scoreDenominations.where((d) => d.value != value).toList();
    _apply(_settings.copyWith(scoreDenominations: list));
  }

  Future<void> _confirmResetPoints() async {
    final amount = int.tryParse(_resetPointsCtrl.text.trim()) ??
        _settings.initialPoints;
    final ok = await showBoardgameConfirmDialog(
      context,
      title: '전원 포인트 일괄 초기화',
      message:
          '모든 플레이어의 포인트를 ${formatCommaNumber(amount)}${_settings.currencyUnit}로 초기화하시겠습니까?',
      subMessage: '⚠️ 실행 시 현재 방에 참여 중인 모든 플레이어의 포인트가 즉시 재설정됩니다.',
      confirmText: '초기화 실행',
      type: ConfirmDialogType.danger,
    );
    if (ok == true) {
      widget.onResetPoints(amount);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmResetScores() async {
    final score =
        int.tryParse(_resetScoreCtrl.text.trim()) ?? _settings.initialScore;
    final ok = await showBoardgameConfirmDialog(
      context,
      title: '전원 점수(VP) 일괄 초기화',
      message: '모든 플레이어의 점수를 ${formatCommaNumber(score)}점으로 초기화하시겠습니까?',
      subMessage: '⚠️ 실행 시 현재 방에 참여 중인 모든 플레이어의 점수가 즉시 재설정됩니다.',
      confirmText: '초기화 실행',
      type: ConfirmDialogType.danger,
    );
    if (ok == true) {
      widget.onResetScores(score);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = _settings.resolvedDisplayMode;
    final isScoreEnabled =
        _settings.enableScore && displayMode != ScoreDisplayMode.currency;
    final currencyDenoms = _settings.effectiveCurrencyDenoms;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
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
                    child: const Icon(Icons.tune_rounded,
                        color: BoardgameColors.goldLight, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '방장 인게임 설정',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '화폐·권한·빠른 증감 단위 관리',
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
              Divider(
                  color: BoardgameColors.gold.withValues(alpha: 0.25),
                  height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 화면 표기 항목 설정
                      const Text(
                        '화면 표기 항목 설정',
                        style: TextStyle(
                          color: BoardgameColors.creamText,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SelectBox(
                              title: '화폐 & 점수',
                              subtitle: '둘 다 표기',
                              selected: displayMode == ScoreDisplayMode.all,
                              onTap: () => _apply(_settings.copyWith(
                                scoreDisplayMode: ScoreDisplayMode.all,
                                enableScore: true,
                                scoreUnit: '점',
                              )),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _SelectBox(
                              title: '화폐(포인트)만',
                              subtitle: '점수 숨김',
                              selected:
                                  displayMode == ScoreDisplayMode.currency,
                              onTap: () => _apply(_settings.copyWith(
                                scoreDisplayMode: ScoreDisplayMode.currency,
                                enableScore: false,
                                scoreUnit: '점',
                              )),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _SelectBox(
                              title: '점수(승점)만',
                              subtitle: '화폐 숨김',
                              selected: displayMode == ScoreDisplayMode.score,
                              onTap: () => _apply(_settings.copyWith(
                                scoreDisplayMode: ScoreDisplayMode.score,
                                enableScore: true,
                                scoreUnit: '점',
                              )),
                            ),
                          ),
                        ],
                      ),

                      // 2. 점수 빠른 증감 단위 & 개수 한도
                      if (isScoreEnabled) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BoardgameColors.amberBright
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '🏆 점수 빠른 증감 단위 & 개수 한도',
                                    style: TextStyle(
                                      color: Color(0xFFFCD34D),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '점 (기본 고정)',
                                    style: TextStyle(
                                      color: Color(0xFFFCD34D),
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (_settings.scoreDenominations.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _settings.scoreDenominations
                                      .map((d) => _DenomChip(
                                            label:
                                                '${d.value > 0 ? '+${d.value}' : d.value}점',
                                            countLabel: d.maxCount != null
                                                ? '${d.maxCount}개'
                                                : '무제한',
                                            isNegative: d.value < 0,
                                            onRemove: () =>
                                                _removeScoreDenom(d.value),
                                          ))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    '빠른 예시:',
                                    style: TextStyle(
                                      color: Color(0xCCFBBF24),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  for (final v in [1, 5, 10])
                                    InkWell(
                                      onTap: () => _addScoreDenom(v, null),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: BoardgameColors.amberBright
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: BoardgameColors.amberBright
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          '+$v점 (무제한)',
                                          style: const TextStyle(
                                            color: Color(0xFFFCD34D),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _DenomInputRow(
                                valueCtrl: _newScoreUnitCtrl,
                                countCtrl: _newScoreUnitCountCtrl,
                                valueHint: '단위 (예: 5 또는 -1)',
                                onAdd: () {
                                  final v = int.tryParse(
                                      _newScoreUnitCtrl.text.trim());
                                  if (v == null || v == 0) return;
                                  final c = int.tryParse(
                                      _newScoreUnitCountCtrl.text.trim());
                                  _addScoreDenom(v, c != null && c > 0 ? c : null);
                                  _newScoreUnitCtrl.clear();
                                  _newScoreUnitCountCtrl.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 3. 화폐 단위 & 빠른 증감 단위
                      if (displayMode != ScoreDisplayMode.score) ...[
                        const SizedBox(height: 14),
                        const Text(
                          '🪙 화폐 단위 설정',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectBox(
                                title: '원 (￦)',
                                selected: _currencyPreset == '원',
                                onTap: () {
                                  setState(() => _currencyPreset = '원');
                                  _apply(_settings.copyWith(currencyUnit: '원'));
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SelectBox(
                                title: '포인트 (p)',
                                selected: _currencyPreset == 'p',
                                onTap: () {
                                  setState(() => _currencyPreset = 'p');
                                  _apply(_settings.copyWith(currencyUnit: 'p'));
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SelectBox(
                                title: '직접 입력',
                                selected: _currencyPreset == 'custom',
                                onTap: () {
                                  setState(() => _currencyPreset = 'custom');
                                  final c = _customCurrencyCtrl.text.trim();
                                  if (c.isNotEmpty) {
                                    _apply(_settings.copyWith(currencyUnit: c));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_currencyPreset == 'custom') ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customCurrencyCtrl,
                            maxLength: 6,
                            style: const TextStyle(
                              color: BoardgameColors.creamText,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                            onChanged: (v) {
                              final t = v.trim();
                              if (t.isNotEmpty) {
                                _apply(_settings.copyWith(currencyUnit: t));
                              }
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '단위 입력 (예: 골드, 냥 등)',
                              hintStyle:
                                  const TextStyle(color: Color(0xFF8A684B)),
                              filled: true,
                              fillColor: BoardgameColors.walnutDeep,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: BoardgameColors.gold
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BoardgameColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '⚡ 화폐 빠른 증감 단위 & 개수 한도',
                                    style: TextStyle(
                                      color: BoardgameColors.creamText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    currencyDenoms.isEmpty
                                        ? '미설정'
                                        : '${currencyDenoms.length}개 설정됨',
                                    style: const TextStyle(
                                      color: BoardgameColors.creamMuted,
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (currencyDenoms.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: currencyDenoms
                                      .map((d) => _DenomChip(
                                            label:
                                                '${d.value > 0 ? '+${formatCommaNumber(d.value)}' : formatCommaNumber(d.value)}${_settings.currencyUnit}',
                                            countLabel: d.maxCount != null
                                                ? '${d.maxCount}개'
                                                : '무제한',
                                            isNegative: d.value < 0,
                                            onRemove: () =>
                                                _removeCurrencyDenom(d.value),
                                          ))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    '빠른 예시:',
                                    style: TextStyle(
                                      color: BoardgameColors.gold,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  for (final v in [100, 500, 1000, 5000])
                                    InkWell(
                                      onTap: () => _addCurrencyDenom(v, null),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: BoardgameColors.gold
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: BoardgameColors.gold
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          '+${formatCommaNumber(v)}${_settings.currencyUnit}',
                                          style: const TextStyle(
                                            color: BoardgameColors.goldLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _DenomInputRow(
                                valueCtrl: _newUnitCtrl,
                                countCtrl: _newUnitCountCtrl,
                                valueHint: '단위 직접 추가 (예: 100)',
                                onAdd: () {
                                  final v =
                                      int.tryParse(_newUnitCtrl.text.trim());
                                  if (v == null || v == 0) return;
                                  final c = int.tryParse(
                                      _newUnitCountCtrl.text.trim());
                                  _addCurrencyDenom(
                                      v, c != null && c > 0 ? c : null);
                                  _newUnitCtrl.clear();
                                  _newUnitCountCtrl.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 4. 실시간 경매 설정
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '실시간 경매 기능 활성화',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        activeTrackColor: BoardgameColors.amberBright,
                        value: _settings.enableAuction,
                        onChanged: (v) =>
                            _apply(_settings.copyWith(enableAuction: v)),
                      ),
                      if (_settings.enableAuction) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BoardgameColors.walnutDarkest
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BoardgameColors.amberBright
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔨 경매 최소 배팅금액',
                                style: TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _minBidCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: BoardgameColors.creamText,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                                onChanged: (v) {
                                  final n = int.tryParse(v.trim());
                                  if (n != null && n > 0) {
                                    _apply(_settings.copyWith(auctionMinBid: n));
                                  }
                                },
                                decoration: _walnutInputDeco(
                                    '최소 배팅금액 (기본: 100)'),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '⏱️ 실시간 경매 제한 시간',
                                style: TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [15, 30, 60, 0].map((t) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: _SelectBox(
                                        title: t == 0 ? '무제한' : '$t초',
                                        selected:
                                            _settings.auctionTimeLimit == t,
                                        onTap: () => _apply(_settings.copyWith(
                                            auctionTimeLimit: t)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '🔄 경매 참여 시 추가되는 최대 시간 (초)',
                                style: TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [0, 10, 15, 20, 30].map((s) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: _SelectBox(
                                        title: s == 0 ? '0초' : '$s초',
                                        selected:
                                            _settings.auctionExtendSeconds == s,
                                        onTap: () {
                                          _extendSecCtrl.text = '$s';
                                          _apply(_settings.copyWith(
                                              auctionExtendSeconds: s));
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 5. 비밀노트 설정
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutDarkest
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BoardgameColors.emeraldBright
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📝 비밀노트 제한 시간 (초과 시 자동 손떼)',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [30, 60, 90, 120, 0].map((t) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _SelectBox(
                                      title: t == 0 ? '무제한' : '$t초',
                                      selected:
                                          _settings.secretNoteTimeLimit == t,
                                      onTap: () {
                                        _secretLimitCtrl.text = '$t';
                                        _apply(_settings.copyWith(
                                            secretNoteTimeLimit: t));
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                '시간 만료 시 자동 전체 오픈',
                                style: TextStyle(
                                  color: BoardgameColors.creamText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              activeTrackColor: BoardgameColors.emeraldBright,
                              value: _settings.secretNoteAutoReveal,
                              onChanged: (v) => _apply(
                                  _settings.copyWith(secretNoteAutoReveal: v)),
                            ),
                          ],
                        ),
                      ),

                      // 6. 권한 설정
                      const SizedBox(height: 14),
                      const Text(
                        '🛡️ 권한 관련 설정',
                        style: TextStyle(
                          color: BoardgameColors.creamText,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _SelectBox(
                              title: '화폐: 모든 플레이어',
                              subtitle: '누구나 자유 증감',
                              selected:
                                  _settings.permissionMode == PermissionMode.all,
                              onTap: () => _apply(_settings.copyWith(
                                  permissionMode: PermissionMode.all)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _SelectBox(
                              title: '화폐: 방장 전용',
                              subtitle: '방장만 조율 가능',
                              selected: _settings.permissionMode ==
                                  PermissionMode.hostOnly,
                              onTap: () => _apply(_settings.copyWith(
                                  permissionMode: PermissionMode.hostOnly)),
                            ),
                          ),
                        ],
                      ),
                      if (isScoreEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SelectBox(
                                title: '점수: 모든 플레이어',
                                subtitle: '누구나 점수 증감',
                                selected:
                                    _settings.resolvedScorePermissionMode ==
                                        PermissionMode.all,
                                onTap: () => _apply(_settings.copyWith(
                                    scorePermissionMode: PermissionMode.all)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _SelectBox(
                                title: '점수: 방장 전용',
                                subtitle: '방장만 점수 조율',
                                selected:
                                    _settings.resolvedScorePermissionMode ==
                                        PermissionMode.hostOnly,
                                onTap: () => _apply(_settings.copyWith(
                                    scorePermissionMode:
                                        PermissionMode.hostOnly)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'P2P 플레이어 간 직접 송금 허용',
                          style: TextStyle(
                            color: BoardgameColors.creamText,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        activeTrackColor: BoardgameColors.amberBright,
                        value: _settings.allowP2P,
                        onChanged: (v) =>
                            _apply(_settings.copyWith(allowP2P: v)),
                      ),

                      // 7. 전원 초기화
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutDarkest
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BoardgameColors.crimsonBright
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔄 전원 포인트 일괄 초기화',
                              style: TextStyle(
                                color: BoardgameColors.crimsonText,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _resetPointsCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: BoardgameColors.crimsonText,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                    decoration: _walnutInputDeco('초기화 금액'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _confirmResetPoints,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        BoardgameColors.crimsonBright,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '전원 리셋',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isScoreEnabled) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BoardgameColors.walnutDarkest
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: BoardgameColors.amberBright
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔄 전원 점수(VP) 일괄 초기화',
                                style: TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _resetScoreCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Color(0xFFFDE68A),
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                      decoration: _walnutInputDeco('초기화 점수'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _confirmResetScores,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          BoardgameColors.amberBright,
                                      foregroundColor:
                                          BoardgameColors.walnutDarkest,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '점수 리셋',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12),
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
              ),
              const SizedBox(height: 8),
              Divider(
                  color: BoardgameColors.gold.withValues(alpha: 0.25),
                  height: 1),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle,
                      size: 7, color: BoardgameColors.emeraldBright),
                  SizedBox(width: 6),
                  Text(
                    '모든 설정은 클릭 시 실시간으로 즉시 저장됩니다',
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: BoardgameColors.walnutCard,
                    foregroundColor: BoardgameColors.creamText,
                    side: BorderSide(
                        color: BoardgameColors.gold.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _walnutInputDeco(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A684B), fontSize: 11.5),
      filled: true,
      fillColor: BoardgameColors.walnutDeep,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: BoardgameColors.gold.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BoardgameColors.amberBright),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? BoardgameColors.amberBright.withValues(alpha: 0.25)
              : BoardgameColors.walnutCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? BoardgameColors.amberBright
                : BoardgameColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFFCD34D)
                    : BoardgameColors.creamMuted,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (selected
                          ? const Color(0xFFFCD34D)
                          : BoardgameColors.creamMuted)
                      .withValues(alpha: 0.75),
                  fontSize: 9.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DenomChip extends StatelessWidget {
  const _DenomChip({
    required this.label,
    required this.countLabel,
    required this.isNegative,
    required this.onRemove,
  });

  final String label;
  final String countLabel;
  final bool isNegative;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNegative
            ? const Color(0xFF401212)
            : BoardgameColors.walnutSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNegative
              ? BoardgameColors.crimsonBright.withValues(alpha: 0.45)
              : BoardgameColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isNegative
                  ? BoardgameColors.crimsonText
                  : BoardgameColors.creamText,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              countLabel,
              style: const TextStyle(
                color: BoardgameColors.creamMuted,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 13, color: BoardgameColors.crimsonText),
          ),
        ],
      ),
    );
  }
}

class _DenomInputRow extends StatelessWidget {
  const _DenomInputRow({
    required this.valueCtrl,
    required this.countCtrl,
    required this.valueHint,
    required this.onAdd,
  });

  final TextEditingController valueCtrl;
  final TextEditingController countCtrl;
  final String valueHint;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: valueCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: BoardgameColors.creamText,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: valueHint,
              hintStyle:
                  const TextStyle(color: Color(0xFF8A684B), fontSize: 11),
              filled: true,
              fillColor: BoardgameColors.walnutDeep,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: BoardgameColors.gold.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: countCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: BoardgameColors.creamText,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: '개수(무제한)',
              hintStyle:
                  const TextStyle(color: Color(0xFF8A684B), fontSize: 11),
              filled: true,
              fillColor: BoardgameColors.walnutDeep,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: BoardgameColors.gold.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('추가',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: BoardgameColors.gold,
            foregroundColor: BoardgameColors.walnutDarkest,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
