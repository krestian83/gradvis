import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

abstract interface class AlphabetAudioPlayer {
  Future<void> playLetter(String audioKey);
  Future<void> playSuccess();
  Future<void> playWrong();
  Future<void> dispose();
}

class AssetAlphabetAudioPlayer implements AlphabetAudioPlayer {
  final AudioPlayer _lettersPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();

  bool _pluginAvailable = true;

  @override
  Future<void> playLetter(String audioKey) async {
    await _safePlay(_lettersPlayer, 'audio/letters/$audioKey.mp3');
  }

  @override
  Future<void> playSuccess() async {
    await _safePlay(_feedbackPlayer, 'audio/sfx/success.mp3');
  }

  @override
  Future<void> playWrong() async {
    await _safePlay(_feedbackPlayer, 'audio/sfx/wrong.mp3');
  }

  Future<void> _safePlay(AudioPlayer player, String assetPath) async {
    if (!_pluginAvailable) return;

    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } on MissingPluginException {
      _pluginAvailable = false;
    } on PlatformException {
      _pluginAvailable = false;
    }
  }

  @override
  Future<void> dispose() async {
    if (!_pluginAvailable) return;
    try {
      await _lettersPlayer.dispose();
      await _feedbackPlayer.dispose();
    } on MissingPluginException {
      _pluginAvailable = false;
    } on PlatformException {
      _pluginAvailable = false;
    }
  }
}
