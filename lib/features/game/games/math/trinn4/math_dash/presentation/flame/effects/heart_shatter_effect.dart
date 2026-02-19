import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// Heart fragment explosion when a life is lost.
class HeartShatterEffect extends PositionComponent {
  HeartShatterEffect({required Vector2 heartPosition})
    : super(position: heartPosition, priority: 92);

  @override
  void onMount() {
    super.onMount();
    final rng = Random();
    for (var i = 0; i < 7; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = rng.nextDouble() * 60 + 30;
      final dx = cos(angle) * speed;
      final dy = sin(angle) * speed;
      final fragment = _HeartFragment(
        size: Vector2.all(rng.nextDouble() * 4 + 2),
      );
      fragment
        ..add(MoveEffect.by(
          Vector2(dx * 0.8, dy * 0.8),
          EffectController(duration: 0.6, curve: Curves.easeOut),
        ))
        ..add(OpacityEffect.to(
          0,
          EffectController(duration: 0.6, curve: Curves.easeIn),
          onComplete: fragment.removeFromParent,
        ));
      add(fragment);
    }

    Future<void>.delayed(const Duration(milliseconds: 700)).then((_) {
      if (isMounted) removeFromParent();
    });
  }
}

class _HeartFragment extends RectangleComponent {
  _HeartFragment({required super.size})
    : super(
        paint: Paint()..color = const Color(0xFFE53935),
        anchor: Anchor.center,
      );
}
