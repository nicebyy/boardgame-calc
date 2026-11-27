import 'package:flutter/foundation.dart';

import 'boardgame_audio_stub.dart'
    if (dart.library.js_interop) 'boardgame_audio_web.dart' as impl;

class BoardgameAudio {
  BoardgameAudio._();

  static bool globalEnabled = true;

  @visibleForTesting
  static void Function(String event)? debugObserver;

  static bool _resolve(bool? enabled) => enabled ?? globalEnabled;

  static void playClick({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('click');
    impl.playClickSound(active);
  }

  static void playTab({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('tab');
    impl.playTabSound(active);
  }

  static void playModal({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('modal');
    impl.playModalSound(active);
  }

  static void playCoinSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('coin');
    impl.playCoinSound(active);
  }

  static void playBetChipSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('bet_chip');
    impl.playBetChipSound(active);
  }

  static void playBidCoinSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('bid_coin');
    impl.playBidCoinSound(active);
  }

  static void playRefundSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('refund');
    impl.playRefundSound(active);
  }

  static void playTransferSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('transfer');
    impl.playTransferSound(active);
  }

  static void playAuctionGong({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('auction_gong');
    impl.playAuctionGong(active);
  }

  static void playWinSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('win');
    impl.playWinSound(active);
  }

  static void playDiceSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('dice');
    impl.playDiceSound(active);
  }

  static void playSecretNoteFoldSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('secret_fold');
    impl.playSecretNoteFoldSound(active);
  }

  static void playSecretNoteRevealSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('secret_reveal');
    impl.playSecretNoteRevealSound(active);
  }

  static void playSecretNoteWriteSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('secret_write');
    impl.playSecretNoteWriteSound(active);
  }

  static void playSecretNoteLockSound({bool? enabled}) {
    final active = _resolve(enabled);
    if (!active) return;
    debugObserver?.call('secret_lock');
    impl.playSecretNoteLockSound(active);
  }
}
