import 'boardgame_audio_stub.dart'
    if (dart.library.js_interop) 'boardgame_audio_web.dart' as impl;

class BoardgameAudio {
  BoardgameAudio._();

  static void playCoinSound({bool enabled = true}) =>
      impl.playCoinSound(enabled);

  static void playTransferSound({bool enabled = true}) =>
      impl.playTransferSound(enabled);

  static void playAuctionGong({bool enabled = true}) =>
      impl.playAuctionGong(enabled);

  static void playWinSound({bool enabled = true}) =>
      impl.playWinSound(enabled);

  static void playDiceSound({bool enabled = true}) =>
      impl.playDiceSound(enabled);

  static void playSecretNoteFoldSound({bool enabled = true}) =>
      impl.playSecretNoteFoldSound(enabled);

  static void playSecretNoteRevealSound({bool enabled = true}) =>
      impl.playSecretNoteRevealSound(enabled);

  static void playSecretNoteLockSound({bool enabled = true}) =>
      impl.playSecretNoteLockSound(enabled);
}
