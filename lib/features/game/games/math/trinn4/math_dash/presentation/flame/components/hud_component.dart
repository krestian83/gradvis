import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// HUD overlay: lives (hearts), question counter, streak display.
class HudComponent extends PositionComponent {
  HudComponent({required this.gameSize})
    : super(size: gameSize, position: Vector2.zero());

  final Vector2 gameSize;
  int _lives = 3;
  int _questionIndex = 0;
  int _totalQuestions = 20;
  int _streak = 0;
  double _streakGlowPhase = 0;

  set lives(int value) => _lives = value;
  set questionIndex(int value) => _questionIndex = value;
  set totalQuestions(int value) => _totalQuestions = value;
  set streak(int value) => _streak = value;

  @override
  void update(double dt) {
    super.update(dt);
    if (_streak >= 3) {
      _streakGlowPhase += dt * 4;
    }
  }

  @override
  void render(Canvas canvas) {
    _drawHearts(canvas);
    _drawQuestionCounter(canvas);
    _drawStreak(canvas);
  }

  void _drawHearts(Canvas canvas) {
    for (var i = 0; i < 3; i++) {
      final x = 16.0 + i * 28.0;
      const y = 16.0;
      final color = i < _lives
          ? const Color(0xFFE53935)
          : const Color(0xFF9E9E9E);
      _drawHeart(canvas, Offset(x, y), 10, color);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy + r * 0.4)
      ..cubicTo(
        center.dx - r, center.dy - r * 0.5,
        center.dx - r * 0.5, center.dy - r,
        center.dx, center.dy - r * 0.3,
      )
      ..cubicTo(
        center.dx + r * 0.5, center.dy - r,
        center.dx + r, center.dy - r * 0.5,
        center.dx, center.dy + r * 0.4,
      );
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawQuestionCounter(Canvas canvas) {
    final display = min(_questionIndex + 1, _totalQuestions);
    final text = '$display/$_totalQuestions';
    final paragraph = _buildParagraph(
      text, 16, const Color(0xFF212121),
    );
    final x = (gameSize.x - paragraph.longestLine) / 2;
    canvas.drawParagraph(paragraph, Offset(x, 12));
  }

  void _drawStreak(Canvas canvas) {
    if (_streak < 1) return;
    final text = '\u00d7$_streak';
    final color = _streak >= 3
        ? const Color(0xFFFFB300)
        : const Color(0xFF212121);
    final paragraph = _buildParagraph(text, 16, color);
    final x = gameSize.x - paragraph.longestLine - 16;

    if (_streak >= 3) {
      final glowOpacity = (0.4 + 0.3 * sin(_streakGlowPhase)).clamp(0.0, 1.0);
      final glowParagraph = _buildParagraph(text, 16, Color.fromARGB(
        (glowOpacity * 255).round(), 255, 179, 0,
      ));
      canvas.save();
      canvas.drawParagraph(glowParagraph, Offset(x - 1, 11));
      canvas.restore();
    }

    canvas.drawParagraph(paragraph, Offset(x, 12));
  }

  Paragraph _buildParagraph(String text, double fontSize, Color color) {
    final builder = ParagraphBuilder(
      ParagraphStyle(
        textAlign: TextAlign.left,
        fontFamily: 'Fredoka One',
        fontSize: fontSize,
      ),
    )
      ..pushStyle(TextStyle(color: color, fontWeight: FontWeight.w700))
      ..addText(text);
    return builder.build()..layout(const ParagraphConstraints(width: 120));
  }
}
