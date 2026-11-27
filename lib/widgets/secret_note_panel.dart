import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/boardgame_models.dart';
import '../theme/boardgame_theme.dart';
import 'player_avatar.dart';

class BoardgameCalcSecretNote extends StatefulWidget {
  const BoardgameCalcSecretNote({
    super.key,
    required this.secretNote,
    required this.players,
    required this.myId,
    this.mySessionId,
    required this.isHost,
    required this.onStartSecretNote,
    required this.onUpdateSecretNote,
    required this.onLockSecretNote,
    required this.onRevealSecretNote,
    required this.onResetSecretNote,
  });

  final BoardgameCalcSecretNoteState? secretNote;
  final List<BoardgameCalcPlayer> players;
  final String myId;
  final String? mySessionId;
  final bool isHost;
  final void Function({int? timeLimit, String? title, bool? autoReveal})
      onStartSecretNote;
  final void Function(String content, {bool? isFolded}) onUpdateSecretNote;
  final VoidCallback onLockSecretNote;
  final VoidCallback onRevealSecretNote;
  final void Function({int? timeLimit, String? title, bool? autoReveal})
      onResetSecretNote;

  @override
  State<BoardgameCalcSecretNote> createState() =>
      _BoardgameCalcSecretNoteState();
}

class _BoardgameCalcSecretNoteState extends State<BoardgameCalcSecretNote> {
  final _noteCtrl = TextEditingController();
  final _startTitleCtrl = TextEditingController(text: '비밀노트');
  bool _isMyScreenCovered = false;
  bool _isSaved = false;
  bool _showStartConfig = false;
  int _startTimeLimit = 60;
  bool _startAutoReveal = true;
  final Set<String> _openedNoteIds = {};
  int? _remainingSeconds;
  Timer? _countdownTimer;
  Timer? _savedTimer;

  BoardgameCalcSecretNoteEntry? get _myEntry {
    final notes = widget.secretNote?.notes;
    if (notes == null) return null;
    if (notes.containsKey(widget.myId)) return notes[widget.myId];
    for (final entry in notes.values) {
      if (widget.mySessionId != null &&
          entry.sessionId == widget.mySessionId) {
        return entry;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _syncFromProps();
    _setupTimer();
  }

  @override
  void didUpdateWidget(covariant BoardgameCalcSecretNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secretNote?.round != widget.secretNote?.round ||
        oldWidget.myId != widget.myId) {
      _syncFromProps();
    }
    if (oldWidget.secretNote?.isRevealed != widget.secretNote?.isRevealed &&
        widget.secretNote?.isRevealed != true) {
      _openedNoteIds.clear();
    }
    if (oldWidget.secretNote?.endsAt != widget.secretNote?.endsAt ||
        oldWidget.secretNote?.isLocked != widget.secretNote?.isLocked ||
        oldWidget.secretNote?.isActive != widget.secretNote?.isActive) {
      _setupTimer();
    }
  }

  void _syncFromProps() {
    final my = _myEntry;
    if (my != null) {
      if (_noteCtrl.text != my.content) {
        _noteCtrl.text = my.content;
      }
      _isMyScreenCovered = my.isFolded;
    } else {
      _noteCtrl.clear();
      _isMyScreenCovered = false;
    }
    if (widget.secretNote?.isRevealed != true) {
      _openedNoteIds.clear();
    }
  }

  void _setupTimer() {
    _countdownTimer?.cancel();
    final sn = widget.secretNote;
    if (sn == null || !sn.isActive || sn.isLocked || sn.endsAt == null) {
      _remainingSeconds = null;
      return;
    }
    void tick() {
      final diff = ((sn.endsAt! - DateTime.now().millisecondsSinceEpoch) / 1000)
          .ceil();
      final clamped = diff < 0 ? 0 : diff;
      if (mounted && _remainingSeconds != clamped) {
        setState(() => _remainingSeconds = clamped);
      }
    }

    tick();
    _countdownTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _savedTimer?.cancel();
    _noteCtrl.dispose();
    _startTitleCtrl.dispose();
    super.dispose();
  }

  void _saveMyNote({bool foldAfterSave = false}) {
    if (widget.secretNote?.isLocked == true) return;
    final nextFold = foldAfterSave ? true : _isMyScreenCovered;
    widget.onUpdateSecretNote(_noteCtrl.text, isFolded: nextFold);
    setState(() {
      _isSaved = true;
      if (foldAfterSave) _isMyScreenCovered = true;
    });
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sn = widget.secretNote;
    final isStarted = sn?.isActive ?? false;
    final isLocked = sn?.isLocked ?? false;
    final isRevealed = sn?.isRevealed ?? false;
    final round = sn?.round ?? 1;
    final notesMap = sn?.notes ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            BoardgameColors.walnutElevated,
            BoardgameColors.walnutSurface,
            BoardgameColors.walnutPanel,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4A2E1D), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 헤더
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A2E1D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: BoardgameColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: Color(0xFFFCD34D), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sn?.title ?? '비밀노트',
                            style: const TextStyle(
                              color: Color(0xFFFEF3C7),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A2E1D),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: BoardgameColors.amberBright
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              'Round $round',
                              style: const TextStyle(
                                color: Color(0xFFFCD34D),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !isStarted
                            ? '⏱ 시작 대기 중'
                            : isRevealed
                                ? '📖 오픈 완료 (노트 열람 가능)'
                                : isLocked
                                    ? '✋ 손떼 완료 (수정 마감)'
                                    : '✏️ 작성 진행 중 (수정 가능)',
                        style: TextStyle(
                          color: !isStarted
                              ? BoardgameColors.creamSubtle
                              : isRevealed
                                  ? BoardgameColors.amberBright
                                  : isLocked
                                      ? BoardgameColors.crimsonText
                                      : const Color(0xFF34D399),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_remainingSeconds != null && !isLocked && !isRevealed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _remainingSeconds! <= 10
                            ? BoardgameColors.crimsonBg
                            : BoardgameColors.walnutSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _remainingSeconds! <= 10
                              ? BoardgameColors.crimsonBright
                              : BoardgameColors.amberBright
                                  .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '⏱ ${_remainingSeconds! ~/ 60}:${(_remainingSeconds! % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _remainingSeconds! <= 10
                              ? BoardgameColors.crimsonText
                              : const Color(0xFFFCD34D),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (widget.isHost) ...[
                    if (!isStarted)
                      ElevatedButton.icon(
                        onPressed: () => setState(
                            () => _showStartConfig = !_showStartConfig),
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: const Text('비밀노트 시작',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    else ...[
                      if (!isLocked)
                        ElevatedButton.icon(
                          onPressed: widget.onLockSecretNote,
                          icon: const Icon(Icons.pan_tool_outlined, size: 14),
                          label: const Text('✋ 손떼',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (!isRevealed)
                        ElevatedButton.icon(
                          onPressed: widget.onRevealSecretNote,
                          icon:
                              const Icon(Icons.menu_book_outlined, size: 14),
                          label: const Text('📖 오픈',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onResetSecretNote(),
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('새 라운드',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 11.5)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: BoardgameColors.walnutSoft,
                          foregroundColor: const Color(0xFFFDE68A),
                          side: BorderSide(
                            color: BoardgameColors.amberBright
                                .withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (isRevealed) ...[
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _openedNoteIds.addAll(widget.players.map((p) => p.id));
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: BoardgameColors.walnutSoft,
                        foregroundColor: const Color(0xFFFDE68A),
                        side: BorderSide(
                          color: BoardgameColors.amberBright
                              .withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('전체 펼치기',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                    OutlinedButton(
                      onPressed: () => setState(() => _openedNoteIds.clear()),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: BoardgameColors.walnutSurface,
                        foregroundColor: BoardgameColors.creamSubtle,
                        side: BorderSide(
                          color: BoardgameColors.walnutMutedBorder
                              .withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('전체 덮기',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. 방장 라운드 시작 옵션 패널
          if (_showStartConfig && widget.isHost && !isStarted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF341B0F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BoardgameColors.amberBright.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ 새 비밀노트 라운드 옵션 설정',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _startTitleCtrl,
                    maxLength: 40,
                    style: const TextStyle(
                      color: BoardgameColors.creamText,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      labelText: '주제 / 제시어 (선택)',
                      labelStyle: const TextStyle(
                          color: BoardgameColors.creamMuted, fontSize: 11),
                      filled: true,
                      fillColor: BoardgameColors.walnutCard,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: BoardgameColors.gold.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '제한 시간 (종료 시 자동 손떼)',
                    style: TextStyle(
                      color: BoardgameColors.creamMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [30, 60, 90, 120, 0].map((t) {
                      final active = _startTimeLimit == t;
                      return InkWell(
                        onTap: () => setState(() => _startTimeLimit = t),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? BoardgameColors.amberBright
                                : Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active
                                  ? BoardgameColors.amberBright
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            t == 0 ? '무제한' : '$t초',
                            style: TextStyle(
                              color: active
                                  ? Colors.black
                                  : BoardgameColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            '제한 시간 만료 시 자동으로 전체 오픈 허용',
                            style: TextStyle(
                              color: BoardgameColors.creamText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          value: _startAutoReveal,
                          onChanged: (v) =>
                              setState(() => _startAutoReveal = v ?? true),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onStartSecretNote(
                            title: _startTitleCtrl.text.trim().isNotEmpty
                                ? _startTitleCtrl.text.trim()
                                : '비밀노트',
                            timeLimit: _startTimeLimit,
                            autoReveal: _startAutoReveal,
                          );
                          setState(() => _showStartConfig = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('라운드 시작 🚀',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 3. 내 비밀노트 작성 영역
          if (isStarted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xE6381E11),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BoardgameColors.amberBright.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '✍️ 내 비밀노트 (${_noteCtrl.text.length}/500자)',
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final next = !_isMyScreenCovered;
                          setState(() => _isMyScreenCovered = next);
                          if (!isLocked) {
                            widget.onUpdateSecretNote(_noteCtrl.text,
                                isFolded: next);
                          }
                        },
                        icon: Icon(
                          _isMyScreenCovered
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 14,
                        ),
                        label: Text(
                          _isMyScreenCovered ? '펼쳐보기' : '화면 가리기 (덮음 🔒)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _isMyScreenCovered
                              ? BoardgameColors.walnutCard
                              : const Color(0xFF1E293B),
                          foregroundColor: _isMyScreenCovered
                              ? const Color(0xFFFCD34D)
                              : BoardgameColors.creamText,
                          side: BorderSide(
                            color: BoardgameColors.amberBright
                                .withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isMyScreenCovered)
                    InkWell(
                      onTap: () => setState(() => _isMyScreenCovered = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 22, horizontal: 16),
                        decoration: BoxDecoration(
                          color: BoardgameColors.walnutCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: BoardgameColors.amberBright
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '🔒 노트가 덮여 있습니다 (비공개 보호 중)',
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "클릭하거나 상단 '펼쳐보기'를 누르면 내용을 확인하고 수정할 수 있습니다.",
                              style: TextStyle(
                                color: BoardgameColors.creamSubtle,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _noteCtrl,
                      maxLength: 500,
                      maxLines: 3,
                      enabled: !isLocked,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: isLocked
                            ? '방장이 손을 떼어 더 이상 노트를 수정할 수 없습니다.'
                            : '비밀노트에 적을 단어나 문장을 자유롭게 적어주세요...',
                        hintStyle: const TextStyle(
                            color: Color(0x66FEF3C7), fontSize: 12),
                        filled: true,
                        fillColor: BoardgameColors.walnutCard,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BoardgameColors.amberBright
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: BoardgameColors.amberBright),
                        ),
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_isSaved)
                            const Text(
                              '✅ 저장됨',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => _saveMyNote(foldAfterSave: false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A2E1D),
                              foregroundColor: const Color(0xFFFDE68A),
                              side: BorderSide(
                                color: BoardgameColors.amberBright
                                    .withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('임시 저장',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 11.5)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _saveMyNote(foldAfterSave: true),
                            icon: const Icon(Icons.lock_outline, size: 14),
                            label: const Text('작성 완료 후 덮기',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 11.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],

          // 4. 참가자 비밀노트 보드
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '🗂️ 참가자 비밀노트 보드 (${widget.players.length}명)',
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                isRevealed
                    ? '💡 카드를 클릭하여 노트를 펼쳐볼 수 있습니다'
                    : '🔒 방장이 오픈하면 카드를 클릭해 열람할 수 있습니다',
                style: const TextStyle(
                  color: BoardgameColors.creamSubtle,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 600
                  ? 3
                  : (constraints.maxWidth >= 380 ? 2 : 1);
              const spacing = 10.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: widget.players.map((p) {
                  final entry = notesMap[p.id] ??
                      notesMap.values
                          .cast<BoardgameCalcSecretNoteEntry?>()
                          .firstWhere((n) => n?.sessionId == p.sessionId,
                              orElse: () => null);
                  final hasContent = entry?.hasContent == true ||
                      (entry?.content.trim().isNotEmpty ?? false);
                  final isOpened = isRevealed && _openedNoteIds.contains(p.id);
                  final pTheme = getPlayerTheme(p.avatarColor);

                  return SizedBox(
                    width: cardWidth,
                    child: InkWell(
                      onTap: isRevealed
                          ? () {
                              setState(() {
                                if (_openedNoteIds.contains(p.id)) {
                                  _openedNoteIds.remove(p.id);
                                } else {
                                  _openedNoteIds.add(p.id);
                                }
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOpened
                              ? const Color(0xFFFBF7EE)
                              : pTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOpened
                                ? BoardgameColors.gold
                                : pTheme.cardBorder,
                            width: 1.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: !hasContent
                                        ? Colors.black.withValues(alpha: 0.08)
                                        : isOpened
                                            ? BoardgameColors.emeraldBright
                                                .withValues(alpha: 0.2)
                                            : BoardgameColors.amberBright
                                                .withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    !hasContent
                                        ? '대기 ✏️'
                                        : isRevealed
                                            ? (isOpened ? '열림 📖' : '클릭 오픈')
                                            : '덮음 🔒',
                                    style: const TextStyle(
                                      color: BoardgameColors.inkPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (!isRevealed)
                              Text(
                                hasContent
                                    ? '🔒 비밀노트 덮음 완료 (비공개)'
                                    : '작성 중...',
                                style: const TextStyle(
                                  color: BoardgameColors.inkMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              )
                            else if (isOpened)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: BoardgameColors.amberBright
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Text(
                                  (entry?.content.trim().isNotEmpty ?? false)
                                      ? entry!.content
                                      : '(작성된 내용이 없습니다)',
                                  style: const TextStyle(
                                    color: BoardgameColors.inkPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: BoardgameColors.amberBright
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: BoardgameColors.amberBright
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Text(
                                  '📖 덮여 있는 노트 (클릭하여 열람)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: BoardgameColors.inkSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
