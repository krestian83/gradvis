import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// Full-screen color flash that fades out.
class ScreenFlashEffect extends RectangleComponent {
  ScreenFlashEffect({
    required Color color,
    required Vector2 gameSize,
    double startOpacity = 0.3,
  }) : super(
         size: gameSize,
         position: Vector2.zero(),
         paint: Paint()..color = color.withValues(alpha: startOpacity),
         priority: 100,
       ) {
    add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.4, curve: Curves.easeOut),
        onComplete: removeFromParent,
      ),
    );
  }

  /// Green flash for correct answers.
  factory ScreenFlashEffect.correct({required Vector2 gameSize}) =>
      ScreenFlashEffect(
        color: const Color(0xFF4CAF50),
        gameSize: gameSize,
      );

  /// Red flash for wrong answers.
  factory ScreenFlashEffect.wrong({required Vector2 gameSize}) =>
      ScreenFlashEffect(
        color: const Color(0xFFE53935),
        gameSize: gameSize,
        startOpacity: 0.35,
      );
}
