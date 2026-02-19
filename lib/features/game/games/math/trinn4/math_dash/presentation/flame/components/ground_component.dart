import 'dart:ui';

import 'package:flame/components.dart';

import '../../../domain/environment_theme.dart';

/// Scrolling ground strip at the bottom of the screen.
class GroundComponent extends PositionComponent {
  GroundComponent({required this.gameSize})
    : super(
        position: Vector2(0, gameSize.y - _groundHeight),
        size: Vector2(gameSize.x, _groundHeight),
      );

  static const _groundHeight = 50.0;
  static const _lineSpacing = 24.0;

  final Vector2 gameSize;
  EnvironmentTheme _theme = EnvironmentTheme.meadow;
  double _scrollOffset = 0;

  set theme(EnvironmentTheme value) => _theme = value;

  void scroll(double dx) {
    _scrollOffset = (_scrollOffset + dx) % _lineSpacing;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = _theme.groundColor);

    // Texture lines
    final linePaint = Paint()
      ..color = _theme.groundAccent
      ..strokeWidth = 1.2;
    for (var x = -_scrollOffset; x < size.x + _lineSpacing; x += _lineSpacing) {
      canvas.drawLine(
        Offset(x, 4),
        Offset(x - 8, size.y),
        linePaint,
      );
    }

    // Top edge highlight
    canvas.drawLine(
      Offset.zero,
      Offset(size.x, 0),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 2,
    );
  }
}
