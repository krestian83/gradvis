import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// A step card used by [StepSequenceVisualizer].
class StepBoxComponent extends RectangleComponent {
  final int stepNumber;
  final Vector2 homePosition;
  final Vector2 sortedPosition;
  final Color baseColor;

  StepBoxComponent({
    required this.stepNumber,
    required this.homePosition,
    required this.sortedPosition,
    required Vector2 boxSize,
    required this.baseColor,
  }) : super(
         position: homePosition.clone(),
         size: boxSize,
         anchor: Anchor.center,
         paint: Paint()..color = baseColor,
       ) {
    add(
      TextComponent(
        text: 'Steg $stepNumber',
        anchor: Anchor.center,
        position: boxSize / 2,
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF13315C),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Visualizer for reordering scrambled steps into a sorted sequence.
class StepSequenceVisualizer extends MathVisualizer {
  static const _boxColor = Color(0xFFDCE6FA);
  static const _sortedFlashColor = Color(0xFF7BD88F);
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _stepBoxes = <StepBoxComponent>[];
  bool _disposed = false;

  StepSequenceVisualizer({required super.context});

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
    final sorted = [..._stepBoxes]
      ..sort((left, right) => left.stepNumber.compareTo(right.stepNumber));

    for (final box in sorted) {
      await _moveBox(box);
      if (_disposed) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    await _flashSorted();
  }

  Future<void> _moveBox(StepBoxComponent box) {
    final completer = Completer<void>();
    box.add(
      MoveEffect.to(
        box.sortedPosition,
        EffectController(duration: 0.42, curve: Curves.easeInOutCubic),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> _flashSorted() async {
    final waits = <Future<void>>[];
    for (final box in _stepBoxes) {
      final completer = Completer<void>();
      waits.add(completer.future);
      box.add(
        ColorEffect(
          _sortedFlashColor,
          EffectController(
            duration: 0.2,
            reverseDuration: 0.2,
            curve: Curves.easeInOut,
          ),
          onComplete: completer.complete,
        ),
      );
    }
    await Future.wait(waits);
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final steps = _steps();
    final count = steps.length;
    const spacing = 12.0;
    final boxWidth = math
        .min(130.0, (width - 24 - spacing * (count - 1)) / count)
        .clamp(80.0, 130.0)
        .toDouble();
    const boxHeight = 86.0;
    final rowY = height * 0.58;
    final rowWidth = boxWidth * count + spacing * (count - 1);
    final startX = width / 2 - rowWidth / 2 + boxWidth / 2;
    final sortedSteps = [...steps]..sort();

    add(
      TextComponent(
        text: 'Sorter stegene',
        anchor: Anchor.topCenter,
        position: Vector2(width / 2, 12),
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF0A2463),
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    for (var index = 0; index < steps.length; index++) {
      final stepNumber = steps[index];
      final homePosition = Vector2(startX + index * (boxWidth + spacing), rowY);
      final sortedIndex = sortedSteps.indexOf(stepNumber);
      final sortedPosition = Vector2(
        startX + sortedIndex * (boxWidth + spacing),
        rowY,
      );
      final box = StepBoxComponent(
        stepNumber: stepNumber,
        homePosition: homePosition,
        sortedPosition: sortedPosition,
        boxSize: Vector2(boxWidth, boxHeight),
        baseColor: _boxColor,
      );
      _stepBoxes.add(box);
      add(box);
    }
  }

  void _resetScene() {
    for (final box in _stepBoxes) {
      _removeEffects(box);
      box.position = box.homePosition.clone();
      box.paint.color = box.baseColor;
    }
  }

  List<int> _steps() {
    if (context.operands.isEmpty) {
      return const [3, 1, 2];
    }
    return context.operands
        .map((operand) => math.max(1, operand.round()))
        .toList();
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }
}
