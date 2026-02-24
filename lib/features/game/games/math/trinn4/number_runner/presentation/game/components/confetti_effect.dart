import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Burst of 12 colored particles that expand and fade over 0.5 s.
class ConfettiEffect extends PositionComponent {
  static const int _count = 12;
  static const double _duration = 0.5;
  static const double _speed = 200;

  static const _colors = [
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
  ];

  final List<_Particle> _particles = [];
  double _elapsed = 0;
  final Random _random = Random();

  ConfettiEffect({required Vector2 origin}) : super(position: origin);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < _count; i++) {
      final angle = (i / _count) * 2 * pi + _random.nextDouble() * 0.5;
      _particles.add(_Particle(
        dx: cos(angle) * _speed * (0.5 + _random.nextDouble()),
        dy: sin(angle) * _speed * (0.5 + _random.nextDouble()),
        color: _colors[i % _colors.length],
        radius: 3 + _random.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = ((1.0 - t) * 255).toInt();

    for (final p in _particles) {
      final x = p.dx * t;
      final y = p.dy * t;
      final paint = Paint()..color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), p.radius * (1 - t * 0.5), paint);
    }
  }
}

class _Particle {
  final double dx;
  final double dy;
  final Color color;
  final double radius;

  _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.radius,
  });
}
