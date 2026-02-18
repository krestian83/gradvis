import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Number-line visualizer for subtraction contexts.
class SubtractionVisualizer extends MathVisualizer {
  static const _baseTickColor = Color(0xFF6382A8);
  static const _activeTickColor = Color(0xFFE63973);
  static const _markerColor = Color(0xFFB80C4D);
  static const _lineColor = Color(0xFF274C77);

  static const _linePadding = 44.0;
  static const _lineThickness = 4.0;
  static const _tickHeight = 28.0;
  static const _tickWidth = 3.0;
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _ticks = <int, RectangleComponent>{};
  late final RectangleComponent _numberLine;
  late final PolygonComponent _marker;
  late final TextComponent _answerLabel;

  bool _disposed = false;
  int? _activeTick;
  int _rangeStart = 0;
  int _rangeEnd = 1;
  double _lineStartX = 0;
  double _lineY = 0;
  double _stepWidth = 0;

  SubtractionVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _startValue => _operandValue(0, fallback: 0).round();

  int get _hopCount {
    final hops = _operandValue(1, fallback: 0).round();
    return hops < 0 ? 0 : hops;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _configureRange();
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
    final hops = _hopCount;

    for (var step = 1; step <= hops; step++) {
      final landingValue = _startValue - step;
      await _moveMarkerTo(landingValue);
      if (_disposed) return;
      _highlightTick(landingValue);
    }

    _showAnswer();
  }

  Future<void> _moveMarkerTo(int value) {
    final completer = Completer<void>();
    _marker.add(
      MoveEffect.to(
        Vector2(_xForValue(value), _lineY),
        EffectController(duration: 1.8, curve: Curves.easeInOutCubic),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;

    _lineStartX = _linePadding;
    final lineEndX = width - _linePadding;
    final lineWidth = math.max(120.0, lineEndX - _lineStartX);
    _lineY = height * 0.56;
    final tickCount = _rangeEnd - _rangeStart + 1;
    _stepWidth = tickCount <= 1 ? lineWidth : lineWidth / (tickCount - 1);

    _numberLine = RectangleComponent(
      position: Vector2(_lineStartX, _lineY - _lineThickness / 2),
      size: Vector2(lineWidth, _lineThickness),
      paint: Paint()..color = _lineColor,
    );
    add(_numberLine);

    final labelRenderer = mathHelpTextPaint(
      color: const Color(0xFF13315C),
      fontSize: 28,
      fontWeight: FontWeight.w700,
    );

    for (var value = _rangeStart; value <= _rangeEnd; value++) {
      final x = _xForValue(value);
      final tick = RectangleComponent(
        position: Vector2(x - _tickWidth / 2, _lineY - _tickHeight / 2),
        size: Vector2(_tickWidth, _tickHeight),
        paint: Paint()..color = _baseTickColor,
      );
      _ticks[value] = tick;
      add(tick);

      add(
        TextComponent(
          text: '$value',
          anchor: Anchor.topCenter,
          position: Vector2(x, _lineY + 24),
          textRenderer: labelRenderer,
        ),
      );
    }

    _marker = PolygonComponent(
      _arrowVertices(),
      anchor: Anchor.center,
      position: Vector2(_xForValue(_startValue), _lineY),
      paint: Paint()..color = _markerColor,
    );
    add(_marker);

    _answerLabel = TextComponent(
      text: _answerText(),
      anchor: Anchor.center,
      position: Vector2(width / 2, _lineY - 72),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: const Color(0xFF9D174D),
        fontSize: 34,
      ),
    );
    add(_answerLabel);
  }

  List<Vector2> _arrowVertices() {
    return [
      Vector2(-20, 0),
      Vector2(-4, -14),
      Vector2(-4, -7),
      Vector2(18, -7),
      Vector2(18, 7),
      Vector2(-4, 7),
      Vector2(-4, 14),
    ];
  }

  void _resetScene() {
    _removeEffects(_marker);
    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.text = _answerText();
    _marker.position = Vector2(_xForValue(_startValue), _lineY);
    _activeTick = null;

    for (final tick in _ticks.values) {
      tick.paint.color = _baseTickColor;
    }
  }

  void _showAnswer() {
    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.45, curve: Curves.easeOutBack),
      ),
    );
  }

  void _highlightTick(int value) {
    if (_activeTick != null) {
      _ticks[_activeTick!]?.paint.color = _baseTickColor;
    }
    final tick = _ticks[value];
    if (tick == null) return;
    tick.paint.color = _activeTickColor;
    _activeTick = value;
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  void _configureRange() {
    final start = _startValue;
    final end = _startValue - _hopCount;
    final answer = context.correctAnswer.round();
    final minValue = math.min(start, math.min(end, answer));
    final maxValue = math.max(start, math.max(end, answer));
    _rangeStart = minValue - 1;
    _rangeEnd = maxValue + 1;
    if (_rangeEnd <= _rangeStart) {
      _rangeEnd = _rangeStart + 1;
    }
  }

  double _xForValue(int value) {
    return _lineStartX + (value - _rangeStart) * _stepWidth;
  }

  num _operandValue(int index, {required num fallback}) {
    if (index >= context.operands.length) return fallback;
    return context.operands[index];
  }

  String _answerText() {
    final first = _operandValue(0, fallback: 0);
    final second = _operandValue(1, fallback: 0);
    return '$first - $second = ${context.correctAnswer}';
  }
}
