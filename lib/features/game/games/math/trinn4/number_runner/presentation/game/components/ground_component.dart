import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// A scrolling brown ground strip at the bottom of the screen.
class GroundComponent extends PositionComponent {
  static const double groundHeight = 40;
  static const Color _color = Color(0xFF8D6E63);

  double _scrollOffset = 0;

  GroundComponent();

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = _color;
    canvas.drawRect(size.toRect(), paint);

    // Scrolling hash marks for movement feel.
    final linePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2;
    const spacing = 30.0;
    final start = -spacing + (_scrollOffset % spacing);
    for (var x = start; x < size.x; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, 6), linePaint);
    }
  }

  void scroll(double dx) {
    _scrollOffset += dx;
  }
}
