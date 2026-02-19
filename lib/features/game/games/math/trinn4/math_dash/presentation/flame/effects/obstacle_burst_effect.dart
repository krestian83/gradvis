import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Small confetti burst at the obstacle position when it's destroyed.
class ObstacleBurstEffect extends PositionComponent {
  ObstacleBurstEffect({
    required Vector2 center,
    this.isCorrect = true,
  }) : super(position: center, priority: 85);

  final bool isCorrect;
  final _particles = <_BurstParticle>[];
  double _elapsed = 0;

  static const _correctColors = [
    Color(0xFF00B4D8),
    Color(0xFF48CAE4),
    Color(0xFF4CAF50),
    Color(0xFFFFB300),
    Color(0xFFFF6D00),
  ];

  static const _wrongColors = [
    Color(0xFFE53935),
    Color(0xFFFF6D00),
    Color(0xFF9E9E9E),
  ];

  @override
  void onMount() {
    super.onMount();
    final rng = Random();
    final colors = isCorrect ? _correctColors : _wrongColors;
    final count = isCorrect ? 18 : 8;
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = rng.nextDouble() * 80 + 30;
      _particles.add(_BurstParticle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 20,
        color: colors[rng.nextInt(colors.length)],
        size: rng.nextDouble() * 5 + 2,
        isCircle: rng.nextBool(),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 120 * dt;
    }
    if (_elapsed > 0.8) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_elapsed < 0.5)
        ? 1.0
        : (1.0 - (_elapsed - 0.5) / 0.3).clamp(0.0, 1.0);
    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity);
      if (p.isCircle) {
        canvas.drawCircle(Offset(p.x, p.y), p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(p.x, p.y),
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }
    }
  }
}

class _BurstParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  bool isCircle;

  _BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.isCircle,
  });
}
