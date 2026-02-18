import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Visualizer for counting sides on basic 2D shapes.
class ShapeSidesVisualizer extends MathVisualizer {
  static const _outlineColor = Color(0xFF355070);
  static const _baseSideColor = Color(0xFF5D7EA8);
  static const _highlightColor = Color(0xFFFFB703);
  static const _labelColor = Color(0xFF0A2463);

  static const _sideThickness = 6.0;
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;

  final _segments = <RectangleComponent>[];
  late final TextComponent _countLabel;
  late final TextComponent _totalLabel;

  bool _disposed = false;
  late int _sideTotal;

  ShapeSidesVisualizer({required super.context});

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
    for (var i = 0; i < _segments.length; i++) {
      await _highlightSegment(_segments[i]);
      if (_disposed) return;
      _countLabel.text = 'Sider: ${i + 1}';
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    _showTotal();
  }

  Future<void> _highlightSegment(RectangleComponent segment) {
    final completer = Completer<void>();
    _removeEffects(segment);
    segment.scale = Vector2.all(1);
    segment.add(
      ColorEffect(
        _highlightColor,
        EffectController(
          duration: 0.18,
          reverseDuration: 0.18,
          curve: Curves.easeInOut,
        ),
        onComplete: completer.complete,
      ),
    );
    segment.add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(
          duration: 0.18,
          reverseDuration: 0.18,
          curve: Curves.easeInOut,
        ),
      ),
    );
    return completer.future;
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final center = Vector2(width / 2, height * 0.56);
    final spec = _resolveSpec(_normalizedOperation());
    _sideTotal = spec.sideCount;

    if (spec.shapeType == _ShapeType.circle) {
      _addCircle(center, spec);
    } else {
      _addPolygon(center, spec);
    }

    _countLabel = TextComponent(
      text: 'Sider: 0',
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
      text: 'Totalt: $_sideTotal',
      anchor: Anchor.center,
      position: Vector2(width / 2, 34),
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(color: _labelColor, fontSize: 30),
    );
    add(_totalLabel);
  }

  void _addPolygon(Vector2 center, _ShapeSpec spec) {
    final vertices = switch (spec.shapeType) {
      _ShapeType.rectangle => _rectangleVertices(center),
      _ShapeType.regularPolygon => _regularPolygonVertices(
        center: center,
        sideCount: spec.sideCount,
        radius: spec.radius,
      ),
      _ => <Vector2>[],
    };

    final shape = PolygonComponent(
      vertices,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = _outlineColor,
    );
    add(shape);

    for (var i = 0; i < vertices.length; i++) {
      final start = vertices[i];
      final end = vertices[(i + 1) % vertices.length];
      final segment = _buildSegment(start: start, end: end);
      _segments.add(segment);
      add(segment);
    }
  }

  void _addCircle(Vector2 center, _ShapeSpec spec) {
    add(
      CircleComponent(
        radius: spec.radius,
        anchor: Anchor.center,
        position: center.clone(),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = _outlineColor,
      ),
    );

    if (spec.sideCount <= 0) return;

    final step = (math.pi * 2) / spec.sideCount;
    for (var i = 0; i < spec.sideCount; i++) {
      final angleA = i * step - math.pi / 2;
      final angleB = (i + 1) * step - math.pi / 2;
      final start = Vector2(
        center.x + math.cos(angleA) * spec.radius,
        center.y + math.sin(angleA) * spec.radius,
      );
      final end = Vector2(
        center.x + math.cos(angleB) * spec.radius,
        center.y + math.sin(angleB) * spec.radius,
      );
      final segment = _buildSegment(start: start, end: end);
      _segments.add(segment);
      add(segment);
    }
  }

  RectangleComponent _buildSegment({
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
      size: Vector2(length, _sideThickness),
      angle: angle,
      anchor: Anchor.center,
      paint: Paint()..color = _baseSideColor,
    );
  }

  List<Vector2> _regularPolygonVertices({
    required Vector2 center,
    required int sideCount,
    required double radius,
  }) {
    final vertices = <Vector2>[];
    final step = (math.pi * 2) / sideCount;
    for (var i = 0; i < sideCount; i++) {
      final angle = i * step - math.pi / 2;
      vertices.add(
        Vector2(
          center.x + math.cos(angle) * radius,
          center.y + math.sin(angle) * radius,
        ),
      );
    }
    return vertices;
  }

  List<Vector2> _rectangleVertices(Vector2 center) {
    const halfWidth = 84.0;
    const halfHeight = 54.0;
    return [
      Vector2(center.x - halfWidth, center.y - halfHeight),
      Vector2(center.x + halfWidth, center.y - halfHeight),
      Vector2(center.x + halfWidth, center.y + halfHeight),
      Vector2(center.x - halfWidth, center.y + halfHeight),
    ];
  }

  void _resetScene() {
    for (final segment in _segments) {
      _removeEffects(segment);
      segment.paint.color = _baseSideColor;
      segment.scale = Vector2.all(1);
    }
    _countLabel.text = 'Sider: 0';
    _removeEffects(_totalLabel);
    _totalLabel.scale = Vector2.zero();
    _totalLabel.text = 'Totalt: $_sideTotal';
  }

  void _showTotal() {
    _removeEffects(_totalLabel);
    _totalLabel.scale = Vector2.zero();
    _totalLabel.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.25, curve: Curves.easeOutBack),
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

  _ShapeSpec _resolveSpec(String operation) {
    switch (operation) {
      case 'trianglesides':
        return const _ShapeSpec(
          shapeType: _ShapeType.regularPolygon,
          sideCount: 3,
          radius: 80,
        );
      case 'squaresides':
        return const _ShapeSpec(
          shapeType: _ShapeType.regularPolygon,
          sideCount: 4,
          radius: 76,
        );
      case 'rectanglesides':
        return const _ShapeSpec(
          shapeType: _ShapeType.rectangle,
          sideCount: 4,
          radius: 0,
        );
      case 'circlesides':
        final answer = context.correctAnswer.round();
        return _ShapeSpec(
          shapeType: _ShapeType.circle,
          sideCount: answer < 0 ? 0 : answer,
          radius: 78,
        );
      case 'pentagonsides':
        return const _ShapeSpec(
          shapeType: _ShapeType.regularPolygon,
          sideCount: 5,
          radius: 80,
        );
      case 'hexagonsides':
        return const _ShapeSpec(
          shapeType: _ShapeType.regularPolygon,
          sideCount: 6,
          radius: 82,
        );
      default:
        final fallback = math.max(3, context.correctAnswer.round());
        return _ShapeSpec(
          shapeType: _ShapeType.regularPolygon,
          sideCount: fallback,
          radius: 80,
        );
    }
  }
}

enum _ShapeType { regularPolygon, rectangle, circle }

class _ShapeSpec {
  final _ShapeType shapeType;
  final int sideCount;
  final double radius;

  const _ShapeSpec({
    required this.shapeType,
    required this.sideCount,
    required this.radius,
  });
}
