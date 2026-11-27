import 'dart:math';

import 'package:boardgame_calc/models/boardgame_models.dart';
import 'package:boardgame_calc/services/local_boardgame_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatting & Sorting Utilities', () {
    test('formatCompactNumber formats numbers under and over 10k identically', () {
      expect(formatCompactNumber(0), '0');
      expect(formatCompactNumber(9500), '9,500');
      expect(formatCompactNumber(9999), '9,999');
      expect(formatCompactNumber(10000), '10k');
      expect(formatCompactNumber(12500), '12.5k');
      expect(formatCompactNumber(-25400), '-25.4k');
      expect(formatCompactNumber(1000000), '1,000k');
    });

    test('formatCompactSignedNumber prepends explicit sign', () {
      expect(formatCompactSignedNumber(0), '+0');
      expect(formatCompactSignedNumber(500), '+500');
      expect(formatCompactSignedNumber(-15000), '-15k');
    });

    test('sortTopPlayers sorts by points/score asc/desc with joinedAt tiebreak', () {
      const players = [
        BoardgameCalcPlayer(
          id: 'p1',
          sessionId: 's1',
          nickname: 'Alpha',
          avatarColor: '#EF4444',
          points: 1000,
          score: 5,
          joinedAt: 100,
        ),
        BoardgameCalcPlayer(
          id: 'p2',
          sessionId: 's2',
          nickname: 'Beta',
          avatarColor: '#3B82F6',
          points: 2000,
          score: 5,
          joinedAt: 50,
        ),
        BoardgameCalcPlayer(
          id: 'p3',
          sessionId: 's3',
          nickname: 'Gamma',
          avatarColor: '#22C55E',
          points: 500,
          score: 12,
          joinedAt: 200,
        ),
      ];

      expect(
        sortTopPlayers(players, TopPlayersSortOption.defaultOrder)
            .map((p) => p.id)
            .toList(),
        ['p1', 'p2', 'p3'],
      );
      expect(
        sortTopPlayers(players, TopPlayersSortOption.pointsDesc)
            .map((p) => p.id)
            .toList(),
        ['p2', 'p1', 'p3'],
      );
      expect(
        sortTopPlayers(players, TopPlayersSortOption.pointsAsc)
            .map((p) => p.id)
            .toList(),
        ['p3', 'p1', 'p2'],
      );
      expect(
        sortTopPlayers(players, TopPlayersSortOption.scoreDesc)
            .map((p) => p.id)
            .toList(),
        ['p3', 'p2', 'p1'], // Beta joinedAt(50) < Alpha joinedAt(100)
      );
      expect(
        sortTopPlayers(players, TopPlayersSortOption.scoreAsc)
            .map((p) => p.id)
            .toList(),
        ['p2', 'p1', 'p3'],
      );
    });
  });

  group('BoardgameCalcRoom JSON Serialization', () {
    test('round-trips room state cleanly via toJson / fromJson', () {
      final engine = LocalBoardgameEngine(random: Random(42));
      final created = engine.createRoom(
        nickname: '호스트',
        title: '직렬화 테스트방',
        settings: const BoardgameCalcSettings(
          currencyUnit: '골드',
          initialPoints: 2500,
          enableScore: true,
          initialScore: 3,
          currencyDenominations: [
            BoardgameCalcDenomination(value: 100, maxCount: 10, remainingCount: 10),
            BoardgameCalcDenomination(value: 500),
          ],
        ),
      );
      final joined = engine.joinRoom(
        roomCode: created.room.roomCode,
        nickname: '게스트',
      );

      final rawJson = joined.room.toJson();
      final decoded = BoardgameCalcRoom.fromJson(rawJson);

      expect(decoded.roomCode, created.room.roomCode);
      expect(decoded.title, '직렬화 테스트방');
      expect(decoded.players.length, 2);
      expect(decoded.settings.currencyUnit, '골드');
      expect(decoded.settings.currencyDenominations.first.maxCount, 10);
      expect(decoded.settings.currencyDenominations.first.remainingCount, 10);
    });
  });

  group('LocalBoardgameEngine Rules', () {
    late LocalBoardgameEngine engine;
    late String roomCode;
    late BoardgameCalcPlayer host;
    late BoardgameCalcPlayer p2;

    setUp(() {
      engine = LocalBoardgameEngine(random: Random(7));
      final res1 = engine.createRoom(
        nickname: '방장',
        settings: const BoardgameCalcSettings(
          currencyUnit: '원',
          initialPoints: 1000,
          initialScore: 0,
          currencyDenominations: [
            BoardgameCalcDenomination(value: 100, maxCount: 2, remainingCount: 2),
            BoardgameCalcDenomination(value: 500),
          ],
          scoreDenominations: [
            BoardgameCalcDenomination(value: 1, maxCount: 2, remainingCount: 2),
          ],
        ),
      );
      roomCode = res1.room.roomCode;
      host = res1.player!;
      final res2 = engine.joinRoom(roomCode: roomCode, nickname: '플레이어2');
      p2 = res2.player!;
    });

    tearDown(() {
      engine.dispose();
    });

    test('prevents duplicate nicknames case-insensitively and assigns distinct colors', () {
      expect(p2.avatarColor.toLowerCase(), isNot(host.avatarColor.toLowerCase()));
      expect(
        () => engine.joinRoom(roomCode: roomCode, nickname: ' 플레이어2 '),
        throwsA(isA<BoardgameEngineException>()),
      );
    });

    test('currency & score adjustment tracks denomination depletion and refund', () {
      // Take 100 twice (remaining 2 -> 0)
      var r = engine.adjustPoints(
        roomCode: roomCode,
        actorId: host.id,
        targetPlayerId: host.id,
        delta: 100,
        unitValue: 100,
      );
      expect(r.room.players.first.points, 1100);
      expect(r.room.settings.currencyDenominations.first.remainingCount, 1);

      r = engine.adjustPoints(
        roomCode: roomCode,
        actorId: host.id,
        targetPlayerId: host.id,
        delta: 100,
        unitValue: 100,
      );
      expect(r.room.players.first.points, 1200);
      expect(r.room.settings.currencyDenominations.first.remainingCount, 0);

      // 3rd take should throw exhaustion error
      expect(
        () => engine.adjustPoints(
          roomCode: roomCode,
          actorId: host.id,
          targetPlayerId: host.id,
          delta: 100,
          unitValue: 100,
        ),
        throwsA(isA<BoardgameEngineException>()),
      );

      // Returning -100 restores count 0 -> 1
      r = engine.adjustPoints(
        roomCode: roomCode,
        actorId: host.id,
        targetPlayerId: host.id,
        delta: -100,
        unitValue: 100,
      );
      expect(r.room.players.first.points, 1100);
      expect(r.room.settings.currencyDenominations.first.remainingCount, 1);

      // Score denominations follow same depletion rule
      r = engine.adjustScore(
        roomCode: roomCode,
        actorId: p2.id,
        targetPlayerId: p2.id,
        delta: 1,
        unitValue: 1,
      );
      expect(r.room.players[1].score, 1);
      expect(r.room.settings.scoreDenominations.first.remainingCount, 1);

      // Host-only permission blocks non-host self adjustment
      engine.updateSettings(
        roomCode: roomCode,
        hostActorId: host.id,
        nextSettings: r.room.settings.copyWith(
          permissionMode: PermissionMode.hostOnly,
        ),
      );
      expect(
        () => engine.adjustPoints(
          roomCode: roomCode,
          actorId: p2.id,
          targetPlayerId: p2.id,
          delta: 500,
        ),
        throwsA(isA<BoardgameEngineException>()),
      );
    });

    test('P2P transfer requires acceptance, rejects cleanly, and checks funds', () {
      // Request transfer
      final reqRes = engine.requestTransfer(
        roomCode: roomCode,
        fromActorId: host.id,
        toPlayerId: p2.id,
        amount: 300,
        memo: '통행료',
      );
      final reqId = reqRes.transferRequest!.requestId;

      // Reject does not move balances
      final rejectRes = engine.respondTransfer(
        roomCode: roomCode,
        requestId: reqId,
        actorId: p2.id,
        accept: false,
      );
      expect(rejectRes.accepted, false);
      expect(rejectRes.room.players[0].points, 1000);
      expect(rejectRes.room.players[1].points, 1000);

      // Accept transfers balance
      final reqRes2 = engine.requestTransfer(
        roomCode: roomCode,
        fromActorId: host.id,
        toPlayerId: p2.id,
        amount: 400,
      );
      final accRes = engine.respondTransfer(
        roomCode: roomCode,
        requestId: reqRes2.transferRequest!.requestId,
        actorId: p2.id,
        accept: true,
      );
      expect(accRes.accepted, true);
      expect(accRes.room.players[0].points, 600);
      expect(accRes.room.players[1].points, 1400);

      // Insufficient balance blocked
      expect(
        () => engine.requestTransfer(
          roomCode: roomCode,
          fromActorId: host.id,
          toPlayerId: p2.id,
          amount: 9999,
        ),
        throwsA(isA<BoardgameEngineException>()),
      );
    });

    test('Auction enforces min bid, conflict check, self-overbid, and pot settlement', () {
      engine.startAuction(
        roomCode: roomCode,
        hostActorId: host.id,
        title: '전설의 유물',
        minIncrement: 100,
      );

      // Bid by p2: 100
      final b1 = engine.placeBid(
        roomCode: roomCode,
        bidderActorId: p2.id,
        bidAmount: 100,
        expectedHighestBid: 0,
      );
      expect(b1.room.auction.highestBid, 100);
      expect(b1.room.auction.highestBidderId, p2.id);

      // Stale expectedHighestBid triggers conflict exception
      expect(
        () => engine.placeBid(
          roomCode: roomCode,
          bidderActorId: host.id,
          bidAmount: 200,
          expectedHighestBid: 0,
        ),
        throwsA(
          predicate<BoardgameEngineException>((e) => e.isConflict),
        ),
      );

      // Cannot self-overbid
      expect(
        () => engine.placeBid(
          roomCode: roomCode,
          bidderActorId: p2.id,
          bidAmount: 300,
          expectedHighestBid: 100,
        ),
        throwsA(isA<BoardgameEngineException>()),
      );

      // Protected reserved auction funds cannot be transferred away
      expect(
        () => engine.requestTransfer(
          roomCode: roomCode,
          fromActorId: p2.id,
          toPlayerId: host.id,
          amount: 950, // p2 has 1000 total, 100 reserved -> max 900
        ),
        throwsA(isA<BoardgameEngineException>()),
      );

      // Host designates p2 winner with burn_pot -> p2 pays 100, auction ends cleanly
      final winRes = engine.designateAuctionWinner(
        roomCode: roomCode,
        hostActorId: host.id,
        potAction: 'burn_pot',
        expectedHighestBid: 100,
      );
      expect(winRes.room.auction.isActive, false);
      expect(winRes.room.players[0].points, 1000);
      expect(winRes.room.players[1].points, 900);
    });

    test('Betting pot accumulates bets, pays winner, and refunds on reset', () {
      engine.placeBet(roomCode: roomCode, actorId: host.id, amount: 250);
      final afterP2 = engine.placeBet(roomCode: roomCode, actorId: p2.id, amount: 350);
      expect(afterP2.room.betting.currentPot, 600);
      expect(afterP2.room.players[0].points, 750);
      expect(afterP2.room.players[1].points, 650);

      // Reset refunds all players
      final resetRes = engine.resetBettingPot(roomCode: roomCode, hostActorId: host.id);
      expect(resetRes.room.betting.currentPot, 0);
      expect(resetRes.room.players[0].points, 1000);
      expect(resetRes.room.players[1].points, 1000);

      // Re-bet and resolve winner
      engine.placeBet(roomCode: roomCode, actorId: host.id, amount: 200);
      engine.placeBet(roomCode: roomCode, actorId: p2.id, amount: 200);
      final winRes = engine.resolveBettingWinner(
        roomCode: roomCode,
        hostActorId: host.id,
        winnerId: p2.id,
      );
      expect(winRes.room.betting.currentPot, 0);
      expect(winRes.room.players[0].points, 800);
      expect(winRes.room.players[1].points, 1200);
    });

    test('Dice roller produces valid values and SecretNote sanitizes unrevealed entries', () {
      final diceRes = engine.rollDice(
        roomCode: roomCode,
        actorId: host.id,
        count: 4,
        sides: 6,
      );
      expect(diceRes.diceState!.values.length, 4);
      for (final v in diceRes.diceState!.values) {
        expect(v, inInclusiveRange(1, 6));
      }

      // SecretNote sanitization
      engine.startSecretNote(
        roomCode: roomCode,
        hostActorId: host.id,
        title: '비밀 단어',
        timeLimit: 0,
      );
      engine.updateSecretNote(
        roomCode: roomCode,
        actorId: host.id,
        content: '사과',
      );
      final updatedRoom = engine
          .updateSecretNote(
            roomCode: roomCode,
            actorId: p2.id,
            content: '바나나',
          )
          .room;

      // Before reveal, p2 sees own content ('바나나') but host content is masked
      final viewForP2 = engine.getSanitizedRoomForPlayer(
        updatedRoom,
        playerId: p2.id,
        sessionId: p2.sessionId,
      );
      expect(viewForP2.secretNote!.notes[p2.id]!.content, '바나나');
      expect(viewForP2.secretNote!.notes[host.id]!.content, '');
      expect(viewForP2.secretNote!.notes[host.id]!.hasContent, true);

      // After reveal, both contents are visible
      final revealed = engine.revealSecretNote(roomCode: roomCode, hostActorId: host.id);
      final viewAfterReveal = engine.getSanitizedRoomForPlayer(
        revealed.room,
        playerId: p2.id,
        sessionId: p2.sessionId,
      );
      expect(viewAfterReveal.secretNote!.isRevealed, true);
      expect(viewAfterReveal.secretNote!.notes[host.id]!.content, '사과');
    });
  });
}
