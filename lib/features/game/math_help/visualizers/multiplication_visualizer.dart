import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-grid visualizer for multiplication contexts.
class MultiplicationVisualizer extends MathVisualizer {
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _transitionDurationSeconds = 0.82;
  static const _staggerDelaySeconds = 0.012;
  static const _phasePause = Duration(milliseconds: 1050);
  static const _loopPause = Duration(seconds: 3);

  static const _labelRevealDurationSeconds = 0.51;
  static const _labelPulseDurationSeconds = 0.21;
  static const _symbolRevealDurationSeconds = 0.36;
  static const _resultPulseDurationSeconds = 0.27;

  static const _firstOperandColor = Color(0xFF1B4F9A);
  static const _equationColor = Color(0xFF0A2463);

  late final int _targetRows;
  late final int _targetColumns;

  int _rows = 1;
  int _columns = 1;

  bool _isAnimating = false;
  bool _disposed = false;
  bool _isSequenceAnimating = false;
  bool _isFirstOperandVisible = false;
  bool _isMultiplicationSignVisible = false;
  bool _isSecondOperandVisible = false;
  bool _isEqualsVisible = false;
  bool _isResultVisible = false;

  Future<void>? _activeTransition;

  _MultiplicationGridComponent? _grid;
  List<_MultiplicationDotComponent> _dots = <_MultiplicationDotComponent>[];
  late final TextComponent _firstOperandLabel;
  late final TextComponent _multiplicationSignLabel;
  late final TextComponent _secondOperandLabel;
  late final TextComponent _equalsLabel;
  late final TextComponent _resultLabel;

  static const _maxOperand = 12;

  MultiplicationVisualizer({required super.context}) {
    _targetRows = _wholeOperand(0).clamp(0, _maxOperand);
    _targetColumns = _wholeOperand(1).clamp(0, _maxOperand);
    _rows = _previewRows;
    _columns = _previewColumns;
  }

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _targetProduct => _targetRows * _targetColumns;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildScene();
    unawaited(_runLoop());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded || _isAnimating || _isSequenceAnimating) {
      return;
    }
    _applyCurrentLayout();
    _applyEquationLayout();
  }

  @override
  void onRemove() {
    _disposed = true;
    super.onRemove();
  }

  Future<void> _runLoop() async {
    while (!_disposed) {
      await _playOnce();
      if (_disposed) {
        return;
      }
      await Future<void>.delayed(_loopPause);
      if (_disposed) {
        return;
      }
    }
  }

  Future<void> _playOnce() async {
    _isSequenceAnimating = true;
    _resetEquationRow();

    try {
      await _executeTransition(rows: _previewRows, columns: _previewColumns);
      if (_disposed) {
        return;
      }

      await _showOperandLabel(_firstOperandLabel);
      _isFirstOperandVisible = true;
      if (!await _pauseForNextStep()) {
        return;
      }

      await _showEquationSymbol(_multiplicationSignLabel);
      _isMultiplicationSignVisible = true;
      if (!await _pauseForNextStep()) {
        return;
      }

      await Future.wait(<Future<void>>[
        _showOperandLabel(_secondOperandLabel),
        _executeTransition(rows: _targetRows, columns: _targetColumns),
      ]);
      _isSecondOperandVisible = true;
      if (!await _pauseForNextStep()) {
        return;
      }

      await _showEquationSymbol(_equalsLabel);
      _isEqualsVisible = true;
      if (!await _pauseForNextStep()) {
        return;
      }

      await _showResultLabel();
      _isResultVisible = true;
    } finally {
      _isSequenceAnimating = false;
    }
  }

  Future<bool> _pauseForNextStep() async {
    if (_disposed) {
      return false;
    }
    await Future<void>.delayed(_phasePause);
    return !_disposed;
  }

  int get _previewRows {
    if (_targetRows <= 1) {
      return _targetRows;
    }
    return _targetColumns > 1 ? _targetRows : 1;
  }

  int get _previewColumns {
    if (_targetProduct <= 1) {
      return _targetColumns;
    }
    return 1;
  }

  void _buildScene() {
    final _DotLayout layout = _createLayout(rows: _rows, columns: _columns);
    _ensureGrid(layout: layout, rows: _rows, columns: _columns);

    _dots = _createDots(layout: layout, rows: _rows, columns: _columns);
    for (final _MultiplicationDotComponent dot in _dots) {
      add(dot);
    }

    _firstOperandLabel = TextComponent(
      text: '$_targetRows',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_firstOperandLabel);

    _multiplicationSignLabel = TextComponent(
      text: 'x',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_multiplicationSignLabel);

    _secondOperandLabel = TextComponent(
      text: '$_targetColumns',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_secondOperandLabel);

    _equalsLabel = TextComponent(
      text: '=',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_equalsLabel);

    _resultLabel = TextComponent(
      text: '${context.correctAnswer}',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_resultLabel);

    _applyEquationLayout();
    _resetEquationRow();
  }

  List<_MultiplicationDotComponent> _createDots({
    required _DotLayout layout,
    required int rows,
    required int columns,
  }) {
    return List<_MultiplicationDotComponent>.generate(
      layout.positions.length,
      (int index) => _MultiplicationDotComponent(
        center: layout.positions[index],
        color: _dotColorFor(index: index, columns: columns),
        radius: layout.radius,
      ),
    );
  }

  Future<void> _executeTransition({
    required int rows,
    required int columns,
  }) async {
    if (!isLoaded) {
      return;
    }
    if (_isAnimating) {
      await _activeTransition;
    }
    if (rows == _rows && columns == _columns) {
      return;
    }

    final Future<void> transition = _runTransition(
      targetRows: rows,
      targetColumns: columns,
    );
    _activeTransition = transition;
    try {
      await transition;
    } finally {
      if (identical(_activeTransition, transition)) {
        _activeTransition = null;
      }
    }
  }

  Future<void> _runTransition({
    required int targetRows,
    required int targetColumns,
  }) async {
    _setAnimating(true);
    try {
      final _DotLayout targetLayout = _createLayout(
        rows: targetRows,
        columns: targetColumns,
      );
      _ensureGrid(
        layout: targetLayout,
        rows: targetRows,
        columns: targetColumns,
      );

      final List<_MultiplicationDotComponent> previousDots =
          List<_MultiplicationDotComponent>.from(_dots);
      final int previousCount = previousDots.length;
      final int targetCount = targetLayout.positions.length;
      final int overlapRows = math.min(_rows, targetRows);
      final int overlapColumns = math.min(_columns, targetColumns);

      final List<_MultiplicationDotComponent?> nextDotSlots =
          List<_MultiplicationDotComponent?>.filled(targetCount, null);
      final Set<int> reusedIndices = <int>{};
      final List<_MultiplicationDotComponent> removedDots =
          <_MultiplicationDotComponent>[];

      for (int row = 0; row < overlapRows; row++) {
        for (int column = 0; column < overlapColumns; column++) {
          final int sourceIndex = (row * _columns) + column;
          final int targetIndex = (row * targetColumns) + column;
          if (sourceIndex >= previousCount || targetIndex >= targetCount) {
            continue;
          }

          final _MultiplicationDotComponent dot = previousDots[sourceIndex];
          final double radiusScale = targetLayout.radius / dot.radius;

          dot.clearEffects();
          dot.paint.color = _dotColorFor(
            index: targetIndex,
            columns: targetColumns,
          );
          dot.animateTo(
            targetPosition: targetLayout.positions[targetIndex],
            duration: _transitionDurationSeconds,
            targetScale: radiusScale,
            delay: targetIndex * _staggerDelaySeconds,
          );

          nextDotSlots[targetIndex] = dot;
          reusedIndices.add(sourceIndex);
        }
      }

      if (targetCount > 0) {
        final Vector2 spawnCenter = previousCount > 0
            ? previousDots.first.position.clone()
            : targetLayout.center;

        for (int targetIndex = 0; targetIndex < targetCount; targetIndex++) {
          if (nextDotSlots[targetIndex] != null) {
            continue;
          }

          Vector2 sourcePosition = spawnCenter.clone();
          double sourceRadius = targetLayout.radius;

          if (previousCount > 0) {
            final int targetRow = targetIndex ~/ math.max(1, targetColumns);
            final int targetColumn = targetIndex % math.max(1, targetColumns);
            final int sourceRow = math.min(targetRow, _rows - 1);
            final int sourceColumn = math.min(targetColumn, _columns - 1);
            int sourceIndex = (sourceRow * _columns) + sourceColumn;
            sourceIndex = _boundedIndex(
              value: sourceIndex,
              minValue: 0,
              maxValue: previousCount - 1,
            );
            final _MultiplicationDotComponent source =
                previousDots[sourceIndex];
            sourcePosition = source.position.clone();
            sourceRadius = source.radius;
          }

          final _MultiplicationDotComponent clone = _MultiplicationDotComponent(
            center: sourcePosition,
            color: _dotColorFor(index: targetIndex, columns: targetColumns),
            radius: sourceRadius,
          );

          clone.scale = Vector2.all(previousCount > 0 ? 0.42 : 0.2);
          add(clone);

          final double radiusScale = targetLayout.radius / clone.radius;
          clone.animateTo(
            targetPosition: targetLayout.positions[targetIndex],
            duration: _transitionDurationSeconds,
            targetScale: radiusScale,
            delay: targetIndex * _staggerDelaySeconds,
          );

          nextDotSlots[targetIndex] = clone;
        }
      }

      int removedOrder = 0;
      for (int sourceIndex = 0; sourceIndex < previousCount; sourceIndex++) {
        if (reusedIndices.contains(sourceIndex)) {
          continue;
        }

        final _MultiplicationDotComponent dot = previousDots[sourceIndex];
        final Vector2 collapseTarget = targetCount == 0
            ? targetLayout.center
            : targetLayout.positions[_collapseIndex(
                sourceIndex: sourceIndex,
                targetRows: targetRows,
                targetColumns: targetColumns,
              )];

        dot.clearEffects();
        dot.animateAway(
          collapseTarget: collapseTarget,
          duration: _transitionDurationSeconds * 0.86,
          delay: removedOrder * _staggerDelaySeconds,
        );
        removedDots.add(dot);
        removedOrder++;
      }

      final int highestIndex = math.max(
        math.max(previousCount, targetCount) - 1,
        0,
      );
      final double totalSeconds =
          _transitionDurationSeconds +
          (highestIndex * _staggerDelaySeconds) +
          0.08;
      await Future<void>.delayed(
        Duration(milliseconds: (totalSeconds * 1000).round()),
      );

      for (final _MultiplicationDotComponent dot in removedDots) {
        dot.removeFromParent();
      }

      final List<_MultiplicationDotComponent> nextDots =
          List<_MultiplicationDotComponent>.generate(targetCount, (int index) {
            final _MultiplicationDotComponent? existing = nextDotSlots[index];
            if (existing != null) {
              return existing;
            }
            final _MultiplicationDotComponent fallback =
                _MultiplicationDotComponent(
                  center: targetLayout.positions[index],
                  color: _dotColorFor(index: index, columns: targetColumns),
                  radius: targetLayout.radius,
                );
            add(fallback);
            return fallback;
          });

      for (int index = 0; index < nextDots.length; index++) {
        final _MultiplicationDotComponent dot = nextDots[index];
        dot.clearEffects();
        dot
          ..radius = targetLayout.radius
          ..scale = Vector2.all(1)
          ..position = targetLayout.positions[index]
          ..paint.color = _dotColorFor(index: index, columns: targetColumns);
      }

      _dots = nextDots;
      _rows = targetRows;
      _columns = targetColumns;
    } finally {
      _setAnimating(false);
    }
  }

  int _collapseIndex({
    required int sourceIndex,
    required int targetRows,
    required int targetColumns,
  }) {
    if (_columns <= 0 || targetRows <= 0 || targetColumns <= 0) {
      return 0;
    }
    final int sourceRow = sourceIndex ~/ _columns;
    final int sourceColumn = sourceIndex % _columns;
    final int collapseRow = math.min(sourceRow, targetRows - 1);
    final int collapseColumn = math.min(sourceColumn, targetColumns - 1);
    return (collapseRow * targetColumns) + collapseColumn;
  }

  void _applyCurrentLayout() {
    final _DotLayout layout = _createLayout(rows: _rows, columns: _columns);
    _ensureGrid(layout: layout, rows: _rows, columns: _columns);

    if (_dots.length != layout.positions.length) {
      for (final _MultiplicationDotComponent dot in _dots) {
        dot.removeFromParent();
      }
      _dots = _createDots(layout: layout, rows: _rows, columns: _columns);
      for (final _MultiplicationDotComponent dot in _dots) {
        add(dot);
      }
      return;
    }

    for (int index = 0; index < _dots.length; index++) {
      final _MultiplicationDotComponent dot = _dots[index];
      dot.clearEffects();
      dot
        ..radius = layout.radius
        ..scale = Vector2.all(1)
        ..position = layout.positions[index]
        ..paint.color = _dotColorFor(index: index, columns: _columns);
    }
  }

  void _ensureGrid({
    required _DotLayout layout,
    required int rows,
    required int columns,
  }) {
    final int gridRows = math.max(1, rows);
    final int gridColumns = math.max(1, columns);

    if (_grid == null) {
      _grid = _MultiplicationGridComponent(
        rows: gridRows,
        columns: gridColumns,
        position: layout.origin,
        size: layout.size,
      );
      add(_grid!);
      return;
    }

    _grid!
      ..position = layout.origin
      ..size = layout.size
      ..setDimensions(rows: gridRows, columns: gridColumns);
  }

  _DotLayout _createLayout({required int rows, required int columns}) {
    final Rect arena = _arenaBounds();
    final int safeRows = math.max(1, rows);
    final int safeColumns = math.max(1, columns);
    final double cellWidth = arena.width / safeColumns;
    final double cellHeight = arena.height / safeRows;
    final double radius = math.max(4, math.min(cellWidth, cellHeight) * 0.22);

    final List<Vector2> positions = <Vector2>[];
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        positions.add(
          Vector2(
            arena.left + (column * cellWidth) + (cellWidth * 0.5),
            arena.top + (row * cellHeight) + (cellHeight * 0.5),
          ),
        );
      }
    }

    return _DotLayout(
      positions: positions,
      radius: radius,
      origin: Vector2(arena.left, arena.top),
      size: Vector2(arena.width, arena.height),
      center: Vector2(arena.center.dx, arena.center.dy),
    );
  }

  Rect _arenaBounds() {
    final double width = size.x > 0 ? size.x : _fallbackWidth;
    final double height = size.y > 0 ? size.y : _fallbackHeight;
    final double horizontalPadding = math.max(12, width * 0.06);
    final double topPadding = height * 0.38;
    final double bottomPadding = math.max(10, height * 0.06);
    final double arenaWidth = math.max(0, width - (horizontalPadding * 2));
    final double arenaHeight = math.max(
      72,
      height - topPadding - bottomPadding,
    );

    return Rect.fromLTWH(
      horizontalPadding,
      topPadding,
      arenaWidth,
      arenaHeight,
    );
  }

  Color _dotColorFor({required int index, required int columns}) {
    final int safeColumns = math.max(1, columns);
    final int row = index ~/ safeColumns;
    final HSLColor baseColor = HSLColor.fromColor(const Color(0xFF1B6DE2));
    return baseColor
        .withHue((baseColor.hue + (row * 9)) % 360)
        .withSaturation(0.74)
        .withLightness(0.5)
        .toColor();
  }

  void _applyEquationLayout() {
    final double width = size.x > 0 ? size.x : _fallbackWidth;
    final double height = size.y > 0 ? size.y : _fallbackHeight;
    final double equationY = math.max(30, height * 0.14);
    final double equationCenterX = width / 2;
    final double equationStep = math.max(26, math.min(46, width * 0.09));

    _firstOperandLabel
      ..position = Vector2(equationCenterX - (equationStep * 2), equationY)
      ..scale = _isFirstOperandVisible ? Vector2.all(1) : Vector2.zero();
    _multiplicationSignLabel
      ..position = Vector2(equationCenterX - equationStep, equationY)
      ..scale = _isMultiplicationSignVisible ? Vector2.all(1) : Vector2.zero();
    _secondOperandLabel
      ..position = Vector2(equationCenterX, equationY)
      ..scale = _isSecondOperandVisible ? Vector2.all(1) : Vector2.zero();
    _equalsLabel
      ..position = Vector2(equationCenterX + equationStep, equationY)
      ..scale = _isEqualsVisible ? Vector2.all(1) : Vector2.zero();
    _resultLabel
      ..position = Vector2(equationCenterX + (equationStep * 2.2), equationY)
      ..scale = _isResultVisible ? Vector2.all(1) : Vector2.zero();
  }

  void _resetEquationRow() {
    _isFirstOperandVisible = false;
    _isMultiplicationSignVisible = false;
    _isSecondOperandVisible = false;
    _isEqualsVisible = false;
    _isResultVisible = false;

    _removeEffects(_firstOperandLabel);
    _firstOperandLabel
      ..text = '$_targetRows'
      ..textRenderer = mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();

    _removeEffects(_multiplicationSignLabel);
    _multiplicationSignLabel
      ..text = 'x'
      ..scale = Vector2.zero();

    _removeEffects(_secondOperandLabel);
    _secondOperandLabel
      ..text = '$_targetColumns'
      ..textRenderer = mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();

    _removeEffects(_equalsLabel);
    _equalsLabel
      ..text = '='
      ..scale = Vector2.zero();

    _removeEffects(_resultLabel);
    _resultLabel
      ..text = '${context.correctAnswer}'
      ..textRenderer = mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();

    _applyEquationLayout();
  }

  Future<void> _showOperandLabel(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final Completer<void> completer = Completer<void>();
    label.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _labelRevealDurationSeconds,
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(
            duration: _labelPulseDurationSeconds,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 1,
          ),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  Future<void> _showEquationSymbol(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final Completer<void> completer = Completer<void>();
    label.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: _symbolRevealDurationSeconds,
          curve: Curves.easeOutBack,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> _showResultLabel() {
    _removeEffects(_resultLabel);
    _resultLabel
      ..text = '${context.correctAnswer}'
      ..textRenderer = mathHelpTextPaint(
        color: _firstOperandColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();

    final Completer<void> completer = Completer<void>();
    _resultLabel.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _labelRevealDurationSeconds,
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1.14),
          EffectController(
            duration: _resultPulseDurationSeconds,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 2,
          ),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  void _removeEffects(PositionComponent component) {
    final List<Effect> effects = component.children
        .whereType<Effect>()
        .toList();
    for (final Effect effect in effects) {
      effect.removeFromParent();
    }
  }

  int _boundedIndex({
    required int value,
    required int minValue,
    required int maxValue,
  }) {
    return math.max(minValue, math.min(maxValue, value));
  }

  void _setAnimating(bool value) {
    _isAnimating = value;
  }

  int _wholeOperand(int index) {
    if (index >= context.operands.length) {
      return 0;
    }
    return math.max(0, context.operands[index].round());
  }
}

class _MultiplicationGridComponent extends PositionComponent {
  _MultiplicationGridComponent({
    required int rows,
    required int columns,
    required super.position,
    required super.size,
  }) : _rows = rows,
       _columns = columns;

  int _rows;
  int _columns;

  final Paint _fillPaint = Paint()..color = const Color(0xFFF8FBFF);
  final Paint _framePaint = Paint()
    ..color = const Color(0xFFBBD0F6)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  final Paint _linePaint = Paint()
    ..color = const Color(0xFFD6E2F7)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  void setDimensions({required int rows, required int columns}) {
    _rows = rows;
    _columns = columns;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Rect rect = Rect.fromLTWH(0, 0, size.x, size.y);
    const Radius cornerRadius = Radius.circular(20);
    final RRect roundedRect = RRect.fromRectAndRadius(rect, cornerRadius);

    canvas.drawRRect(roundedRect, _fillPaint);
    canvas.drawRRect(roundedRect, _framePaint);

    if (_rows <= 0 || _columns <= 0) {
      return;
    }

    final double cellWidth = rect.width / _columns;
    final double cellHeight = rect.height / _rows;

    for (int column = 1; column < _columns; column++) {
      final double x = cellWidth * column;
      canvas.drawLine(Offset(x, 0), Offset(x, rect.height), _linePaint);
    }

    for (int row = 1; row < _rows; row++) {
      final double y = cellHeight * row;
      canvas.drawLine(Offset(0, y), Offset(rect.width, y), _linePaint);
    }
  }
}

class _MultiplicationDotComponent extends CircleComponent {
  _MultiplicationDotComponent({
    required Vector2 center,
    required Color color,
    required double radius,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         position: center,
         paint: Paint()..color = color,
       );

  void clearEffects() {
    final List<Effect> effects = children.whereType<Effect>().toList();
    for (final Effect effect in effects) {
      effect.removeFromParent();
    }
  }

  void animateTo({
    required Vector2 targetPosition,
    required double duration,
    required double targetScale,
    double delay = 0,
  }) {
    _addAxisAlignedMove(
      targetPosition: targetPosition,
      duration: duration,
      delay: delay,
      curve: Curves.easeInOutCubic,
    );
    add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: duration * 0.92,
          startDelay: delay,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  void animateAway({
    required Vector2 collapseTarget,
    required double duration,
    double delay = 0,
  }) {
    _addAxisAlignedMove(
      targetPosition: collapseTarget,
      duration: duration,
      delay: delay,
      curve: Curves.easeInCubic,
    );
    add(
      ScaleEffect.to(
        Vector2.all(0.08),
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeInBack,
        ),
      ),
    );
  }

  void _addAxisAlignedMove({
    required Vector2 targetPosition,
    required double duration,
    required double delay,
    required Curve curve,
  }) {
    final Vector2 startPosition = position.clone();
    final double horizontalDistance = (targetPosition.x - startPosition.x)
        .abs();
    final double verticalDistance = (targetPosition.y - startPosition.y).abs();
    final double totalDistance = horizontalDistance + verticalDistance;

    if (totalDistance == 0) {
      return;
    }
    if (horizontalDistance == 0 || verticalDistance == 0) {
      add(
        MoveEffect.to(
          targetPosition,
          EffectController(duration: duration, startDelay: delay, curve: curve),
        ),
      );
      return;
    }

    final Vector2 bendPoint = Vector2(targetPosition.x, startPosition.y);
    final double horizontalDuration =
        duration * (horizontalDistance / totalDistance);
    final double verticalDuration = duration - horizontalDuration;

    add(
      SequenceEffect(<Effect>[
        MoveEffect.to(
          bendPoint,
          EffectController(
            duration: horizontalDuration,
            startDelay: delay,
            curve: curve,
          ),
        ),
        MoveEffect.to(
          targetPosition,
          EffectController(duration: verticalDuration, curve: curve),
        ),
      ]),
    );
  }
}

class _DotLayout {
  const _DotLayout({
    required this.positions,
    required this.radius,
    required this.origin,
    required this.size,
    required this.center,
  });

  final List<Vector2> positions;
  final double radius;
  final Vector2 origin;
  final Vector2 size;
  final Vector2 center;
}
