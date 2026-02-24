import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Yellow circle projectile fired from the player toward an obstacle.
class ProjectileComponent extends PositionComponent with CollisionCallbacks {
  static const double _radius = 8;
  static const double speed = 600;

  bool active = false;
  ObstacleTarget? target;

  ProjectileComponent()
      : super(
          size: Vector2.all(_radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final paint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      paint,
    );
    // Glow ring.
    final glow = Paint()
      ..color = const Color(0x60FFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(_radius, _radius), _radius + 2, glow);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active || target == null) return;
    final direction = target!.position - position;
    if (direction.length < 10) {
      target!.onHit();
      active = false;
      return;
    }
    position += direction.normalized() * speed * dt;
  }
}

/// Interface for the projectile to know where to fly.
class ObstacleTarget {
  final Vector2 position;
  final void Function() onHit;

  ObstacleTarget({required this.position, required this.onHit});
}
