import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Green rectangle representing the player, with a bobbing run cycle.
class PlayerComponent extends PositionComponent with CollisionCallbacks {
  static const double _width = 40;
  static const double _height = 60;
  static const double _bobAmplitude = 3;
  static const double _bobFrequency = 6;

  double _elapsed = 0;
  bool _bobbing = true;
  double _baseY = 0;

  PlayerComponent() : super(size: Vector2(_width, _height));

  set bobbing(bool value) => _bobbing = value;

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)),
      paint,
    );
    // Eyes
    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(const Offset(14, 16), 5, eyePaint);
    canvas.drawCircle(const Offset(28, 16), 5, eyePaint);
    final pupil = Paint()..color = const Color(0xFF333333);
    canvas.drawCircle(const Offset(16, 16), 2, pupil);
    canvas.drawCircle(const Offset(30, 16), 2, pupil);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_bobbing) return;
    _elapsed += dt;
    position.y = _baseY + sin(_elapsed * _bobFrequency) * _bobAmplitude;
  }
}
