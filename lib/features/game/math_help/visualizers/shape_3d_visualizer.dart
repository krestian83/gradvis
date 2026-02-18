import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Visualizer for counting faces or edges on simple 3D shape diagrams.
class Shape3DVisualizer extends MathVisualizer {
  static const _faceColor = Color(0xFF6C8EBF);
  static const _secondaryFaceColor = Color(0xFF89A6D2);
  static const _edgeColor = Color(0xFF355070);
  static const _highlightColor = Color(0xFFFFB703);
  static const _labelColor = Color(0xFF0A2463);

  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _parts = <_VisualPart>[];
  late final TextComponent _countLabel;
  late final TextComponent _totalLabel;

  bool _disposed = false;
  String _counterTitle = 'Faces';
  int _targetTotal = 0;

  Shape3DVisualizer({required super.context});

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
    for (var i = 0; i < _parts.length; i++) {
      await _highlightPart(_parts[i]);
      if (_disposed) return;
      _countLabel.text = '$_counterTitle: ${i + 1}';
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    _showTotal();
  }

  Future<void> _highlightPart(_VisualPart part) {
    final completer = Completer<void>();
    final component = part.component;
    _removeEffects(component);
    component.scale = Vector2.all(1);

    component.add(
      ColorEffect(
        _highlightColor,
        EffectController(
          duration: 0.2,
          reverseDuration: 0.2,
          curve: Curves.easeInOut,
        ),
        onComplete: completer.complete,
      ),
    );
    component.add(
      ScaleEffect.to(
        Vector2.all(1.14),
        EffectController(
          duration: 0.2,
          reverseDuration: 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final center = Vector2(width / 2, height * 0.58);
    final operation = _normalizedOperation();

    switch (operation) {
      case 'cubeedges':
        _counterTitle = 'Edges';
        _buildCubeEdges(center);
      case 'pyramidedges':
        _counterTitle = 'Edges';
        _buildPyramidEdges(center);
      case 'cylinderfaces':
        _counterTitle = 'Faces';
        _buildCylinderFaces(center);
      case 'spherefaces':
        _counterTitle = 'Faces';
        _buildSphereFace(center);
      case 'pyramidfaces':
        _counterTitle = 'Faces';
        _buildPyramidFaces(center);
      case 'conefaces':
        _counterTitle = 'Faces';
        _buildConeFaces(center);
      case 'cubefaces':
      default:
        _counterTitle = 'Faces';
        _buildCubeFaceNet(center);
    }

    _targetTotal = _parts.length;

    _countLabel = TextComponent(
      text: '$_counterTitle: 0',
      anchor: Anchor.topLeft,
      position: Vector2(16, 14),
      textRenderer: mathHelpTextPaint(
        color: _labelColor,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_countLabel);

    _totalLabel = TextComponent(
      text: 'Totalt: $_targetTotal',
      anchor: Anchor.center,
      position: Vector2(width / 2, 34),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(color: _labelColor, fontSize: 30),
    );
    add(_totalLabel);
  }

  void _buildCubeFaceNet(Vector2 center) {
    const side = 42.0;
    const gap = 4.0;
    final step = side + gap;
    final offsets = [
      Vector2(0, -1),
      Vector2(-1, 0),
      Vector2(0, 0),
      Vector2(1, 0),
      Vector2(2, 0),
      Vector2(0, 1),
    ];

    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final color = i.isEven ? _faceColor : _secondaryFaceColor;
      final square = RectangleComponent(
        position: Vector2(
          center.x + offset.x * step,
          center.y + offset.y * step,
        ),
        size: Vector2.all(side),
        anchor: Anchor.center,
        paint: Paint()..color = color,
      );
      _addPart(square, color);
    }
  }

  void _buildCubeEdges(Vector2 center) {
    final frontTopLeft = Vector2(center.x - 70, center.y - 26);
    final frontTopRight = Vector2(center.x - 8, center.y - 26);
    final frontBottomRight = Vector2(center.x - 8, center.y + 36);
    final frontBottomLeft = Vector2(center.x - 70, center.y + 36);
    const shiftX = 44.0;
    const shiftY = -34.0;

    final backTopLeft = Vector2(
      frontTopLeft.x + shiftX,
      frontTopLeft.y + shiftY,
    );
    final backTopRight = Vector2(
      frontTopRight.x + shiftX,
      frontTopRight.y + shiftY,
    );
    final backBottomRight = Vector2(
      frontBottomRight.x + shiftX,
      frontBottomRight.y + shiftY,
    );
    final backBottomLeft = Vector2(
      frontBottomLeft.x + shiftX,
      frontBottomLeft.y + shiftY,
    );

    final edges = [
      (frontTopLeft, frontTopRight),
      (frontTopRight, frontBottomRight),
      (frontBottomRight, frontBottomLeft),
      (frontBottomLeft, frontTopLeft),
      (backTopLeft, backTopRight),
      (backTopRight, backBottomRight),
      (backBottomRight, backBottomLeft),
      (backBottomLeft, backTopLeft),
      (frontTopLeft, backTopLeft),
      (frontTopRight, backTopRight),
      (frontBottomRight, backBottomRight),
      (frontBottomLeft, backBottomLeft),
    ];

    for (final edge in edges) {
      final segment = _buildEdgeSegment(start: edge.$1, end: edge.$2);
      _addPart(segment, _edgeColor);
    }
  }

  void _buildCylinderFaces(Vector2 center) {
    final body = RectangleComponent(
      position: center.clone(),
      size: Vector2(132, 60),
      anchor: Anchor.center,
      paint: Paint()..color = _faceColor,
    );
    _addPart(body, _faceColor);

    final top = CircleComponent(
      radius: 24,
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 72),
      paint: Paint()..color = _secondaryFaceColor,
    );
    _addPart(top, _secondaryFaceColor);

    final bottom = CircleComponent(
      radius: 24,
      anchor: Anchor.center,
      position: Vector2(center.x, center.y + 72),
      paint: Paint()..color = _secondaryFaceColor,
    );
    _addPart(bottom, _secondaryFaceColor);
  }

  void _buildSphereFace(Vector2 center) {
    final sphere = CircleComponent(
      radius: 58,
      anchor: Anchor.center,
      position: center.clone(),
      paint: Paint()..color = _faceColor,
    );
    _addPart(sphere, _faceColor);
  }

  void _buildPyramidFaces(Vector2 center) {
    final base = RectangleComponent(
      position: center.clone(),
      size: Vector2.all(68),
      anchor: Anchor.center,
      paint: Paint()..color = _faceColor,
    );
    _addPart(base, _faceColor);

    final top = _buildTriangle(
      a: Vector2(center.x - 34, center.y - 34),
      b: Vector2(center.x + 34, center.y - 34),
      c: Vector2(center.x, center.y - 90),
      color: _secondaryFaceColor,
    );
    _addPart(top, _secondaryFaceColor);

    final right = _buildTriangle(
      a: Vector2(center.x + 34, center.y - 34),
      b: Vector2(center.x + 34, center.y + 34),
      c: Vector2(center.x + 90, center.y),
      color: _secondaryFaceColor,
    );
    _addPart(right, _secondaryFaceColor);

    final bottom = _buildTriangle(
      a: Vector2(center.x - 34, center.y + 34),
      b: Vector2(center.x + 34, center.y + 34),
      c: Vector2(center.x, center.y + 90),
      color: _secondaryFaceColor,
    );
    _addPart(bottom, _secondaryFaceColor);

    final left = _buildTriangle(
      a: Vector2(center.x - 34, center.y - 34),
      b: Vector2(center.x - 34, center.y + 34),
      c: Vector2(center.x - 90, center.y),
      color: _secondaryFaceColor,
    );
    _addPart(left, _secondaryFaceColor);
  }

  void _buildPyramidEdges(Vector2 center) {
    final baseA = Vector2(center.x - 56, center.y + 20);
    final baseB = Vector2(center.x + 56, center.y + 20);
    final baseC = Vector2(center.x + 56, center.y + 88);
    final baseD = Vector2(center.x - 56, center.y + 88);
    final apex = Vector2(center.x, center.y - 56);

    final edges = [
      (baseA, baseB),
      (baseB, baseC),
      (baseC, baseD),
      (baseD, baseA),
      (baseA, apex),
      (baseB, apex),
      (baseC, apex),
      (baseD, apex),
    ];

    for (final edge in edges) {
      final segment = _buildEdgeSegment(start: edge.$1, end: edge.$2);
      _addPart(segment, _edgeColor);
    }
  }

  void _buildConeFaces(Vector2 center) {
    final side = _buildTriangle(
      a: Vector2(center.x - 58, center.y + 52),
      b: Vector2(center.x + 58, center.y + 52),
      c: Vector2(center.x, center.y - 56),
      color: _faceColor,
    );
    _addPart(side, _faceColor);

    final base = CircleComponent(
      radius: 30,
      anchor: Anchor.center,
      position: Vector2(center.x, center.y + 98),
      paint: Paint()..color = _secondaryFaceColor,
    );
    _addPart(base, _secondaryFaceColor);
  }

  PolygonComponent _buildTriangle({
    required Vector2 a,
    required Vector2 b,
    required Vector2 c,
    required Color color,
  }) {
    return PolygonComponent([a, b, c], paint: Paint()..color = color);
  }

  RectangleComponent _buildEdgeSegment({
    required Vector2 start,
    required Vector2 end,
  }) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);
    final middle = Vector2((start.x + end.x) / 2, (start.y + end.y) / 2);

    return RectangleComponent(
      position: middle,
      size: Vector2(length, 4),
      angle: angle,
      anchor: Anchor.center,
      paint: Paint()..color = _edgeColor,
    );
  }

  void _addPart(ShapeComponent component, Color baseColor) {
    component.paint.color = baseColor;
    add(component);
    _parts.add(_VisualPart(component: component, baseColor: baseColor));
  }

  void _resetScene() {
    for (final part in _parts) {
      _removeEffects(part.component);
      part.component.paint.color = part.baseColor;
      part.component.scale = Vector2.all(1);
    }
    _countLabel.text = '$_counterTitle: 0';
    _removeEffects(_totalLabel);
    _totalLabel.scale = Vector2.zero();
    _totalLabel.text = 'Totalt: $_targetTotal';
  }

  void _showTotal() {
    _removeEffects(_totalLabel);
    _totalLabel.scale = Vector2.zero();
    _totalLabel.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.24, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.18),
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

  String _normalizedOperation() {
    return context.operation?.trim().toLowerCase() ?? '';
  }
}

class _VisualPart {
  final ShapeComponent component;
  final Color baseColor;

  const _VisualPart({required this.component, required this.baseColor});
}
