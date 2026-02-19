import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Alignment, Colors, HSLColor, LinearGradient, Radius;

import '../../../domain/environment_theme.dart';

/// Procedural 3-layer parallax background that scrolls with the runner.
///
/// Each layer is rich with gradient-filled terrain, theme-specific props,
/// highlights, and atmospheric effects — matching the obstacle/runner
/// polish level.
class ParallaxBackground extends PositionComponent {
  ParallaxBackground({required this.gameSize})
    : super(size: gameSize, position: Vector2.zero());

  final Vector2 gameSize;
  EnvironmentTheme _theme = EnvironmentTheme.meadow;
  EnvironmentTheme? _nextTheme;
  double _transitionProgress = 1.0;
  double _farOffset = 0;
  double _midOffset = 0;
  double _nearOffset = 0;
  double _time = 0;

  static const _farFactor = 0.2;
  static const _midFactor = 0.5;
  static const _nearFactor = 0.8;

  set theme(EnvironmentTheme value) {
    if (value == _theme && _nextTheme == null) return;
    if (value == _theme) return;
    _nextTheme = value;
    _transitionProgress = 0;
  }

  void scroll(double dx) {
    _farOffset += dx * _farFactor;
    _midOffset += dx * _midFactor;
    _nearOffset += dx * _nearFactor;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_nextTheme != null && _transitionProgress < 1.0) {
      _transitionProgress =
          (_transitionProgress + dt / 1.5).clamp(0.0, 1.0);
      if (_transitionProgress >= 1.0) {
        _theme = _nextTheme!;
        _nextTheme = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _drawSky(canvas);
    _drawAtmosphere(canvas);
    _drawFarLayer(canvas);
    _drawMidLayer(canvas);
    _drawNearLayer(canvas);
  }

  // ── Sky ────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas) {
    final skyTop = _lerpColor((t) => t.skyTop);
    final skyBottom = _lerpColor((t) => t.skyBottom);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, size.y * 0.6),
          [skyTop, skyBottom],
        ),
    );
  }

  void _drawAtmosphere(Canvas canvas) {
    final active = _nextTheme ?? _theme;
    switch (active) {
      case EnvironmentTheme.meadow:
        _drawClouds(canvas, Colors.white.withValues(alpha: 0.35));
        _drawSunGlow(canvas);
      case EnvironmentTheme.beach:
        _drawClouds(canvas, Colors.white.withValues(alpha: 0.25));
        _drawSunGlow(canvas);
        _drawSunReflection(canvas);
      case EnvironmentTheme.snow:
        _drawClouds(
          canvas, const Color(0xFFCFD8DC).withValues(alpha: 0.4),
        );
        _drawSnowfall(canvas);
      case EnvironmentTheme.volcano:
        _drawStarfield(canvas);
        _drawEmbers(canvas);
    }
  }

  // ── Atmospheric effects ────────────────────────────────────────

  void _drawClouds(Canvas canvas, Color color) {
    final rng = math.Random(7);
    final drift = _time * 4;
    for (var i = 0; i < 5; i++) {
      final baseX = rng.nextDouble() * size.x * 1.5;
      final y = 10 + rng.nextDouble() * size.y * 0.25;
      final w = 40 + rng.nextDouble() * 60;
      final h = 12 + rng.nextDouble() * 10;
      final x = (baseX - drift) % (size.x + w * 2) - w;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(h / 2),
      );
      canvas.drawRRect(rr, Paint()..color = color);
      // Highlight puff
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * 0.15, y, w * 0.5, h * 0.5),
          Radius.circular(h / 3),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  void _drawSunGlow(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x * 0.82, size.y * 0.1),
      30,
      Paint()
        ..color = const Color(0x22FFEB3B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    canvas.drawCircle(
      Offset(size.x * 0.82, size.y * 0.1),
      12,
      Paint()..color = const Color(0x44FFF9C4),
    );
  }

  void _drawSunReflection(Canvas canvas) {
    final shimmer = math.sin(_time * 2) * 0.08 + 0.15;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.82, size.y * 0.58),
        width: 80,
        height: 6,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: shimmer)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawStarfield(Canvas canvas) {
    final rng = math.Random(42);
    final twinkle = _time * 1.5;
    for (var i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.x;
      final y = rng.nextDouble() * size.y * 0.45;
      final baseR = 0.4 + rng.nextDouble() * 1.2;
      final phase = rng.nextDouble() * math.pi * 2;
      final flicker = 0.5 + 0.5 * math.sin(twinkle * (1 + i * 0.1) + phase);
      canvas.drawCircle(
        Offset(x, y),
        baseR * flicker,
        Paint()..color = Colors.white.withValues(alpha: 0.6 * flicker),
      );
    }
  }

  void _drawEmbers(Canvas canvas) {
    final rng = math.Random(99);
    for (var i = 0; i < 12; i++) {
      final baseX = rng.nextDouble() * size.x;
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final yOff = (_time * speed * 30 + i * 40) % (size.y * 0.8);
      final y = size.y * 0.8 - yOff;
      final wobble = math.sin(_time * 2 + i) * 8;
      final alpha = ((1.0 - yOff / (size.y * 0.8)) * 0.6).clamp(0.0, 0.6);
      canvas.drawCircle(
        Offset(baseX + wobble, y),
        1.0 + rng.nextDouble(),
        Paint()..color = Color.fromARGB(
          (alpha * 255).round(), 0xFF, 0x6D, 0x00,
        ),
      );
    }
  }

  void _drawSnowfall(Canvas canvas) {
    final rng = math.Random(77);
    for (var i = 0; i < 20; i++) {
      final baseX = rng.nextDouble() * size.x;
      final speed = 0.2 + rng.nextDouble() * 0.4;
      final yOff = (_time * speed * 40 + i * 30) % size.y;
      final drift = math.sin(_time * 1.5 + i * 0.7) * 10;
      final r = 0.8 + rng.nextDouble() * 1.5;
      canvas.drawCircle(
        Offset(baseX + drift, yOff),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  // ── Far layer ──────────────────────────────────────────────────

  void _drawFarLayer(Canvas canvas) {
    final color = _lerpColor((t) => t.farColor);
    const tileW = 200.0;
    final y = size.y * 0.55;
    final h = size.y - y;

    for (var x = -(_farOffset % tileW); x < size.x + tileW; x += tileW) {
      _drawGradientHill(canvas, x, y, tileW, h, color, 0.22);

      final active = _nextTheme ?? _theme;
      switch (active) {
        case EnvironmentTheme.meadow:
          _drawFarMeadow(canvas, x, y, tileW, h);
        case EnvironmentTheme.beach:
          _drawFarBeach(canvas, x, y, tileW, h);
        case EnvironmentTheme.snow:
          _drawFarSnow(canvas, x, y, tileW, h);
        case EnvironmentTheme.volcano:
          _drawFarVolcano(canvas, x, y, tileW, h);
      }
    }
  }

  void _drawFarMeadow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Distant tree clusters
    final treePaint = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(x + w * 0.3, y + h * 0.3), 10, treePaint);
    canvas.drawCircle(Offset(x + w * 0.4, y + h * 0.25), 13, treePaint);
    canvas.drawCircle(Offset(x + w * 0.5, y + h * 0.3), 9, treePaint);
    // Highlight on hills
    canvas.drawOval(
      Rect.fromLTWH(x + w * 0.2, y + h * 0.35, w * 0.3, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
  }

  void _drawFarBeach(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Ocean waves
    final wavePaint = Paint()
      ..color = const Color(0xFF039BE5).withValues(alpha: 0.3);
    final waveY = y + h * 0.4 + math.sin(_time * 0.8 + x * 0.02) * 3;
    canvas.drawOval(
      Rect.fromLTWH(x, waveY, w, 8),
      wavePaint,
    );
    // Distant sailboat
    if ((x / w).round() % 3 == 0) {
      final bx = x + w * 0.6;
      final by = y + h * 0.25;
      // Hull
      canvas.drawOval(
        Rect.fromLTWH(bx - 6, by, 12, 4),
        Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.4),
      );
      // Sail
      final sail = Path()
        ..moveTo(bx, by - 1)
        ..lineTo(bx + 5, by - 10)
        ..lineTo(bx, by - 10)
        ..close();
      canvas.drawPath(
        sail, Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  void _drawFarSnow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Mountain peaks with snow caps
    final peakX = x + w * 0.5;
    final peakY = y - h * 0.3;
    // Mountain body
    final mountain = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(peakX - w * 0.45, y + h * 0.6)
      ..lineTo(peakX + w * 0.45, y + h * 0.6)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = const Color(0xFF78909C).withValues(alpha: 0.5),
    );
    // Snow cap
    final cap = Path()
      ..moveTo(peakX, peakY)
      ..lineTo(peakX - w * 0.15, peakY + h * 0.25)
      ..lineTo(peakX + w * 0.15, peakY + h * 0.25)
      ..close();
    canvas.drawPath(
      cap,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    // Ridge highlight
    canvas.drawLine(
      Offset(peakX, peakY),
      Offset(peakX + w * 0.1, peakY + h * 0.15),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFarVolcano(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Volcanic mountain
    final peakX = x + w * 0.5;
    final peakY = y - h * 0.25;
    final mtn = Path()
      ..moveTo(peakX - 8, peakY)
      ..lineTo(peakX - w * 0.4, y + h * 0.6)
      ..lineTo(peakX + w * 0.4, y + h * 0.6)
      ..lineTo(peakX + 8, peakY)
      ..close();
    canvas.drawPath(
      mtn,
      Paint()..color = const Color(0xFF37474F).withValues(alpha: 0.6),
    );
    // Lava cracks
    final crackPaint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(peakX - 3, peakY + 2),
      Offset(peakX - 15, peakY + h * 0.35),
      crackPaint,
    );
    canvas.drawLine(
      Offset(peakX + 3, peakY + 2),
      Offset(peakX + 12, peakY + h * 0.4),
      crackPaint,
    );
    // Crater glow
    canvas.drawOval(
      Rect.fromLTWH(peakX - 8, peakY - 4, 16, 6),
      Paint()
        ..color = const Color(0x44FF6D00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  // ── Mid layer ──────────────────────────────────────────────────

  void _drawMidLayer(Canvas canvas) {
    final color = _lerpColor((t) => t.midColor);
    const tileW = 140.0;
    final y = size.y * 0.72;
    final h = size.y - y;

    for (var x = -(_midOffset % tileW); x < size.x + tileW; x += tileW) {
      _drawGradientHill(canvas, x, y, tileW, h, color, 0.12);

      final active = _nextTheme ?? _theme;
      switch (active) {
        case EnvironmentTheme.meadow:
          _drawMidMeadow(canvas, x, y, tileW, h);
        case EnvironmentTheme.beach:
          _drawMidBeach(canvas, x, y, tileW, h);
        case EnvironmentTheme.snow:
          _drawMidSnow(canvas, x, y, tileW, h);
        case EnvironmentTheme.volcano:
          _drawMidVolcano(canvas, x, y, tileW, h);
      }
    }
  }

  void _drawMidMeadow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Gradient bush
    final bushCenter = Offset(x + w * 0.5, y + h * 0.15);
    _drawGradientCircle(
      canvas, bushCenter, 14,
      const Color(0xFF43A047), const Color(0xFF2E7D32), 0.5,
    );
    _drawGradientCircle(
      canvas, bushCenter + const Offset(-9, 3), 10,
      const Color(0xFF4CAF50), const Color(0xFF388E3C), 0.45,
    );
    // Highlight
    canvas.drawCircle(
      bushCenter + const Offset(-2, -5),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
  }

  void _drawMidBeach(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Sand dune with gradient
    final duneRect = Rect.fromLTWH(x + 10, y + h * 0.1, w - 20, h * 0.5);
    canvas.drawOval(
      duneRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5DFA0).withValues(alpha: 0.5),
            const Color(0xFFE8C97A).withValues(alpha: 0.4),
          ],
        ).createShader(duneRect),
    );
    // Shells
    final shellPaint = Paint()..color = const Color(0xFFFFF3E0).withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromLTWH(x + w * 0.3, y + h * 0.15, 5, 3.5),
      shellPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(x + w * 0.7, y + h * 0.2, 4, 3),
      shellPaint,
    );
    // Ripple lines
    final ripple = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final ry = y + h * 0.05 + math.sin(_time + x * 0.05) * 2;
    canvas.drawOval(
      Rect.fromLTWH(x + 5, ry, w - 10, 4),
      ripple,
    );
  }

  void _drawMidSnow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Pine tree with layered gradient triangles
    final treeX = x + w * 0.5;
    final treeY = y - 8;
    for (var i = 0; i < 3; i++) {
      final ty = treeY + i * 8.0;
      final halfW = 12.0 - i * 2.0;
      final th = 14.0;
      final tri = Path()
        ..moveTo(treeX, ty)
        ..lineTo(treeX - halfW, ty + th)
        ..lineTo(treeX + halfW, ty + th)
        ..close();
      canvas.drawPath(
        tri,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32).withValues(alpha: 0.6),
              const Color(0xFF1B5E20).withValues(alpha: 0.5),
            ],
          ).createShader(Rect.fromLTWH(treeX - halfW, ty, halfW * 2, th)),
      );
      // Snow on branches
      canvas.drawOval(
        Rect.fromLTWH(treeX - halfW * 0.6, ty + 1, halfW * 1.2, 3),
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }
    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(treeX - 2, treeY + 26, 4, 8),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.5),
    );
    // Snow mound at base
    canvas.drawOval(
      Rect.fromLTWH(treeX - 10, y + h * 0.1, 20, 7),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawMidVolcano(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Rocky formation
    final rockRR = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + w * 0.25, y - 5, w * 0.5, h * 0.6),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rockRR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF424242).withValues(alpha: 0.6),
            const Color(0xFF212121).withValues(alpha: 0.5),
          ],
        ).createShader(rockRR.outerRect),
    );
    // Highlight edge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + w * 0.27, y - 4, w * 0.3, 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    // Mini lava pool
    final poolY = y + h * 0.25;
    canvas.drawOval(
      Rect.fromLTWH(x + w * 0.15, poolY, w * 0.3, 6),
      Paint()
        ..color = const Color(0xFFFF6D00).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawOval(
      Rect.fromLTWH(x + w * 0.18, poolY + 1, w * 0.24, 4),
      Paint()..color = const Color(0xFFFFAB00).withValues(alpha: 0.3),
    );
  }

  // ── Near layer ─────────────────────────────────────────────────

  void _drawNearLayer(Canvas canvas) {
    final color = _lerpColor((t) => t.nearColor);
    const tileW = 100.0;
    final y = size.y * 0.85;
    final h = size.y - y;

    for (var x = -(_nearOffset % tileW); x < size.x + tileW; x += tileW) {
      _drawGradientHill(canvas, x, y, tileW, h, color, 0.06);

      final active = _nextTheme ?? _theme;
      switch (active) {
        case EnvironmentTheme.meadow:
          _drawNearMeadow(canvas, x, y, tileW, h);
        case EnvironmentTheme.beach:
          _drawNearBeach(canvas, x, y, tileW, h);
        case EnvironmentTheme.snow:
          _drawNearSnow(canvas, x, y, tileW, h);
        case EnvironmentTheme.volcano:
          _drawNearVolcano(canvas, x, y, tileW, h);
      }
    }
  }

  void _drawNearMeadow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Grass tufts
    final grassPaint = Paint()
      ..color = const Color(0xFF388E3C).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(x.toInt() + 1);
    for (var i = 0; i < 5; i++) {
      final gx = x + rng.nextDouble() * w;
      final gy = y + 2 + rng.nextDouble() * h * 0.3;
      final sway = math.sin(_time * 1.5 + gx * 0.1) * 2;
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + sway, gy - 5 - rng.nextDouble() * 3),
        grassPaint,
      );
    }
    // Stone
    if (rng.nextDouble() > 0.5) {
      final sx = x + w * 0.6;
      final sy = y + h * 0.15;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 6, height: 4),
        Paint()..color = const Color(0xFF9E9E9E).withValues(alpha: 0.4),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx - 1, sy - 1), width: 3, height: 2),
        Paint()..color = Colors.white.withValues(alpha: 0.1),
      );
    }
  }

  void _drawNearBeach(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Palm tree
    final px = x + w * 0.5;
    final py = y - 2;
    // Trunk gradient
    final trunkRect = Rect.fromLTWH(px - 2.5, py - 28, 5, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunkRect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8D6E63),
            const Color(0xFF5D4037),
          ],
        ).createShader(trunkRect),
    );
    // Trunk ridges
    final ridgePaint = Paint()
      ..color = const Color(0xFF4E342E).withValues(alpha: 0.3)
      ..strokeWidth = 0.6;
    for (var ry = py - 25.0; ry < py; ry += 4) {
      canvas.drawLine(
        Offset(px - 2.5, ry), Offset(px + 2.5, ry), ridgePaint,
      );
    }
    // Canopy — gradient leaves
    final leafColors = [
      const Color(0xFF2E7D32), const Color(0xFF388E3C),
      const Color(0xFF43A047),
    ];
    final sway = math.sin(_time * 1.2 + x * 0.05) * 3;
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi * 0.8 + i * math.pi * 0.4;
      final lx = px + math.cos(angle) * 14 + sway;
      final ly = py - 32 + math.sin(angle) * 6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: 16, height: 7),
        Paint()..color = leafColors[i % 3].withValues(alpha: 0.7),
      );
    }
    // Starfish
    final rng = math.Random(x.toInt());
    if (rng.nextBool()) {
      _drawStarfish(canvas, Offset(x + rng.nextDouble() * w, y + h * 0.12));
    }
  }

  void _drawNearSnow(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Snow drift
    canvas.drawOval(
      Rect.fromLTWH(x + 5, y - 2, w * 0.6, 8),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.drawOval(
      Rect.fromLTWH(x + 5, y - 2, w * 0.4, 3),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    // Icicles from drift edge
    final rng = math.Random(x.toInt() + 3);
    for (var i = 0; i < 3; i++) {
      final ix = x + 10 + i * 12.0 + rng.nextDouble() * 5;
      final ih = 4 + rng.nextDouble() * 4;
      final icicle = Path()
        ..moveTo(ix - 1.5, y - 1)
        ..lineTo(ix, y - 1 + ih)
        ..lineTo(ix + 1.5, y - 1)
        ..close();
      canvas.drawPath(
        icicle,
        Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.5),
      );
    }
    // Frozen puddle
    if (rng.nextBool()) {
      final fx = x + w * 0.65;
      final fy = y + h * 0.1;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: 14, height: 5),
        Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.25),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(fx - 2, fy - 1), width: 6, height: 2,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  void _drawNearVolcano(
    Canvas canvas, double x, double y, double w, double h,
  ) {
    // Cracked ground
    final crackPaint = Paint()
      ..color = const Color(0xFFFF6D00).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(x.toInt() + 5);
    final cx = x + rng.nextDouble() * w * 0.6 + w * 0.2;
    final cy = y + h * 0.15;
    for (var i = 0; i < 3; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final len = 6 + rng.nextDouble() * 10;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * len, cy + math.sin(angle) * len),
        crackPaint,
      );
    }
    // Glow from crack
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()
        ..color = const Color(0x22FF6D00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Volcanic rock
    final rx = x + w * 0.7;
    final ry = y + h * 0.05;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx, ry), width: 8, height: 5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF616161).withValues(alpha: 0.5),
            const Color(0xFF37474F).withValues(alpha: 0.4),
          ],
        ).createShader(
          Rect.fromCenter(center: Offset(rx, ry), width: 8, height: 5),
        ),
    );
  }

  // ── Shared drawing helpers ─────────────────────────────────────

  void _drawGradientHill(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color color,
    double peakRise,
  ) {
    final peakY = y - h * peakRise;
    final path = Path()
      ..moveTo(x, y + h * 0.3)
      ..quadraticBezierTo(x + w * 0.5, peakY, x + w, y + h * 0.3)
      ..lineTo(x + w, size.y)
      ..lineTo(x, size.y)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          Offset(x, peakY),
          Offset(x, size.y),
          [color, _darken(color, 0.15)],
        ),
    );
    // Hill highlight
    final hlPath = Path()
      ..moveTo(x + w * 0.15, y + h * 0.25)
      ..quadraticBezierTo(
        x + w * 0.5, peakY + 2, x + w * 0.85, y + h * 0.25,
      )
      ..quadraticBezierTo(
        x + w * 0.5, peakY + 6, x + w * 0.15, y + h * 0.25,
      )
      ..close();
    canvas.drawPath(
      hlPath,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  void _drawGradientCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color c1,
    Color c2,
    double alpha,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c1.withValues(alpha: alpha), c2.withValues(alpha: alpha)],
        ).createShader(rect),
    );
  }

  void _drawStarfish(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.5);
    const arms = 5;
    const outerR = 4.0;
    const innerR = 1.8;
    final path = Path();
    for (var i = 0; i < arms * 2; i++) {
      final angle = (i * math.pi / arms) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      center, 1, Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  Color _lerpColor(Color Function(EnvironmentTheme) pick) {
    if (_nextTheme == null) return pick(_theme);
    return Color.lerp(
      pick(_theme), pick(_nextTheme!), _transitionProgress,
    )!;
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0, 1))
        .toColor();
  }
}
