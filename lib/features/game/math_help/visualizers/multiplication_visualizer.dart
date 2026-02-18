import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-grid visualizer for multiplication contexts.
class MultiplicationVisualizer extends MathVisualizer {
  static const _dotRadius = 10.0;
  static const _dotGap = 28.0;
  static const _rowPause = Duration(milliseconds: 140);
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  static const _dotColor = Color(0xFF1E847F);
  static const _answerColor = Color(0xFF0A2463);

  final _dotRows = <List<CircleComponent>>[];
  late final TextComponent _answerLabel;
  bool _disposed = false;

  MultiplicationVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _rows => _wholeOperand(0);

  int get _columns => _wholeOperand(1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildScene();
    unawaited(_runLoop());
  }

  @override
  void onRemove() {
    _disposed = true;
    super.onRemove();
  }

  Future<void> _runLoop() async {
    while (!_disposed) {
      await _playOnce();
      if (_disposed) return;
      await Future<void>.delayed(_loopPause);
    }
  }

  Future<void> _playOnce() async {
    _resetScene();

    for (final row in _dotRows) {
      for (final dot in row) {
        await _fadeInDot(dot);
        if (_disposed) return;
      }
      await Future<void>.delayed(_rowPause);
    }

    _showAnswer();
  }

  Future<void> _fadeInDot(CircleComponent dot) {
    final completer = Completer<void>();
    dot.add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.2, curve: Curves.easeOut),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final gridWidth = _columns <= 1 ? 0.0 : (_columns - 1) * _dotGap;
    final gridHeight = _rows <= 1 ? 0.0 : (_rows - 1) * _dotGap;
    final startX = width / 2 - gridWidth / 2;
    final startY = height * 0.44 - gridHeight / 2;

    for (var row = 0; row < _rows; row++) {
      final rowDots = <CircleComponent>[];
      for (var column = 0; column < _columns; column++) {
        final dot = CircleComponent(
          radius: _dotRadius,
          anchor: Anchor.center,
          position: Vector2(startX + column * _dotGap, startY + row * _dotGap),
          paint: Paint()..color = _dotColor,
        )..opacity = 0;

        add(dot);
        rowDots.add(dot);
      }
      _dotRows.add(rowDots);
    }

    _answerLabel = TextComponent(
      text: '= ${context.correctAnswer}',
      anchor: Anchor.center,
      position: Vector2(width / 2, height * 0.82),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(color: _answerColor, fontSize: 34),
    );
    add(_answerLabel);
  }

  void _resetScene() {
    for (final row in _dotRows) {
      for (final dot in row) {
        _removeEffects(dot);
        dot.opacity = 0;
      }
    }
    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.text = '= ${context.correctAnswer}';
  }

  void _showAnswer() {
    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.36, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.16),
          EffectController(
            duration: 0.18,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 2,
          ),
        ),
      ]),
    );
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  int _wholeOperand(int index) {
    if (index >= context.operands.length) return 0;
    return math.max(0, context.operands[index].round());
  }
}
