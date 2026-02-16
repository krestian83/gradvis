import 'package:flutter/widgets.dart';

import 'game_interface.dart';

/// Maps curriculum slots to game widget factories.
///
/// To add a game:
/// ```dart
/// GameRegistry.instance.register(
///   GameSlot(subject: Subject.math, trinn: 1, level: 0),
///   ({required onComplete}) => MyMathGame(onComplete: onComplete),
/// );
/// ```
class GameRegistry {
  GameRegistry._();
  static final instance = GameRegistry._();

  final _registry = <GameSlot, GameFactory>{};

  void register(GameSlot slot, GameFactory factory) =>
      _registry[slot] = factory;

  bool hasGame(GameSlot slot) => _registry.containsKey(slot);

  GameWidget? build(
    GameSlot slot, {
    required ValueChanged<GameResult> onComplete,
  }) {
    final factory = _registry[slot];
    return factory?.call(onComplete: onComplete);
  }
}
