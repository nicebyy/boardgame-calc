import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/boardgame_models.dart';
import '../services/boardgame_audio.dart';
import '../services/boardgame_socket_client.dart';
import '../services/lobby_bgm_service.dart';
import '../services/local_boardgame_engine.dart';

enum ConnectionMode {
  offline,
  online,
}

class TransferToastMessage {
  const TransferToastMessage({required this.message, required this.isWarn});
  final String message;
  final bool isWarn;
}

class DiceToastMessage {
  const DiceToastMessage({required this.message, required this.diceState});
  final String message;
  final BoardgameCalcDiceState diceState;
}

class BoardgameCalcController extends ChangeNotifier {
  BoardgameCalcController({
    LocalBoardgameEngine? localEngine,
    BoardgameSocketClient? socketClient,
    LobbyBgmPlayer? bgmPlayer,
    ConnectionMode initialMode = ConnectionMode.offline,
  })  : _localEngine = localEngine ?? LocalBoardgameEngine(),
        _socket = socketClient ?? BoardgameSocketClient(),
        _bgmPlayer = bgmPlayer ?? AudioplayersLobbyBgmPlayer(),
        _mode = initialMode {
    _bindSocketCallbacks();
  }

  static const _keySessionId = 'bgcalc_session_id';
  static const _keyRoomCode = 'bgcalc_room_code';
  static const _keyNickname = 'bgcalc_nickname';
  static const _keyAvatarColor = 'bgcalc_avatar_color';
  static const _keyServerUrl = 'bgcalc_server_url';
  static const _keyMode = 'bgcalc_connection_mode';
  static const _keyViewMode = 'boardgame_calc_top_players_view_mode';
  static const _keySortOption = 'boardgame_calc_top_players_sort_option';
  static const _keyBgmEnabled = 'bgcalc_bgm_enabled';
  static const _keyBgmVolume = 'bgcalc_bgm_volume';
  static const _keySoundEnabled = 'bgcalc_sound_enabled';
  static const _keyOfflineRooms = 'bgcalc_offline_rooms_v1';
  static const _keyOfflineActiveRoom = 'bgcalc_offline_active_room';
  static const _keyOfflineActivePlayer = 'bgcalc_offline_active_player';

  final LocalBoardgameEngine _localEngine;
  final BoardgameSocketClient _socket;
  final LobbyBgmPlayer _bgmPlayer;
  SharedPreferences? _prefs;

  ConnectionMode _mode;
  String _serverUrl = BoardgameCalcConstants.defaultServerUrl;
  String _sessionId = '';
  String _savedNickname = '플레이어1';
  String _savedAvatarColor = '#3b82f6';

  BoardgameCalcRoom? _room;
  BoardgameCalcPlayer? _me;
  List<BoardgameCalcRoomSummary> _publicRooms = [];
  bool _isConnected = false;
  bool _isLoadingRooms = false;
  String? _error;
  bool _soundEnabled = true;

  bool _bgmEnabled = true;
  double _bgmVolume = 0.35;
  LobbyBgmStatus _bgmStatus = LobbyBgmStatus.disabled;
  bool? _lastBgmInGame;
  bool _disposed = false;

  BoardgameCalcTransferRequest? _pendingConsentRequest;
  BoardgameCalcTransferRequest? _sentTransferRequest;
  TransferToastMessage? _transferToast;
  String? _auctionConflictToast;
  DiceToastMessage? _diceToast;

  TopPlayersViewMode _topPlayersViewMode = TopPlayersViewMode.card;
  TopPlayersSortOption _topPlayersSortOption =
      TopPlayersSortOption.defaultOrder;

  Timer? _diceToastTimer;
  Timer? _transferToastTimer;
  Timer? _conflictToastTimer;
  Timer? _errorTimer;

  ConnectionMode get mode => _mode;
  bool get isOfflineMode => _mode == ConnectionMode.offline;
  String get serverUrl => _serverUrl;
  String get mySessionId => _sessionId;
  String get savedNickname => _savedNickname;
  String get savedAvatarColor => _savedAvatarColor;

  BoardgameCalcRoom? get room => _room;
  BoardgameCalcPlayer? get me => _me;
  List<BoardgameCalcRoomSummary> get publicRooms => _publicRooms;
  bool get isConnected => _mode == ConnectionMode.offline ? true : _isConnected;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get error => _error;
  bool get soundEnabled => _soundEnabled;
  bool get bgmEnabled => _bgmEnabled;
  double get bgmVolume => _bgmVolume;
  LobbyBgmStatus get bgmStatus => _bgmStatus;

  BoardgameCalcTransferRequest? get pendingConsentRequest =>
      _pendingConsentRequest;
  BoardgameCalcTransferRequest? get sentTransferRequest => _sentTransferRequest;
  TransferToastMessage? get transferToast => _transferToast;
  String? get auctionConflictToast => _auctionConflictToast;
  DiceToastMessage? get diceToast => _diceToast;

  TopPlayersViewMode get topPlayersViewMode => _topPlayersViewMode;
  TopPlayersSortOption get topPlayersSortOption => _topPlayersSortOption;

  List<BoardgameCalcLog> get gameLogs => (_room?.logs ?? [])
      .where((l) => l.type != LogType.join && l.type != LogType.leave)
      .toList();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    var sid = _prefs!.getString(_keySessionId);
    if (sid == null || sid.isEmpty) {
      final rng = Random();
      sid =
          'bgc_${rng.nextInt(999999).toString().padLeft(6, '0')}_${DateTime.now().millisecondsSinceEpoch}';
      await _prefs!.setString(_keySessionId, sid);
    }
    _sessionId = sid;
    _savedNickname = _prefs!.getString(_keyNickname) ?? '플레이어1';
    _savedAvatarColor = _prefs!.getString(_keyAvatarColor) ?? '#3b82f6';
    _serverUrl =
        _prefs!.getString(_keyServerUrl) ?? BoardgameCalcConstants.defaultServerUrl;
    _topPlayersViewMode =
        TopPlayersViewMode.fromWire(_prefs!.getString(_keyViewMode));
    _topPlayersSortOption =
        TopPlayersSortOption.fromWire(_prefs!.getString(_keySortOption));
    _bgmEnabled = _prefs!.getBool(_keyBgmEnabled) ?? true;
    _bgmVolume = (_prefs!.getDouble(_keyBgmVolume) ?? 0.35).clamp(0.0, 1.0);
    _soundEnabled = _prefs!.getBool(_keySoundEnabled) ?? true;
    BoardgameAudio.globalEnabled = _soundEnabled;

    final storedMode = _prefs!.getString(_keyMode);
    if (storedMode == 'online') {
      _mode = ConnectionMode.online;
    } else {
      _mode = ConnectionMode.offline;
    }

    // 오프라인 저장소 복원
    final offlineJson = _prefs!.getString(_keyOfflineRooms);
    if (offlineJson != null && offlineJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(offlineJson);
        if (decoded is List) {
          _localEngine.loadRoomsFromJson(decoded);
        }
      } catch (_) {}
    }

    if (_mode == ConnectionMode.offline) {
      _publicRooms = _localEngine.getPublicRooms();
      final activeRoomCode = _prefs!.getString(_keyOfflineActiveRoom);
      final activePlayerId = _prefs!.getString(_keyOfflineActivePlayer);
      if (activeRoomCode != null) {
        final restoredRoom = _localEngine.getRoom(activeRoomCode);
        if (restoredRoom != null) {
          final restoredMe = restoredRoom.players.cast<BoardgameCalcPlayer?>().firstWhere(
                (p) =>
                    p?.id == activePlayerId ||
                    p?.sessionId == activePlayerId ||
                    p?.sessionId == _sessionId,
                orElse: () => restoredRoom.players.isNotEmpty
                    ? restoredRoom.players.first
                    : null,
              );
          if (restoredMe != null) {
            _me = restoredMe;
            _room = _localEngine.getSanitizedRoomForPlayer(
              restoredRoom,
              playerId: restoredMe.id,
              sessionId: restoredMe.sessionId,
            );
          }
        }
      }
      _lastBgmInGame = _room != null;
      notifyListeners();
    } else {
      _socket.connect(_serverUrl);
      _lastBgmInGame = _room != null;
      notifyListeners();
    }
    await _syncLobbyBgmState(force: true);
  }

  Future<void> _persistOfflineState() async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString(
        _keyOfflineRooms,
        jsonEncode(_localEngine.exportRoomsToJson()),
      );
      if (_room != null && _mode == ConnectionMode.offline) {
        await _prefs!.setString(_keyOfflineActiveRoom, _room!.roomCode);
      } else {
        await _prefs!.remove(_keyOfflineActiveRoom);
      }
      if (_me != null && _mode == ConnectionMode.offline) {
        await _prefs!.setString(_keyOfflineActivePlayer, _me!.id);
      } else {
        await _prefs!.remove(_keyOfflineActivePlayer);
      }
    } catch (_) {}
  }

  void _bindSocketCallbacks() {
    _socket.onConnect = () {
      _isConnected = true;
      _error = null;
      fetchPublicRooms();

      final savedRoom = _prefs?.getString(_keyRoomCode);
      final savedNick = _prefs?.getString(_keyNickname);
      if (_mode == ConnectionMode.online &&
          savedRoom != null &&
          savedRoom.isNotEmpty &&
          savedNick != null &&
          savedNick.isNotEmpty &&
          _sessionId.isNotEmpty) {
        _socket.joinRoom(
          {
            'roomCode': savedRoom,
            'nickname': savedNick,
            'sessionId': _sessionId,
          },
          (res) {
            if (res['success'] == true &&
                res['room'] is Map &&
                res['player'] is Map) {
              _room = BoardgameCalcRoom.fromJson(
                  Map<String, dynamic>.from(res['room'] as Map));
              _me = BoardgameCalcPlayer.fromJson(
                  Map<String, dynamic>.from(res['player'] as Map));
              notifyListeners();
            } else if (res['success'] == false) {
              _prefs?.remove(_keyRoomCode);
              _room = null;
              _me = null;
              _pendingConsentRequest = null;
              _sentTransferRequest = null;
              setError(res['error'] as String? ?? '이전 방이 종료되었거나 찾을 수 없습니다.');
              fetchPublicRooms();
            }
          },
        );
      }
      notifyListeners();
    };

    _socket.onDisconnect = () {
      _isConnected = false;
      notifyListeners();
    };

    _socket.onRoomList = (rooms) {
      if (_mode == ConnectionMode.online) {
        _publicRooms = rooms;
        _isLoadingRooms = false;
        notifyListeners();
      }
    };

    _socket.onJoined = (room, player) {
      _room = room;
      _me = player;
      _error = null;
      _prefs?.setString(_keyRoomCode, room.roomCode);
      _prefs?.setString(_keyNickname, player.nickname);
      _prefs?.setString(_keyAvatarColor, player.avatarColor);
      _savedNickname = player.nickname;
      _savedAvatarColor = player.avatarColor;
      notifyListeners();
    };

    _socket.onRoomState = (newRoom) {
      if (_mode != ConnectionMode.online) return;
      final currentCode = _room?.roomCode.trim().toUpperCase();
      final incomingCode = newRoom.roomCode.trim().toUpperCase();
      if (currentCode == null ||
          currentCode.isEmpty ||
          (incomingCode.isNotEmpty && currentCode != incomingCode)) {
        return;
      }
      _room = newRoom;
      final foundMe = newRoom.players.cast<BoardgameCalcPlayer?>().firstWhere(
            (p) =>
                p != null &&
                (p.sessionId == _sessionId ||
                    (_socket.socketId != null && p.id == _socket.socketId)),
            orElse: () => null,
          );
      if (foundMe != null) {
        _me = foundMe;
      }
      notifyListeners();
    };

    _socket.onRoomDeleted = (roomCode, reason) {
      if (_mode != ConnectionMode.online) return;
      final cur = _room?.roomCode.trim().toUpperCase();
      final target = roomCode.trim().toUpperCase();
      if (cur == null || cur == target) {
        _room = null;
        _me = null;
        _pendingConsentRequest = null;
        _sentTransferRequest = null;
        _prefs?.remove(_keyRoomCode);
        if (reason != null && reason.isNotEmpty) {
          setError(reason);
        }
      }
      fetchPublicRooms();
      notifyListeners();
    };

    _socket.onLogAdded = (log) {
      _playSoundForLog(log);
    };

    _socket.onTransferConsentRequired = (request) {
      _pendingConsentRequest = request;
      BoardgameAudio.playCoinSound(enabled: _soundEnabled);
      notifyListeners();
    };

    _socket.onTransferRequestSent = (request) {
      _sentTransferRequest = request;
      _showTransferToast(
        "'${request.toName}'님에게 ${formatCommaNumber(request.amount)} 송금 수락을 요청했습니다. 상대방의 승인을 기다립니다.",
        isWarn: false,
      );
      notifyListeners();
    };

    _socket.onTransferResolved = ({
      required requestId,
      required accepted,
      required otherPlayerName,
      required amount,
    }) {
      _sentTransferRequest = null;
      if (accepted) {
        _showTransferToast(
          "'$otherPlayerName'님이 ${formatCommaNumber(amount)} 송금을 수락했습니다!",
          isWarn: false,
        );
      } else {
        _showTransferToast(
          "'$otherPlayerName'님이 ${formatCommaNumber(amount)} 송금 요청을 거절했습니다.",
          isWarn: true,
        );
      }
      notifyListeners();
    };

    _socket.onDiceRolled = (diceState) {
      if (diceState.values.isNotEmpty) {
        _showDiceToast(diceState);
      }
    };

    _socket.onSecretNoteAction = (action) {
      if (action == 'revealed') {
        _playSecretSoundDeduped('reveal');
      } else if (action == 'locked') {
        _playSecretSoundDeduped('lock');
      } else if (action == 'started' || action == 'reset') {
        _playSecretSoundDeduped('fold');
      }
    };

    _socket.onError = (message, {isConflict = false, type}) {
      setError(message);
      if (isConflict || type == 'auction_bid' || type == 'auction_winner') {
        _showAuctionConflictToast(message);
      }
    };
  }

  DateTime? _lastSecretSoundAt;
  String? _lastSecretSoundKind;

  void _playSecretSoundDeduped(String kind) {
    final now = DateTime.now();
    if (_lastSecretSoundKind == kind &&
        _lastSecretSoundAt != null &&
        now.difference(_lastSecretSoundAt!).inMilliseconds < 150) {
      return;
    }
    _lastSecretSoundKind = kind;
    _lastSecretSoundAt = now;
    if (kind == 'reveal') {
      BoardgameAudio.playSecretNoteRevealSound(enabled: _soundEnabled);
    } else if (kind == 'lock') {
      BoardgameAudio.playSecretNoteLockSound(enabled: _soundEnabled);
    } else {
      BoardgameAudio.playSecretNoteFoldSound(enabled: _soundEnabled);
    }
  }

  void _playSoundForLog(BoardgameCalcLog log) {
    switch (log.type) {
      case LogType.adjust:
      case LogType.scoreAdjust:
        BoardgameAudio.playCoinSound(enabled: _soundEnabled);
      case LogType.transfer:
        BoardgameAudio.playTransferSound(enabled: _soundEnabled);
      case LogType.auctionStart:
        BoardgameAudio.playAuctionGong(enabled: _soundEnabled);
      case LogType.auctionBid:
        BoardgameAudio.playBidCoinSound(enabled: _soundEnabled);
      case LogType.bettingBet:
        BoardgameAudio.playBetChipSound(enabled: _soundEnabled);
      case LogType.auctionWin:
      case LogType.bettingWin:
        BoardgameAudio.playWinSound(enabled: _soundEnabled);
      case LogType.auctionReset:
      case LogType.bettingReset:
        BoardgameAudio.playRefundSound(enabled: _soundEnabled);
      case LogType.dice:
        BoardgameAudio.playDiceSound(enabled: _soundEnabled);
      case LogType.secretNote:
        if (log.description.contains('오픈') ||
            log.description.contains('열람')) {
          _playSecretSoundDeduped('reveal');
        } else if (log.description.contains('손떼') ||
            log.description.contains('마감')) {
          _playSecretSoundDeduped('lock');
        } else {
          _playSecretSoundDeduped('fold');
        }
      default:
        break;
    }
  }

  void _showTransferToast(String message, {required bool isWarn}) {
    _transferToast = TransferToastMessage(message: message, isWarn: isWarn);
    _transferToastTimer?.cancel();
    _transferToastTimer = Timer(const Duration(seconds: 5), () {
      _transferToast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void _showDiceToast(BoardgameCalcDiceState diceState) {
    final msg = diceState.rolledBy != null
        ? "'${diceState.rolledBy}'님이 주사위 ${diceState.count}개(D${diceState.sides})를 굴렸습니다!"
        : '주사위 ${diceState.count}개(D${diceState.sides})를 굴렸습니다!';
    _diceToast = DiceToastMessage(message: msg, diceState: diceState);
    _diceToastTimer?.cancel();
    _diceToastTimer = Timer(const Duration(seconds: 5), () {
      _diceToast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void _showAuctionConflictToast(String msg) {
    _auctionConflictToast = msg;
    _conflictToastTimer?.cancel();
    _conflictToastTimer = Timer(const Duration(seconds: 6), () {
      _auctionConflictToast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    _errorTimer?.cancel();
    if (msg != null) {
      _errorTimer = Timer(const Duration(seconds: 5), () {
        _error = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void clearAuctionConflictToast() {
    _auctionConflictToast = null;
    notifyListeners();
  }

  void clearDiceToast() {
    _diceToast = null;
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    BoardgameAudio.globalEnabled = enabled;
    _prefs?.setBool(_keySoundEnabled, enabled);
    if (enabled) BoardgameAudio.playClick(enabled: true);
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    BoardgameAudio.globalEnabled = _soundEnabled;
    _prefs?.setBool(_keySoundEnabled, _soundEnabled);
    if (_soundEnabled) BoardgameAudio.playClick(enabled: true);
    notifyListeners();
  }

  Future<void> toggleBgm() async {
    _bgmEnabled = !_bgmEnabled;
    await _prefs?.setBool(_keyBgmEnabled, _bgmEnabled);
    await _syncLobbyBgmState(force: true);
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0).toDouble();
    await _prefs?.setDouble(_keyBgmVolume, _bgmVolume);
    await _bgmPlayer.setVolume(_bgmVolume);
    if (!_disposed) super.notifyListeners();
  }

  Future<void> resumeBgmOnGesture() async {
    if (_disposed || !_bgmEnabled || _room != null) return;
    await _syncLobbyBgmState(force: true);
  }

  Future<void> _syncLobbyBgmState({bool force = false}) async {
    if (_disposed) return;
    final inGame = _room != null;
    if (!force && _lastBgmInGame == inGame) return;
    _lastBgmInGame = inGame;

    if (inGame) {
      await _bgmPlayer.stop();
      if (_disposed) return;
      _bgmStatus = LobbyBgmStatus.pausedInGame;
      super.notifyListeners();
      return;
    }

    if (!_bgmEnabled) {
      await _bgmPlayer.stop();
      if (_disposed) return;
      _bgmStatus = LobbyBgmStatus.disabled;
      super.notifyListeners();
      return;
    }

    final exists =
        await _bgmPlayer.hasAsset(AudioplayersLobbyBgmPlayer.defaultBundlePath);
    if (_disposed) return;
    if (!exists) {
      await _bgmPlayer.stop();
      if (_disposed) return;
      _bgmStatus = LobbyBgmStatus.missingAsset;
      super.notifyListeners();
      return;
    }

    try {
      await _bgmPlayer.playAsset(
        AudioplayersLobbyBgmPlayer.defaultAssetSourcePath,
        volume: _bgmVolume,
      );
      if (_disposed) return;
      _bgmStatus = LobbyBgmStatus.playing;
    } catch (_) {
      if (_disposed) return;
      _bgmStatus = LobbyBgmStatus.needsUserGesture;
    }
    super.notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
    final inGame = _room != null;
    if (_lastBgmInGame != inGame) {
      unawaited(_syncLobbyBgmState());
    }
  }

  void setTopPlayersViewMode(TopPlayersViewMode viewMode) {
    BoardgameAudio.playTab();
    _topPlayersViewMode = viewMode;
    _prefs?.setString(_keyViewMode, viewMode.wireValue);
    notifyListeners();
  }

  void setTopPlayersSortOption(TopPlayersSortOption sortOption) {
    BoardgameAudio.playTab();
    _topPlayersSortOption = sortOption;
    _prefs?.setString(_keySortOption, sortOption.wireValue);
    notifyListeners();
  }

  Future<void> setConnectionMode(ConnectionMode nextMode,
      {String? customServerUrl}) async {
    if (customServerUrl != null && customServerUrl.trim().isNotEmpty) {
      _serverUrl = customServerUrl.trim();
      await _prefs?.setString(_keyServerUrl, _serverUrl);
    }
    if (_mode == nextMode &&
        (nextMode == ConnectionMode.offline || _socket.isConnected)) {
      return;
    }

    BoardgameAudio.playTab();
    _mode = nextMode;
    await _prefs?.setString(
        _keyMode, nextMode == ConnectionMode.online ? 'online' : 'offline');
    _room = null;
    _me = null;
    _error = null;
    _pendingConsentRequest = null;
    _sentTransferRequest = null;

    if (nextMode == ConnectionMode.online) {
      _socket.connect(_serverUrl);
      fetchPublicRooms();
    } else {
      _socket.disconnect();
      _isConnected = false;
      _publicRooms = _localEngine.getPublicRooms();
    }
    notifyListeners();
  }

  void updateServerUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return;
    _serverUrl = clean;
    _prefs?.setString(_keyServerUrl, clean);
    if (_mode == ConnectionMode.online) {
      _socket.connect(clean);
    }
    notifyListeners();
  }

  void saveProfileDraft({String? nickname, String? avatarColor}) {
    if (nickname != null && nickname.trim().isNotEmpty) {
      _savedNickname = nickname.trim();
      _prefs?.setString(_keyNickname, _savedNickname);
    }
    if (avatarColor != null && avatarColor.trim().isNotEmpty) {
      _savedAvatarColor = avatarColor.trim();
      _prefs?.setString(_keyAvatarColor, _savedAvatarColor);
    }
  }

  void fetchPublicRooms({bool silent = false}) {
    if (_mode == ConnectionMode.offline) {
      _publicRooms = _localEngine.getPublicRooms();
      _isLoadingRooms = false;
      notifyListeners();
      return;
    }
    if (!silent) {
      _isLoadingRooms = true;
      notifyListeners();
    }
    if (!_socket.isConnected) {
      _socket.connect(_serverUrl);
    }
    _socket.getRooms((res) {
      if (!silent) {
        _isLoadingRooms = false;
      }
      if (res['success'] == true && res['rooms'] is List) {
        _publicRooms = (res['rooms'] as List)
            .whereType<Map>()
            .map((e) =>
                BoardgameCalcRoomSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      notifyListeners();
    });
  }

  void _syncOfflineRoom(BoardgameCalcRoom nextRoom,
      {BoardgameCalcLog? log, BoardgameCalcPlayer? overrideMe}) {
    final currentMe = overrideMe ?? _me;
    BoardgameCalcPlayer? matchedMe;
    if (currentMe != null) {
      matchedMe = nextRoom.players.cast<BoardgameCalcPlayer?>().firstWhere(
            (p) => p?.id == currentMe.id || p?.sessionId == currentMe.sessionId,
            orElse: () => null,
          );
    }
    matchedMe ??=
        nextRoom.players.isNotEmpty ? nextRoom.players.first : null;
    _me = matchedMe;
    _room = matchedMe != null
        ? _localEngine.getSanitizedRoomForPlayer(
            nextRoom,
            playerId: matchedMe.id,
            sessionId: matchedMe.sessionId,
          )
        : nextRoom;
    _publicRooms = _localEngine.getPublicRooms();

    if (matchedMe != null) {
      final pending = _localEngine.getPendingTransfersForPlayer(
        nextRoom.roomCode,
        matchedMe.id,
        matchedMe.sessionId,
      );
      _pendingConsentRequest = pending.isNotEmpty ? pending.first : null;
    }

    if (log != null) {
      _playSoundForLog(log);
    }
    _persistOfflineState();
    notifyListeners();
  }

  void _runOffline(void Function() action) {
    try {
      action();
    } on BoardgameEngineException catch (e) {
      setError(e.message);
      if (e.isConflict) {
        _showAuctionConflictToast(e.message);
      }
    } catch (e) {
      setError(e.toString());
    }
  }

  void createRoom({
    required String nickname,
    String? title,
    String? avatarColor,
    BoardgameCalcSettings? settings,
  }) {
    final cleanNick = nickname.trim().isNotEmpty ? nickname.trim() : '플레이어1';
    saveProfileDraft(nickname: cleanNick, avatarColor: avatarColor);
    setError(null);

    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final result = _localEngine.createRoom(
          nickname: cleanNick,
          title: title,
          avatarColor: avatarColor ?? _savedAvatarColor,
          settings: settings,
          sessionId: _sessionId,
        );
        _syncOfflineRoom(result.room, overrideMe: result.player);
      });
      return;
    }

    if (!_socket.isConnected) {
      _socket.connect(_serverUrl);
    }
    _socket.createRoom(
      {
        'title': (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : '$cleanNick의 보드게임방',
        'nickname': cleanNick,
        'avatarColor': avatarColor ?? _savedAvatarColor,
        'sessionId': _sessionId,
        if (settings != null) 'settings': settings.toJson(),
      },
      (res) {
        if (res['success'] == true &&
            res['room'] is Map &&
            res['player'] is Map) {
          _room = BoardgameCalcRoom.fromJson(
              Map<String, dynamic>.from(res['room'] as Map));
          _me = BoardgameCalcPlayer.fromJson(
              Map<String, dynamic>.from(res['player'] as Map));
          _prefs?.setString(_keyRoomCode, _room!.roomCode);
          _prefs?.setString(_keyNickname, _me!.nickname);
          setError(null);
        } else if (res['success'] == false) {
          setError(res['error'] as String? ?? '방 생성에 실패했습니다.');
          fetchPublicRooms();
        }
        notifyListeners();
      },
    );
  }

  void joinRoom({
    required String roomCode,
    required String nickname,
    String? avatarColor,
  }) {
    final cleanNick = nickname.trim().isNotEmpty ? nickname.trim() : '플레이어';
    saveProfileDraft(nickname: cleanNick, avatarColor: avatarColor);
    setError(null);

    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final result = _localEngine.joinRoom(
          roomCode: roomCode,
          nickname: cleanNick,
          avatarColor: avatarColor,
          sessionId: _sessionId,
        );
        _syncOfflineRoom(result.room, overrideMe: result.player);
      });
      return;
    }

    if (!_socket.isConnected) {
      _socket.connect(_serverUrl);
    }
    _socket.joinRoom(
      {
        'roomCode': roomCode.trim().toUpperCase(),
        'nickname': cleanNick,
        'avatarColor': ?avatarColor,
        'sessionId': _sessionId,
      },
      (res) {
        if (res['success'] == true &&
            res['room'] is Map &&
            res['player'] is Map) {
          _room = BoardgameCalcRoom.fromJson(
              Map<String, dynamic>.from(res['room'] as Map));
          _me = BoardgameCalcPlayer.fromJson(
              Map<String, dynamic>.from(res['player'] as Map));
          _prefs?.setString(_keyRoomCode, _room!.roomCode);
          _prefs?.setString(_keyNickname, _me!.nickname);
          setError(null);
        } else if (res['success'] == false) {
          setError(res['error'] as String? ?? '방 입장에 실패했습니다.');
          _prefs?.remove(_keyRoomCode);
          fetchPublicRooms();
        }
        notifyListeners();
      },
    );
  }

  /// 오프라인 모드 전용: 같은 방에 로컬 플레이어 추가 (Pass & Play)
  void addLocalPlayer(String nickname, {String? avatarColor}) {
    if (_mode != ConnectionMode.offline || _room == null) return;
    final cleanNick = nickname.trim();
    if (cleanNick.isEmpty) {
      setError('추가할 플레이어 닉네임을 입력해주세요.');
      return;
    }
    _runOffline(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      final res = _localEngine.joinRoom(
        roomCode: _room!.roomCode,
        nickname: cleanNick,
        avatarColor: avatarColor,
        sessionId: 'local_sess_${now}_${Random().nextInt(9999)}',
        socketId: 'local_sock_${now}_${Random().nextInt(9999)}',
      );
      // 방장 시점 유지
      _syncOfflineRoom(res.room, overrideMe: _me);
    });
  }

  /// 오프라인 모드 전용: 현재 조작 시점 플레이어 전환 (Pass & Play)
  void switchActiveLocalPlayer(BoardgameCalcPlayer target) {
    if (_mode != ConnectionMode.offline || _room == null) return;
    final rawRoom = _localEngine.getRoom(_room!.roomCode);
    if (rawRoom == null) return;
    BoardgameAudio.playTab();
    _syncOfflineRoom(rawRoom, overrideMe: target);
  }

  void leaveRoom() {
    final code = _room?.roomCode;
    if (_mode == ConnectionMode.online && code != null && _socket.isConnected) {
      _socket.leaveRoom(code);
    }
    _room = null;
    _me = null;
    _pendingConsentRequest = null;
    _sentTransferRequest = null;
    _prefs?.remove(_keyRoomCode);
    _persistOfflineState();
    fetchPublicRooms();
    notifyListeners();
  }

  void deleteRoom(
    String roomCode, {
    void Function(Map<String, dynamic> res)? callback,
  }) {
    final targetCode = roomCode.trim().toUpperCase();
    if (_mode == ConnectionMode.offline) {
      try {
        _localEngine.deleteRoom(
          targetCode,
          actorId: _me?.id ?? _sessionId,
        );
        if (_room?.roomCode.toUpperCase() == targetCode) {
          _room = null;
          _me = null;
          _pendingConsentRequest = null;
          _sentTransferRequest = null;
        }
        _publicRooms = _localEngine.getPublicRooms();
        _persistOfflineState();
        notifyListeners();
        callback?.call({'success': true, 'roomCode': targetCode});
      } on BoardgameEngineException catch (e) {
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }

    _socket.deleteRoom(
      {
        'roomCode': targetCode,
        'sessionId': _me?.sessionId ?? _sessionId,
      },
      (res) {
        if (res['success'] == true ||
            (res['error'] as String?)?.contains('찾을 수 없습니다') == true) {
          if (_room?.roomCode.toUpperCase() == targetCode) {
            _room = null;
            _me = null;
            _prefs?.remove(_keyRoomCode);
          }
          fetchPublicRooms();
        }
        callback?.call(res);
        notifyListeners();
      },
    );
  }

  void adjustPoints(
    String targetPlayerId,
    int delta, {
    String? reason,
    int? unitValue,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.adjustPoints(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          targetPlayerId: targetPlayerId,
          delta: delta,
          reason: reason,
          unitValue: unitValue,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.adjustPoints({
      'roomCode': _room!.roomCode,
      'targetPlayerId': targetPlayerId,
      'delta': delta,
      'reason': ?reason,
      'unitValue': ?unitValue,
    });
  }

  void adjustScore(
    String targetPlayerId,
    int delta, {
    String? reason,
    int? unitValue,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.adjustScore(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          targetPlayerId: targetPlayerId,
          delta: delta,
          reason: reason,
          unitValue: unitValue,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.adjustScore({
      'roomCode': _room!.roomCode,
      'targetPlayerId': targetPlayerId,
      'delta': delta,
      'reason': ?reason,
      'unitValue': ?unitValue,
    });
  }

  void requestTransfer(String toPlayerId, int amount, {String? memo}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.requestTransfer(
          roomCode: _room!.roomCode,
          fromActorId: _me!.id,
          toPlayerId: toPlayerId,
          amount: amount,
          memo: memo,
        );
        _sentTransferRequest = res.transferRequest;
        _showTransferToast(
          "'${res.toPlayer!.nickname}'님에게 ${formatCommaNumber(amount)} 송금 요청을 보냈습니다. (수신자 시점 전환 시 수락 모달이 표시됩니다)",
          isWarn: false,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.requestTransfer({
      'roomCode': _room!.roomCode,
      'toPlayerId': toPlayerId,
      'amount': amount,
      if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
    });
  }

  void respondTransfer(String requestId, bool accept) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.respondTransfer(
          roomCode: _room!.roomCode,
          requestId: requestId,
          actorId: _me!.id,
          accept: accept,
        );
        _pendingConsentRequest = null;
        _sentTransferRequest = null;
        _showTransferToast(
          accept
              ? "'${res.fromPlayer!.nickname}'님의 ${formatCommaNumber(res.transferRequest!.amount)} 송금을 수락했습니다!"
              : "'${res.fromPlayer!.nickname}'님의 송금 요청을 거절했습니다.",
          isWarn: !accept,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.respondTransfer({
      'roomCode': _room!.roomCode,
      'requestId': requestId,
      'accept': accept,
    });
    _pendingConsentRequest = null;
    notifyListeners();
  }

  void startAuction({String? title, int? minIncrement, int? timeLimit}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.startAuction(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          title: title,
          minIncrement: minIncrement,
          timeLimit: timeLimit,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.startAuction({
      'roomCode': _room!.roomCode,
      'title': ?title,
      'minIncrement': ?minIncrement,
      'timeLimit': ?timeLimit,
    });
  }

  void placeBid(
    int amount, {
    int? expectedHighestBid,
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.placeBid(
          roomCode: _room!.roomCode,
          bidderActorId: _me!.id,
          bidAmount: amount,
          expectedHighestBid: expectedHighestBid,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        if (e.isConflict) _showAuctionConflictToast(e.message);
        callback?.call({
          'success': false,
          'error': e.message,
          'isConflict': e.isConflict,
        });
      }
      return;
    }
    _socket.placeBid(
      {
        'roomCode': _room!.roomCode,
        'bidAmount': amount,
        'expectedHighestBid': ?expectedHighestBid,
      },
      (res) {
        if (res['success'] == false && res['error'] != null) {
          final msg = res['error'] as String;
          setError(msg);
          if (res['isConflict'] == true) {
            _showAuctionConflictToast(msg);
          }
        }
        callback?.call(res);
      },
    );
  }

  void designateAuctionWinner({
    String? winnerId,
    String potAction = 'burn_pot',
    int? expectedHighestBid,
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.designateAuctionWinner(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          winnerId: winnerId,
          potAction: potAction,
          expectedHighestBid: expectedHighestBid,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        if (e.isConflict) _showAuctionConflictToast(e.message);
        callback?.call({
          'success': false,
          'error': e.message,
          'isConflict': e.isConflict,
        });
      }
      return;
    }
    _socket.designateAuctionWinner(
      {
        'roomCode': _room!.roomCode,
        'winnerId': ?winnerId,
        'potAction': potAction,
        'expectedHighestBid': ?expectedHighestBid,
      },
      (res) {
        if (res['success'] == false && res['error'] != null) {
          final msg = res['error'] as String;
          setError(msg);
          if (res['isConflict'] == true) {
            _showAuctionConflictToast(msg);
          }
        }
        callback?.call(res);
      },
    );
  }

  void resetAuction() {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.resetAuction(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.resetAuction(_room!.roomCode);
  }

  void placeBet(
    int amount, {
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.placeBet(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          amount: amount,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.placeBet(
      {'roomCode': _room!.roomCode, 'amount': amount},
      (res) {
        if (res['success'] == false && res['error'] != null) {
          setError(res['error'] as String);
        }
        callback?.call(res);
      },
    );
  }

  void resolveBettingWinner(
    String winnerId, {
    String action = 'transfer',
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.resolveBettingWinner(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          winnerId: winnerId,
          action: action,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.resolveBettingWinner(
      {
        'roomCode': _room!.roomCode,
        'winnerId': winnerId,
        'action': action,
      },
      (res) {
        if (res['success'] == false && res['error'] != null) {
          setError(res['error'] as String);
        }
        callback?.call(res);
      },
    );
  }

  void resetBettingPot({void Function(Map<String, dynamic> res)? callback}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.resetBettingPot(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.resetBettingPot(_room!.roomCode, (res) {
      if (res['success'] == false && res['error'] != null) {
        setError(res['error'] as String);
      }
      callback?.call(res);
    });
  }

  void updateSettings(BoardgameCalcSettings nextSettings) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.updateSettings(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          nextSettings: nextSettings,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.updateSettings(_room!.roomCode, nextSettings.toJson());
  }

  void resetPoints({int? customAmount}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.resetAllPoints(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          customAmount: customAmount,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.resetPoints(_room!.roomCode, customAmount: customAmount);
  }

  void resetScores({int? customScore}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.resetAllScores(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          customScore: customScore,
        );
        _syncOfflineRoom(res.room, log: res.log);
      });
      return;
    }
    _socket.resetScores(_room!.roomCode, customScore: customScore);
  }

  void renamePlayer(
    String targetPlayerId,
    String newNickname, {
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.renamePlayer(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          targetPlayerId: targetPlayerId,
          newNickname: newNickname,
        );
        if (res.player?.id == _me?.id) {
          saveProfileDraft(nickname: res.player!.nickname);
        }
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.renamePlayer(
      {
        'roomCode': _room!.roomCode,
        'targetPlayerId': targetPlayerId,
        'newNickname': newNickname,
      },
      (res) {
        if (res['success'] == false && res['error'] != null) {
          setError(res['error'] as String);
        }
        callback?.call(res);
      },
    );
  }

  void updatePlayerColor(String avatarColor, {String? targetPlayerId}) {
    if (_room == null) return;
    if (targetPlayerId == null || targetPlayerId == _me?.id) {
      saveProfileDraft(avatarColor: avatarColor);
    }
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.updatePlayerColor(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          targetPlayerId: targetPlayerId,
          avatarColor: avatarColor,
        );
        _syncOfflineRoom(res.room);
      });
      return;
    }
    _socket.updateColor(_room!.roomCode, avatarColor);
  }

  void setCenterTool(CenterToolType tool) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      _runOffline(() {
        final res = _localEngine.setCenterTool(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          tool: tool,
        );
        _syncOfflineRoom(res.room);
      });
      return;
    }
    _socket.setCenterTool(_room!.roomCode, tool);
  }

  void rollDice(
    int count,
    int sides, {
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.rollDice(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          count: count,
          sides: sides,
        );
        if (res.diceState != null) {
          _showDiceToast(res.diceState!);
        }
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({
          'success': true,
          'diceState': res.diceState?.toJson(),
        });
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.rollDice(_room!.roomCode, count, sides, callback);
  }

  void startSecretNote({
    int? timeLimit,
    String? title,
    bool? autoReveal,
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.startSecretNote(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          timeLimit: timeLimit,
          title: title,
          autoReveal: autoReveal,
          onTimerExpire: (expiredRoom) {
            _playSecretSoundDeduped(
              expiredRoom.secretNote?.isRevealed == true ? 'reveal' : 'lock',
            );
            _syncOfflineRoom(expiredRoom);
          },
        );
        _playSecretSoundDeduped('fold');
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.startSecretNote(
      {
        'roomCode': _room!.roomCode,
        'timeLimit': ?timeLimit,
        'title': ?title,
        'autoReveal': ?autoReveal,
      },
      callback,
    );
  }

  void updateSecretNote(
    String content, {
    bool? isFolded,
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.updateSecretNote(
          roomCode: _room!.roomCode,
          actorId: _me!.id,
          content: content,
          isFolded: isFolded,
        );
        _syncOfflineRoom(res.room);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.updateSecretNote(
      {
        'roomCode': _room!.roomCode,
        'content': content,
        'isFolded': ?isFolded,
      },
      callback,
    );
  }

  void lockSecretNote({void Function(Map<String, dynamic> res)? callback}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.lockSecretNote(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
        );
        _playSecretSoundDeduped('lock');
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.lockSecretNote(_room!.roomCode, callback);
  }

  void revealSecretNote({void Function(Map<String, dynamic> res)? callback}) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.revealSecretNote(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
        );
        _playSecretSoundDeduped('reveal');
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.revealSecretNote(_room!.roomCode, callback);
  }

  void resetSecretNote({
    int? timeLimit,
    String? title,
    bool? autoReveal,
    void Function(Map<String, dynamic> res)? callback,
  }) {
    if (_room == null) return;
    if (_mode == ConnectionMode.offline) {
      try {
        final res = _localEngine.resetSecretNote(
          roomCode: _room!.roomCode,
          hostActorId: _me!.id,
          timeLimit: timeLimit,
          title: title,
          autoReveal: autoReveal,
        );
        _syncOfflineRoom(res.room, log: res.log);
        callback?.call({'success': true});
      } on BoardgameEngineException catch (e) {
        setError(e.message);
        callback?.call({'success': false, 'error': e.message});
      }
      return;
    }
    _socket.resetSecretNote(
      {
        'roomCode': _room!.roomCode,
        'timeLimit': ?timeLimit,
        'title': ?title,
        'autoReveal': ?autoReveal,
      },
      callback,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _diceToastTimer?.cancel();
    _transferToastTimer?.cancel();
    _conflictToastTimer?.cancel();
    _errorTimer?.cancel();
    _localEngine.dispose();
    _socket.disconnect();
    unawaited(_bgmPlayer.dispose());
    super.dispose();
  }
}
