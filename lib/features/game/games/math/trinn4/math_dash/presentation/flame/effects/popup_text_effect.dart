import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show Color, FontWeight, TextStyle;

/// Rising "+1" popup text that fades out.
class PopupTextEffect extends PositionComponent {
  PopupTextEffect({
    required String text,
    required Vector2 startPosition,
    Color color = const Color(0xFF4CAF50),
  }) : _color = color,
       _duration = 0.8,
       super(
         position: startPosition.clone(),
         anchor: Anchor.center,
         priority: 90,
       ) {
    _textComponent = TextComponent(
      text: text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'Fredoka One',
        ),
      ),
    );
    add(_textComponent);
    add(
      MoveEffect.by(
        Vector2(0, -40),
        EffectController(duration: _duration, curve: Curves.easeOut),
      ),
    );
  }

  late final TextComponent _textComponent;
  final Color _color;
  final double _duration;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = Curves.easeIn.transform(
      (_elapsed / _duration).clamp(0.0, 1.0),
    );
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    _textComponent.textRenderer = TextPaint(
      style: TextStyle(
        color: _color.withValues(alpha: alpha),
        fontSize: 22,
        fontWeight: FontWeight.w800,
        fontFamily: 'Fredoka One',
      ),
    );
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }
}
