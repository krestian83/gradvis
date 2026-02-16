import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Controls intro theme music playback and fade-out.
class ThemeMusicController {
  final AudioPlayer _player = AudioPlayer();

  bool _started = false;
  bool _fadingOut = false;
  bool _fadedOut = false;
  bool _pluginAvailable = true;

  /// Starts looped theme playback once.
  Future<void> startLoop() async {
    if (_started || _fadedOut || !_pluginAvailable) return;

    try {
      _started = true;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/music/theme.mp3'));
    } on MissingPluginException {
      _pluginAvailable = false;
      _started = false;
    } on PlatformException {
      _pluginAvailable = false;
      _started = false;
    }
  }

  /// Fades music out, then stops playback.
  Future<void> fadeOutAndStop({
    Duration duration = const Duration(milliseconds: 1400),
    int steps = 14,
  }) async {
    if (_fadedOut || _fadingOut || !_started || !_pluginAvailable) return;

    try {
      _fadingOut = true;
      final stepDuration = Duration(
        milliseconds: (duration.inMilliseconds / steps).round(),
      );

      for (var i = 1; i <= steps; i++) {
        final volume = (1.0 - (i / steps)).clamp(0.0, 1.0);
        await _player.setVolume(volume);
        await Future<void>.delayed(stepDuration);
      }

      await _player.stop();
      _fadedOut = true;
      _fadingOut = false;
    } on MissingPluginException {
      _pluginAvailable = false;
      _fadingOut = false;
    } on PlatformException {
      _pluginAvailable = false;
      _fadingOut = false;
    }
  }

  Future<void> dispose() async {
    if (!_pluginAvailable) return;
    try {
      await _player.dispose();
    } on MissingPluginException {
      _pluginAvailable = false;
    } on PlatformException {
      _pluginAvailable = false;
    }
  }
}
