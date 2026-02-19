import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart'
    show Color, FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

/// A number projectile that flies from the runner toward the obstacle.
/// On arrival it calls [onHit] and removes itself.
class ThrownNumber extends PositionComponent {
  ThrownNumber({
    required this.text,
    required Vector2 start,
    required this.target,
    required this.isCorrect,
    required this.onHit,
    this.flightDuration = 0.4,
  }) : _start = start.clone(),
       super(
         position: start.clone(),
         size: Vector2(32, 32),
         anchor: Anchor.center,
         priority: 80,
       );

  final String text;
  final Vector2 _start;
  final Vector2 target;
  final bool isCorrect;
  final VoidCallback onHit;
  final double flightDuration;

  double _elapsed = 0;
  bool _hit = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final t = (_elapsed / flightDuration).clamp(0.0, 1.0);
    // Ease-out trajectory
    final eased = 1.0 - (1.0 - t) * (1.0 - t);

    // Straight line with a slight arc upward
    final arcHeight = -30.0 * math.sin(t * math.pi);
    position.x = _start.x + (target.x - _start.x) * eased;
    position.y = _start.y + (target.y - _start.y) * eased + arcHeight;

    if (t >= 1.0 && !_hit) {
      _hit = true;
      onHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Glowing circle background
    final bgColor = isCorrect
        ? const Color(0xFF00B4D8)
        : const Color(0xFFE53935);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      14,
      Paint()
        ..color = bgColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      12,
      Paint()..color = bgColor,
    );

    // Number text
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          fontFamily: 'Fredoka One',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2),
    );
  }
}
