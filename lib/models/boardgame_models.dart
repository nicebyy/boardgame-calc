import 'package:intl/intl.dart';

enum PermissionMode {
  all('all'),
  hostOnly('host_only');

  const PermissionMode(this.wireValue);
  final String wireValue;

  static PermissionMode fromWire(String? value) {
    return value == 'host_only' ? PermissionMode.hostOnly : PermissionMode.all;
  }
}

enum ScoreDisplayMode {
  all('all'),
  currency('currency'),
  score('score');

  const ScoreDisplayMode(this.wireValue);
  final String wireValue;

  static ScoreDisplayMode fromWire(String? value) {
    switch (value) {
      case 'currency':
        return ScoreDisplayMode.currency;
      case 'score':
        return ScoreDisplayMode.score;
      default:
        return ScoreDisplayMode.all;
    }
  }
}

enum TopPlayersViewMode {
  card('card'),
  list('list');

  const TopPlayersViewMode(this.wireValue);
  final String wireValue;

  static TopPlayersViewMode fromWire(String? value) {
    return value == 'list' ? TopPlayersViewMode.list : TopPlayersViewMode.card;
  }
}

enum TopPlayersSortOption {
  defaultOrder('default', '기본 순서', '기본순'),
  pointsDesc('points_desc', '화폐 많은 순 (내림차순)', '화폐 ↓'),
  pointsAsc('points_asc', '화폐 적은 순 (오름차순)', '화폐 ↑'),
  scoreDesc('score_desc', '점수 높은 순 (내림차순)', '점수 ↓'),
  scoreAsc('score_asc', '점수 낮은 순 (오름차순)', '점수 ↑');

  const TopPlayersSortOption(this.wireValue, this.label, this.shortLabel);
  final String wireValue;
  final String label;
  final String shortLabel;

  static TopPlayersSortOption fromWire(String? value) {
    for (final opt in TopPlayersSortOption.values) {
      if (opt.wireValue == value) return opt;
    }
    return TopPlayersSortOption.defaultOrder;
  }
}

enum CenterToolType {
  empty('empty'),
  dice('dice'),
  betting('betting'),
  auction('auction'),
  secretNote('secret_note');

  const CenterToolType(this.wireValue);
  final String wireValue;

  static CenterToolType fromWire(String? value) {
    switch (value) {
      case 'dice':
        return CenterToolType.dice;
      case 'betting':
        return CenterToolType.betting;
      case 'auction':
        return CenterToolType.auction;
      case 'secret_note':
        return CenterToolType.secretNote;
      default:
        return CenterToolType.empty;
    }
  }
}

enum LogType {
  join('join'),
  leave('leave'),
  adjust('adjust'),
  scoreAdjust('score_adjust'),
  rename('rename'),
  transfer('transfer'),
  transferRequest('transfer_request'),
  transferRejected('transfer_rejected'),
  auctionStart('auction_start'),
  auctionBid('auction_bid'),
  auctionWin('auction_win'),
  auctionReset('auction_reset'),
  bettingBet('betting_bet'),
  bettingWin('betting_win'),
  bettingReset('betting_reset'),
  reset('reset'),
  setting('setting'),
  dice('dice'),
  secretNote('secret_note');

  const LogType(this.wireValue);
  final String wireValue;

  static LogType fromWire(String? value) {
    for (final t in LogType.values) {
      if (t.wireValue == value) return t;
    }
    return LogType.setting;
  }
}

enum LogFilterCategory {
  all('all', '전체'),
  currency('currency', '화폐(포인트)'),
  score('score', '승점'),
  auction('auction', '경매'),
  betting('betting', '배팅'),
  dice('dice', '주사위'),
  secretNote('secret_note', '비밀노트'),
  system('system', '기타/설정');

  const LogFilterCategory(this.wireValue, this.label);
  final String wireValue;
  final String label;
}

class BoardgameCalcConstants {
  BoardgameCalcConstants._();

  static const int maxNicknameLength = 15;
  static const int maxSafeAmount = 1000000000000;
  static const String defaultServerUrl = 'https://1234banpick.me';
  static const String defaultCurrencyUnit = '원';
  static const String defaultScoreUnit = '점';
  static const int defaultInitialPoints = 1000;
  static const List<int> defaultQuickTransferUnits = [100, 500, 1000];
  static const List<int> defaultScoreQuickUnits = [1, 2, 5, 10, 20];
  static const int diceMinCount = 1;
  static const int diceMaxCount = 12;
  static const int diceMinSides = 2;
  static const int diceMaxSides = 1000;
  static const int auctionDefaultTimeLimit = 30;
  static const int auctionDefaultMinBid = 100;
  static const int auctionDefaultExtendSeconds = 20;
  static const int secretNoteDefaultTimeLimit = 60;
}

final NumberFormat _commaFormatter = NumberFormat('#,##0', 'en_US');
final NumberFormat _decimalFormatter = NumberFormat('#,##0.#', 'en_US');

String formatCommaNumber(num? value) {
  if (value == null || !value.isFinite) return '0';
  return _commaFormatter.format(value.truncate());
}

/// 1만(10,000) 이상인 경우 k 단위로 자동 변환 (원본 formatCompactNumber 1:1 호환)
String formatCompactNumber(num? value) {
  if (value == null || !value.isFinite) return '0';
  final doubleVal = value.toDouble();
  final abs = doubleVal.abs();
  if (abs >= 10000) {
    final inK = abs / 1000.0;
    final roundedOne = double.parse(inK.toStringAsFixed(1));
    final formatted = (inK % 1 == 0 || roundedOne % 1 == 0)
        ? _commaFormatter.format(roundedOne.truncate())
        : _decimalFormatter.format(roundedOne);
    return '${doubleVal < 0 ? '-' : ''}${formatted}k';
  }
  return _commaFormatter.format(doubleVal.truncate());
}

String formatCompactSignedNumber(num? value) {
  if (value == null || !value.isFinite) return '0';
  final formatted = formatCompactNumber(value.abs());
  return '${value >= 0 ? '+' : '-'}$formatted';
}

class BoardgameCalcDenomination {
  const BoardgameCalcDenomination({
    required this.value,
    this.maxCount,
    this.remainingCount,
  });

  final int value;
  final int? maxCount;
  final int? remainingCount;

  bool get isDepleted =>
      maxCount != null && maxCount! > 0 && (remainingCount ?? 0) <= 0;

  BoardgameCalcDenomination copyWith({
    int? value,
    int? maxCount,
    bool clearMaxCount = false,
    int? remainingCount,
    bool clearRemainingCount = false,
  }) {
    return BoardgameCalcDenomination(
      value: value ?? this.value,
      maxCount: clearMaxCount ? null : (maxCount ?? this.maxCount),
      remainingCount:
          clearRemainingCount ? null : (remainingCount ?? this.remainingCount),
    );
  }

  factory BoardgameCalcDenomination.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcDenomination(
      value: (json['value'] as num?)?.toInt() ?? 0,
      maxCount: (json['maxCount'] as num?)?.toInt(),
      remainingCount: (json['remainingCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'maxCount': maxCount,
      'remainingCount': remainingCount,
    };
  }
}

class BoardgameCalcSettings {
  const BoardgameCalcSettings({
    this.currencyUnit = BoardgameCalcConstants.defaultCurrencyUnit,
    this.initialPoints = BoardgameCalcConstants.defaultInitialPoints,
    this.permissionMode = PermissionMode.all,
    this.scorePermissionMode,
    this.allowP2P = true,
    this.enableAuction = true,
    this.quickAdjustUnits = const [],
    this.currencyDenominations = const [],
    this.enableScore = true,
    this.scoreUnit = BoardgameCalcConstants.defaultScoreUnit,
    this.initialScore = 0,
    this.scoreDisplayMode,
    this.auctionTimeLimit = BoardgameCalcConstants.auctionDefaultTimeLimit,
    this.auctionMinBid = BoardgameCalcConstants.auctionDefaultMinBid,
    this.auctionExtendSeconds =
        BoardgameCalcConstants.auctionDefaultExtendSeconds,
    this.scoreDenominations = const [],
    this.secretNoteTimeLimit =
        BoardgameCalcConstants.secretNoteDefaultTimeLimit,
    this.secretNoteAutoReveal = true,
  });

  final String currencyUnit;
  final int initialPoints;
  final PermissionMode permissionMode;
  final PermissionMode? scorePermissionMode;
  final bool allowP2P;
  final bool enableAuction;
  final List<int> quickAdjustUnits;
  final List<BoardgameCalcDenomination> currencyDenominations;
  final bool enableScore;
  final String scoreUnit;
  final int initialScore;
  final ScoreDisplayMode? scoreDisplayMode;
  final int auctionTimeLimit;
  final int auctionMinBid;
  final int auctionExtendSeconds;
  final List<BoardgameCalcDenomination> scoreDenominations;
  final int secretNoteTimeLimit;
  final bool secretNoteAutoReveal;

  ScoreDisplayMode get resolvedDisplayMode {
    if (scoreDisplayMode != null) return scoreDisplayMode!;
    if (!enableScore) return ScoreDisplayMode.currency;
    return ScoreDisplayMode.all;
  }

  PermissionMode get resolvedScorePermissionMode =>
      scorePermissionMode ?? permissionMode;

  List<BoardgameCalcDenomination> get effectiveCurrencyDenoms {
    if (currencyDenominations.isNotEmpty) return currencyDenominations;
    return quickAdjustUnits
        .map((v) => BoardgameCalcDenomination(value: v))
        .toList();
  }

  BoardgameCalcSettings copyWith({
    String? currencyUnit,
    int? initialPoints,
    PermissionMode? permissionMode,
    PermissionMode? scorePermissionMode,
    bool? allowP2P,
    bool? enableAuction,
    List<int>? quickAdjustUnits,
    List<BoardgameCalcDenomination>? currencyDenominations,
    bool? enableScore,
    String? scoreUnit,
    int? initialScore,
    ScoreDisplayMode? scoreDisplayMode,
    int? auctionTimeLimit,
    int? auctionMinBid,
    int? auctionExtendSeconds,
    List<BoardgameCalcDenomination>? scoreDenominations,
    int? secretNoteTimeLimit,
    bool? secretNoteAutoReveal,
  }) {
    return BoardgameCalcSettings(
      currencyUnit: currencyUnit ?? this.currencyUnit,
      initialPoints: initialPoints ?? this.initialPoints,
      permissionMode: permissionMode ?? this.permissionMode,
      scorePermissionMode: scorePermissionMode ?? this.scorePermissionMode,
      allowP2P: allowP2P ?? this.allowP2P,
      enableAuction: enableAuction ?? this.enableAuction,
      quickAdjustUnits: quickAdjustUnits ?? this.quickAdjustUnits,
      currencyDenominations:
          currencyDenominations ?? this.currencyDenominations,
      enableScore: enableScore ?? this.enableScore,
      scoreUnit: scoreUnit ?? this.scoreUnit,
      initialScore: initialScore ?? this.initialScore,
      scoreDisplayMode: scoreDisplayMode ?? this.scoreDisplayMode,
      auctionTimeLimit: auctionTimeLimit ?? this.auctionTimeLimit,
      auctionMinBid: auctionMinBid ?? this.auctionMinBid,
      auctionExtendSeconds: auctionExtendSeconds ?? this.auctionExtendSeconds,
      scoreDenominations: scoreDenominations ?? this.scoreDenominations,
      secretNoteTimeLimit: secretNoteTimeLimit ?? this.secretNoteTimeLimit,
      secretNoteAutoReveal: secretNoteAutoReveal ?? this.secretNoteAutoReveal,
    );
  }

  factory BoardgameCalcSettings.fromJson(Map<String, dynamic> json) {
    final quickUnitsRaw = (json['quickAdjustUnits'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        [];
    final currencyDenomsRaw = (json['currencyDenominations'] as List<dynamic>?)
            ?.map((e) =>
                BoardgameCalcDenomination.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final scoreDenomsRaw = (json['scoreDenominations'] as List<dynamic>?)
            ?.map((e) =>
                BoardgameCalcDenomination.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return BoardgameCalcSettings(
      currencyUnit: (json['currencyUnit'] as String?)?.trim().isNotEmpty == true
          ? (json['currencyUnit'] as String).trim()
          : BoardgameCalcConstants.defaultCurrencyUnit,
      initialPoints: (json['initialPoints'] as num?)?.toInt() ??
          BoardgameCalcConstants.defaultInitialPoints,
      permissionMode: PermissionMode.fromWire(json['permissionMode'] as String?),
      scorePermissionMode: json['scorePermissionMode'] != null
          ? PermissionMode.fromWire(json['scorePermissionMode'] as String?)
          : null,
      allowP2P: json['allowP2P'] as bool? ?? true,
      enableAuction: json['enableAuction'] as bool? ?? true,
      quickAdjustUnits: quickUnitsRaw,
      currencyDenominations: currencyDenomsRaw.isNotEmpty
          ? currencyDenomsRaw
          : quickUnitsRaw
              .map((v) => BoardgameCalcDenomination(value: v))
              .toList(),
      enableScore: json['enableScore'] as bool? ?? true,
      scoreUnit: (json['scoreUnit'] as String?)?.trim().isNotEmpty == true
          ? (json['scoreUnit'] as String).trim()
          : BoardgameCalcConstants.defaultScoreUnit,
      initialScore: (json['initialScore'] as num?)?.toInt() ?? 0,
      scoreDisplayMode: json['scoreDisplayMode'] != null
          ? ScoreDisplayMode.fromWire(json['scoreDisplayMode'] as String?)
          : null,
      auctionTimeLimit: (json['auctionTimeLimit'] as num?)?.toInt() ??
          BoardgameCalcConstants.auctionDefaultTimeLimit,
      auctionMinBid: (json['auctionMinBid'] as num?)?.toInt() ??
          BoardgameCalcConstants.auctionDefaultMinBid,
      auctionExtendSeconds: (json['auctionExtendSeconds'] as num?)?.toInt() ??
          BoardgameCalcConstants.auctionDefaultExtendSeconds,
      scoreDenominations: scoreDenomsRaw,
      secretNoteTimeLimit: (json['secretNoteTimeLimit'] as num?)?.toInt() ??
          BoardgameCalcConstants.secretNoteDefaultTimeLimit,
      secretNoteAutoReveal: json['secretNoteAutoReveal'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencyUnit': currencyUnit,
      'initialPoints': initialPoints,
      'permissionMode': permissionMode.wireValue,
      if (scorePermissionMode != null)
        'scorePermissionMode': scorePermissionMode!.wireValue,
      'allowP2P': allowP2P,
      'enableAuction': enableAuction,
      'quickAdjustUnits': quickAdjustUnits,
      'currencyDenominations':
          currencyDenominations.map((e) => e.toJson()).toList(),
      'enableScore': enableScore,
      'scoreUnit': scoreUnit,
      'initialScore': initialScore,
      if (scoreDisplayMode != null)
        'scoreDisplayMode': scoreDisplayMode!.wireValue,
      'auctionTimeLimit': auctionTimeLimit,
      'auctionMinBid': auctionMinBid,
      'auctionExtendSeconds': auctionExtendSeconds,
      'scoreDenominations': scoreDenominations.map((e) => e.toJson()).toList(),
      'secretNoteTimeLimit': secretNoteTimeLimit,
      'secretNoteAutoReveal': secretNoteAutoReveal,
    };
  }
}

class BoardgameCalcPlayer {
  const BoardgameCalcPlayer({
    required this.id,
    required this.sessionId,
    required this.nickname,
    required this.avatarColor,
    this.avatarUrl,
    this.userId,
    this.points = 0,
    this.score = 0,
    this.isHost = false,
    this.isOnline = true,
    required this.joinedAt,
  });

  final String id;
  final String sessionId;
  final String nickname;
  final String avatarColor;
  final String? avatarUrl;
  final String? userId;
  final int points;
  final int score;
  final bool isHost;
  final bool isOnline;
  final int joinedAt;

  bool matchesIdentity({String? myId, String? mySessionId}) {
    if (myId != null && myId.isNotEmpty && id == myId) return true;
    if (mySessionId != null &&
        mySessionId.isNotEmpty &&
        sessionId == mySessionId) {
      return true;
    }
    return false;
  }

  BoardgameCalcPlayer copyWith({
    String? id,
    String? sessionId,
    String? nickname,
    String? avatarColor,
    String? avatarUrl,
    String? userId,
    int? points,
    int? score,
    bool? isHost,
    bool? isOnline,
    int? joinedAt,
  }) {
    return BoardgameCalcPlayer(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
      isOnline: isOnline ?? this.isOnline,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory BoardgameCalcPlayer.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcPlayer(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '플레이어',
      avatarColor: json['avatarColor'] as String? ?? '#3b82f6',
      avatarUrl: json['avatarUrl'] as String?,
      userId: json['userId'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      isHost: json['isHost'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? true,
      joinedAt: (json['joinedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'nickname': nickname,
      'avatarColor': avatarColor,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (userId != null) 'userId': userId,
      'points': points,
      'score': score,
      'isHost': isHost,
      'isOnline': isOnline,
      'joinedAt': joinedAt,
    };
  }
}

class BoardgameCalcLog {
  const BoardgameCalcLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.actorName,
    this.targetName,
    this.amount,
    required this.description,
  });

  final String id;
  final int timestamp;
  final LogType type;
  final String actorName;
  final String? targetName;
  final int? amount;
  final String description;

  bool matchesCategory(LogFilterCategory category) {
    switch (category) {
      case LogFilterCategory.all:
        return true;
      case LogFilterCategory.currency:
        return type == LogType.adjust ||
            type == LogType.transfer ||
            type == LogType.transferRequest ||
            type == LogType.transferRejected;
      case LogFilterCategory.score:
        return type == LogType.scoreAdjust;
      case LogFilterCategory.auction:
        return type == LogType.auctionStart ||
            type == LogType.auctionBid ||
            type == LogType.auctionWin ||
            type == LogType.auctionReset;
      case LogFilterCategory.betting:
        return type == LogType.bettingBet ||
            type == LogType.bettingWin ||
            type == LogType.bettingReset;
      case LogFilterCategory.dice:
        return type == LogType.dice;
      case LogFilterCategory.secretNote:
        return type == LogType.secretNote;
      case LogFilterCategory.system:
        return type == LogType.setting ||
            type == LogType.reset ||
            type == LogType.rename;
    }
  }

  factory BoardgameCalcLog.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcLog(
      id: json['id'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      type: LogType.fromWire(json['type'] as String?),
      actorName: json['actorName'] as String? ?? '',
      targetName: json['targetName'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'type': type.wireValue,
      'actorName': actorName,
      if (targetName != null) 'targetName': targetName,
      if (amount != null) 'amount': amount,
      'description': description,
    };
  }
}

class AuctionWinner {
  const AuctionWinner({
    required this.id,
    required this.name,
    required this.amount,
    required this.pot,
  });

  final String id;
  final String name;
  final int amount;
  final int pot;

  factory AuctionWinner.fromJson(Map<String, dynamic> json) {
    return AuctionWinner(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      pot: (json['pot'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'pot': pot,
      };
}

class BoardgameCalcAuction {
  const BoardgameCalcAuction({
    this.isActive = false,
    this.title = '일반 경매',
    this.currentPot = 0,
    this.highestBid = 0,
    this.highestBidderId,
    this.highestBidderSessionId,
    this.highestBidderName,
    this.highestBidderAvatarUrl,
    this.highestBidderAvatarColor,
    this.minIncrement = 100,
    this.round = 0,
    this.timeLimit,
    this.endsAt,
    this.winner,
  });

  final bool isActive;
  final String title;
  final int currentPot;
  final int highestBid;
  final String? highestBidderId;
  final String? highestBidderSessionId;
  final String? highestBidderName;
  final String? highestBidderAvatarUrl;
  final String? highestBidderAvatarColor;
  final int minIncrement;
  final int round;
  final int? timeLimit;
  final int? endsAt;
  final AuctionWinner? winner;

  BoardgameCalcAuction copyWith({
    bool? isActive,
    String? title,
    int? currentPot,
    int? highestBid,
    String? highestBidderId,
    bool clearHighestBidder = false,
    String? highestBidderSessionId,
    String? highestBidderName,
    String? highestBidderAvatarUrl,
    String? highestBidderAvatarColor,
    int? minIncrement,
    int? round,
    int? timeLimit,
    bool clearTiming = false,
    int? endsAt,
    AuctionWinner? winner,
    bool clearWinner = false,
  }) {
    return BoardgameCalcAuction(
      isActive: isActive ?? this.isActive,
      title: title ?? this.title,
      currentPot: currentPot ?? this.currentPot,
      highestBid: highestBid ?? this.highestBid,
      highestBidderId:
          clearHighestBidder ? null : (highestBidderId ?? this.highestBidderId),
      highestBidderSessionId: clearHighestBidder
          ? null
          : (highestBidderSessionId ?? this.highestBidderSessionId),
      highestBidderName: clearHighestBidder
          ? null
          : (highestBidderName ?? this.highestBidderName),
      highestBidderAvatarUrl: clearHighestBidder
          ? null
          : (highestBidderAvatarUrl ?? this.highestBidderAvatarUrl),
      highestBidderAvatarColor: clearHighestBidder
          ? null
          : (highestBidderAvatarColor ?? this.highestBidderAvatarColor),
      minIncrement: minIncrement ?? this.minIncrement,
      round: round ?? this.round,
      timeLimit: clearTiming ? null : (timeLimit ?? this.timeLimit),
      endsAt: clearTiming ? null : (endsAt ?? this.endsAt),
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  factory BoardgameCalcAuction.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcAuction(
      isActive: json['isActive'] as bool? ?? false,
      title: json['title'] as String? ?? '일반 경매',
      currentPot: (json['currentPot'] as num?)?.toInt() ?? 0,
      highestBid: (json['highestBid'] as num?)?.toInt() ?? 0,
      highestBidderId: json['highestBidderId'] as String?,
      highestBidderSessionId: json['highestBidderSessionId'] as String?,
      highestBidderName: json['highestBidderName'] as String?,
      highestBidderAvatarUrl: json['highestBidderAvatarUrl'] as String?,
      highestBidderAvatarColor: json['highestBidderAvatarColor'] as String?,
      minIncrement: (json['minIncrement'] as num?)?.toInt() ?? 100,
      round: (json['round'] as num?)?.toInt() ?? 0,
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      endsAt: (json['endsAt'] as num?)?.toInt(),
      winner: json['winner'] != null
          ? AuctionWinner.fromJson(Map<String, dynamic>.from(json['winner']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'title': title,
      'currentPot': currentPot,
      'highestBid': highestBid,
      if (highestBidderId != null) 'highestBidderId': highestBidderId,
      if (highestBidderSessionId != null)
        'highestBidderSessionId': highestBidderSessionId,
      if (highestBidderName != null) 'highestBidderName': highestBidderName,
      if (highestBidderAvatarUrl != null)
        'highestBidderAvatarUrl': highestBidderAvatarUrl,
      if (highestBidderAvatarColor != null)
        'highestBidderAvatarColor': highestBidderAvatarColor,
      'minIncrement': minIncrement,
      'round': round,
      if (timeLimit != null) 'timeLimit': timeLimit,
      if (endsAt != null) 'endsAt': endsAt,
      if (winner != null) 'winner': winner!.toJson(),
    };
  }
}

class BoardgameCalcPlayerBet {
  const BoardgameCalcPlayerBet({
    required this.playerId,
    this.sessionId,
    required this.nickname,
    this.avatarColor,
    this.avatarUrl,
    required this.totalAmount,
    required this.lastBetAmount,
    required this.betCount,
    required this.updatedAt,
  });

  final String playerId;
  final String? sessionId;
  final String nickname;
  final String? avatarColor;
  final String? avatarUrl;
  final int totalAmount;
  final int lastBetAmount;
  final int betCount;
  final int updatedAt;

  BoardgameCalcPlayerBet copyWith({
    String? playerId,
    String? sessionId,
    String? nickname,
    String? avatarColor,
    String? avatarUrl,
    int? totalAmount,
    int? lastBetAmount,
    int? betCount,
    int? updatedAt,
  }) {
    return BoardgameCalcPlayerBet(
      playerId: playerId ?? this.playerId,
      sessionId: sessionId ?? this.sessionId,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalAmount: totalAmount ?? this.totalAmount,
      lastBetAmount: lastBetAmount ?? this.lastBetAmount,
      betCount: betCount ?? this.betCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BoardgameCalcPlayerBet.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcPlayerBet(
      playerId: json['playerId'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      nickname: json['nickname'] as String? ?? '플레이어',
      avatarColor: json['avatarColor'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      lastBetAmount: (json['lastBetAmount'] as num?)?.toInt() ?? 0,
      betCount: (json['betCount'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        if (sessionId != null) 'sessionId': sessionId,
        'nickname': nickname,
        if (avatarColor != null) 'avatarColor': avatarColor,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'totalAmount': totalAmount,
        'lastBetAmount': lastBetAmount,
        'betCount': betCount,
        'updatedAt': updatedAt,
      };
}

class BettingLastWinner {
  const BettingLastWinner({
    required this.id,
    required this.name,
    required this.amount,
    this.action,
    this.resolvedAt,
  });

  final String id;
  final String name;
  final int amount;
  final String? action;
  final int? resolvedAt;

  factory BettingLastWinner.fromJson(Map<String, dynamic> json) {
    return BettingLastWinner(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      action: json['action'] as String?,
      resolvedAt: (json['resolvedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        if (action != null) 'action': action,
        if (resolvedAt != null) 'resolvedAt': resolvedAt,
      };
}

class BoardgameCalcBetting {
  const BoardgameCalcBetting({
    this.currentPot = 0,
    this.highestBet = 0,
    this.highestBetterId,
    this.highestBetterName,
    this.playerBets = const {},
    this.lastWinner,
  });

  final int currentPot;
  final int highestBet;
  final String? highestBetterId;
  final String? highestBetterName;
  final Map<String, BoardgameCalcPlayerBet> playerBets;
  final BettingLastWinner? lastWinner;

  BoardgameCalcBetting copyWith({
    int? currentPot,
    int? highestBet,
    String? highestBetterId,
    String? highestBetterName,
    bool clearHighestBetter = false,
    Map<String, BoardgameCalcPlayerBet>? playerBets,
    BettingLastWinner? lastWinner,
  }) {
    return BoardgameCalcBetting(
      currentPot: currentPot ?? this.currentPot,
      highestBet: highestBet ?? this.highestBet,
      highestBetterId:
          clearHighestBetter ? null : (highestBetterId ?? this.highestBetterId),
      highestBetterName: clearHighestBetter
          ? null
          : (highestBetterName ?? this.highestBetterName),
      playerBets: playerBets ?? this.playerBets,
      lastWinner: lastWinner ?? this.lastWinner,
    );
  }

  factory BoardgameCalcBetting.fromJson(Map<String, dynamic> json) {
    final betsRaw = json['playerBets'] as Map<dynamic, dynamic>? ?? {};
    final bets = <String, BoardgameCalcPlayerBet>{};
    for (final entry in betsRaw.entries) {
      bets[entry.key.toString()] = BoardgameCalcPlayerBet.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return BoardgameCalcBetting(
      currentPot: (json['currentPot'] as num?)?.toInt() ?? 0,
      highestBet: (json['highestBet'] as num?)?.toInt() ?? 0,
      highestBetterId: json['highestBetterId'] as String?,
      highestBetterName: json['highestBetterName'] as String?,
      playerBets: bets,
      lastWinner: json['lastWinner'] != null
          ? BettingLastWinner.fromJson(
              Map<String, dynamic>.from(json['lastWinner']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentPot': currentPot,
        'highestBet': highestBet,
        if (highestBetterId != null) 'highestBetterId': highestBetterId,
        if (highestBetterName != null) 'highestBetterName': highestBetterName,
        'playerBets': playerBets.map((k, v) => MapEntry(k, v.toJson())),
        if (lastWinner != null) 'lastWinner': lastWinner!.toJson(),
      };
}

class BoardgameCalcDiceState {
  const BoardgameCalcDiceState({
    this.count = 2,
    this.sides = 6,
    this.values = const [3, 4],
    this.isRolling = false,
    this.rolledBy,
    this.rolledById,
    this.rolledByAvatarUrl,
    this.rolledByAvatarColor,
    this.sum,
    this.comboName,
    this.rolledAt,
  });

  final int count;
  final int sides;
  final List<int> values;
  final bool isRolling;
  final String? rolledBy;
  final String? rolledById;
  final String? rolledByAvatarUrl;
  final String? rolledByAvatarColor;
  final int? sum;
  final String? comboName;
  final int? rolledAt;

  factory BoardgameCalcDiceState.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcDiceState(
      count: (json['count'] as num?)?.toInt() ?? 2,
      sides: (json['sides'] as num?)?.toInt() ?? 6,
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [3, 4],
      isRolling: json['isRolling'] as bool? ?? false,
      rolledBy: json['rolledBy'] as String?,
      rolledById: json['rolledById'] as String?,
      rolledByAvatarUrl: json['rolledByAvatarUrl'] as String?,
      rolledByAvatarColor: json['rolledByAvatarColor'] as String?,
      sum: (json['sum'] as num?)?.toInt(),
      comboName: json['comboName'] as String?,
      rolledAt: (json['rolledAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'sides': sides,
        'values': values,
        'isRolling': isRolling,
        if (rolledBy != null) 'rolledBy': rolledBy,
        if (rolledById != null) 'rolledById': rolledById,
        if (rolledByAvatarUrl != null) 'rolledByAvatarUrl': rolledByAvatarUrl,
        if (rolledByAvatarColor != null)
          'rolledByAvatarColor': rolledByAvatarColor,
        if (sum != null) 'sum': sum,
        if (comboName != null) 'comboName': comboName,
        if (rolledAt != null) 'rolledAt': rolledAt,
      };
}

class BoardgameCalcSecretNoteEntry {
  const BoardgameCalcSecretNoteEntry({
    required this.playerId,
    this.sessionId,
    required this.nickname,
    this.avatarColor,
    this.avatarUrl,
    this.content = '',
    this.hasContent = false,
    this.isFolded = false,
    this.submittedAt,
    required this.updatedAt,
  });

  final String playerId;
  final String? sessionId;
  final String nickname;
  final String? avatarColor;
  final String? avatarUrl;
  final String content;
  final bool hasContent;
  final bool isFolded;
  final int? submittedAt;
  final int updatedAt;

  BoardgameCalcSecretNoteEntry copyWith({
    String? playerId,
    String? sessionId,
    String? nickname,
    String? avatarColor,
    String? avatarUrl,
    String? content,
    bool? hasContent,
    bool? isFolded,
    int? submittedAt,
    int? updatedAt,
  }) {
    return BoardgameCalcSecretNoteEntry(
      playerId: playerId ?? this.playerId,
      sessionId: sessionId ?? this.sessionId,
      nickname: nickname ?? this.nickname,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      content: content ?? this.content,
      hasContent: hasContent ?? this.hasContent,
      isFolded: isFolded ?? this.isFolded,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BoardgameCalcSecretNoteEntry.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcSecretNoteEntry(
      playerId: json['playerId'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      nickname: json['nickname'] as String? ?? '플레이어',
      avatarColor: json['avatarColor'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      hasContent: json['hasContent'] as bool? ?? false,
      isFolded: json['isFolded'] as bool? ?? false,
      submittedAt: (json['submittedAt'] as num?)?.toInt(),
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        if (sessionId != null) 'sessionId': sessionId,
        'nickname': nickname,
        if (avatarColor != null) 'avatarColor': avatarColor,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'content': content,
        'hasContent': hasContent,
        'isFolded': isFolded,
        if (submittedAt != null) 'submittedAt': submittedAt,
        'updatedAt': updatedAt,
      };
}

class BoardgameCalcSecretNoteState {
  const BoardgameCalcSecretNoteState({
    this.isActive = false,
    this.title = '비밀노트',
    this.isLocked = false,
    this.isRevealed = false,
    this.timeLimit = 60,
    this.autoReveal = true,
    this.endsAt,
    this.notes = const {},
    this.round = 1,
    this.startedAt,
    this.lockedAt,
    this.revealedAt,
  });

  final bool isActive;
  final String title;
  final bool isLocked;
  final bool isRevealed;
  final int timeLimit;
  final bool autoReveal;
  final int? endsAt;
  final Map<String, BoardgameCalcSecretNoteEntry> notes;
  final int round;
  final int? startedAt;
  final int? lockedAt;
  final int? revealedAt;

  BoardgameCalcSecretNoteState copyWith({
    bool? isActive,
    String? title,
    bool? isLocked,
    bool? isRevealed,
    int? timeLimit,
    bool? autoReveal,
    int? endsAt,
    bool clearEndsAt = false,
    Map<String, BoardgameCalcSecretNoteEntry>? notes,
    int? round,
    int? startedAt,
    int? lockedAt,
    int? revealedAt,
  }) {
    return BoardgameCalcSecretNoteState(
      isActive: isActive ?? this.isActive,
      title: title ?? this.title,
      isLocked: isLocked ?? this.isLocked,
      isRevealed: isRevealed ?? this.isRevealed,
      timeLimit: timeLimit ?? this.timeLimit,
      autoReveal: autoReveal ?? this.autoReveal,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      notes: notes ?? this.notes,
      round: round ?? this.round,
      startedAt: startedAt ?? this.startedAt,
      lockedAt: lockedAt ?? this.lockedAt,
      revealedAt: revealedAt ?? this.revealedAt,
    );
  }

  factory BoardgameCalcSecretNoteState.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'] as Map<dynamic, dynamic>? ?? {};
    final notesMap = <String, BoardgameCalcSecretNoteEntry>{};
    for (final entry in notesRaw.entries) {
      notesMap[entry.key.toString()] = BoardgameCalcSecretNoteEntry.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return BoardgameCalcSecretNoteState(
      isActive: json['isActive'] as bool? ?? false,
      title: json['title'] as String? ?? '비밀노트',
      isLocked: json['isLocked'] as bool? ?? false,
      isRevealed: json['isRevealed'] as bool? ?? false,
      timeLimit: (json['timeLimit'] as num?)?.toInt() ?? 60,
      autoReveal: json['autoReveal'] as bool? ?? true,
      endsAt: (json['endsAt'] as num?)?.toInt(),
      notes: notesMap,
      round: (json['round'] as num?)?.toInt() ?? 1,
      startedAt: (json['startedAt'] as num?)?.toInt(),
      lockedAt: (json['lockedAt'] as num?)?.toInt(),
      revealedAt: (json['revealedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'title': title,
        'isLocked': isLocked,
        'isRevealed': isRevealed,
        'timeLimit': timeLimit,
        'autoReveal': autoReveal,
        if (endsAt != null) 'endsAt': endsAt,
        'notes': notes.map((k, v) => MapEntry(k, v.toJson())),
        'round': round,
        if (startedAt != null) 'startedAt': startedAt,
        if (lockedAt != null) 'lockedAt': lockedAt,
        if (revealedAt != null) 'revealedAt': revealedAt,
      };
}

class BoardgameCalcRoom {
  const BoardgameCalcRoom({
    required this.roomCode,
    required this.title,
    required this.hostId,
    required this.hostSessionId,
    this.hostUserId,
    required this.settings,
    required this.players,
    required this.auction,
    required this.betting,
    this.centerTool = CenterToolType.empty,
    this.dice,
    this.secretNote,
    this.logs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String roomCode;
  final String title;
  final String hostId;
  final String hostSessionId;
  final String? hostUserId;
  final BoardgameCalcSettings settings;
  final List<BoardgameCalcPlayer> players;
  final BoardgameCalcAuction auction;
  final BoardgameCalcBetting betting;
  final CenterToolType centerTool;
  final BoardgameCalcDiceState? dice;
  final BoardgameCalcSecretNoteState? secretNote;
  final List<BoardgameCalcLog> logs;
  final int createdAt;
  final int updatedAt;

  CenterToolType get resolvedCenterTool {
    if (centerTool == CenterToolType.auction && !settings.enableAuction) {
      return CenterToolType.empty;
    }
    return centerTool;
  }

  BoardgameCalcRoom copyWith({
    String? roomCode,
    String? title,
    String? hostId,
    String? hostSessionId,
    String? hostUserId,
    BoardgameCalcSettings? settings,
    List<BoardgameCalcPlayer>? players,
    BoardgameCalcAuction? auction,
    BoardgameCalcBetting? betting,
    CenterToolType? centerTool,
    BoardgameCalcDiceState? dice,
    BoardgameCalcSecretNoteState? secretNote,
    List<BoardgameCalcLog>? logs,
    int? createdAt,
    int? updatedAt,
  }) {
    return BoardgameCalcRoom(
      roomCode: roomCode ?? this.roomCode,
      title: title ?? this.title,
      hostId: hostId ?? this.hostId,
      hostSessionId: hostSessionId ?? this.hostSessionId,
      hostUserId: hostUserId ?? this.hostUserId,
      settings: settings ?? this.settings,
      players: players ?? this.players,
      auction: auction ?? this.auction,
      betting: betting ?? this.betting,
      centerTool: centerTool ?? this.centerTool,
      dice: dice ?? this.dice,
      secretNote: secretNote ?? this.secretNote,
      logs: logs ?? this.logs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory BoardgameCalcRoom.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcRoom(
      roomCode: json['roomCode'] as String? ?? '',
      title: json['title'] as String? ?? '보드게임 계산기',
      hostId: json['hostId'] as String? ?? '',
      hostSessionId: json['hostSessionId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String?,
      settings: BoardgameCalcSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
      players: (json['players'] as List<dynamic>?)
              ?.map((e) =>
                  BoardgameCalcPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      auction: BoardgameCalcAuction.fromJson(
        Map<String, dynamic>.from(json['auction'] as Map? ?? {}),
      ),
      betting: BoardgameCalcBetting.fromJson(
        Map<String, dynamic>.from(json['betting'] as Map? ?? {}),
      ),
      centerTool: CenterToolType.fromWire(json['centerTool'] as String?),
      dice: json['dice'] != null
          ? BoardgameCalcDiceState.fromJson(
              Map<String, dynamic>.from(json['dice'] as Map))
          : null,
      secretNote: json['secretNote'] != null
          ? BoardgameCalcSecretNoteState.fromJson(
              Map<String, dynamic>.from(json['secretNote'] as Map))
          : null,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) =>
                  BoardgameCalcLog.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'title': title,
        'hostId': hostId,
        'hostSessionId': hostSessionId,
        if (hostUserId != null) 'hostUserId': hostUserId,
        'settings': settings.toJson(),
        'players': players.map((e) => e.toJson()).toList(),
        'auction': auction.toJson(),
        'betting': betting.toJson(),
        'centerTool': centerTool.wireValue,
        if (dice != null) 'dice': dice!.toJson(),
        if (secretNote != null) 'secretNote': secretNote!.toJson(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class BoardgameCalcTransferRequest {
  const BoardgameCalcTransferRequest({
    required this.requestId,
    required this.roomCode,
    required this.fromId,
    this.fromSessionId,
    required this.fromName,
    required this.toId,
    this.toSessionId,
    required this.toName,
    required this.amount,
    this.memo,
    required this.createdAt,
  });

  final String requestId;
  final String roomCode;
  final String fromId;
  final String? fromSessionId;
  final String fromName;
  final String toId;
  final String? toSessionId;
  final String toName;
  final int amount;
  final String? memo;
  final int createdAt;

  factory BoardgameCalcTransferRequest.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcTransferRequest(
      requestId: json['requestId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      fromId: json['fromId'] as String? ?? '',
      fromSessionId: json['fromSessionId'] as String?,
      fromName: json['fromName'] as String? ?? '',
      toId: json['toId'] as String? ?? '',
      toSessionId: json['toSessionId'] as String?,
      toName: json['toName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      memo: json['memo'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'roomCode': roomCode,
        'fromId': fromId,
        if (fromSessionId != null) 'fromSessionId': fromSessionId,
        'fromName': fromName,
        'toId': toId,
        if (toSessionId != null) 'toSessionId': toSessionId,
        'toName': toName,
        'amount': amount,
        if (memo != null) 'memo': memo,
        'createdAt': createdAt,
      };
}

class BoardgameCalcRoomSummary {
  const BoardgameCalcRoomSummary({
    required this.roomCode,
    required this.title,
    required this.hostNickname,
    required this.hostSessionId,
    this.hostUserId,
    required this.playerCount,
    required this.onlineCount,
    required this.settings,
    this.hasAuction = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String roomCode;
  final String title;
  final String hostNickname;
  final String hostSessionId;
  final String? hostUserId;
  final int playerCount;
  final int onlineCount;
  final BoardgameCalcSettings settings;
  final bool hasAuction;
  final int createdAt;
  final int updatedAt;

  factory BoardgameCalcRoomSummary.fromJson(Map<String, dynamic> json) {
    return BoardgameCalcRoomSummary(
      roomCode: json['roomCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hostNickname: json['hostNickname'] as String? ?? '방장',
      hostSessionId: json['hostSessionId'] as String? ?? '',
      hostUserId: json['hostUserId'] as String?,
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      onlineCount: (json['onlineCount'] as num?)?.toInt() ?? 0,
      settings: BoardgameCalcSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
      hasAuction: json['hasAuction'] as bool? ?? false,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }
}

List<BoardgameCalcPlayer> sortTopPlayers(
  List<BoardgameCalcPlayer> players,
  TopPlayersSortOption sortOption,
) {
  final list = List<BoardgameCalcPlayer>.from(players);
  if (sortOption == TopPlayersSortOption.defaultOrder) {
    return list;
  }
  list.sort((a, b) {
    int diff = 0;
    switch (sortOption) {
      case TopPlayersSortOption.pointsDesc:
        diff = b.points.compareTo(a.points);
      case TopPlayersSortOption.pointsAsc:
        diff = a.points.compareTo(b.points);
      case TopPlayersSortOption.scoreDesc:
        diff = b.score.compareTo(a.score);
      case TopPlayersSortOption.scoreAsc:
        diff = a.score.compareTo(b.score);
      case TopPlayersSortOption.defaultOrder:
        diff = 0;
    }
    if (diff != 0) return diff;
    return a.joinedAt.compareTo(b.joinedAt);
  });
  return list;
}

({String currencyUnit, String scoreUnit}) getRoomUnits(
  BoardgameCalcSettings? settings,
) {
  final currency = settings?.currencyUnit.trim() ?? '';
  final score = settings?.scoreUnit.trim() ?? '';
  return (
    currencyUnit: currency.isNotEmpty
        ? currency
        : BoardgameCalcConstants.defaultCurrencyUnit,
    scoreUnit:
        score.isNotEmpty ? score : BoardgameCalcConstants.defaultScoreUnit,
  );
}
