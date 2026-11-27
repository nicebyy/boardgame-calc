import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/boardgame_models.dart';

typedef AckCallback = void Function(Map<String, dynamic> response);

/// 원본 `pickban_smulator` NestJS `BoardgameCalcGateway` (`boardgameCalc:*`) 와 1:1 호환되는 Socket.IO 클라이언트.
class BoardgameSocketClient {
  io.Socket? _socket;
  String _serverUrl = 'http://localhost:3001';

  void Function()? onConnect;
  void Function()? onDisconnect;
  void Function(List<BoardgameCalcRoomSummary> rooms)? onRoomList;
  void Function(BoardgameCalcRoom room, BoardgameCalcPlayer player)? onJoined;
  void Function(BoardgameCalcRoom room)? onRoomState;
  void Function(String roomCode, String? reason)? onRoomDeleted;
  void Function(BoardgameCalcLog log)? onLogAdded;
  void Function(BoardgameCalcTransferRequest request)? onTransferConsentRequired;
  void Function(BoardgameCalcTransferRequest request)? onTransferRequestSent;
  void Function({
    required String requestId,
    required bool accepted,
    required String otherPlayerName,
    required int amount,
  })? onTransferResolved;
  void Function(BoardgameCalcDiceState diceState)? onDiceRolled;
  void Function(String action)? onSecretNoteAction;
  void Function(String message, {bool isConflict, String? type})? onError;

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;
  String get serverUrl => _serverUrl;

  void connect(String serverUrl) {
    final cleanUrl = serverUrl.trim().isNotEmpty
        ? serverUrl.trim()
        : 'http://localhost:3001';
    if (_socket != null && _serverUrl == cleanUrl) {
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    disconnect();
    _serverUrl = cleanUrl;

    final socket = io.io(
      cleanUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(15)
          .setReconnectionDelay(1000)
          .build(),
    );

    socket.onConnect((_) {
      onConnect?.call();
    });

    socket.onDisconnect((_) {
      onDisconnect?.call();
    });

    socket.onConnectError((err) {
      onDisconnect?.call();
      onError?.call('서버 연결에 실패했습니다 ($cleanUrl). 오프라인 모드를 이용하거나 서버 주소를 확인해주세요.');
    });

    socket.on('boardgameCalc:roomList', (data) {
      if (data is List) {
        final rooms = data
            .whereType<Map>()
            .map((e) =>
                BoardgameCalcRoomSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        onRoomList?.call(rooms);
      }
    });

    socket.on('boardgameCalc:joined', (data) {
      if (data is Map && data['room'] is Map && data['player'] is Map) {
        final room = BoardgameCalcRoom.fromJson(
            Map<String, dynamic>.from(data['room'] as Map));
        final player = BoardgameCalcPlayer.fromJson(
            Map<String, dynamic>.from(data['player'] as Map));
        onJoined?.call(room, player);
      }
    });

    socket.on('boardgameCalc:roomState', (data) {
      if (data is Map) {
        final room =
            BoardgameCalcRoom.fromJson(Map<String, dynamic>.from(data));
        onRoomState?.call(room);
      }
    });

    socket.on('boardgameCalc:roomDeleted', (data) {
      if (data is Map) {
        final code = data['roomCode'] as String? ?? '';
        final reason = data['reason'] as String?;
        onRoomDeleted?.call(code, reason);
      }
    });

    socket.on('boardgameCalc:logAdded', (data) {
      if (data is Map) {
        onLogAdded
            ?.call(BoardgameCalcLog.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    socket.on('boardgameCalc:transferConsentRequired', (data) {
      if (data is Map) {
        onTransferConsentRequired?.call(BoardgameCalcTransferRequest.fromJson(
            Map<String, dynamic>.from(data)));
      }
    });

    socket.on('boardgameCalc:transferRequestSent', (data) {
      if (data is Map) {
        onTransferRequestSent?.call(BoardgameCalcTransferRequest.fromJson(
            Map<String, dynamic>.from(data)));
      }
    });

    socket.on('boardgameCalc:transferResolved', (data) {
      if (data is Map) {
        onTransferResolved?.call(
          requestId: data['requestId'] as String? ?? '',
          accepted: data['accepted'] as bool? ?? false,
          otherPlayerName: data['otherPlayerName'] as String? ?? '',
          amount: (data['amount'] as num?)?.toInt() ?? 0,
        );
      }
    });

    socket.on('boardgameCalc:diceRolled', (data) {
      if (data is Map) {
        onDiceRolled?.call(
            BoardgameCalcDiceState.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    socket.on('boardgameCalc:secretNoteAction', (data) {
      if (data is Map) {
        onSecretNoteAction?.call(data['action'] as String? ?? '');
      }
    });

    socket.on('boardgameCalc:error', (data) {
      if (data is Map) {
        onError?.call(
          data['message'] as String? ?? '요청 처리 중 오류가 발생했습니다.',
          isConflict: data['isConflict'] as bool? ?? false,
          type: data['type'] as String?,
        );
      }
    });

    _socket = socket;
    socket.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void _emit(String event, dynamic data, [AckCallback? ack]) {
    final socket = _socket;
    if (socket == null) return;
    if (!socket.connected) {
      socket.connect();
    }
    if (ack != null) {
      var done = false;
      final timer = Timer(const Duration(seconds: 5), () {
        if (!done) {
          done = true;
          ack({'success': false, 'error': '서버 응답 시간이 초과되었습니다.'});
        }
      });
      socket.emitWithAck(event, data, ack: (res) {
        if (done) return;
        done = true;
        timer.cancel();
        if (res is Map) {
          ack(Map<String, dynamic>.from(res));
        } else {
          ack({'success': true});
        }
      });
    } else {
      socket.emit(event, data);
    }
  }

  void getRooms([AckCallback? ack]) => _emit('boardgameCalc:getRooms', {}, ack);

  void createRoom(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:createRoom', payload, ack);

  void joinRoom(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:joinRoom', payload, ack);

  void leaveRoom(String roomCode) =>
      _emit('boardgameCalc:leaveRoom', {'roomCode': roomCode});

  void deleteRoom(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:deleteRoom', payload, ack);

  void adjustPoints(Map<String, dynamic> payload) =>
      _emit('boardgameCalc:adjustPoints', payload);

  void adjustScore(Map<String, dynamic> payload) =>
      _emit('boardgameCalc:adjustScore', payload);

  void requestTransfer(Map<String, dynamic> payload) =>
      _emit('boardgameCalc:requestTransfer', payload);

  void respondTransfer(Map<String, dynamic> payload) =>
      _emit('boardgameCalc:respondTransfer', payload);

  void startAuction(Map<String, dynamic> payload) =>
      _emit('boardgameCalc:auctionStart', payload);

  void placeBid(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:auctionBid', payload, ack);

  void designateAuctionWinner(Map<String, dynamic> payload,
          [AckCallback? ack]) =>
      _emit('boardgameCalc:auctionDesignateWinner', payload, ack);

  void resetAuction(String roomCode) =>
      _emit('boardgameCalc:auctionReset', {'roomCode': roomCode});

  void placeBet(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:placeBet', payload, ack);

  void resolveBettingWinner(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:resolveBettingWinner', payload, ack);

  void resetBettingPot(String roomCode, [AckCallback? ack]) =>
      _emit('boardgameCalc:resetBettingPot', {'roomCode': roomCode}, ack);

  void updateSettings(String roomCode, Map<String, dynamic> settings) =>
      _emit('boardgameCalc:updateSettings', {
        'roomCode': roomCode,
        'settings': settings,
      });

  void resetPoints(String roomCode, {int? customAmount}) =>
      _emit('boardgameCalc:resetPoints', {
        'roomCode': roomCode,
        'customAmount': ?customAmount,
      });

  void resetScores(String roomCode, {int? customScore}) =>
      _emit('boardgameCalc:resetScores', {
        'roomCode': roomCode,
        'customScore': ?customScore,
      });

  void renamePlayer(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:renamePlayer', payload, ack);

  void updateColor(String roomCode, String avatarColor) =>
      _emit('boardgameCalc:updateColor', {
        'roomCode': roomCode,
        'avatarColor': avatarColor,
      });

  void setCenterTool(String roomCode, CenterToolType tool, [AckCallback? ack]) =>
      _emit(
          'boardgameCalc:setCenterTool',
          {
            'roomCode': roomCode,
            'tool': tool.wireValue,
          },
          ack);

  void rollDice(String roomCode, int count, int sides, [AckCallback? ack]) =>
      _emit(
          'boardgameCalc:rollDice',
          {
            'roomCode': roomCode,
            'count': count,
            'sides': sides,
          },
          ack);

  void startSecretNote(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:startSecretNote', payload, ack);

  void updateSecretNote(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:updateSecretNote', payload, ack);

  void lockSecretNote(String roomCode, [AckCallback? ack]) =>
      _emit('boardgameCalc:lockSecretNote', {'roomCode': roomCode}, ack);

  void revealSecretNote(String roomCode, [AckCallback? ack]) =>
      _emit('boardgameCalc:revealSecretNote', {'roomCode': roomCode}, ack);

  void resetSecretNote(Map<String, dynamic> payload, [AckCallback? ack]) =>
      _emit('boardgameCalc:resetSecretNote', payload, ack);
}
