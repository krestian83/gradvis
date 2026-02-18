import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-grid visualizer for addition contexts.
class AdditionVisualizer extends MathVisualizer {
  static const _maxAddend = 20;
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _dotRadiusFactor = 0.22;
  static const _minDotRadius = 3.6;
  static const _hiddenSecondDotScale = 0.62;
  static const _revealDurationSeconds = 0.51;
  static const _revealStaggerDelaySeconds = 0.075;
  static const _colorMorphDuration = Duration(milliseconds: 900);
  static const _phasePause = Duration(milliseconds: 1050);
  static const _loopPause = Duration(seconds: 3);

  static const _firstDotColor = Color(0xFF1B6DE2);
  static const _secondDotColor = Color(0xFFF18F01);
  static const _mergedDotColor = Color(0xFF2E7D32);
  static const _firstLabelColor = Color(0xFF1B4F9A);
  static const _secondLabelColor = Color(0xFFB36A00);
  static const _equationColor = Color(0xFF0A2463);

  final _firstDots = <_AdditionDotComponent>[];
  final _secondDots = <_AdditionDotComponent>[];

  bool _disposed = false;
  bool _isAnimating = false;
  bool _isSecondGroupVisible = false;
  bool _isFirstCountVisible = false;
  bool _isSecondCountVisible = false;
  bool _isPlusVisible = false;
  bool _isEqualsVisible = false;
  bool _isResultVisible = false;

  late final int _firstAddend;
  late final int _secondAddend;

  _RoundedGridComponent? _grid;
  late final TextComponent _firstCountLabel;
  late final TextComponent _secondCountLabel;
  late final TextComponent _plusLabel;
  late final TextComponent _equalsLabel;
  late final TextComponent _resultLabel;
  late _SceneLayout _layout;

  AdditionVisualizer({required super.context}) {
    _firstAddend = _normalizedOperand(0);
    _secondAddend = _normalizedOperand(1);
  }

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _totalDots => _firstAddend + _secondAddend;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layout = _createLayout();
    _buildScene();
    unawaited(_runLoop());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded || _isAnimating) {
      return;
    }
    _applyLayoutPreservingState();
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
    }
  }

  Future<void> _playOnce() async {
    _resetScene();
    _isAnimating = true;

    try {
      await _showCountLabel(_firstCountLabel);
      _isFirstCountVisible = true;
      if (!await _pauseForNextStep()) {
        return;
      }

      await _showPlusLabel();
      if (!await _pauseForNextStep()) {
        return;
      }

      if (_secondDots.isNotEmpty) {
        await Future.wait(<Future<void>>[
          _revealSecondGroup(),
          _showCountLabel(_secondCountLabel),
        ]);
        _isSecondCountVisible = true;
        if (!await _pauseForNextStep()) {
          return;
        }
      } else {
        await _showCountLabel(_secondCountLabel);
        _isSecondCountVisible = true;
        if (!await _pauseForNextStep()) {
          return;
        }
      }

      await _showEqualsLabel();
      if (!await _pauseForNextStep()) {
        return;
      }

      await Future.wait(<Future<void>>[
        _showResultLabel(),
        _morphMergedDotsToOneColor(),
      ]);
      if (_disposed) {
        return;
      }
    } finally {
      _isAnimating = false;
    }
  }

  Future<bool> _pauseForNextStep() async {
    if (_disposed) {
      return false;
    }
    await Future<void>.delayed(_phasePause);
    return !_disposed;
  }

  void _buildScene() {
    _grid = _RoundedGridComponent(
      rows: _layout.rows,
      columns: _layout.columns,
      position: _layout.gridOrigin,
      size: _layout.gridSize,
    );
    add(_grid!);

    for (var index = 0; index < _firstAddend; index++) {
      final dot = _AdditionDotComponent(
        center: _layout.targetPositions[index],
        color: _firstDotColor,
        radius: _layout.dotRadius,
      );
      add(dot);
      _firstDots.add(dot);
    }

    for (var index = 0; index < _secondAddend; index++) {
      final dot =
          _AdditionDotComponent(
              center: _layout.targetPositions[_firstAddend + index],
              color: _secondDotColor,
              radius: _layout.dotRadius,
            )
            ..scale = Vector2.all(_hiddenSecondDotScale)
            ..opacity = 0;
      add(dot);
      _secondDots.add(dot);
    }

    _firstCountLabel = TextComponent(
      text: '$_firstAddend',
      anchor: Anchor.center,
      position: _layout.firstCountPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _firstLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_firstCountLabel);

    _secondCountLabel = TextComponent(
      text: '$_secondAddend',
      anchor: Anchor.center,
      position: _layout.secondCountPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _secondLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_secondCountLabel);

    _plusLabel = TextComponent(
      text: '+',
      anchor: Anchor.center,
      position: _layout.plusPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_plusLabel);

    _equalsLabel = TextComponent(
      text: '=',
      anchor: Anchor.center,
      position: _layout.equalsPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_equalsLabel);

    _resultLabel = TextComponent(
      text: '$_totalDots',
      anchor: Anchor.center,
      position: _layout.resultPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_resultLabel);

    _resetScene();
  }

  void _resetScene() {
    for (var index = 0; index < _firstDots.length; index++) {
      final dot = _firstDots[index];
      dot.clearEffects();
      dot
        ..radius = _layout.dotRadius
        ..position = _layout.targetPositions[index]
        ..scale = Vector2.all(1)
        ..paint.color = _firstDotColor;
    }

    for (var index = 0; index < _secondDots.length; index++) {
      final dot = _secondDots[index];
      dot.clearEffects();
      dot
        ..radius = _layout.dotRadius
        ..paint.color = _secondDotColor
        ..position = _layout.targetPositions[_firstAddend + index]
        ..scale = Vector2.all(_hiddenSecondDotScale)
        ..opacity = 0;
    }

    _removeEffects(_firstCountLabel);
    _firstCountLabel
      ..text = '$_firstAddend'
      ..textRenderer = mathHelpTextPaint(
        color: _firstLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.firstCountPosition
      ..scale = Vector2.zero();

    _removeEffects(_secondCountLabel);
    _secondCountLabel
      ..text = '$_secondAddend'
      ..textRenderer = mathHelpTextPaint(
        color: _secondLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.secondCountPosition
      ..scale = Vector2.zero();

    _removeEffects(_plusLabel);
    _plusLabel
      ..text = '+'
      ..position = _layout.plusPosition
      ..scale = Vector2.zero();

    _removeEffects(_equalsLabel);
    _equalsLabel
      ..text = '='
      ..position = _layout.equalsPosition
      ..scale = Vector2.zero();

    _removeEffects(_resultLabel);
    _resultLabel
      ..text = '$_totalDots'
      ..textRenderer = mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.resultPosition
      ..scale = Vector2.zero();

    _isSecondGroupVisible = false;
    _isFirstCountVisible = false;
    _isSecondCountVisible = false;
    _isPlusVisible = false;
    _isEqualsVisible = false;
    _isResultVisible = false;
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  void _applyLayoutPreservingState() {
    _layout = _createLayout();
    _grid
      ?..position = _layout.gridOrigin
      ..size = _layout.gridSize
      ..setDimensions(rows: _layout.rows, columns: _layout.columns);

    for (var index = 0; index < _firstDots.length; index++) {
      final dot = _firstDots[index];
      dot
        ..radius = _layout.dotRadius
        ..position = _layout.targetPositions[index]
        ..scale = Vector2.all(1);
    }

    for (var index = 0; index < _secondDots.length; index++) {
      final dot = _secondDots[index];
      final targetPosition = _layout.targetPositions[_firstAddend + index];
      final scale = _isSecondGroupVisible ? 1.0 : _hiddenSecondDotScale;
      final opacity = _isSecondGroupVisible ? 1.0 : 0.0;
      dot
        ..radius = _layout.dotRadius
        ..position = targetPosition
        ..scale = Vector2.all(scale)
        ..opacity = opacity;
    }

    _firstCountLabel
      ..position = _layout.firstCountPosition
      ..scale = _isFirstCountVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _firstLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );
    _secondCountLabel
      ..position = _layout.secondCountPosition
      ..scale = _isSecondCountVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _secondLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );
    _plusLabel
      ..position = _layout.plusPosition
      ..scale = _isPlusVisible ? Vector2.all(1) : Vector2.zero();
    _equalsLabel
      ..position = _layout.equalsPosition
      ..scale = _isEqualsVisible ? Vector2.all(1) : Vector2.zero();
    _resultLabel
      ..position = _layout.resultPosition
      ..scale = _isResultVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _isResultVisible ? _mergedDotColor : _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      );
  }

  _SceneLayout _createLayout() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final horizontalPadding = math.max(12.0, width * 0.06);
    final bottomPadding = math.max(10.0, height * 0.06);
    final equationY = math.max(30.0, height * 0.14);
    final gridTop = height * 0.34;
    final gridBottom = height - bottomPadding;

    final gridRect = Rect.fromLTWH(
      horizontalPadding,
      gridTop,
      math.max(80.0, width - (horizontalPadding * 2)),
      math.max(72.0, gridBottom - gridTop),
    );

    final targetCount = _totalDots;
    final targetSpec = _bestGrid(
      count: math.max(1, targetCount),
      width: gridRect.width,
      height: gridRect.height,
    );
    final targetPositions = _gridPositions(
      rect: gridRect,
      columns: targetSpec.columns,
      count: targetCount,
    );

    var radiusBase = math.min(targetSpec.cellWidth, targetSpec.cellHeight);
    final radius = math.max(_minDotRadius, radiusBase * _dotRadiusFactor);
    final equationCenterX = width / 2;
    final equationStep = math.max(26.0, math.min(46.0, width * 0.09));
    final firstEquationNumberPosition = Vector2(
      equationCenterX - (equationStep * 2.0),
      equationY,
    );
    final plusPosition = Vector2(equationCenterX - equationStep, equationY);
    final secondEquationNumberPosition = Vector2(equationCenterX, equationY);
    final equalsPosition = Vector2(equationCenterX + equationStep, equationY);
    final resultPosition = Vector2(
      equationCenterX + (equationStep * 2.2),
      equationY,
    );

    return _SceneLayout(
      rows: targetSpec.rows,
      columns: targetSpec.columns,
      gridOrigin: Vector2(gridRect.left, gridRect.top),
      gridSize: Vector2(gridRect.width, gridRect.height),
      targetPositions: targetPositions,
      dotRadius: radius,
      firstCountPosition: firstEquationNumberPosition,
      secondCountPosition: secondEquationNumberPosition,
      plusPosition: plusPosition,
      equalsPosition: equalsPosition,
      resultPosition: resultPosition,
    );
  }

  _GridSpec _bestGrid({
    required int count,
    required double width,
    required double height,
  }) {
    if (count <= 1) {
      return _GridSpec(
        rows: 1,
        columns: 1,
        cellWidth: width,
        cellHeight: height,
      );
    }

    var best = _GridSpec(
      rows: count,
      columns: 1,
      cellWidth: width,
      cellHeight: height / count,
    );
    var bestScore = double.infinity;

    for (var columns = 1; columns <= count; columns++) {
      final rows = (count / columns).ceil();
      final cellWidth = width / columns;
      final cellHeight = height / rows;
      final unusedSlots = (rows * columns) - count;
      final aspectPenalty = (cellWidth / math.max(1, cellHeight) - 1).abs();
      final score = aspectPenalty + (unusedSlots * 0.016);
      if (score < bestScore) {
        bestScore = score;
        best = _GridSpec(
          rows: rows,
          columns: columns,
          cellWidth: cellWidth,
          cellHeight: cellHeight,
        );
      }
    }

    return best;
  }

  List<Vector2> _gridPositions({
    required Rect rect,
    required int columns,
    required int count,
  }) {
    if (count == 0) {
      return const <Vector2>[];
    }
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;

    return List<Vector2>.generate(count, (index) {
      final row = index ~/ columns;
      final column = index % columns;
      return Vector2(
        rect.left + (column * cellWidth) + (cellWidth * 0.5),
        rect.top + (row * cellHeight) + (cellHeight * 0.5),
      );
    });
  }

  int _normalizedOperand(int index) {
    if (index >= context.operands.length) {
      return 0;
    }
    final rounded = context.operands[index].round();
    if (rounded < 0) {
      return 0;
    }
    if (rounded > _maxAddend) {
      return _maxAddend;
    }
    return rounded;
  }

  Future<void> _showCountLabel(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final completer = Completer<void>();
    label.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.51, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(
            duration: 0.21,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 1,
          ),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  Future<void> _revealSecondGroup() async {
    _isSecondGroupVisible = true;
    final revealFutures = <Future<void>>[];
    for (var index = 0; index < _secondDots.length; index++) {
      revealFutures.add(
        _secondDots[index].revealInGrid(
          duration: _revealDurationSeconds,
          targetScale: 1,
          delay: index * _revealStaggerDelaySeconds,
        ),
      );
    }
    if (revealFutures.isEmpty) {
      return;
    }
    await Future.wait(revealFutures);
  }

  Future<void> _morphMergedDotsToOneColor() async {
    final allDots = <_AdditionDotComponent>[..._firstDots, ..._secondDots];
    if (allDots.isEmpty) {
      return;
    }

    final fromColors = allDots.map((dot) => dot.paint.color).toList();
    const stepCount = 16;
    final stepMilliseconds = (_colorMorphDuration.inMilliseconds / stepCount)
        .round();
    final stepDuration = Duration(milliseconds: math.max(1, stepMilliseconds));

    for (var step = 1; step <= stepCount; step++) {
      if (_disposed) {
        return;
      }
      final progress = Curves.easeInOutCubic.transform(step / stepCount);
      for (var index = 0; index < allDots.length; index++) {
        allDots[index].paint.color =
            Color.lerp(fromColors[index], _mergedDotColor, progress) ??
            _mergedDotColor;
      }
      await Future<void>.delayed(stepDuration);
    }
  }

  Future<void> _showPlusLabel() async {
    if (_isPlusVisible) {
      return;
    }
    _isPlusVisible = true;
    await _showEquationSymbol(_plusLabel);
  }

  Future<void> _showEqualsLabel() async {
    if (_isEqualsVisible) {
      return;
    }
    _isEqualsVisible = true;
    await _showEquationSymbol(_equalsLabel);
  }

  Future<void> _showResultLabel() async {
    if (_isResultVisible) {
      return;
    }
    _isResultVisible = true;
    _removeEffects(_resultLabel);
    _resultLabel.scale = Vector2.zero();
    _resultLabel.text = '$_totalDots';
    _resultLabel.textRenderer = mathHelpTextPaint(
      color: _mergedDotColor,
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );

    final completer = Completer<void>();
    _resultLabel.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.51, curve: Curves.easeOutBack),
        ),
        ScaleEffect.to(
          Vector2.all(1.14),
          EffectController(
            duration: 0.27,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 2,
          ),
        ),
      ], onComplete: completer.complete),
    );
    await completer.future;
  }

  Future<void> _showEquationSymbol(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final completer = Completer<void>();
    label.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.36, curve: Curves.easeOutBack),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }
}

class _RoundedGridComponent extends RectangleComponent {
  _RoundedGridComponent({
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
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    const cornerRadius = Radius.circular(18);
    final roundedRect = RRect.fromRectAndRadius(rect, cornerRadius);

    canvas.drawRRect(roundedRect, _fillPaint);
    canvas.drawRRect(roundedRect, _framePaint);

    if (_rows <= 0 || _columns <= 0) {
      return;
    }

    final cellWidth = rect.width / _columns;
    final cellHeight = rect.height / _rows;

    for (var column = 1; column < _columns; column++) {
      final x = cellWidth * column;
      canvas.drawLine(Offset(x, 0), Offset(x, rect.height), _linePaint);
    }

    for (var row = 1; row < _rows; row++) {
      final y = cellHeight * row;
      canvas.drawLine(Offset(0, y), Offset(rect.width, y), _linePaint);
    }
  }
}

class _AdditionDotComponent extends CircleComponent {
  _AdditionDotComponent({
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
    final effects = children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  Future<void> revealInGrid({
    required double duration,
    required double targetScale,
    double delay = 0,
  }) {
    final completer = Completer<void>();
    add(
      OpacityEffect.to(
        1,
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeOut,
        ),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeOutBack,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }
}

class _GridSpec {
  const _GridSpec({
    required this.rows,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
  });

  final int rows;
  final int columns;
  final double cellWidth;
  final double cellHeight;
}

class _SceneLayout {
  const _SceneLayout({
    required this.rows,
    required this.columns,
    required this.gridOrigin,
    required this.gridSize,
    required this.targetPositions,
    required this.dotRadius,
    required this.firstCountPosition,
    required this.secondCountPosition,
    required this.plusPosition,
    required this.equalsPosition,
    required this.resultPosition,
  });

  final int rows;
  final int columns;
  final Vector2 gridOrigin;
  final Vector2 gridSize;
  final List<Vector2> targetPositions;
  final double dotRadius;
  final Vector2 firstCountPosition;
  final Vector2 secondCountPosition;
  final Vector2 plusPosition;
  final Vector2 equalsPosition;
  final Vector2 resultPosition;
}
