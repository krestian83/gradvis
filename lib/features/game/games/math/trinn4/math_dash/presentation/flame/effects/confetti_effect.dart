import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Colored particle burst for the victory sequence.
class ConfettiEffect extends PositionComponent {
  ConfettiEffect({required this.gameSize})
    : super(size: gameSize, position: Vector2.zero(), priority: 95);

  final Vector2 gameSize;
  final _particles = <_ConfettiParticle>[];
  double _elapsed = 0;

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFFFF6D00),
  ];

  @override
  void onMount() {
    super.onMount();
    final rng = Random();
    for (var i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble() * gameSize.x,
        y: -rng.nextDouble() * 40,
        vx: (rng.nextDouble() - 0.5) * 60,
        vy: rng.nextDouble() * 120 + 40,
        rotation: rng.nextDouble() * 6.28,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        color: _colors[rng.nextInt(_colors.length)],
        size: rng.nextDouble() * 6 + 3,
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
      p.rotation += p.rotationSpeed * dt;
      p.vy += 30 * dt;
    }
    if (_elapsed > 4.0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_elapsed < 3.0)
        ? 1.0
        : (1.0 - (_elapsed - 3.0)).clamp(0.0, 1.0);

    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;
  bool isCircle;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    required this.isCircle,
  });
}
