import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Red rectangle obstacle that approaches the player from the right.
class ObstacleComponent extends PositionComponent with CollisionCallbacks {
  static const double _size = 50;
  static const Color _color = Color(0xFFE53935);

  bool active = false;

  ObstacleComponent() : super(size: Vector2.all(_size));

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final paint = Paint()..color = _color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      paint,
    );
    // Danger cross.
    final cross = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(15, 15),
      Offset(_size - 15, _size - 15),
      cross,
    );
    canvas.drawLine(
      Offset(_size - 15, 15),
      const Offset(15, _size - 15),
      cross,
    );
  }
}
