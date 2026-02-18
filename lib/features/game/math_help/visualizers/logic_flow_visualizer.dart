import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// The decision-node marker used by [LogicFlowVisualizer].
class DecisionDiamondComponent extends PolygonComponent {
  final int stepIndex;

  DecisionDiamondComponent({
    required this.stepIndex,
    required Vector2 center,
    required Color color,
  }) : super(
         [Vector2(0, -26), Vector2(26, 0), Vector2(0, 26), Vector2(-26, 0)],
         position: center,
         anchor: Anchor.center,
         paint: Paint()..color = color,
       );
}

/// Visualizer for simple branching logic flow.
class LogicFlowVisualizer extends MathVisualizer {
  static const _nodeColor = Color(0xFFDCE6FA);
  static const _decisionColor = Color(0xFFA8C5F2);
  static const _pathColor = Color(0xFF6A8EBF);
  static const _dotColor = Color(0xFF0A2463);
  static const _wrongColor = Color(0xFFFF8A80);
  static const _correctColor = Color(0xFF7BD88F);
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _stepCenters = <Vector2>[];

  late final CircleComponent _flowDot;
  late final RectangleComponent _leftArrow;
  late final RectangleComponent _rightArrow;
  late final RectangleComponent _leftOutcome;
  late final RectangleComponent _rightOutcome;
  bool _disposed = false;

  int _stepCount = 3;
  int _decisionIndex = 2;
  int _correctOutcomeIndex = 0;
  Vector2 _leftOutcomeCenter = Vector2.zero();
  Vector2 _rightOutcomeCenter = Vector2.zero();

  LogicFlowVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

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

    for (var index = 1; index < _decisionIndex; index++) {
      await _moveDotTo(_stepCenters[index]);
      if (_disposed) return;
    }

    await _highlightDecisionBranch();
    if (_disposed) return;

    final target = _correctOutcomeIndex == 0
        ? _leftOutcomeCenter
        : _rightOutcomeCenter;
    await _moveDotTo(target);
    if (_disposed) return;

    await _pulseOutcome(
      _correctOutcomeIndex == 0 ? _leftOutcome : _rightOutcome,
    );
  }

  Future<void> _moveDotTo(Vector2 target) {
    final completer = Completer<void>();
    _flowDot.add(
      MoveEffect.to(
        target,
        EffectController(duration: 0.42, curve: Curves.easeInOutCubic),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> _highlightDecisionBranch() {
    final completer = Completer<void>();
    final correctArrow = _correctOutcomeIndex == 0 ? _leftArrow : _rightArrow;
    final wrongArrow = _correctOutcomeIndex == 0 ? _rightArrow : _leftArrow;

    wrongArrow.add(
      ColorEffect(
        _wrongColor,
        EffectController(
          duration: 0.18,
          reverseDuration: 0.18,
          curve: Curves.easeInOut,
        ),
      ),
    );

    correctArrow.add(
      ColorEffect(
        _correctColor,
        EffectController(
          duration: 0.2,
          reverseDuration: 0.2,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: 2,
        ),
        onComplete: completer.complete,
      ),
    );

    return completer.future;
  }

  Future<void> _pulseOutcome(RectangleComponent outcome) {
    final completer = Completer<void>();
    outcome.add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(
          duration: 0.18,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: 2,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    _stepCount = _resolveStepCount();
    _decisionIndex = _resolveDecisionIndex();
    _correctOutcomeIndex = _resolveCorrectOutcome();

    final centerX = width / 2;
    final startY = 52.0;
    const stepGap = 54.0;

    add(
      TextComponent(
        text: 'Folg flyten',
        anchor: Anchor.topCenter,
        position: Vector2(centerX, 10),
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF0A2463),
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    for (var step = 1; step <= _stepCount; step++) {
      final center = Vector2(centerX, startY + (step - 1) * stepGap);
      _stepCenters.add(center);

      if (step == _decisionIndex) {
        add(
          DecisionDiamondComponent(
            stepIndex: step,
            center: center,
            color: _decisionColor,
          ),
        );
        add(
          TextComponent(
            text: '?',
            anchor: Anchor.center,
            position: center.clone(),
            textRenderer: mathHelpTextPaint(
              color: const Color(0xFF13315C),
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      } else {
        add(
          RectangleComponent(
            position: center.clone(),
            size: Vector2(136, 54),
            anchor: Anchor.center,
            paint: Paint()..color = _nodeColor,
          ),
        );
        add(
          TextComponent(
            text: 'Steg $step',
            anchor: Anchor.center,
            position: center.clone(),
            textRenderer: mathHelpTextPaint(
              color: const Color(0xFF13315C),
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      if (step > 1) {
        add(_buildConnector(_stepCenters[step - 2], center));
      }
    }

    final decisionCenter = _stepCenters[_decisionIndex - 1];
    _leftOutcomeCenter = Vector2(
      centerX - 84,
      math.min(height - 34, decisionCenter.y + 64).toDouble(),
    );
    _rightOutcomeCenter = Vector2(
      centerX + 84,
      math.min(height - 34, decisionCenter.y + 64).toDouble(),
    );

    _leftArrow = _buildConnector(
      decisionCenter + Vector2(-18, 20),
      _leftOutcomeCenter + Vector2(0, -28),
    );
    _rightArrow = _buildConnector(
      decisionCenter + Vector2(18, 20),
      _rightOutcomeCenter + Vector2(0, -28),
    );
    add(_leftArrow);
    add(_rightArrow);

    _leftOutcome = RectangleComponent(
      position: _leftOutcomeCenter.clone(),
      size: Vector2(116, 52),
      anchor: Anchor.center,
      paint: Paint()..color = _nodeColor,
    );
    _rightOutcome = RectangleComponent(
      position: _rightOutcomeCenter.clone(),
      size: Vector2(116, 52),
      anchor: Anchor.center,
      paint: Paint()..color = _nodeColor,
    );
    add(_leftOutcome);
    add(_rightOutcome);

    add(
      TextComponent(
        text: 'Utfall 1',
        anchor: Anchor.center,
        position: _leftOutcomeCenter.clone(),
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF13315C),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    add(
      TextComponent(
        text: 'Utfall 2',
        anchor: Anchor.center,
        position: _rightOutcomeCenter.clone(),
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF13315C),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    _flowDot = CircleComponent(
      radius: 10,
      position: _stepCenters.first.clone(),
      anchor: Anchor.center,
      paint: Paint()..color = _dotColor,
    );
    add(_flowDot);
  }

  RectangleComponent _buildConnector(Vector2 start, Vector2 end) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);
    final center = Vector2((start.x + end.x) / 2, (start.y + end.y) / 2);
    return RectangleComponent(
      position: center,
      size: Vector2(length, 4),
      angle: angle,
      anchor: Anchor.center,
      paint: Paint()..color = _pathColor,
    );
  }

  void _resetScene() {
    _removeEffects(_flowDot);
    _removeEffects(_leftArrow);
    _removeEffects(_rightArrow);
    _removeEffects(_leftOutcome);
    _removeEffects(_rightOutcome);

    _flowDot.position = _stepCenters.first.clone();
    _leftArrow.paint.color = _pathColor;
    _rightArrow.paint.color = _pathColor;
    _leftOutcome.paint.color = _nodeColor;
    _rightOutcome.paint.color = _nodeColor;
    _leftOutcome.scale = Vector2.all(1);
    _rightOutcome.scale = Vector2.all(1);
  }

  int _resolveStepCount() {
    if (context.operands.isEmpty) return 3;
    return context.operands.first.round().clamp(2, 4).toInt();
  }

  int _resolveDecisionIndex() {
    if (context.operands.length < 2) return 2;
    return context.operands[1].round().clamp(1, _stepCount).toInt();
  }

  int _resolveCorrectOutcome() {
    final answer = context.correctAnswer.round();
    if (answer <= 0) return 0;
    return (answer - 1) % 2;
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }
}
