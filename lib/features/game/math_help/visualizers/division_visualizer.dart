import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-group visualizer for division contexts.
class DivisionVisualizer extends MathVisualizer {
  static const _dotRadius = 8.0;
  static const _dotGap = 16.0;
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  static const _dotColor = Color(0xFF2D6A4F);
  static const _groupLabelColor = Color(0xFF1B4332);
  static const _answerColor = Color(0xFF0A2463);

  final _dots = <CircleComponent>[];
  final _clusterPositions = <Vector2>[];
  final _groupPositions = <Vector2>[];
  final _groupCenters = <Vector2>[];
  final _groupLabels = <TextComponent>[];

  late final TextComponent _answerLabel;
  bool _disposed = false;

  DivisionVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _groupCount {
    final divisor = _operandValue(1, fallback: 1).round();
    return divisor <= 0 ? 1 : divisor;
  }

  int get _groupSize {
    final answer = context.correctAnswer.round();
    return answer < 0 ? 0 : answer;
  }

  int get _dotCount => _groupCount * _groupSize;

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
    await _splitIntoGroups();
    if (_disposed) return;
    await _revealGroupLabels();
    if (_disposed) return;
    _showAnswer();
  }

  Future<void> _splitIntoGroups() async {
    final moves = <Future<void>>[];
    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];
      final target = _groupPositions[i];
      final completer = Completer<void>();
      dot.add(
        MoveEffect.to(
          target,
          EffectController(
            duration: 0.85,
            curve: Curves.easeInOutCubic,
            startDelay: (i % _groupCount) * 0.03,
          ),
          onComplete: completer.complete,
        ),
      );
      moves.add(completer.future);
    }
    await Future.wait(moves);
  }

  Future<void> _revealGroupLabels() async {
    for (final label in _groupLabels) {
      final completer = Completer<void>();
      label.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.28, curve: Curves.easeOutBack),
          onComplete: completer.complete,
        ),
      );
      await completer.future;
      if (_disposed) return;
    }
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final clusterCenter = Vector2(width / 2, height * 0.34);

    _clusterPositions.addAll(_buildClusterPositions(clusterCenter));
    _groupCenters.addAll(_buildGroupCenters(width, height));
    _groupPositions.addAll(_buildGroupPositions());

    for (final position in _clusterPositions) {
      final dot = CircleComponent(
        radius: _dotRadius,
        anchor: Anchor.center,
        position: position.clone(),
        paint: Paint()..color = _dotColor,
      );
      _dots.add(dot);
      add(dot);
    }

    for (final center in _groupCenters) {
      final label = TextComponent(
        text: '$_groupSize',
        anchor: Anchor.topCenter,
        position: Vector2(center.x, center.y + 26),
        scale: Vector2.zero(),
        textRenderer: mathHelpTextPaint(
          color: _groupLabelColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      );
      _groupLabels.add(label);
      add(label);
    }

    _answerLabel = TextComponent(
      text: _answerText(),
      anchor: Anchor.center,
      position: Vector2(width / 2, height * 0.82),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(color: _answerColor, fontSize: 32),
    );
    add(_answerLabel);
  }

  List<Vector2> _buildClusterPositions(Vector2 center) {
    if (_dotCount == 0) return const [];

    final columns = math.sqrt(_dotCount).ceil();
    final rows = (_dotCount / columns).ceil();
    final positions = <Vector2>[];

    for (var i = 0; i < _dotCount; i++) {
      final row = i ~/ columns;
      final column = i % columns;
      final x = center.x + (column - (columns - 1) / 2) * _dotGap;
      final y = center.y + (row - (rows - 1) / 2) * _dotGap;
      positions.add(Vector2(x, y));
    }

    return positions;
  }

  List<Vector2> _buildGroupCenters(double width, double height) {
    final groupsPerRow = math.min(4, _groupCount);
    final rowCount = (_groupCount / groupsPerRow).ceil();
    const groupGapX = 82.0;
    const groupGapY = 76.0;
    final startX = width / 2 - (groupsPerRow - 1) * groupGapX / 2;
    final startY = height * 0.57 - (rowCount - 1) * groupGapY / 2;
    final centers = <Vector2>[];

    for (var group = 0; group < _groupCount; group++) {
      final row = group ~/ groupsPerRow;
      final column = group % groupsPerRow;
      centers.add(
        Vector2(startX + column * groupGapX, startY + row * groupGapY),
      );
    }

    return centers;
  }

  List<Vector2> _buildGroupPositions() {
    if (_dotCount == 0) return const [];

    final positions = <Vector2>[];
    final columns = math.max(1, math.sqrt(_groupSize).ceil());
    final rows = (_groupSize / columns).ceil();

    for (var group = 0; group < _groupCount; group++) {
      final center = _groupCenters[group];
      for (var i = 0; i < _groupSize; i++) {
        final row = i ~/ columns;
        final column = i % columns;
        final x = center.x + (column - (columns - 1) / 2) * _dotGap;
        final y = center.y + (row - (rows - 1) / 2) * _dotGap;
        positions.add(Vector2(x, y));
      }
    }

    return positions;
  }

  void _resetScene() {
    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];
      _removeEffects(dot);
      dot.position = _clusterPositions[i].clone();
    }

    for (final label in _groupLabels) {
      _removeEffects(label);
      label.scale = Vector2.zero();
    }

    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.text = _answerText();
  }

  void _showAnswer() {
    _removeEffects(_answerLabel);
    _answerLabel.scale = Vector2.zero();
    _answerLabel.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.35, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.14),
          EffectController(
            duration: 0.2,
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

  num _operandValue(int index, {required num fallback}) {
    if (index >= context.operands.length) return fallback;
    return context.operands[index];
  }

  String _answerText() {
    return '$_dotCount / $_groupCount = ${context.correctAnswer}';
  }
}
