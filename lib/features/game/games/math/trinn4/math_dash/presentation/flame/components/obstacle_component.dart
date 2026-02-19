import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Alignment, Colors, LinearGradient, Radius;

import '../../../domain/environment_theme.dart';

/// A theme-specific obstacle that scrolls left toward the runner.
///
/// All shapes use gradient fills, highlights, eyes, and scale-aware
/// coordinates to match the runner character's polish level.
class ObstacleComponent extends PositionComponent {
  ObstacleComponent({
    required this.theme,
    required this.variant,
    required super.position,
  }) : super(size: Vector2(40, 50), anchor: Anchor.bottomCenter);

  final EnvironmentTheme theme;
  final int variant;

  double _wobblePhase = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _wobblePhase += dt * 2.5;
  }

  @override
  void render(Canvas canvas) {
    final sx = size.x / 40;
    final sy = size.y / 50;

    // Subtle idle wobble.
    final wobble = sin(_wobblePhase * 2 * pi) * 1.5;
    canvas.save();
    canvas.translate(20 * sx, 50 * sy);
    canvas.rotate(wobble * pi / 180);
    canvas.translate(-20 * sx, -50 * sy);

    switch (theme) {
      case EnvironmentTheme.meadow:
        variant.isEven
            ? _drawRock(canvas, sx, sy)
            : _drawTreeStump(canvas, sx, sy);
      case EnvironmentTheme.beach:
        variant.isEven
            ? _drawSandcastle(canvas, sx, sy)
            : _drawCrab(canvas, sx, sy);
      case EnvironmentTheme.snow:
        variant.isEven
            ? _drawSnowman(canvas, sx, sy)
            : _drawIceBlock(canvas, sx, sy);
      case EnvironmentTheme.volcano:
        variant.isEven
            ? _drawLavaPool(canvas, sx, sy)
            : _drawMeteor(canvas, sx, sy);
    }

    canvas.restore();
  }

  // ── Shared helpers ──────────────────────────────────────────────

  void _drawGradientRRect(
    Canvas canvas,
    RRect rr,
    Color c1,
    Color c2,
  ) {
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ).createShader(rr.outerRect),
    );
    // Glossy overlay.
    canvas.drawRRect(
      rr,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  void _drawHighlight(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    double r,
    double sx,
    double sy,
  ) {
    canvas.drawRRect(
      RRect.fromLTRBR(
        x * sx,
        y * sy,
        (x + w) * sx,
        (y + h) * sy,
        Radius.circular(r * sx),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _drawEyes(
    Canvas canvas,
    double lx,
    double rx,
    double y,
    double outerR,
    double pupilR,
    double sx,
    double sy,
  ) {
    final white = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final pupil = Paint()..color = const Color(0xFF3D2B30);

    for (final ex in [lx, rx]) {
      canvas.drawCircle(Offset(ex * sx, y * sy), outerR * sx, white);
      canvas.drawCircle(Offset(ex * sx, y * sy), pupilR * sx, pupil);
    }
  }

  void _drawSmile(
    Canvas canvas,
    double cx,
    double y,
    double width,
    double depth,
    double strokeW,
    double sx,
    double sy,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF3D2B30).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * sx
      ..strokeCap = StrokeCap.round;
    final hw = width / 2;
    final path = Path()
      ..moveTo((cx - hw) * sx, y * sy)
      ..cubicTo(
        (cx - hw * 0.3) * sx,
        (y + depth) * sy,
        (cx + hw * 0.3) * sx,
        (y + depth) * sy,
        (cx + hw) * sx,
        y * sy,
      );
    canvas.drawPath(path, paint);
  }

  void _drawGradientOval(
    Canvas canvas,
    Rect rect,
    Color c1,
    Color c2,
  ) {
    canvas.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c1, c2],
        ).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  // ── Meadow ──────────────────────────────────────────────────────

  void _drawRock(Canvas canvas, double sx, double sy) {
    // Body
    final rr = RRect.fromLTRBR(
      4 * sx, 14 * sy, 36 * sx, 50 * sy,
      Radius.circular(10 * sx),
    );
    _drawGradientRRect(
      canvas, rr,
      const Color(0xFFB0BEC5),
      const Color(0xFF78909C),
    );
    // Highlight
    _drawHighlight(canvas, 6, 15, 28, 3, 2, sx, sy);
    // Moss patches
    final moss = Paint()..color = const Color(0xFF66BB6A).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(10 * sx, 42 * sy), 3 * sx, moss);
    canvas.drawCircle(Offset(30 * sx, 38 * sy), 2.5 * sx, moss);
    // Face
    _drawEyes(canvas, 14, 26, 28, 2.5, 1.3, sx, sy);
    _drawSmile(canvas, 20, 34, 8, 2.5, 0.8, sx, sy);
  }

  void _drawTreeStump(Canvas canvas, double sx, double sy) {
    // Trunk
    final trunkRR = RRect.fromLTRBR(
      10 * sx, 14 * sy, 30 * sx, 50 * sy,
      Radius.circular(3 * sx),
    );
    _drawGradientRRect(
      canvas, trunkRR,
      const Color(0xFF8D6E63),
      const Color(0xFF5D4037),
    );
    _drawHighlight(canvas, 12, 15, 16, 2.5, 1.5, sx, sy);
    // Top disc
    final topRR = RRect.fromLTRBR(
      8 * sx, 8 * sy, 32 * sx, 18 * sy,
      Radius.circular(5 * sx),
    );
    _drawGradientRRect(
      canvas, topRR,
      const Color(0xFFA1887F),
      const Color(0xFF8D6E63),
    );
    // Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF5D4037).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * sx;
    canvas.drawCircle(Offset(20 * sx, 13 * sy), 3.5 * sx, ringPaint);
    canvas.drawCircle(Offset(20 * sx, 13 * sy), 6 * sx, ringPaint);
    // Mushroom
    final capPaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(32 * sx, 40 * sy), 3 * sx, capPaint);
    canvas.drawRRect(
      RRect.fromLTRBR(
        31 * sx, 40 * sy, 33 * sx, 46 * sy,
        Radius.circular(0.5 * sx),
      ),
      Paint()..color = const Color(0xFFECEFF1),
    );
    // Face on trunk
    _drawEyes(canvas, 15, 25, 30, 2, 1.1, sx, sy);
    _drawSmile(canvas, 20, 36, 7, 2, 0.7, sx, sy);
  }

  // ── Beach ───────────────────────────────────────────────────────

  void _drawSandcastle(Canvas canvas, double sx, double sy) {
    // Base
    final baseRR = RRect.fromLTRBR(
      3 * sx, 30 * sy, 37 * sx, 50 * sy,
      Radius.circular(3 * sx),
    );
    _drawGradientRRect(
      canvas, baseRR,
      const Color(0xFFF0D58C),
      const Color(0xFFD4A843),
    );
    _drawHighlight(canvas, 5, 31, 30, 2.5, 1.5, sx, sy);
    // Tower
    final towerRR = RRect.fromLTRBR(
      10 * sx, 14 * sy, 30 * sx, 32 * sy,
      Radius.circular(2.5 * sx),
    );
    _drawGradientRRect(
      canvas, towerRR,
      const Color(0xFFF5DFA0),
      const Color(0xFFDDB955),
    );
    _drawHighlight(canvas, 12, 15, 16, 2, 1.2, sx, sy);
    // Battlements
    final battPaint = Paint()..color = const Color(0xFFDDB955);
    for (final bx in [11.0, 17.0, 23.0]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          bx * sx, 10 * sy, (bx + 4) * sx, 15 * sy,
          Radius.circular(1 * sx),
        ),
        battPaint,
      );
    }
    // Flag
    final flagPole = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 0.8 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(20 * sx, 4 * sy),
      Offset(20 * sx, 11 * sy),
      flagPole,
    );
    final flag = Path()
      ..moveTo(20.5 * sx, 4 * sy)
      ..lineTo(26 * sx, 5.5 * sy)
      ..lineTo(20.5 * sx, 7 * sy)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFE53935));
    // Face on tower
    _drawEyes(canvas, 15, 25, 22, 1.8, 1.0, sx, sy);
    _drawSmile(canvas, 20, 26, 6, 1.8, 0.6, sx, sy);
  }

  void _drawCrab(Canvas canvas, double sx, double sy) {
    // Body
    final bodyRect = Rect.fromLTWH(6 * sx, 24 * sy, 28 * sx, 18 * sy);
    _drawGradientOval(
      canvas, bodyRect,
      const Color(0xFFEF5350),
      const Color(0xFFC62828),
    );
    // Shell highlight
    canvas.drawOval(
      Rect.fromLTWH(10 * sx, 25 * sy, 20 * sx, 6 * sy),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    // Claws
    final clawPaint = Paint()..color = const Color(0xFFE53935);
    for (final side in [-1.0, 1.0]) {
      final cx = side < 0 ? 4.0 : 36.0;
      final claw = RRect.fromLTRBR(
        (cx - 4) * sx, 20 * sy, (cx + 4) * sx, 28 * sy,
        Radius.circular(3 * sx),
      );
      canvas.drawRRect(claw, clawPaint);
      // Claw slit
      canvas.drawLine(
        Offset(cx * sx, 21 * sy),
        Offset((cx + side * 3) * sx, 24 * sy),
        Paint()
          ..color = const Color(0xFFC62828)
          ..strokeWidth = 0.8 * sx
          ..strokeCap = StrokeCap.round,
      );
    }
    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 1.5 * sx
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final baseX = side < 0 ? 10.0 : 30.0;
      for (var i = 0; i < 3; i++) {
        final dy = 30.0 + i * 4.0;
        canvas.drawLine(
          Offset(baseX * sx, dy * sy),
          Offset((baseX + side * 8) * sx, (dy + 4) * sy),
          legPaint,
        );
      }
    }
    // Eye stalks
    final stalkPaint = Paint()
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 1.5 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(14 * sx, 25 * sy), Offset(13 * sx, 18 * sy), stalkPaint,
    );
    canvas.drawLine(
      Offset(26 * sx, 25 * sy), Offset(27 * sx, 18 * sy), stalkPaint,
    );
    _drawEyes(canvas, 13, 27, 16, 2.8, 1.5, sx, sy);
    _drawSmile(canvas, 20, 34, 8, 2, 0.7, sx, sy);
  }

  // ── Snow ────────────────────────────────────────────────────────

  void _drawSnowman(Canvas canvas, double sx, double sy) {
    // Bottom ball
    _drawGradientOval(
      canvas,
      Rect.fromCenter(
        center: Offset(20 * sx, 40 * sy),
        width: 24 * sx,
        height: 22 * sy,
      ),
      const Color(0xFFF5F5F5),
      const Color(0xFFCFD8DC),
    );
    // Middle ball
    _drawGradientOval(
      canvas,
      Rect.fromCenter(
        center: Offset(20 * sx, 24 * sy),
        width: 18 * sx,
        height: 16 * sy,
      ),
      const Color(0xFFFAFAFA),
      const Color(0xFFE0E0E0),
    );
    // Head
    _drawGradientOval(
      canvas,
      Rect.fromCenter(
        center: Offset(20 * sx, 11 * sy),
        width: 14 * sx,
        height: 13 * sy,
      ),
      const Color(0xFFFFFFFF),
      const Color(0xFFECEFF1),
    );
    // Scarf
    final scarfBody = RRect.fromLTRBR(
      13 * sx, 17 * sy, 27 * sx, 20 * sy,
      Radius.circular(1 * sx),
    );
    canvas.drawRRect(
      scarfBody,
      Paint()..color = const Color(0xFFE53935),
    );
    // Scarf tail
    canvas.drawRRect(
      RRect.fromLTRBR(
        25 * sx, 19 * sy, 29 * sx, 27 * sy,
        Radius.circular(1 * sx),
      ),
      Paint()..color = const Color(0xFFD32F2F),
    );
    // Buttons
    final buttonPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset(20 * sx, 22 * sy), 1.2 * sx, buttonPaint);
    canvas.drawCircle(Offset(20 * sx, 27 * sy), 1.2 * sx, buttonPaint);
    canvas.drawCircle(Offset(20 * sx, 32 * sy), 1.2 * sx, buttonPaint);
    // Carrot nose
    final nose = Path()
      ..moveTo(20 * sx, 11 * sy)
      ..lineTo(27 * sx, 12.5 * sy)
      ..lineTo(20 * sx, 13 * sy)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFFF9800));
    // Twig arms
    final twigPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.2 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(11 * sx, 24 * sy), Offset(2 * sx, 18 * sy), twigPaint,
    );
    canvas.drawLine(
      Offset(3 * sx, 19 * sy), Offset(0 * sx, 16 * sy), twigPaint,
    );
    canvas.drawLine(
      Offset(29 * sx, 24 * sy), Offset(38 * sx, 18 * sy), twigPaint,
    );
    canvas.drawLine(
      Offset(37 * sx, 19 * sy), Offset(40 * sx, 16 * sy), twigPaint,
    );
    // Face
    _drawEyes(canvas, 16, 24, 9, 1.8, 1.0, sx, sy);
    _drawSmile(canvas, 20, 14, 5, 1.5, 0.6, sx, sy);
  }

  void _drawIceBlock(Canvas canvas, double sx, double sy) {
    // Main block
    final rr = RRect.fromLTRBR(
      5 * sx, 12 * sy, 35 * sx, 50 * sy,
      Radius.circular(4 * sx),
    );
    _drawGradientRRect(
      canvas, rr,
      const Color(0xFF80DEEA),
      const Color(0xFF00ACC1),
    );
    _drawHighlight(canvas, 7, 13, 26, 3, 2, sx, sy);
    // Inner frost lines
    final frostPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.8 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(10 * sx, 20 * sy), Offset(18 * sx, 26 * sy), frostPaint,
    );
    canvas.drawLine(
      Offset(18 * sx, 26 * sy), Offset(14 * sx, 34 * sy), frostPaint,
    );
    canvas.drawLine(
      Offset(24 * sx, 18 * sy), Offset(30 * sx, 28 * sy), frostPaint,
    );
    canvas.drawLine(
      Offset(30 * sx, 28 * sy), Offset(26 * sx, 38 * sy), frostPaint,
    );
    // Sparkle dots
    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(12 * sx, 18 * sy), 1 * sx, sparkle);
    canvas.drawCircle(Offset(28 * sx, 22 * sy), 0.8 * sx, sparkle);
    canvas.drawCircle(Offset(16 * sx, 40 * sy), 0.7 * sx, sparkle);
    // Face
    _drawEyes(canvas, 14, 26, 26, 2.2, 1.2, sx, sy);
    _drawSmile(canvas, 20, 33, 8, 2, 0.7, sx, sy);
  }

  // ── Volcano ─────────────────────────────────────────────────────

  void _drawLavaPool(Canvas canvas, double sx, double sy) {
    // Outer glow
    canvas.drawOval(
      Rect.fromLTWH(0 * sx, 26 * sy, 40 * sx, 24 * sy),
      Paint()
        ..color = const Color(0x44FF6D00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Pool
    final poolRect = Rect.fromLTWH(2 * sx, 28 * sy, 36 * sx, 20 * sy);
    _drawGradientOval(
      canvas, poolRect,
      const Color(0xFFFF9100),
      const Color(0xFFE65100),
    );
    // Inner bright core
    canvas.drawOval(
      Rect.fromLTWH(10 * sx, 32 * sy, 20 * sx, 10 * sy),
      Paint()..color = const Color(0xFFFFAB00).withValues(alpha: 0.35),
    );
    // Bubbles
    final bubble = sin(_wobblePhase * 2 * pi);
    final bubblePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(14 * sx, (34 + bubble * 2) * sy),
      2 * sx,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(26 * sx, (36 - bubble * 1.5) * sy),
      1.5 * sx,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(20 * sx, (33 + bubble) * sy),
      1 * sx,
      bubblePaint,
    );
    // Face
    _drawEyes(canvas, 14, 26, 36, 2.2, 1.2, sx, sy);
    // Angry brows
    final browPaint = Paint()
      ..color = const Color(0xFF3D2B30).withValues(alpha: 0.7)
      ..strokeWidth = 0.8 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(11 * sx, 33 * sy), Offset(15.5 * sx, 34.5 * sy), browPaint,
    );
    canvas.drawLine(
      Offset(29 * sx, 33 * sy), Offset(24.5 * sx, 34.5 * sy), browPaint,
    );
  }

  void _drawMeteor(Canvas canvas, double sx, double sy) {
    // Trail glow
    final trailGlow = Paint()
      ..color = const Color(0x55FF6D00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final trailPath = Path()
      ..moveTo(32 * sx, 18 * sy)
      ..lineTo(48 * sx, 8 * sy)
      ..lineTo(48 * sx, 20 * sy)
      ..lineTo(32 * sx, 28 * sy)
      ..close();
    canvas.drawPath(trailPath, trailGlow);
    // Trail streaks
    final streakPaint = Paint()
      ..color = const Color(0xCCFF8F00)
      ..strokeWidth = 1.5 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(32 * sx, 20 * sy), Offset(44 * sx, 14 * sy), streakPaint,
    );
    canvas.drawLine(
      Offset(30 * sx, 26 * sy), Offset(42 * sx, 22 * sy), streakPaint,
    );
    canvas.drawLine(
      Offset(34 * sx, 14 * sy), Offset(40 * sx, 10 * sy), streakPaint,
    );
    // Core
    final coreRect = Rect.fromCenter(
      center: Offset(20 * sx, 24 * sy),
      width: 28 * sx,
      height: 28 * sy,
    );
    canvas.drawOval(
      coreRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF616161), Color(0xFF212121)],
        ).createShader(coreRect),
    );
    canvas.drawOval(
      coreRect,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    // Highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(16 * sx, 18 * sy),
        width: 10 * sx,
        height: 6 * sy,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    // Crater dents
    final craterPaint = Paint()
      ..color = const Color(0xFF424242).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(24 * sx, 28 * sy), 2.5 * sx, craterPaint);
    canvas.drawCircle(Offset(14 * sx, 26 * sy), 1.5 * sx, craterPaint);
    // Face
    _drawEyes(canvas, 15, 25, 22, 2.5, 1.3, sx, sy);
    // Angry brows
    final browPaint = Paint()
      ..color = const Color(0xFF3D2B30).withValues(alpha: 0.8)
      ..strokeWidth = 0.9 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12 * sx, 19 * sy), Offset(16.5 * sx, 20.5 * sy), browPaint,
    );
    canvas.drawLine(
      Offset(28 * sx, 19 * sy), Offset(23.5 * sx, 20.5 * sy), browPaint,
    );
    _drawSmile(canvas, 20, 28, 6, -1.5, 0.7, sx, sy);
  }
}
