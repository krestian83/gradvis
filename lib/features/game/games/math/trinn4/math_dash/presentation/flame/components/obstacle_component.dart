import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/environment_theme.dart';

/// A theme-specific obstacle that scrolls left toward the runner.
class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.theme,
    required this.variant,
    required super.position,
  }) : super(size: Vector2(40, 50), anchor: Anchor.bottomCenter);

  final EnvironmentTheme theme;
  final int variant;

  @override
  void render(Canvas canvas) {
    switch (theme) {
      case EnvironmentTheme.meadow:
        variant.isEven ? _drawRock(canvas) : _drawTreeStump(canvas);
      case EnvironmentTheme.beach:
        variant.isEven ? _drawSandcastle(canvas) : _drawCrab(canvas);
      case EnvironmentTheme.snow:
        variant.isEven ? _drawSnowman(canvas) : _drawIceBlock(canvas);
      case EnvironmentTheme.volcano:
        variant.isEven ? _drawLavaPool(canvas) : _drawMeteor(canvas);
    }
  }

  void _drawRock(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF9E9E9E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 15, 32, 35),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 15, 32, 35),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0x22FFFFFF),
    );
  }

  void _drawTreeStump(Canvas canvas) {
    // Trunk
    canvas.drawRect(
      Rect.fromLTWH(10, 10, 20, 40),
      Paint()..color = const Color(0xFF795548),
    );
    // Rings
    canvas.drawCircle(
      const Offset(20, 12),
      9,
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawCircle(
      const Offset(20, 12),
      5,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSandcastle(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE8C97A);
    // Base
    canvas.drawRect(Rect.fromLTWH(4, 30, 32, 20), paint);
    // Tower
    canvas.drawRect(Rect.fromLTWH(10, 12, 20, 20), paint);
    // Top
    _drawTriangle(canvas, const Offset(20, 4), 12, 10, paint);
  }

  void _drawCrab(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFFE53935);
    // Body
    canvas.drawOval(Rect.fromLTWH(8, 22, 24, 18), bodyPaint);
    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final dx in [-4.0, 36.0]) {
      canvas.drawLine(Offset(dx, 28), Offset(dx + (dx < 0 ? -6 : 6), 36), legPaint);
      canvas.drawLine(Offset(dx, 32), Offset(dx + (dx < 0 ? -6 : 6), 40), legPaint);
    }
    // Eyes
    canvas.drawCircle(const Offset(14, 20), 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(const Offset(26, 20), 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(const Offset(14, 20), 1.5, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(const Offset(26, 20), 1.5, Paint()..color = const Color(0xFF212121));
  }

  void _drawSnowman(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawCircle(const Offset(20, 40), 12, paint);
    canvas.drawCircle(const Offset(20, 22), 9, paint);
    canvas.drawCircle(const Offset(20, 10), 6, paint);
    // Eyes
    canvas.drawCircle(const Offset(17, 9), 1.5, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(const Offset(23, 9), 1.5, Paint()..color = const Color(0xFF212121));
    // Nose
    canvas.drawCircle(const Offset(20, 12), 1.5, Paint()..color = const Color(0xFFFF9800));
  }

  void _drawIceBlock(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(6, 16, 28, 34),
      Paint()..color = const Color(0xFF80DEEA),
    );
    canvas.drawRect(
      Rect.fromLTWH(6, 16, 28, 34),
      Paint()
        ..color = const Color(0xFFB2EBF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawLavaPool(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFF6D00);
    canvas.drawOval(Rect.fromLTWH(2, 30, 36, 18), paint);
    // Glow
    canvas.drawOval(
      Rect.fromLTWH(2, 30, 36, 18),
      Paint()
        ..color = const Color(0x55FFAB00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawMeteor(Canvas canvas) {
    canvas.drawCircle(
      const Offset(20, 25),
      14,
      Paint()..color = const Color(0xFF424242),
    );
    // Trail
    final trailPaint = Paint()..color = const Color(0xAAFF6D00);
    canvas.drawLine(const Offset(34, 20), const Offset(48, 12), trailPaint);
    canvas.drawLine(const Offset(32, 25), const Offset(46, 22), trailPaint);
  }

  void _drawTriangle(
    Canvas canvas,
    Offset top,
    double halfWidth,
    double height,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx - halfWidth, top.dy + height)
      ..lineTo(top.dx + halfWidth, top.dy + height)
      ..close();
    canvas.drawPath(path, paint);
  }
}
