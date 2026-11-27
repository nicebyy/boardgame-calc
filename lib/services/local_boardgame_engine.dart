import 'dart:async';
import 'dart:math';

import '../models/boardgame_models.dart';
import '../theme/boardgame_theme.dart';

class BoardgameEngineException implements Exception {
  BoardgameEngineException(this.message, {this.isConflict = false});

  final String message;
  final bool isConflict;

  @override
  String toString() => message;
}

class ActionResult {
  const ActionResult({
    required this.room,
    this.log,
    this.player,
    this.diceState,
    this.transferRequest,
    this.accepted,
    this.fromPlayer,
    this.toPlayer,
    this.noteEntry,
  });

  final BoardgameCalcRoom room;
  final BoardgameCalcLog? log;
  final BoardgameCalcPlayer? player;
  final BoardgameCalcDiceState? diceState;
  final BoardgameCalcTransferRequest? transferRequest;
  final bool? accepted;
  final BoardgameCalcPlayer? fromPlayer;
  final BoardgameCalcPlayer? toPlayer;
  final BoardgameCalcSecretNoteEntry? noteEntry;
}

/// 원본 NestJS `BoardgameCalcService` 의 비즈니스 룰을 100% 동일하게 구현한 순수 Dart 로컬/오프라인 엔진.
class LocalBoardgameEngine {
  LocalBoardgameEngine({Random? random}) : _rng = random ?? Random();

  final Random _rng;
  final Map<String, BoardgameCalcRoom> _rooms = {};
  final Map<String, BoardgameCalcTransferRequest> _pendingTransfers = {};
  final Map<String, Timer> _secretNoteTimers = {};

  static final RegExp _hexColorRegex = RegExp(r'^#[0-9a-fA-F]{6}$');

  void dispose() {
    for (final timer in _secretNoteTimers.values) {
      timer.cancel();
    }
    _secretNoteTimers.clear();
  }

  void loadRoomsFromJson(List<dynamic> roomsJson) {
    _rooms.clear();
    for (final raw in roomsJson) {
      if (raw is Map) {
        final room = BoardgameCalcRoom.fromJson(Map<String, dynamic>.from(raw));
        if (room.roomCode.isNotEmpty) {
          _rooms[room.roomCode] = room;
        }
      }
    }
  }

  List<Map<String, dynamic>> exportRoomsToJson() {
    return _rooms.values.map((r) => r.toJson()).toList();
  }

  List<BoardgameCalcTransferRequest> getPendingTransfersForPlayer(
    String roomCode,
    String playerId,
    String? sessionId,
  ) {
    final code = roomCode.trim().toUpperCase();
    return _pendingTransfers.values
        .where((req) =>
            req.roomCode == code &&
            (req.toId == playerId ||
                (sessionId != null &&
                    sessionId.isNotEmpty &&
                    req.toSessionId == sessionId)))
        .toList();
  }

  BoardgameCalcRoom? getRoom(String roomCode) =>
      _rooms[roomCode.trim().toUpperCase()];

  BoardgameCalcRoom _getRoomOrThrow(String? roomCode) {
    final code = roomCode?.trim().toUpperCase() ?? '';
    if (code.isEmpty) {
      throw BoardgameEngineException('방 코드가 필요합니다.');
    }
    final room = _rooms[code];
    if (room == null) {
      throw BoardgameEngineException('방을 찾을 수 없습니다.');
    }
    return room;
  }

  bool _isRoomHost(BoardgameCalcRoom room, BoardgameCalcPlayer? player) {
    if (player == null) return false;
    return player.isHost ||
        room.hostId == player.id ||
        (player.sessionId.isNotEmpty && room.hostSessionId == player.sessionId);
  }

  int _getReservedBid(BoardgameCalcRoom room, BoardgameCalcPlayer player) {
    if (!room.auction.isActive || room.auction.highestBid <= 0) return 0;
    final isHighest = room.auction.highestBidderId == player.id ||
        (player.sessionId.isNotEmpty &&
            (room.auction.highestBidderId == player.sessionId ||
                room.auction.highestBidderSessionId == player.sessionId));
    return isHighest ? room.auction.highestBid : 0;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[_rng.nextInt(chars.length)];
    }
    return _rooms.containsKey(code) ? _generateRoomCode() : code;
  }

  List<BoardgameCalcDenomination> _normalizeDenominations(
    List<BoardgameCalcDenomination> items,
    List<BoardgameCalcDenomination>? prevDenoms,
  ) {
    final map = <int, BoardgameCalcDenomination>{};
    for (final item in items) {
      final val = item.value;
      if (val != 0 && val.abs() <= BoardgameCalcConstants.maxSafeAmount) {
        final maxCount =
            (item.maxCount != null && item.maxCount! > 0) ? item.maxCount : null;
        BoardgameCalcDenomination? prev;
        if (prevDenoms != null) {
          for (final d in prevDenoms) {
            if (d.value == val) {
              prev = d;
              break;
            }
          }
        }
        int? remainingCount;
        if (maxCount == null) {
          remainingCount = null;
        } else if (item.remainingCount != null) {
          remainingCount = item.remainingCount!.clamp(0, maxCount);
        } else if (prev != null && prev.remainingCount != null) {
          remainingCount = prev.remainingCount!.clamp(0, maxCount);
        } else {
          remainingCount = maxCount;
        }
        map[val] = BoardgameCalcDenomination(
          value: val,
          maxCount: maxCount,
          remainingCount: remainingCount,
        );
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) {
        final cmp = a.value.abs().compareTo(b.value.abs());
        return cmp != 0 ? cmp : a.value.compareTo(b.value);
      });
    return sorted;
  }

  (BoardgameCalcRoom, BoardgameCalcLog) _addLog(
    BoardgameCalcRoom room, {
    required LogType type,
    required String actorName,
    String? targetName,
    int? amount,
    required String description,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newLog = BoardgameCalcLog(
      id: 'log-$now-${_rng.nextInt(9999).toString().padLeft(4, '0')}',
      timestamp: now,
      type: type,
      actorName: actorName,
      targetName: targetName,
      amount: amount,
      description: description,
    );
    final updatedLogs = [newLog, ...room.logs];
    final trimmed =
        updatedLogs.length > 100 ? updatedLogs.sublist(0, 100) : updatedLogs;
    final updatedRoom = room.copyWith(logs: trimmed, updatedAt: now);
    _rooms[room.roomCode] = updatedRoom;
    return (updatedRoom, newLog);
  }

  ActionResult createRoom({
    required String nickname,
    String? avatarColor,
    String? avatarUrl,
    String? title,
    BoardgameCalcSettings? settings,
    String? sessionId,
    String? socketId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final roomCode = _generateRoomCode();
    final cleanNick = nickname.trim().isNotEmpty ? nickname.trim() : '방장';
    final sessId =
        (sessionId != null && sessionId.isNotEmpty) ? sessionId : 'sess-$now';
    final sockId =
        (socketId != null && socketId.isNotEmpty) ? socketId : 'local-$now';

    final inputSettings = settings ?? const BoardgameCalcSettings();
    final initialDenoms = inputSettings.currencyDenominations.isNotEmpty
        ? _normalizeDenominations(inputSettings.currencyDenominations, null)
        : inputSettings.quickAdjustUnits
            .map((v) => BoardgameCalcDenomination(value: v))
            .toList();

    final resolvedSettings = inputSettings.copyWith(
      currencyUnit: inputSettings.currencyUnit.trim().isNotEmpty
          ? inputSettings.currencyUnit.trim()
          : BoardgameCalcConstants.defaultCurrencyUnit,
      scoreUnit: '점',
      currencyDenominations: initialDenoms,
      quickAdjustUnits: initialDenoms.map((d) => d.value).toList(),
      scoreDenominations:
          _normalizeDenominations(inputSettings.scoreDenominations, null),
    );

    final hostPlayer = BoardgameCalcPlayer(
      id: sockId,
      sessionId: sessId,
      nickname: cleanNick,
      avatarColor: avatarColor ?? playerThemePalette.first.hex,
      avatarUrl: avatarUrl,
      points: resolvedSettings.initialPoints,
      score: resolvedSettings.initialScore,
      isHost: true,
      isOnline: true,
      joinedAt: now,
    );

    final room = BoardgameCalcRoom(
      roomCode: roomCode,
      title: (title != null && title.trim().isNotEmpty)
          ? title.trim()
          : '$cleanNick님의 보드게임 계산기',
      hostId: sockId,
      hostSessionId: sessId,
      settings: resolvedSettings,
      players: [hostPlayer],
      auction: const BoardgameCalcAuction(),
      betting: const BoardgameCalcBetting(),
      centerTool: CenterToolType.empty,
      dice: const BoardgameCalcDiceState(count: 2, sides: 6, values: [3, 4]),
      secretNote: BoardgameCalcSecretNoteState(
        timeLimit: resolvedSettings.secretNoteTimeLimit,
        autoReveal: resolvedSettings.secretNoteAutoReveal,
      ),
      logs: const [],
      createdAt: now,
      updatedAt: now,
    );

    _rooms[roomCode] = room;
    return ActionResult(room: room, player: hostPlayer);
  }

  ActionResult joinRoom({
    required String roomCode,
    required String nickname,
    String? avatarColor,
    String? avatarUrl,
    String? sessionId,
    String? socketId,
  }) {
    final code = roomCode.trim().toUpperCase();
    final room = _rooms[code];
    if (room == null) {
      throw BoardgameEngineException("방 코드 '$code'에 해당하는 방을 찾을 수 없습니다.");
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanNick = nickname.trim().isNotEmpty ? nickname.trim() : '플레이어';
    final sessId = (sessionId != null && sessionId.isNotEmpty)
        ? sessionId
        : 'sess-$now-${_rng.nextInt(9999)}';
    final sockId = (socketId != null && socketId.isNotEmpty)
        ? socketId
        : 'local-$now-${_rng.nextInt(9999)}';

    final existingIdx = room.players.indexWhere((p) => p.sessionId == sessId);
    if (existingIdx >= 0) {
      var existing = room.players[existingIdx];
      if (cleanNick != existing.nickname) {
        final dup = room.players.any((p) =>
            p.sessionId != sessId &&
            p.nickname.trim().toLowerCase() == cleanNick.toLowerCase());
        if (dup) {
          throw BoardgameEngineException(
            "방에 이미 동일한 닉네임('$cleanNick')을 사용하는 플레이어가 있습니다. 다른 닉네임을 사용해주세요.",
          );
        }
      }
      existing = existing.copyWith(
        id: sockId,
        isOnline: true,
        nickname: cleanNick,
        isHost: existing.sessionId == room.hostSessionId || existing.isHost,
      );
      final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
      updatedPlayers[existingIdx] = existing;
      final updatedRoom = room.copyWith(
        players: updatedPlayers,
        hostId: existing.isHost ? sockId : room.hostId,
        updatedAt: now,
      );
      _rooms[code] = updatedRoom;
      return ActionResult(room: updatedRoom, player: existing);
    }

    final isDuplicate = room.players.any(
      (p) => p.nickname.trim().toLowerCase() == cleanNick.toLowerCase(),
    );
    if (isDuplicate) {
      throw BoardgameEngineException(
        "방에 이미 동일한 닉네임('$cleanNick')을 사용하는 플레이어가 있습니다. 다른 닉네임을 사용해주세요.",
      );
    }

    final usedColors =
        room.players.map((p) => p.avatarColor.trim().toLowerCase()).toSet();
    String chosenColor;
    if (avatarColor != null &&
        avatarColor.trim().isNotEmpty &&
        !usedColors.contains(avatarColor.trim().toLowerCase())) {
      chosenColor = avatarColor.trim();
    } else {
      chosenColor = playerThemePalette
              .map((e) => e.hex)
              .firstWhere((c) => !usedColors.contains(c.toLowerCase()),
                  orElse: () => playerThemePalette[
                          room.players.length % playerThemePalette.length]
                      .hex);
    }

    final player = BoardgameCalcPlayer(
      id: sockId,
      sessionId: sessId,
      nickname: cleanNick,
      avatarColor: chosenColor,
      avatarUrl: avatarUrl,
      points: room.settings.initialPoints,
      score: room.settings.initialScore,
      isHost: false,
      isOnline: true,
      joinedAt: now,
    );

    final updatedRoom = room.copyWith(
      players: [...room.players, player],
      updatedAt: now,
    );
    _rooms[code] = updatedRoom;
    return ActionResult(room: updatedRoom, player: player);
  }

  void deleteRoom(String roomCode, {required String actorId}) {
    final code = roomCode.trim().toUpperCase();
    final room = _rooms[code];
    if (room == null) return;
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (room.players.length > 1 && !_isRoomHost(room, actor)) {
      throw BoardgameEngineException('방장만 방을 삭제할 수 있습니다.');
    }
    _pendingTransfers.removeWhere((_, req) => req.roomCode == code);
    _secretNoteTimers.remove(code)?.cancel();
    _rooms.remove(code);
  }

  ActionResult adjustPoints({
    required String roomCode,
    required String actorId,
    required String targetPlayerId,
    required int delta,
    String? reason,
    int? unitValue,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final targetIdx = room.players.indexWhere(
        (p) => p.id == targetPlayerId || p.sessionId == targetPlayerId);
    if (targetIdx < 0) {
      throw BoardgameEngineException('대상 플레이어를 찾을 수 없습니다.');
    }
    final target = room.players[targetIdx];

    final isHost = _isRoomHost(room, actor);
    final isSelf = target.id == actor.id || target.sessionId == actor.sessionId;

    if (!isHost) {
      if (room.settings.permissionMode == PermissionMode.hostOnly) {
        throw BoardgameEngineException('방장만 포인트를 직접 수정할 수 있습니다.');
      }
      if (!isSelf) {
        throw BoardgameEngineException(
            '다른 플레이어의 포인트는 방장만 직접 조율할 수 있습니다. P2P 송금(합의 모달)을 이용해주세요.');
      }
    }

    if (delta == 0 || delta.abs() > BoardgameCalcConstants.maxSafeAmount) {
      throw BoardgameEngineException('유효한 변경 금액을 입력해주세요.');
    }

    var denoms =
        List<BoardgameCalcDenomination>.from(room.settings.currencyDenominations);
    if (denoms.isNotEmpty) {
      final targetUnitValue = unitValue ?? delta;
      var denomIdx = denoms.indexWhere((d) => d.value == targetUnitValue);
      if (denomIdx < 0) {
        denomIdx =
            denoms.indexWhere((d) => d.value.abs() == targetUnitValue.abs());
      }
      if (denomIdx >= 0) {
        final denom = denoms[denomIdx];
        if (denom.maxCount != null && denom.maxCount! > 0) {
          final isTaking =
              (denom.value > 0 && delta > 0) || (denom.value < 0 && delta < 0);
          final isReturning =
              (denom.value > 0 && delta < 0) || (denom.value < 0 && delta > 0);
          if (isTaking) {
            if ((denom.remainingCount ?? 0) <= 0) {
              final formatted =
                  denom.value > 0 ? '+${denom.value}' : '${denom.value}';
              throw BoardgameEngineException(
                  '$formatted${room.settings.currencyUnit} 단위 화폐가 모두 소진되었습니다. (남은 수량: 0개)');
            }
            denoms[denomIdx] = denom.copyWith(
              remainingCount: max(0, (denom.remainingCount ?? denom.maxCount!) - 1),
            );
          } else if (isReturning) {
            denoms[denomIdx] = denom.copyWith(
              remainingCount: min(denom.maxCount!, (denom.remainingCount ?? 0) + 1),
            );
          }
        }
      }
    }

    final updatedTarget = target.copyWith(points: target.points + delta);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[targetIdx] = updatedTarget;

    room = room.copyWith(
      players: updatedPlayers,
      settings: room.settings.copyWith(currencyDenominations: denoms),
    );

    final sign = delta > 0
        ? '+${formatCommaNumber(delta)}'
        : formatCommaNumber(delta);
    final reasonText =
        (reason != null && reason.isNotEmpty) ? ' ($reason)' : '';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.adjust,
      actorName: actor.nickname,
      targetName: updatedTarget.nickname,
      amount: delta,
      description:
          "'${actor.nickname}'님이 '${updatedTarget.nickname}'님의 포인트를 $sign${room.settings.currencyUnit} 변경했습니다 (현재: ${formatCommaNumber(updatedTarget.points)}${room.settings.currencyUnit})$reasonText",
    );
    return ActionResult(room: loggedRoom, log: log, player: updatedTarget);
  }

  ActionResult adjustScore({
    required String roomCode,
    required String actorId,
    required String targetPlayerId,
    required int delta,
    String? reason,
    int? unitValue,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final targetIdx = room.players.indexWhere(
        (p) => p.id == targetPlayerId || p.sessionId == targetPlayerId);
    if (targetIdx < 0) {
      throw BoardgameEngineException('대상 플레이어를 찾을 수 없습니다.');
    }
    final target = room.players[targetIdx];

    final isHost = _isRoomHost(room, actor);
    final isSelf = target.id == actor.id || target.sessionId == actor.sessionId;
    final scorePermission = room.settings.resolvedScorePermissionMode;

    if (!isHost) {
      if (scorePermission == PermissionMode.hostOnly) {
        throw BoardgameEngineException('방장만 점수를 직접 수정할 수 있습니다.');
      }
      if (!isSelf) {
        throw BoardgameEngineException('다른 플레이어의 점수는 방장만 직접 조율할 수 있습니다.');
      }
    }

    if (delta == 0 || delta.abs() > BoardgameCalcConstants.maxSafeAmount) {
      throw BoardgameEngineException('유효한 변경 점수를 입력해주세요.');
    }

    var denoms =
        List<BoardgameCalcDenomination>.from(room.settings.scoreDenominations);
    if (denoms.isNotEmpty) {
      final targetUnitValue = unitValue ?? delta;
      var denomIdx = denoms.indexWhere((d) => d.value == targetUnitValue);
      if (denomIdx < 0) {
        denomIdx =
            denoms.indexWhere((d) => d.value.abs() == targetUnitValue.abs());
      }
      if (denomIdx >= 0) {
        final denom = denoms[denomIdx];
        if (denom.maxCount != null && denom.maxCount! > 0) {
          final isTaking =
              (denom.value > 0 && delta > 0) || (denom.value < 0 && delta < 0);
          final isReturning =
              (denom.value > 0 && delta < 0) || (denom.value < 0 && delta > 0);
          if (isTaking) {
            if ((denom.remainingCount ?? 0) <= 0) {
              final formatted =
                  denom.value > 0 ? '+${denom.value}' : '${denom.value}';
              throw BoardgameEngineException(
                  '$formatted점 단위 점수 토큰이 모두 소진되었습니다. (남은 수량: 0개)');
            }
            denoms[denomIdx] = denom.copyWith(
              remainingCount: max(0, (denom.remainingCount ?? denom.maxCount!) - 1),
            );
          } else if (isReturning) {
            denoms[denomIdx] = denom.copyWith(
              remainingCount: min(denom.maxCount!, (denom.remainingCount ?? 0) + 1),
            );
          }
        }
      }
    }

    final updatedTarget = target.copyWith(score: target.score + delta);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[targetIdx] = updatedTarget;
    room = room.copyWith(
      players: updatedPlayers,
      settings: room.settings.copyWith(scoreDenominations: denoms),
    );

    final scoreUnit = room.settings.scoreUnit;
    final sign = delta > 0
        ? '+${formatCommaNumber(delta)}'
        : formatCommaNumber(delta);
    final reasonText =
        (reason != null && reason.isNotEmpty) ? ' ($reason)' : '';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.scoreAdjust,
      actorName: actor.nickname,
      targetName: updatedTarget.nickname,
      amount: delta,
      description:
          "'${actor.nickname}'님이 '${updatedTarget.nickname}'님의 점수를 $sign$scoreUnit 변경했습니다 (현재: ${formatCommaNumber(updatedTarget.score)}$scoreUnit)$reasonText",
    );
    return ActionResult(room: loggedRoom, log: log, player: updatedTarget);
  }

  ActionResult requestTransfer({
    required String roomCode,
    required String fromActorId,
    required String toPlayerId,
    required int amount,
    String? memo,
  }) {
    final room = _getRoomOrThrow(roomCode);
    if (!room.settings.allowP2P) {
      throw BoardgameEngineException('현재 방에서 플레이어 간 P2P 송금이 비활성화되어 있습니다.');
    }

    final fromPlayer = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == fromActorId || p?.sessionId == fromActorId,
          orElse: () => null,
        );
    if (fromPlayer == null) {
      throw BoardgameEngineException('송금자를 찾을 수 없습니다.');
    }

    final toPlayer = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == toPlayerId || p?.sessionId == toPlayerId,
          orElse: () => null,
        );
    if (toPlayer == null) {
      throw BoardgameEngineException('수신자를 찾을 수 없습니다.');
    }

    if (fromPlayer.id == toPlayer.id ||
        fromPlayer.sessionId == toPlayer.sessionId) {
      throw BoardgameEngineException('본인에게는 송금할 수 없습니다.');
    }

    if (amount <= 0 || amount > BoardgameCalcConstants.maxSafeAmount) {
      throw BoardgameEngineException('0보다 큰 유효한 금액을 입력해주세요.');
    }

    if (fromPlayer.points < amount) {
      throw BoardgameEngineException(
          '잔액이 부족합니다 (현재 잔액: ${formatCommaNumber(fromPlayer.points)}${room.settings.currencyUnit}).');
    }

    final reservedBid = _getReservedBid(room, fromPlayer);
    if (fromPlayer.points - amount < reservedBid) {
      throw BoardgameEngineException(
          '진행 중인 경매의 최고 입찰액(${formatCommaNumber(reservedBid)}${room.settings.currencyUnit})으로 묶인 잔액은 송금할 수 없습니다.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final requestId = 'req-$now-${_rng.nextInt(9999)}';
    final cleanMemo = memo?.trim();
    final req = BoardgameCalcTransferRequest(
      requestId: requestId,
      roomCode: room.roomCode,
      fromId: fromPlayer.id,
      fromSessionId: fromPlayer.sessionId,
      fromName: fromPlayer.nickname,
      toId: toPlayer.id,
      toSessionId: toPlayer.sessionId,
      toName: toPlayer.nickname,
      amount: amount,
      memo: (cleanMemo != null && cleanMemo.isNotEmpty) ? cleanMemo : null,
      createdAt: now,
    );
    _pendingTransfers[requestId] = req;

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.transferRequest,
      actorName: fromPlayer.nickname,
      targetName: toPlayer.nickname,
      amount: amount,
      description:
          "'${fromPlayer.nickname}'님이 '${toPlayer.nickname}'님에게 ${formatCommaNumber(amount)}${room.settings.currencyUnit} 송금 수락을 요청했습니다.${req.memo != null ? ' [메모: ${req.memo}]' : ''}",
    );

    return ActionResult(
      room: loggedRoom,
      log: log,
      transferRequest: req,
      fromPlayer: fromPlayer,
      toPlayer: toPlayer,
    );
  }

  ActionResult respondTransfer({
    required String roomCode,
    required String requestId,
    required String actorId,
    required bool accept,
  }) {
    final req = _pendingTransfers[requestId];
    if (req == null) {
      throw BoardgameEngineException('만료되었거나 유효하지 않은 송금 요청입니다.');
    }

    var room = _getRoomOrThrow(req.roomCode);
    final toIdx = room.players.indexWhere((p) =>
        p.id == actorId ||
        p.sessionId == actorId);
    if (toIdx < 0) {
      throw BoardgameEngineException('수신자 본인만 응답할 수 있습니다.');
    }
    final toPlayer = room.players[toIdx];
    final isIntended = toPlayer.id == req.toId ||
        (req.toSessionId != null && toPlayer.sessionId == req.toSessionId);
    if (!isIntended) {
      throw BoardgameEngineException('수신자 본인만 응답할 수 있습니다.');
    }

    final fromIdx = room.players.indexWhere((p) =>
        p.id == req.fromId ||
        (req.fromSessionId != null && p.sessionId == req.fromSessionId));
    if (fromIdx < 0) {
      _pendingTransfers.remove(requestId);
      throw BoardgameEngineException('송금자를 찾을 수 없습니다.');
    }
    final fromPlayer = room.players[fromIdx];

    if (!accept) {
      _pendingTransfers.remove(requestId);
      final (loggedRoom, log) = _addLog(
        room,
        type: LogType.transferRejected,
        actorName: toPlayer.nickname,
        targetName: fromPlayer.nickname,
        description:
            "'${toPlayer.nickname}'님이 '${fromPlayer.nickname}'님의 ${formatCommaNumber(req.amount)}${room.settings.currencyUnit} 송금 요청을 거절했습니다.",
      );
      return ActionResult(
        room: loggedRoom,
        log: log,
        transferRequest: req,
        fromPlayer: fromPlayer,
        toPlayer: toPlayer,
        accepted: false,
      );
    }

    final reservedBid = _getReservedBid(room, fromPlayer);
    if (fromPlayer.points - req.amount < reservedBid) {
      throw BoardgameEngineException(
          '진행 중인 경매의 최고 입찰액(${formatCommaNumber(reservedBid)}${room.settings.currencyUnit})으로 묶인 잔액은 송금할 수 없습니다.');
    }
    if (fromPlayer.points < req.amount) {
      throw BoardgameEngineException('송금자의 잔액이 부족하여 송금을 완료할 수 없습니다.');
    }

    _pendingTransfers.remove(requestId);

    final updatedFrom =
        fromPlayer.copyWith(points: fromPlayer.points - req.amount);
    final updatedTo = toPlayer.copyWith(points: toPlayer.points + req.amount);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[fromIdx] = updatedFrom;
    updatedPlayers[toIdx] = updatedTo;
    room = room.copyWith(players: updatedPlayers);

    final memoText = req.memo != null ? ' [메모: ${req.memo}]' : '';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.transfer,
      actorName: updatedFrom.nickname,
      targetName: updatedTo.nickname,
      amount: req.amount,
      description:
          "'${updatedTo.nickname}'님이 수락하여 '${updatedFrom.nickname}'님이 ${formatCommaNumber(req.amount)}${room.settings.currencyUnit}을(를) 송금 완료했습니다.$memoText",
    );

    return ActionResult(
      room: loggedRoom,
      log: log,
      transferRequest: req,
      fromPlayer: updatedFrom,
      toPlayer: updatedTo,
      accepted: true,
    );
  }

  ActionResult startAuction({
    required String roomCode,
    required String hostActorId,
    String? title,
    int? minIncrement,
    int? timeLimit,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 경매를 시작할 수 있습니다.');
    }
    if (!room.settings.enableAuction) {
      throw BoardgameEngineException('경매 기능이 비활성화되어 있습니다.');
    }

    final effectiveMin = (minIncrement != null && minIncrement > 0)
        ? minIncrement
        : room.settings.auctionMinBid;
    final effectiveTime = timeLimit ?? room.settings.auctionTimeLimit;
    final now = DateTime.now().millisecondsSinceEpoch;
    final endsAt =
        effectiveTime > 0 ? now + effectiveTime * 1000 : null;

    room = room.copyWith(
      auction: BoardgameCalcAuction(
        isActive: true,
        title: (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : '실시간 경매',
        currentPot: 0,
        highestBid: 0,
        minIncrement: effectiveMin,
        timeLimit: effectiveTime,
        endsAt: endsAt,
        round: room.auction.round + 1,
      ),
    );

    final timeText = effectiveTime > 0 ? ', 제한시간: $effectiveTime초' : '';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.auctionStart,
      actorName: host!.nickname,
      description:
          "[경매] '${host.nickname}' 방장이 경매를 시작했습니다 (최소 입찰단위: ${formatCommaNumber(effectiveMin)}${room.settings.currencyUnit}$timeText).",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult placeBid({
    required String roomCode,
    required String bidderActorId,
    required int bidAmount,
    int? expectedHighestBid,
  }) {
    var room = _getRoomOrThrow(roomCode);
    if (!room.auction.isActive) {
      throw BoardgameEngineException('진행 중인 경매가 없습니다.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (room.auction.endsAt != null && now > room.auction.endsAt!) {
      throw BoardgameEngineException('경매 제한 시간이 종료되었습니다. 추가 입찰이 불가능합니다.');
    }

    final bidder = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == bidderActorId || p?.sessionId == bidderActorId,
          orElse: () => null,
        );
    if (bidder == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    if (room.auction.highestBidderId == bidder.id ||
        (bidder.sessionId.isNotEmpty &&
            (room.auction.highestBidderId == bidder.sessionId ||
                room.auction.highestBidderSessionId == bidder.sessionId))) {
      throw BoardgameEngineException(
          '이미 현재 최고 입찰자입니다. 다른 플레이어가 입찰할 때까지 기다려주세요.');
    }

    if (expectedHighestBid != null &&
        expectedHighestBid != room.auction.highestBid) {
      final nextMin = room.auction.highestBid + room.auction.minIncrement;
      throw BoardgameEngineException(
        "입찰 경쟁 발생: '${room.auction.highestBidderName}'님이 먼저 ${formatCommaNumber(room.auction.highestBid)}${room.settings.currencyUnit}에 입찰했습니다. (새 최소 입찰가: ${formatCommaNumber(nextMin)}${room.settings.currencyUnit})",
        isConflict: true,
      );
    }

    if (bidAmount <= 0 || bidAmount > BoardgameCalcConstants.maxSafeAmount) {
      throw BoardgameEngineException('유효한 입찰 금액을 입력해주세요.');
    }

    final minNext = room.auction.highestBid + room.auction.minIncrement;
    if (bidAmount < minNext) {
      throw BoardgameEngineException(
          '최소 ${formatCommaNumber(minNext)}${room.settings.currencyUnit} 이상으로 입찰해야 합니다.');
    }

    if (bidder.points < bidAmount) {
      throw BoardgameEngineException(
          '보유 포인트가 부족합니다 (보유: ${formatCommaNumber(bidder.points)}${room.settings.currencyUnit}).');
    }

    final diff = bidAmount - room.auction.highestBid;
    var endsAt = room.auction.endsAt;
    var timeLimit = room.auction.timeLimit;
    final extendSeconds = room.settings.auctionExtendSeconds;
    if (extendSeconds > 0 && endsAt != null) {
      final currentRemainingMs = max(0, endsAt - now);
      final targetRemainingMs = max(currentRemainingMs, extendSeconds * 1000);
      endsAt = now + targetRemainingMs;
      final newRemainingSec = (targetRemainingMs / 1000).ceil();
      if (timeLimit != null && newRemainingSec > timeLimit) {
        timeLimit = newRemainingSec;
      }
    }

    room = room.copyWith(
      auction: room.auction.copyWith(
        highestBid: bidAmount,
        highestBidderId: bidder.id,
        highestBidderSessionId: bidder.sessionId,
        highestBidderName: bidder.nickname,
        highestBidderAvatarUrl: bidder.avatarUrl,
        highestBidderAvatarColor: bidder.avatarColor,
        currentPot: room.auction.currentPot + diff,
        endsAt: endsAt,
        timeLimit: timeLimit,
      ),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.auctionBid,
      actorName: bidder.nickname,
      amount: bidAmount,
      description:
          "[경매 입찰] '${bidder.nickname}'님이 최고 판돈 ${formatCommaNumber(bidAmount)}${room.settings.currencyUnit} 입찰! (모인 돈: ${formatCommaNumber(room.auction.currentPot)}${room.settings.currencyUnit})",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult designateAuctionWinner({
    required String roomCode,
    required String hostActorId,
    String? winnerId,
    String potAction = 'burn_pot',
    int? expectedHighestBid,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 승자를 지정할 수 있습니다.');
    }
    if (!room.auction.isActive) {
      throw BoardgameEngineException('진행 중인 경매가 없습니다.');
    }
    if (expectedHighestBid != null &&
        expectedHighestBid != room.auction.highestBid) {
      throw BoardgameEngineException(
        "승자 지정 중 새로운 입찰이 발생했습니다! (현재 최고가: ${formatCommaNumber(room.auction.highestBid)}${room.settings.currencyUnit}, 입찰자: '${room.auction.highestBidderName}').",
        isConflict: true,
      );
    }

    final targetWinnerId = winnerId ??
        room.auction.highestBidderId ??
        room.auction.highestBidderSessionId;
    if (targetWinnerId == null || targetWinnerId.isEmpty) {
      throw BoardgameEngineException('입찰자가 없어 낙찰할 수 없습니다. 입찰이 진행된 후 낙찰해주세요.');
    }

    final winnerIdx = room.players.indexWhere(
      (p) => p.id == targetWinnerId || p.sessionId == targetWinnerId,
    );
    if (winnerIdx < 0) {
      throw BoardgameEngineException('지정된 승리자를 찾을 수 없습니다.');
    }

    var winner = room.players[winnerIdx];
    final finalBid = room.auction.highestBid;
    final finalPot = room.auction.currentPot;

    if (finalBid > 0 && winner.points < finalBid) {
      throw BoardgameEngineException(
        "최종 입찰자인 '${winner.nickname}'님의 보유 포인트(${formatCommaNumber(winner.points)}${room.settings.currencyUnit})가 낙찰가(${formatCommaNumber(finalBid)}${room.settings.currencyUnit})보다 부족합니다.",
      );
    }

    var newPoints = winner.points;
    if (finalBid > 0) {
      newPoints = max(0, newPoints - finalBid);
    }
    if (potAction == 'transfer_pot' && finalPot > 0) {
      newPoints += finalPot;
    }
    winner = winner.copyWith(points: newPoints);

    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[winnerIdx] = winner;

    room = room.copyWith(
      players: updatedPlayers,
      auction: room.auction.copyWith(
        isActive: false,
        highestBid: 0,
        currentPot: 0,
        clearHighestBidder: true,
        clearTiming: true,
        winner: AuctionWinner(
          id: winner.id,
          name: winner.nickname,
          amount: finalBid,
          pot: finalPot,
        ),
      ),
    );

    final actionText =
        potAction == 'transfer_pot' ? '판돈 지급 완료' : '낙찰 대금 차감 완료';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.auctionWin,
      actorName: host!.nickname,
      targetName: winner.nickname,
      amount: finalBid,
      description:
          "[경매 즉시 낙찰] '${winner.nickname}'님이 최고 입찰가 ${formatCommaNumber(finalBid)}${room.settings.currencyUnit}에 최종 낙찰! ($actionText, 차감 후 잔액: ${formatCommaNumber(winner.points)}${room.settings.currencyUnit})",
    );
    return ActionResult(room: loggedRoom, log: log, player: winner);
  }

  ActionResult resetAuction({
    required String roomCode,
    required String hostActorId,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 경매를 리셋할 수 있습니다.');
    }

    room = room.copyWith(
      auction: room.auction.copyWith(
        isActive: false,
        highestBid: 0,
        currentPot: 0,
        clearHighestBidder: true,
        clearTiming: true,
      ),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.auctionReset,
      actorName: host!.nickname,
      description: '[경매] 방장이 경매 판돈 및 모인 돈을 리셋했습니다.',
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult placeBet({
    required String roomCode,
    required String actorId,
    required int amount,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final idx = room.players
        .indexWhere((p) => p.id == actorId || p.sessionId == actorId);
    if (idx < 0) throw BoardgameEngineException('방 참가자가 아닙니다.');
    var player = room.players[idx];

    if (amount <= 0 || amount > BoardgameCalcConstants.maxSafeAmount) {
      throw BoardgameEngineException('배팅 금액은 0보다 큰 유효한 숫자여야 합니다.');
    }
    if (player.points < amount) {
      throw BoardgameEngineException(
          '보유 포인트가 부족합니다 (보유: ${formatCommaNumber(player.points)}${room.settings.currencyUnit}).');
    }

    final reservedBid = _getReservedBid(room, player);
    if (player.points - amount < reservedBid) {
      throw BoardgameEngineException(
          '진행 중인 경매의 최고 입찰액(${formatCommaNumber(reservedBid)}${room.settings.currencyUnit})으로 묶인 잔액은 배팅할 수 없습니다.');
    }

    player = player.copyWith(points: player.points - amount);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[idx] = player;

    final newPot = room.betting.currentPot + amount;
    final isNewHigh = amount > room.betting.highestBet;
    final betKey = player.sessionId.isNotEmpty ? player.sessionId : player.id;
    final updatedBets =
        Map<String, BoardgameCalcPlayerBet>.from(room.betting.playerBets);
    final existing = updatedBets[betKey] ?? updatedBets[player.id];

    updatedBets[betKey] = BoardgameCalcPlayerBet(
      playerId: player.id,
      sessionId: player.sessionId,
      nickname: player.nickname,
      avatarColor: player.avatarColor,
      avatarUrl: player.avatarUrl,
      totalAmount: (existing?.totalAmount ?? 0) + amount,
      lastBetAmount: amount,
      betCount: (existing?.betCount ?? 0) + 1,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    room = room.copyWith(
      players: updatedPlayers,
      betting: room.betting.copyWith(
        currentPot: newPot,
        highestBet: isNewHigh ? amount : room.betting.highestBet,
        highestBetterId:
            isNewHigh ? player.id : room.betting.highestBetterId,
        highestBetterName:
            isNewHigh ? player.nickname : room.betting.highestBetterName,
        playerBets: updatedBets,
      ),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.bettingBet,
      actorName: player.nickname,
      amount: amount,
      description:
          "[배팅] '${player.nickname}'님이 ${formatCommaNumber(amount)}${room.settings.currencyUnit} 배팅! (모인 판돈: ${formatCommaNumber(newPot)}${room.settings.currencyUnit})",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  List<BoardgameCalcPlayer> _refundBettingPotToPlayers(BoardgameCalcRoom room) {
    final players = List<BoardgameCalcPlayer>.from(room.players);
    for (final bet in room.betting.playerBets.values) {
      if (bet.totalAmount <= 0) continue;
      final idx = players.indexWhere((p) =>
          (bet.sessionId != null && p.sessionId == bet.sessionId) ||
          p.id == bet.playerId);
      if (idx >= 0) {
        players[idx] = players[idx]
            .copyWith(points: players[idx].points + bet.totalAmount);
      }
    }
    return players;
  }

  ActionResult resolveBettingWinner({
    required String roomCode,
    required String hostActorId,
    String? winnerId,
    String action = 'transfer',
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 승자를 지정할 수 있습니다.');
    }
    final pot = room.betting.currentPot;
    if (pot <= 0) {
      throw BoardgameEngineException('정산할 판돈이 없습니다.');
    }

    var updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    BoardgameCalcPlayer? winner;
    if (action == 'transfer') {
      final winnerIdx = updatedPlayers.indexWhere(
          (p) => p.id == winnerId || p.sessionId == winnerId);
      if (winnerIdx < 0) {
        throw BoardgameEngineException('지정된 승리자를 찾을 수 없습니다.');
      }
      winner = updatedPlayers[winnerIdx]
          .copyWith(points: updatedPlayers[winnerIdx].points + pot);
      updatedPlayers[winnerIdx] = winner;
    } else if (action == 'burn') {
      updatedPlayers = _refundBettingPotToPlayers(room);
    }

    room = room.copyWith(
      players: updatedPlayers,
      betting: BoardgameCalcBetting(
        currentPot: 0,
        highestBet: 0,
        playerBets: const {},
        lastWinner: BettingLastWinner(
          id: winner?.id ?? host!.id,
          name: winner?.nickname ?? (action == 'burn' ? '전액 환불' : host!.nickname),
          amount: pot,
          action: action,
          resolvedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );

    final desc = (action == 'transfer' && winner != null)
        ? "[배팅 승자] '${winner.nickname}'님이 모인 판돈 ${formatCommaNumber(pot)}${room.settings.currencyUnit}을(를) 획득했습니다! (판돈 지급 완료, 남은 잔액: ${formatCommaNumber(winner.points)}${room.settings.currencyUnit})"
        : "[배팅 취소/환불] 방장이 모인 판돈 ${formatCommaNumber(pot)}${room.settings.currencyUnit}을(를) 취소하고 참여자들에게 전액 환불했습니다. (전액 환불 완료)";

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.bettingWin,
      actorName: host!.nickname,
      targetName: winner?.nickname,
      amount: pot,
      description: desc,
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult resetBettingPot({
    required String roomCode,
    required String hostActorId,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 판돈을 초기화할 수 있습니다.');
    }

    var refundedTotal = 0;
    var refundedCount = 0;
    for (final bet in room.betting.playerBets.values) {
      if (bet.totalAmount > 0) {
        refundedTotal += bet.totalAmount;
        refundedCount++;
      }
    }
    final updatedPlayers = _refundBettingPotToPlayers(room);

    room = room.copyWith(
      players: updatedPlayers,
      betting: BoardgameCalcBetting(
        currentPot: 0,
        highestBet: 0,
        playerBets: const {},
        lastWinner: room.betting.lastWinner,
      ),
    );

    final refundDesc = refundedTotal > 0
        ? '배팅에 참여한 $refundedCount명에게 총 ${formatCommaNumber(refundedTotal)}${room.settings.currencyUnit}을(를) 전액 환불했습니다.'
        : '모인 판돈을 0으로 초기화했습니다.';
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.bettingReset,
      actorName: host!.nickname,
      amount: refundedTotal,
      description: '[배팅 초기화] 방장이 배팅을 취소하여 $refundDesc',
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult updateSettings({
    required String roomCode,
    required String hostActorId,
    required BoardgameCalcSettings nextSettings,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 설정을 변경할 수 있습니다.');
    }

    final normalizedCurrency = _normalizeDenominations(
      nextSettings.currencyDenominations,
      room.settings.currencyDenominations,
    );
    final normalizedScore = _normalizeDenominations(
      nextSettings.scoreDenominations,
      room.settings.scoreDenominations,
    );

    final merged = nextSettings.copyWith(
      currencyUnit: nextSettings.currencyUnit.trim().isNotEmpty
          ? nextSettings.currencyUnit.trim()
          : '원',
      scoreUnit: '점',
      currencyDenominations: normalizedCurrency,
      quickAdjustUnits: normalizedCurrency.map((d) => d.value).toList(),
      scoreDenominations: normalizedScore,
      auctionMinBid: max(1, nextSettings.auctionMinBid),
      auctionTimeLimit: max(0, nextSettings.auctionTimeLimit),
      auctionExtendSeconds: max(0, nextSettings.auctionExtendSeconds),
      secretNoteTimeLimit: max(0, nextSettings.secretNoteTimeLimit),
    );

    final nextCenter = (!merged.enableAuction &&
            room.centerTool == CenterToolType.auction)
        ? CenterToolType.empty
        : room.centerTool;

    final nextSecret = room.secretNote?.copyWith(
      timeLimit: merged.secretNoteTimeLimit,
      autoReveal: merged.secretNoteAutoReveal,
    );

    room = room.copyWith(
      settings: merged,
      centerTool: nextCenter,
      secretNote: nextSecret,
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.setting,
      actorName: host!.nickname,
      description:
          "'${host.nickname}' 방장이 게임 설정을 변경했습니다 (화폐: ${merged.currencyUnit}, 권한: ${merged.permissionMode == PermissionMode.hostOnly ? '방장전용' : '전체'}).",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult resetAllPoints({
    required String roomCode,
    required String hostActorId,
    int? customAmount,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 포인트를 일괄 초기화할 수 있습니다.');
    }

    final targetAmount = (customAmount != null &&
            customAmount >= 0 &&
            customAmount <= BoardgameCalcConstants.maxSafeAmount)
        ? customAmount
        : room.settings.initialPoints;

    final updatedPlayers =
        room.players.map((p) => p.copyWith(points: targetAmount)).toList();
    final updatedDenoms = room.settings.currencyDenominations
        .map((d) => (d.maxCount != null && d.maxCount! > 0)
            ? d.copyWith(remainingCount: d.maxCount)
            : d)
        .toList();

    room = room.copyWith(
      players: updatedPlayers,
      settings: room.settings.copyWith(currencyDenominations: updatedDenoms),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.reset,
      actorName: host!.nickname,
      amount: targetAmount,
      description:
          "'${host.nickname}' 방장이 모든 플레이어의 잔액을 ${formatCommaNumber(targetAmount)}${room.settings.currencyUnit}으로 일괄 초기화했습니다.",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult resetAllScores({
    required String roomCode,
    required String hostActorId,
    int? customScore,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 점수를 일괄 초기화할 수 있습니다.');
    }

    final targetScore = (customScore != null &&
            customScore.abs() <= BoardgameCalcConstants.maxSafeAmount)
        ? customScore
        : room.settings.initialScore;

    final updatedPlayers =
        room.players.map((p) => p.copyWith(score: targetScore)).toList();
    final updatedDenoms = room.settings.scoreDenominations
        .map((d) => (d.maxCount != null && d.maxCount! > 0)
            ? d.copyWith(remainingCount: d.maxCount)
            : d)
        .toList();

    room = room.copyWith(
      players: updatedPlayers,
      settings: room.settings.copyWith(scoreDenominations: updatedDenoms),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.scoreAdjust,
      actorName: host!.nickname,
      amount: targetScore,
      description:
          "'${host.nickname}' 방장이 모든 플레이어의 점수를 ${formatCommaNumber(targetScore)}${room.settings.scoreUnit}으로 일괄 초기화했습니다.",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult renamePlayer({
    required String roomCode,
    required String actorId,
    required String targetPlayerId,
    required String newNickname,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final targetIdx = room.players.indexWhere(
        (p) => p.id == targetPlayerId || p.sessionId == targetPlayerId);
    if (targetIdx < 0) {
      throw BoardgameEngineException('대상 플레이어를 찾을 수 없습니다.');
    }
    final target = room.players[targetIdx];

    final isSelf = target.id == actor.id || target.sessionId == actor.sessionId;
    if (!isSelf && !_isRoomHost(room, actor)) {
      throw BoardgameEngineException('본인 또는 방장만 플레이어 닉네임을 변경할 수 있습니다.');
    }

    final cleanNick = newNickname.trim();
    if (cleanNick.isEmpty) {
      throw BoardgameEngineException('닉네임을 입력해주세요.');
    }
    if (cleanNick.length > BoardgameCalcConstants.maxNicknameLength) {
      throw BoardgameEngineException(
          '닉네임은 최대 ${BoardgameCalcConstants.maxNicknameLength}자까지 가능합니다.');
    }

    if (cleanNick == target.nickname) {
      return ActionResult(room: room, player: target);
    }

    final isDup = room.players.any((p) =>
        p.id != target.id &&
        p.sessionId != target.sessionId &&
        p.nickname.trim().toLowerCase() == cleanNick.toLowerCase());
    if (isDup) {
      throw BoardgameEngineException(
          "방에 이미 동일한 닉네임('$cleanNick')을 사용하는 플레이어가 있습니다.");
    }

    final oldNick = target.nickname;
    final updatedTarget = target.copyWith(nickname: cleanNick);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[targetIdx] = updatedTarget;

    var updatedTitle = room.title;
    if (target.isHost && updatedTitle.contains(oldNick)) {
      updatedTitle = updatedTitle.replaceAll(oldNick, cleanNick);
    }

    var auction = room.auction;
    if (auction.highestBidderId == target.id ||
        (target.sessionId.isNotEmpty &&
            auction.highestBidderSessionId == target.sessionId)) {
      auction = auction.copyWith(highestBidderName: cleanNick);
    }

    final updatedBets =
        Map<String, BoardgameCalcPlayerBet>.from(room.betting.playerBets);
    for (final entry in updatedBets.entries) {
      if (entry.value.playerId == target.id ||
          (target.sessionId.isNotEmpty &&
              entry.value.sessionId == target.sessionId)) {
        updatedBets[entry.key] = entry.value.copyWith(nickname: cleanNick);
      }
    }

    final updatedSecretNotes = Map<String, BoardgameCalcSecretNoteEntry>.from(
        room.secretNote?.notes ?? {});
    for (final entry in updatedSecretNotes.entries) {
      if (entry.value.playerId == target.id ||
          (target.sessionId.isNotEmpty &&
              entry.value.sessionId == target.sessionId)) {
        updatedSecretNotes[entry.key] =
            entry.value.copyWith(nickname: cleanNick);
      }
    }

    room = room.copyWith(
      title: updatedTitle,
      players: updatedPlayers,
      auction: auction,
      betting: room.betting.copyWith(
        highestBetterName: room.betting.highestBetterId == target.id
            ? cleanNick
            : room.betting.highestBetterName,
        playerBets: updatedBets,
      ),
      secretNote: room.secretNote?.copyWith(notes: updatedSecretNotes),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.rename,
      actorName: actor.nickname,
      targetName: cleanNick,
      description: isSelf
          ? "'$oldNick'님이 닉네임을 '$cleanNick'(으)로 변경했습니다."
          : "'${actor.nickname}' 방장이 '$oldNick'님의 닉네임을 '$cleanNick'(으)로 강제 변경했습니다.",
    );
    return ActionResult(room: loggedRoom, log: log, player: updatedTarget);
  }

  ActionResult updatePlayerColor({
    required String roomCode,
    required String actorId,
    String? targetPlayerId,
    required String avatarColor,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final targetIdx = targetPlayerId != null
        ? room.players.indexWhere(
            (p) => p.id == targetPlayerId || p.sessionId == targetPlayerId)
        : room.players.indexWhere(
            (p) => p.id == actor.id || p.sessionId == actor.sessionId);
    if (targetIdx < 0) {
      throw BoardgameEngineException('플레이어를 찾을 수 없습니다.');
    }
    final target = room.players[targetIdx];

    final isSelf = target.id == actor.id || target.sessionId == actor.sessionId;
    if (!isSelf && !_isRoomHost(room, actor)) {
      throw BoardgameEngineException('본인 또는 방장만 테마 색상을 변경할 수 있습니다.');
    }

    final cleanColor = avatarColor.trim();
    if (!_hexColorRegex.hasMatch(cleanColor)) {
      throw BoardgameEngineException('유효한 색상 코드(#RRGGBB)를 선택해주세요.');
    }

    final updatedTarget = target.copyWith(avatarColor: cleanColor);
    final updatedPlayers = List<BoardgameCalcPlayer>.from(room.players);
    updatedPlayers[targetIdx] = updatedTarget;

    var auction = room.auction;
    if (auction.highestBidderId == target.id ||
        (target.sessionId.isNotEmpty &&
            auction.highestBidderSessionId == target.sessionId)) {
      auction = auction.copyWith(highestBidderAvatarColor: cleanColor);
    }

    room = room.copyWith(
      players: updatedPlayers,
      auction: auction,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _rooms[room.roomCode] = room;
    return ActionResult(room: room, player: updatedTarget);
  }

  ActionResult setCenterTool({
    required String roomCode,
    required String hostActorId,
    required CenterToolType tool,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 중앙 보드판 도구를 관리할 수 있습니다.');
    }

    final safeTool =
        (tool == CenterToolType.auction && !room.settings.enableAuction)
            ? CenterToolType.empty
            : tool;

    room = room.copyWith(
      centerTool: safeTool,
      secretNote: (safeTool == CenterToolType.secretNote &&
              room.secretNote == null)
          ? BoardgameCalcSecretNoteState(
              timeLimit: room.settings.secretNoteTimeLimit,
              autoReveal: room.settings.secretNoteAutoReveal,
            )
          : room.secretNote,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _rooms[room.roomCode] = room;
    return ActionResult(room: room);
  }

  ActionResult rollDice({
    required String roomCode,
    required String actorId,
    required int count,
    required int sides,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final safeCount = count.clamp(
      BoardgameCalcConstants.diceMinCount,
      BoardgameCalcConstants.diceMaxCount,
    );
    final safeSides = sides.clamp(
      BoardgameCalcConstants.diceMinSides,
      BoardgameCalcConstants.diceMaxSides,
    );

    final values =
        List.generate(safeCount, (_) => _rng.nextInt(safeSides) + 1);
    final sum = values.fold<int>(0, (acc, v) => acc + v);

    String? comboName;
    final allSame = values.length > 1 && values.every((v) => v == values.first);
    if (allSame) {
      if (values.length == 2) {
        comboName = '🎉 더블 (${values.first}×2)';
      } else if (values.length == 3) {
        comboName = '🔥 트리플 (${values.first}×3)';
      } else {
        comboName = '👑 퍼펙트 매치 (${values.first}×${values.length})';
      }
    } else if (safeSides == 20 && values.contains(20)) {
      comboName = '⚡ 내추럴 20 (대성공!)';
    } else if (safeSides == 20 && values.contains(1)) {
      comboName = '💀 펌블 1 (대실패!)';
    }

    final diceState = BoardgameCalcDiceState(
      count: safeCount,
      sides: safeSides,
      values: values,
      sum: sum,
      comboName: comboName,
      rolledBy: actor.nickname,
      rolledById: actor.id,
      rolledByAvatarUrl: actor.avatarUrl,
      rolledByAvatarColor: actor.avatarColor,
      rolledAt: DateTime.now().millisecondsSinceEpoch,
    );

    room = room.copyWith(
      dice: diceState,
      centerTool: CenterToolType.dice,
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.dice,
      actorName: actor.nickname,
      description:
          "'${actor.nickname}'님이 주사위 $safeCount개(D$safeSides)를 굴렸습니다. [결과: ${values.join(', ')} / 합계: $sum${comboName != null ? ' - $comboName' : ''}]",
    );
    return ActionResult(room: loggedRoom, log: log, diceState: diceState);
  }

  ActionResult startSecretNote({
    required String roomCode,
    required String hostActorId,
    int? timeLimit,
    String? title,
    bool? autoReveal,
    void Function(BoardgameCalcRoom expiredRoom)? onTimerExpire,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 비밀노트를 시작할 수 있습니다.');
    }

    final resolvedLimit = max(0, timeLimit ?? room.settings.secretNoteTimeLimit);
    final resolvedAutoReveal = autoReveal ?? room.settings.secretNoteAutoReveal;
    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : '비밀노트';

    _secretNoteTimers.remove(room.roomCode)?.cancel();

    final currentRound = (room.secretNote?.round ?? 0) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    final endsAt = resolvedLimit > 0 ? now + resolvedLimit * 1000 : null;

    room = room.copyWith(
      centerTool: CenterToolType.secretNote,
      secretNote: BoardgameCalcSecretNoteState(
        isActive: true,
        title: resolvedTitle,
        isLocked: false,
        isRevealed: false,
        timeLimit: resolvedLimit,
        autoReveal: resolvedAutoReveal,
        endsAt: endsAt,
        notes: const {},
        round: currentRound,
        startedAt: now,
      ),
    );

    if (resolvedLimit > 0) {
      _secretNoteTimers[room.roomCode] =
          Timer(Duration(seconds: resolvedLimit), () {
        _secretNoteTimers.remove(room.roomCode);
        final current = _rooms[room.roomCode];
        if (current == null ||
            current.secretNote == null ||
            !current.secretNote!.isActive ||
            current.secretNote!.isLocked) {
          return;
        }
        final lockTime = DateTime.now().millisecondsSinceEpoch;
        var nextNote = current.secretNote!.copyWith(
          isLocked: true,
          lockedAt: lockTime,
        );
        var desc = '제한 시간($resolvedLimit초)이 종료되어 비밀노트 작성이 마감(손떼)되었습니다.';
        if (nextNote.autoReveal) {
          nextNote = nextNote.copyWith(isRevealed: true, revealedAt: lockTime);
          desc += ' 모든 참가자의 비밀노트가 오픈되었습니다!';
        }
        final (expiredRoom, _) = _addLog(
          current.copyWith(secretNote: nextNote),
          type: LogType.secretNote,
          actorName: '시스템',
          description: desc,
        );
        onTimerExpire?.call(expiredRoom);
      });
    }

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.secretNote,
      actorName: host!.nickname,
      description:
          "'${host.nickname}' 방장이 비밀노트 라운드 $currentRound(주제: '$resolvedTitle', 제한시간: ${resolvedLimit > 0 ? '$resolvedLimit초' : '무제한'})를 시작했습니다.",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult updateSecretNote({
    required String roomCode,
    required String actorId,
    required String content,
    bool? isFolded,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final actor = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == actorId || p?.sessionId == actorId,
          orElse: () => null,
        );
    if (actor == null) throw BoardgameEngineException('방 참가자가 아닙니다.');

    final sn = room.secretNote;
    if (sn == null || !sn.isActive) {
      throw BoardgameEngineException('비밀노트가 시작되지 않았습니다.');
    }
    if (sn.isLocked) {
      throw BoardgameEngineException(
          '방장이 손을 떼어(손떼 완료) 더 이상 노트를 수정할 수 없습니다.');
    }

    final cleanContent = content.length > 500 ? content.substring(0, 500) : content;
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = BoardgameCalcSecretNoteEntry(
      playerId: actor.id,
      sessionId: actor.sessionId,
      nickname: actor.nickname,
      avatarColor: actor.avatarColor,
      avatarUrl: actor.avatarUrl,
      content: cleanContent,
      hasContent: cleanContent.trim().isNotEmpty,
      isFolded: isFolded ?? false,
      submittedAt: now,
      updatedAt: now,
    );

    final nextNotes = Map<String, BoardgameCalcSecretNoteEntry>.from(sn.notes);
    nextNotes[actor.id] = entry;
    room = room.copyWith(
      secretNote: sn.copyWith(notes: nextNotes),
      updatedAt: now,
    );
    _rooms[room.roomCode] = room;
    return ActionResult(room: room, noteEntry: entry);
  }

  ActionResult lockSecretNote({
    required String roomCode,
    required String hostActorId,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 "손떼"를 활성화할 수 있습니다.');
    }
    if (room.secretNote == null || !room.secretNote!.isActive) {
      throw BoardgameEngineException('비밀노트가 시작되지 않았습니다.');
    }
    _secretNoteTimers.remove(room.roomCode)?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    room = room.copyWith(
      secretNote: room.secretNote!.copyWith(isLocked: true, lockedAt: now),
    );
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.secretNote,
      actorName: host!.nickname,
      description:
          "'${host.nickname}' 방장이 \"손떼\" 버튼을 눌렀습니다! 모든 참가자의 노트 수정이 마감되었습니다.",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult revealSecretNote({
    required String roomCode,
    required String hostActorId,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 비밀노트를 오픈할 수 있습니다.');
    }
    if (room.secretNote == null || !room.secretNote!.isActive) {
      throw BoardgameEngineException('비밀노트가 시작되지 않았습니다.');
    }
    _secretNoteTimers.remove(room.roomCode)?.cancel();

    final now = DateTime.now().millisecondsSinceEpoch;
    room = room.copyWith(
      secretNote: room.secretNote!.copyWith(
        isLocked: true,
        lockedAt: room.secretNote!.lockedAt ?? now,
        isRevealed: true,
        revealedAt: now,
      ),
    );
    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.secretNote,
      actorName: host!.nickname,
      description:
          "'${host.nickname}' 방장이 비밀노트를 오픈했습니다! 이제 중앙 보드에서 덮여 있는 노트를 클릭하여 내용을 열람할 수 있습니다.",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  ActionResult resetSecretNote({
    required String roomCode,
    required String hostActorId,
    int? timeLimit,
    String? title,
    bool? autoReveal,
  }) {
    var room = _getRoomOrThrow(roomCode);
    final host = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
          (p) => p?.id == hostActorId || p?.sessionId == hostActorId,
          orElse: () => null,
        );
    if (!_isRoomHost(room, host)) {
      throw BoardgameEngineException('방장만 비밀노트를 초기화할 수 있습니다.');
    }
    _secretNoteTimers.remove(room.roomCode)?.cancel();

    final nextRound = (room.secretNote?.round ?? 0) + 1;
    final resolvedLimit = max(
      0,
      timeLimit ?? room.secretNote?.timeLimit ?? room.settings.secretNoteTimeLimit,
    );
    final resolvedAuto = autoReveal ??
        room.secretNote?.autoReveal ??
        room.settings.secretNoteAutoReveal;
    final resolvedTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : (room.secretNote?.title ?? '비밀노트');

    room = room.copyWith(
      secretNote: BoardgameCalcSecretNoteState(
        isActive: false,
        title: resolvedTitle,
        isLocked: false,
        isRevealed: false,
        timeLimit: resolvedLimit,
        autoReveal: resolvedAuto,
        endsAt: null,
        notes: const {},
        round: nextRound,
      ),
    );

    final (loggedRoom, log) = _addLog(
      room,
      type: LogType.secretNote,
      actorName: host!.nickname,
      description: "'${host.nickname}' 방장이 비밀노트를 초기화했습니다 (새 라운드 대기).",
    );
    return ActionResult(room: loggedRoom, log: log);
  }

  BoardgameCalcRoom getSanitizedRoomForPlayer(
    BoardgameCalcRoom room, {
    String? playerId,
    String? sessionId,
  }) {
    final sn = room.secretNote;
    if (sn == null || !sn.isActive || sn.isRevealed) {
      return room;
    }

    final maskedNotes = <String, BoardgameCalcSecretNoteEntry>{};
    for (final entry in sn.notes.entries) {
      final isMe = (playerId != null &&
              (entry.value.playerId == playerId || entry.key == playerId)) ||
          (sessionId != null &&
              sessionId.isNotEmpty &&
              entry.value.sessionId == sessionId);
      maskedNotes[entry.key] = isMe
          ? entry.value
          : entry.value.copyWith(content: '');
    }
    return room.copyWith(secretNote: sn.copyWith(notes: maskedNotes));
  }

  List<BoardgameCalcRoomSummary> getPublicRooms() {
    final list = _rooms.values.map((room) {
      final onlineCount = room.players.where((p) => p.isOnline).length;
      final hostPlayer = room.players.cast<BoardgameCalcPlayer?>().firstWhere(
            (p) => p?.isHost == true,
            orElse: () => room.players.isNotEmpty ? room.players.first : null,
          );
      return BoardgameCalcRoomSummary(
        roomCode: room.roomCode,
        title: room.title,
        hostNickname: hostPlayer?.nickname ?? '방장',
        hostSessionId: room.hostSessionId,
        hostUserId: room.hostUserId,
        playerCount: room.players.length,
        onlineCount: onlineCount,
        settings: room.settings,
        hasAuction: room.auction.isActive,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
      );
    }).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }
}
