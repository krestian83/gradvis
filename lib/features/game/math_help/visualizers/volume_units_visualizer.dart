import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// A single unit-cell used by [VolumeUnitsVisualizer].
class VolumeUnitCubeComponent extends PolygonComponent {
  final int layerIndex;
  final Vector2 startPosition;
  final Vector2 targetPosition;

  VolumeUnitCubeComponent({
    required this.layerIndex,
    required this.startPosition,
    required this.targetPosition,
    required Vector2 cellX,
    required Vector2 cellY,
    required Color color,
  }) : super(
         [Vector2.zero(), cellX, cellX + cellY, cellY],
         position: startPosition.clone(),
         paint: Paint()..color = color,
       ) {
    opacity = 0;
  }
}

/// Visualizer for counting volume with unit cells in an isometric box.
class VolumeUnitsVisualizer extends MathVisualizer {
  static const _outlineColor = Color(0xFF355070);
  static const _cubeColor = Color(0xFF7AA6E8);
  static const _cubeAltColor = Color(0xFF8FB9F8);
  static const _labelColor = Color(0xFF0A2463);
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _cubes = <VolumeUnitCubeComponent>[];
  final _frontLayer = <VolumeUnitCubeComponent>[];
  final _remainingLayers = <int, List<VolumeUnitCubeComponent>>{};
  late final TextComponent _counterLabel;
  late final TextComponent _resultLabel;
  bool _disposed = false;

  VolumeUnitsVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _widthUnits => _operand(0);

  int get _heightUnits => _operand(1);

  int get _depthUnits => _operand(2);

  int get _cubeCount => _widthUnits * _heightUnits * _depthUnits;

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
    var shown = 0;

    for (final cube in _frontLayer) {
      await _revealFrontCube(cube);
      if (_disposed) return;
      shown += 1;
      _counterLabel.text = 'Volum: $shown';
    }

    for (var layer = 1; layer < _depthUnits; layer++) {
      final cubes =
          _remainingLayers[layer] ?? const <VolumeUnitCubeComponent>[];
      for (final cube in cubes) {
        await _revealLayerCube(cube);
        if (_disposed) return;
        shown += 1;
        _counterLabel.text = 'Volum: $shown';
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    _showResult();
  }

  Future<void> _revealFrontCube(VolumeUnitCubeComponent cube) {
    final completer = Completer<void>();
    cube.add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.15, curve: Curves.easeOut),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> _revealLayerCube(VolumeUnitCubeComponent cube) {
    final completer = Completer<void>();
    cube.add(
      MoveEffect.to(
        cube.targetPosition,
        EffectController(duration: 0.28, curve: Curves.easeOutCubic),
        onComplete: completer.complete,
      ),
    );
    cube.add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.2, curve: Curves.easeOut),
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final unitWidth = math
        .min(24.0, (width * 0.62) / _widthUnits)
        .clamp(12.0, 24.0)
        .toDouble();
    final unitHeight = math
        .min(20.0, (height * 0.44) / _heightUnits)
        .clamp(10.0, 20.0)
        .toDouble();
    final unitX = Vector2(unitWidth, unitWidth * 0.38);
    final unitY = Vector2(0, unitHeight);
    final depthShift = Vector2(-unitWidth * 0.55, -unitHeight * 0.52);
    final widthVector = unitX * _widthUnits.toDouble();
    final heightVector = unitY * _heightUnits.toDouble();
    final depthVector = depthShift * _depthUnits.toDouble();

    final frontA = Vector2.zero();
    final frontB = frontA + widthVector;
    final frontC = frontB + heightVector;
    final frontD = frontA + heightVector;
    final backA = frontA + depthVector;
    final backB = frontB + depthVector;
    final backC = frontC + depthVector;

    final corners = [
      frontA,
      frontB,
      frontC,
      frontD,
      backA,
      backB,
      backC,
      frontD + depthVector,
    ];
    final minX = corners.map((point) => point.x).reduce(math.min);
    final maxX = corners.map((point) => point.x).reduce(math.max);
    final minY = corners.map((point) => point.y).reduce(math.min);
    final maxY = corners.map((point) => point.y).reduce(math.max);
    final centerOffset = Vector2(
      width / 2 - (minX + maxX) / 2,
      height * 0.5 - (minY + maxY) / 2,
    );

    _addOutlineFace([frontA, frontB, frontC, frontD], centerOffset);
    _addOutlineFace([frontA, frontB, backB, backA], centerOffset);
    _addOutlineFace([frontB, frontC, backC, backB], centerOffset);

    final cellX = Vector2(unitX.x * 0.88, unitX.y * 0.88);
    final cellY = Vector2(unitY.x * 0.88, unitY.y * 0.88);

    for (var layer = 0; layer < _depthUnits; layer++) {
      for (var row = 0; row < _heightUnits; row++) {
        for (var column = 0; column < _widthUnits; column++) {
          final target =
              centerOffset +
              (unitX * column.toDouble()) +
              (unitY * row.toDouble()) +
              (depthShift * layer.toDouble()) +
              Vector2(1, 1);
          final start = layer == 0 ? target : target - (depthShift * 0.45);
          final color = (row + column + layer).isEven
              ? _cubeColor
              : _cubeAltColor;

          final cube = VolumeUnitCubeComponent(
            layerIndex: layer,
            startPosition: start,
            targetPosition: target,
            cellX: cellX,
            cellY: cellY,
            color: color,
          );
          _cubes.add(cube);
          add(cube);

          if (layer == 0) {
            _frontLayer.add(cube);
            continue;
          }
          _remainingLayers.putIfAbsent(
            layer,
            () => <VolumeUnitCubeComponent>[],
          );
          _remainingLayers[layer]!.add(cube);
        }
      }
    }

    _counterLabel = TextComponent(
      text: 'Volum: 0',
      anchor: Anchor.topLeft,
      position: Vector2(16, 12),
      textRenderer: mathHelpTextPaint(
        color: _labelColor,
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_counterLabel);

    _resultLabel = TextComponent(
      text: 'Totalt: ${context.correctAnswer}',
      anchor: Anchor.center,
      position: Vector2(width / 2, height * 0.88),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(color: _labelColor, fontSize: 32),
    );
    add(_resultLabel);
  }

  void _addOutlineFace(List<Vector2> points, Vector2 offset) {
    add(
      PolygonComponent(
        points.map((point) => point + offset).toList(),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _outlineColor,
      ),
    );
  }

  void _resetScene() {
    for (final cube in _cubes) {
      _removeEffects(cube);
      cube.opacity = 0;
      cube.position = cube.startPosition.clone();
    }
    _counterLabel.text = 'Volum: 0';
    _removeEffects(_resultLabel);
    _resultLabel.scale = Vector2.zero();
    _resultLabel.text = 'Totalt: ${context.correctAnswer}';
  }

  void _showResult() {
    _counterLabel.text = 'Volum: $_cubeCount';
    _removeEffects(_resultLabel);
    _resultLabel.scale = Vector2.zero();
    _resultLabel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.42, curve: Curves.easeOutBack),
      ),
    );
  }

  int _operand(int index) {
    if (index >= context.operands.length) return 1;
    return math.max(1, context.operands[index].round());
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }
}
