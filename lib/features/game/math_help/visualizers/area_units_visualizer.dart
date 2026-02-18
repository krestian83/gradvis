import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// A single unit-square tile used by [AreaUnitsVisualizer].
class AreaUnitTileComponent extends RectangleComponent {
  AreaUnitTileComponent({
    required Vector2 position,
    required double tileSize,
    required Color color,
  }) : super(
         position: position,
         size: Vector2.all(tileSize - 2),
         anchor: Anchor.topLeft,
         paint: Paint()..color = color,
       ) {
    opacity = 0;
  }
}

/// Visualizer for counting area using non-standard unit squares.
class AreaUnitsVisualizer extends MathVisualizer {
  static const _outlineColor = Color(0xFF355070);
  static const _tileColor = Color(0xFF8BC6EC);
  static const _tileAltColor = Color(0xFFA5D8FF);
  static const _labelColor = Color(0xFF0A2463);
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _tiles = <AreaUnitTileComponent>[];
  late final TextComponent _counterLabel;
  late final TextComponent _resultLabel;
  bool _disposed = false;

  AreaUnitsVisualizer({required super.context});

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _widthUnits => _operand(0);

  int get _heightUnits => _operand(1);

  int get _tileCount => _widthUnits * _heightUnits;

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
    var count = 0;
    for (final tile in _tiles) {
      await _fadeInTile(tile);
      if (_disposed) return;
      count += 1;
      _counterLabel.text = 'Areal: $count';
    }
    _showResult();
  }

  Future<void> _fadeInTile(AreaUnitTileComponent tile) {
    final completer = Completer<void>();
    tile.add(
      OpacityEffect.to(
        1,
        EffectController(duration: 0.16, curve: Curves.easeOut),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final maxGridWidth = width * 0.72;
    final maxGridHeight = height * 0.52;
    final tileSize = math
        .min(maxGridWidth / _widthUnits, maxGridHeight / _heightUnits)
        .clamp(14.0, 42.0)
        .toDouble();
    final gridWidth = _widthUnits * tileSize;
    final gridHeight = _heightUnits * tileSize;
    final startX = width / 2 - gridWidth / 2;
    final startY = height * 0.2;

    add(
      RectangleComponent(
        position: Vector2(startX, startY),
        size: Vector2(gridWidth, gridHeight),
        anchor: Anchor.topLeft,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = _outlineColor,
      ),
    );

    for (var row = 0; row < _heightUnits; row++) {
      for (var column = 0; column < _widthUnits; column++) {
        final color = (row + column).isEven ? _tileColor : _tileAltColor;
        final tile = AreaUnitTileComponent(
          position: Vector2(
            startX + column * tileSize + 1,
            startY + row * tileSize + 1,
          ),
          tileSize: tileSize,
          color: color,
        );
        _tiles.add(tile);
        add(tile);
      }
    }

    _counterLabel = TextComponent(
      text: 'Areal: 0',
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

  void _resetScene() {
    for (final tile in _tiles) {
      _removeEffects(tile);
      tile.opacity = 0;
    }
    _counterLabel.text = 'Areal: 0';
    _removeEffects(_resultLabel);
    _resultLabel.scale = Vector2.zero();
    _resultLabel.text = 'Totalt: ${context.correctAnswer}';
  }

  void _showResult() {
    _counterLabel.text = 'Areal: $_tileCount';
    _removeEffects(_resultLabel);
    _resultLabel.scale = Vector2.zero();
    _resultLabel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.4, curve: Curves.easeOutBack),
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
