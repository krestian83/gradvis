import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Visualizer for selecting the most suitable measurement unit.
class UnitChoiceVisualizer extends MathVisualizer {
  static const _loopPause = Duration(seconds: 2);
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _labelColor = Color(0xFF0A2463);

  final _options = <UnitChoiceOptionComponent>[];
  late final TextComponent _titleLabel;
  late final TextComponent _valueLabel;
  bool _disposed = false;
  int _correctIndex = 0;

  UnitChoiceVisualizer({required super.context});

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
    for (var index = 0; index < _options.length; index++) {
      final option = _options[index];
      if (index == _correctIndex) {
        await option.showCorrect();
      } else {
        await option.showWrong();
      }
      if (_disposed) return;
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  void _buildScene() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final scenario = _resolveScenario();
    _correctIndex = scenario.correctIndex;
    final itemCount = scenario.options.length;
    final spacing = 14.0;
    final optionWidth = math
        .min(116.0, (width - 34 - spacing * (itemCount - 1)) / itemCount)
        .clamp(84.0, 116.0)
        .toDouble();
    const optionHeight = 124.0;
    final startX =
        width / 2 - ((optionWidth * itemCount) + spacing * (itemCount - 1)) / 2;
    final rowY = height * 0.62;

    _titleLabel = TextComponent(
      text: 'Velg riktig enhet',
      anchor: Anchor.topCenter,
      position: Vector2(width / 2, 10),
      textRenderer: mathHelpTextPaint(
        color: _labelColor,
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_titleLabel);

    _valueLabel = TextComponent(
      text: 'Verdi: ${_valueText()}',
      anchor: Anchor.topCenter,
      position: Vector2(width / 2, 48),
      textRenderer: mathHelpTextPaint(
        color: _labelColor,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_valueLabel);

    for (var index = 0; index < scenario.options.length; index++) {
      final optionSpec = scenario.options[index];
      final option = UnitChoiceOptionComponent(
        unitId: optionSpec.unitId,
        label: optionSpec.label,
        position: Vector2(
          startX + optionWidth / 2 + index * (optionWidth + spacing),
          rowY,
        ),
        size: Vector2(optionWidth, optionHeight),
      );
      _options.add(option);
      add(option);
    }
  }

  void _resetScene() {
    for (final option in _options) {
      option.resetVisuals();
    }
  }

  _UnitChoiceScenario _resolveScenario() {
    final label = context.label?.toLowerCase().trim() ?? '';
    for (final rule in _scenarioRules) {
      if (label.contains(rule.keyword)) {
        return rule.scenario;
      }
    }
    return _fallbackScenario;
  }

  String _valueText() {
    if (context.operands.isEmpty) return context.correctAnswer.toString();
    return context.operands.first.toString();
  }
}

class UnitChoiceOptionComponent extends PositionComponent {
  static const _cardColor = Color(0xFFE6EDF8);
  static const _iconColor = Color(0xFF355070);
  static const _wrongColor = Color(0xFFFF8A80);
  static const _correctColor = Color(0xFF7BD88F);

  final String unitId;
  final String label;
  final Vector2 homePosition;

  late final CircleComponent _glow;
  late final RectangleComponent _card;

  UnitChoiceOptionComponent({
    required this.unitId,
    required this.label,
    required Vector2 position,
    required Vector2 size,
  }) : homePosition = position.clone(),
       super(position: position, size: size, anchor: Anchor.center) {
    final center = Vector2(size.x / 2, size.y / 2);

    _glow = CircleComponent(
      radius: size.x * 0.48,
      anchor: Anchor.center,
      position: center.clone(),
      paint: Paint()..color = const Color(0x663CCF6A),
    )..opacity = 0;
    add(_glow);

    _card = RectangleComponent(
      size: size,
      position: center.clone(),
      anchor: Anchor.center,
      paint: Paint()..color = _cardColor,
    );
    add(_card);

    _addIcon(center);

    add(
      TextComponent(
        text: label,
        anchor: Anchor.topCenter,
        position: Vector2(center.x, size.y - 36),
        textRenderer: mathHelpTextPaint(
          color: const Color(0xFF13315C),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> showWrong() async {
    resetVisuals();
    final completer = Completer<void>();
    _card.add(
      ColorEffect(
        _wrongColor,
        EffectController(
          duration: 0.18,
          reverseDuration: 0.18,
          curve: Curves.easeInOut,
        ),
        onComplete: completer.complete,
      ),
    );
    add(
      MoveEffect.by(
        Vector2(8, 0),
        EffectController(
          duration: 0.08,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: 4,
        ),
      ),
    );
    await completer.future;
  }

  Future<void> showCorrect() async {
    resetVisuals();
    final completer = Completer<void>();
    _glow.add(
      OpacityEffect.to(
        1,
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
    _card.add(
      ColorEffect(
        _correctColor,
        EffectController(
          duration: 0.18,
          reverseDuration: 0.18,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: 2,
        ),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(
          duration: 0.18,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: 2,
        ),
      ),
    );
    await completer.future;
  }

  void resetVisuals() {
    _removeEffects(this);
    _removeEffects(_card);
    _removeEffects(_glow);
    _glow.opacity = 0;
    _card.paint.color = _cardColor;
    scale = Vector2.all(1);
    position = homePosition.clone();
  }

  void _addIcon(Vector2 center) {
    switch (unitId) {
      case 'teaspoon':
        _addTeaspoonIcon(center);
      case 'cup':
        _addCupIcon(center);
      case 'bucket':
        _addBucketIcon(center);
      case 'bottle':
        _addBottleIcon(center);
      case 'glass':
        _addGlassIcon(center);
      default:
        _addTeaspoonIcon(center);
    }
  }

  void _addTeaspoonIcon(Vector2 center) {
    add(
      RectangleComponent(
        position: Vector2(center.x - 22, center.y - 16),
        size: Vector2(32, 6),
        anchor: Anchor.topLeft,
        paint: Paint()..color = _iconColor,
      ),
    );
    add(
      CircleComponent(
        radius: 10,
        position: Vector2(center.x + 14, center.y - 13),
        anchor: Anchor.center,
        paint: Paint()..color = _iconColor,
      ),
    );
  }

  void _addCupIcon(Vector2 center) {
    add(
      RectangleComponent(
        position: Vector2(center.x - 20, center.y - 22),
        size: Vector2(36, 30),
        anchor: Anchor.topLeft,
        paint: Paint()..color = _iconColor,
      ),
    );
    add(
      CircleComponent(
        radius: 8,
        position: Vector2(center.x + 20, center.y - 8),
        anchor: Anchor.center,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _iconColor,
      ),
    );
  }

  void _addBucketIcon(Vector2 center) {
    add(
      PolygonComponent([
        Vector2(center.x - 20, center.y - 10),
        Vector2(center.x + 20, center.y - 10),
        Vector2(center.x + 14, center.y + 20),
        Vector2(center.x - 14, center.y + 20),
      ], paint: Paint()..color = _iconColor),
    );
    add(
      RectangleComponent(
        position: Vector2(center.x - 12, center.y - 18),
        size: Vector2(24, 4),
        anchor: Anchor.topLeft,
        paint: Paint()..color = _iconColor,
      ),
    );
  }

  void _addBottleIcon(Vector2 center) {
    add(
      RectangleComponent(
        position: Vector2(center.x - 14, center.y - 22),
        size: Vector2(28, 42),
        anchor: Anchor.topLeft,
        paint: Paint()..color = _iconColor,
      ),
    );
    add(
      RectangleComponent(
        position: Vector2(center.x - 6, center.y - 32),
        size: Vector2(12, 10),
        anchor: Anchor.topLeft,
        paint: Paint()..color = _iconColor,
      ),
    );
  }

  void _addGlassIcon(Vector2 center) {
    add(
      PolygonComponent([
        Vector2(center.x - 18, center.y - 24),
        Vector2(center.x + 18, center.y - 24),
        Vector2(center.x + 12, center.y + 20),
        Vector2(center.x - 12, center.y + 20),
      ], paint: Paint()..color = _iconColor),
    );
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }
}

class _UnitChoiceRule {
  final String keyword;
  final _UnitChoiceScenario scenario;

  const _UnitChoiceRule({required this.keyword, required this.scenario});
}

class _UnitChoiceScenario {
  final List<_UnitOption> options;
  final int correctIndex;

  const _UnitChoiceScenario({
    required this.options,
    required this.correctIndex,
  });
}

class _UnitOption {
  final String unitId;
  final String label;

  const _UnitOption({required this.unitId, required this.label});
}

const _scenarioRules = [
  _UnitChoiceRule(
    keyword: 'badekar',
    scenario: _UnitChoiceScenario(
      options: [
        _UnitOption(unitId: 'teaspoon', label: 'Skje'),
        _UnitOption(unitId: 'cup', label: 'Kopp'),
        _UnitOption(unitId: 'bucket', label: 'Botte'),
      ],
      correctIndex: 2,
    ),
  ),
  _UnitChoiceRule(
    keyword: 'medisin',
    scenario: _UnitChoiceScenario(
      options: [
        _UnitOption(unitId: 'teaspoon', label: 'Skje'),
        _UnitOption(unitId: 'cup', label: 'Kopp'),
        _UnitOption(unitId: 'bucket', label: 'Botte'),
      ],
      correctIndex: 0,
    ),
  ),
  _UnitChoiceRule(
    keyword: 'juice',
    scenario: _UnitChoiceScenario(
      options: [
        _UnitOption(unitId: 'teaspoon', label: 'Skje'),
        _UnitOption(unitId: 'glass', label: 'Glass'),
        _UnitOption(unitId: 'bucket', label: 'Botte'),
      ],
      correctIndex: 1,
    ),
  ),
  _UnitChoiceRule(
    keyword: 'flaske',
    scenario: _UnitChoiceScenario(
      options: [
        _UnitOption(unitId: 'cup', label: 'Kopp'),
        _UnitOption(unitId: 'bottle', label: 'Flaske'),
        _UnitOption(unitId: 'bucket', label: 'Botte'),
      ],
      correctIndex: 1,
    ),
  ),
  _UnitChoiceRule(
    keyword: 'suppe',
    scenario: _UnitChoiceScenario(
      options: [
        _UnitOption(unitId: 'teaspoon', label: 'Skje'),
        _UnitOption(unitId: 'cup', label: 'Kopp'),
        _UnitOption(unitId: 'bucket', label: 'Botte'),
      ],
      correctIndex: 1,
    ),
  ),
];

const _fallbackScenario = _UnitChoiceScenario(
  options: [
    _UnitOption(unitId: 'teaspoon', label: 'Skje'),
    _UnitOption(unitId: 'cup', label: 'Kopp'),
    _UnitOption(unitId: 'bucket', label: 'Botte'),
  ],
  correctIndex: 1,
);
