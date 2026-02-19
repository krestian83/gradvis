import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/environment_theme.dart';

/// Procedural 3-layer parallax background that scrolls with the runner.
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
    if (_nextTheme != null && _transitionProgress < 1.0) {
      _transitionProgress = (_transitionProgress + dt / 1.5).clamp(0.0, 1.0);
      if (_transitionProgress >= 1.0) {
        _theme = _nextTheme!;
        _nextTheme = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _drawSky(canvas);
    _drawLayer(canvas, _farOffset, _theme.farColor, 0.55, _drawFarDetails);
    _drawLayer(canvas, _midOffset, _theme.midColor, 0.72, _drawMidDetails);
    _drawLayer(canvas, _nearOffset, _theme.nearColor, 0.85, _drawNearDetails);
  }

  void _drawSky(Canvas canvas) {
    final skyTop = _lerpThemeColor((t) => t.skyTop);
    final skyBottom = _lerpThemeColor((t) => t.skyBottom);
    final skyPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        Offset(0, size.y * 0.6),
        [skyTop, skyBottom],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), skyPaint);
  }

  Color _lerpThemeColor(Color Function(EnvironmentTheme) pick) {
    if (_nextTheme == null) return pick(_theme);
    return Color.lerp(pick(_theme), pick(_nextTheme!), _transitionProgress)!;
  }

  void _drawLayer(
    Canvas canvas,
    double offset,
    Color color,
    double heightFraction,
    void Function(Canvas, double, double, double) detailsFn,
  ) {
    final y = size.y * heightFraction;
    final h = size.y - y;
    final scrollMod = offset % size.x;

    detailsFn(canvas, scrollMod, y, h);
  }

  void _drawFarDetails(Canvas canvas, double offset, double y, double h) {
    final paint = Paint()..color = _lerpThemeColor((t) => t.farColor);
    // Rolling hills / mountains
    const hillWidth = 200.0;
    for (var x = -offset; x < size.x + hillWidth; x += hillWidth) {
      final path = Path()
        ..moveTo(x, y + h * 0.6)
        ..quadraticBezierTo(x + hillWidth * 0.5, y - h * 0.2, x + hillWidth, y + h * 0.6)
        ..lineTo(x + hillWidth, size.y)
        ..lineTo(x, size.y)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawMidDetails(Canvas canvas, double offset, double y, double h) {
    final paint = Paint()..color = _lerpThemeColor((t) => t.midColor);
    const width = 140.0;
    for (var x = -offset; x < size.x + width; x += width) {
      final path = Path()
        ..moveTo(x, y + h * 0.3)
        ..quadraticBezierTo(x + width * 0.5, y - h * 0.1, x + width, y + h * 0.3)
        ..lineTo(x + width, size.y)
        ..lineTo(x, size.y)
        ..close();
      canvas.drawPath(path, paint);

      // Theme-specific detail
      if (_theme == EnvironmentTheme.meadow ||
          (_nextTheme == EnvironmentTheme.meadow && _transitionProgress < 0.5)) {
        // Bush
        canvas.drawCircle(
          Offset(x + width * 0.5, y + h * 0.25),
          12,
          Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.6),
        );
      } else if (_theme == EnvironmentTheme.snow) {
        // Pine tree
        _drawTriangle(
          canvas,
          Offset(x + width * 0.5, y - 5),
          18,
          30,
          Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.5),
        );
      }
    }
  }

  void _drawNearDetails(Canvas canvas, double offset, double y, double h) {
    final paint = Paint()..color = _lerpThemeColor((t) => t.nearColor);
    const width = 100.0;
    for (var x = -offset; x < size.x + width; x += width) {
      final path = Path()
        ..moveTo(x, y + h * 0.15)
        ..quadraticBezierTo(
          x + width * 0.5, y - h * 0.05,
          x + width, y + h * 0.15,
        )
        ..lineTo(x + width, size.y)
        ..lineTo(x, size.y)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Theme-specific near elements
    if (_theme == EnvironmentTheme.beach) {
      for (var x = -offset % 180; x < size.x + 30; x += 180) {
        _drawPalmTree(canvas, Offset(x, y));
      }
    } else if (_theme == EnvironmentTheme.volcano) {
      // Star dots
      final starPaint = Paint()..color = const Color(0xFFFFFFFF);
      final rng = math.Random(42);
      for (var i = 0; i < 20; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * size.x, rng.nextDouble() * y * 0.6),
          rng.nextDouble() * 1.5 + 0.5,
          starPaint,
        );
      }
    }
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

  void _drawPalmTree(Canvas canvas, Offset base) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(center: base + const Offset(0, -15), width: 6, height: 30),
      Paint()..color = const Color(0xFF795548),
    );
    // Canopy
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(base + const Offset(0, -32), 14, leafPaint);
    canvas.drawCircle(base + const Offset(-10, -28), 10, leafPaint);
    canvas.drawCircle(base + const Offset(10, -28), 10, leafPaint);
  }
}
