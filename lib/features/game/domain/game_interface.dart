import 'package:flutter/widgets.dart';

import '../../../core/constants/subject.dart';

/// Result returned when a game ends.
class GameResult {
  final int stars;
  final int pointsEarned;

  const GameResult({required this.stars, required this.pointsEarned});
}

/// Identifies a specific curriculum slot.
class GameSlot {
  final Subject subject;
  final int trinn;
  final int level;

  const GameSlot({
    required this.subject,
    required this.trinn,
    required this.level,
  });

  @override
  int get hashCode => Object.hash(subject, trinn, level);

  @override
  bool operator ==(Object other) =>
      other is GameSlot &&
      other.subject == subject &&
      other.trinn == trinn &&
      other.level == level;
}

/// Any game must implement this to plug into the game screen.
abstract interface class GameWidget implements Widget {
  ValueChanged<GameResult> get onComplete;
}

/// Factory function that creates a game widget.
typedef GameFactory =
    GameWidget Function({required ValueChanged<GameResult> onComplete});
