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
  static const _stagingScale = 0.86;
  static const _hiddenStagingScale = 0.62;
  static const _revealDurationSeconds = 0.51;
  static const _revealStaggerDelaySeconds = 0.075;
  static const _moveDurationSeconds = 1.92;
  static const _moveStaggerDelaySeconds = 0.09;
  static const _countSlideDurationSeconds = 0.84;
  static const _countSlideStaggerSeconds = 0.18;
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
  bool _isMerged = false;
  bool _isSecondGroupVisible = false;
  bool _areCountsInEquation = false;

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

    await _showCountLabel(_firstCountLabel);
    if (_disposed) {
      return;
    }
    await Future<void>.delayed(_phasePause);
    if (_disposed) {
      return;
    }

    if (_secondDots.isNotEmpty) {
      await _revealSecondGroup();
      if (_disposed) {
        return;
      }
      await _showCountLabel(_secondCountLabel);
      if (_disposed) {
        return;
      }
      await Future<void>.delayed(_phasePause);
      if (_disposed) {
        return;
      }
    }

    final moveFutures = <Future<void>>[];
    for (var index = 0; index < _secondDots.length; index++) {
      final dot = _secondDots[index];
      moveFutures.add(
        dot.animateTo(
          targetPosition: _layout.targetPositions[_firstAddend + index],
          duration: _moveDurationSeconds,
          targetScale: 1,
          delay: index * _moveStaggerDelaySeconds,
        ),
      );
    }

    if (moveFutures.isNotEmpty) {
      await Future.wait(moveFutures);
      if (_disposed) {
        return;
      }
    }

    await _morphMergedDotsToOneColor();
    if (_disposed) {
      return;
    }
    await _slideCountsIntoEquation();
    if (_disposed) {
      return;
    }
    _isMerged = true;
    await _showEquationTail();
    _isAnimating = false;
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
              center: _layout.stagingPositions[index],
              color: _secondDotColor,
              radius: _layout.dotRadius,
            )
            ..scale = Vector2.all(_hiddenStagingScale)
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
        ..position = _layout.stagingPositions[index]
        ..scale = Vector2.all(_hiddenStagingScale)
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

    _areCountsInEquation = false;
    _isSecondGroupVisible = false;
    _isMerged = false;
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
      final position = _isMerged
          ? targetPosition
          : _layout.stagingPositions[index];
      final scale = _isMerged
          ? 1.0
          : (_isSecondGroupVisible ? _stagingScale : _hiddenStagingScale);
      final opacity = _isSecondGroupVisible || _isMerged ? 1.0 : 0.0;
      dot
        ..radius = _layout.dotRadius
        ..position = position
        ..scale = Vector2.all(scale)
        ..opacity = opacity;
    }

    _firstCountLabel.position = _areCountsInEquation
        ? _layout.firstEquationNumberPosition
        : _layout.firstCountPosition;
    _secondCountLabel.position = _areCountsInEquation
        ? _layout.secondEquationNumberPosition
        : _layout.secondCountPosition;
    _plusLabel.position = _layout.plusPosition;
    _equalsLabel.position = _layout.equalsPosition;
    _resultLabel.position = _layout.resultPosition;
  }

  _SceneLayout _createLayout() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final horizontalPadding = math.max(12.0, width * 0.06);
    final bottomPadding = math.max(10.0, height * 0.06);
    final equationY = math.max(30.0, height * 0.14);

    final stagingTop = height * 0.24;
    final stagingBottom = height * 0.47;
    final gridTop = height * 0.5;
    final gridBottom = height - bottomPadding;

    final gridRect = Rect.fromLTWH(
      horizontalPadding,
      gridTop,
      math.max(80.0, width - (horizontalPadding * 2)),
      math.max(72.0, gridBottom - gridTop),
    );
    final stagingRect = Rect.fromLTWH(
      horizontalPadding,
      stagingTop,
      math.max(80.0, width - (horizontalPadding * 2)),
      math.max(44.0, stagingBottom - stagingTop),
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

    final stagingSpec = _bestGrid(
      count: math.max(1, _secondAddend),
      width: stagingRect.width,
      height: stagingRect.height,
    );
    final stagingPositions = _gridPositions(
      rect: stagingRect,
      columns: stagingSpec.columns,
      count: _secondAddend,
    );

    var radiusBase = math.min(targetSpec.cellWidth, targetSpec.cellHeight);
    if (_secondAddend > 0) {
      final stageMin = math.min(stagingSpec.cellWidth, stagingSpec.cellHeight);
      radiusBase = math.min(radiusBase, stageMin);
    }
    final radius = math.max(_minDotRadius, radiusBase * _dotRadiusFactor);
    final firstCountPosition = _countPosition(
      points: targetPositions.take(_firstAddend).toList(),
      fallbackX: gridRect.left + gridRect.width * 0.3,
      fallbackY: gridRect.top - 12,
      radius: radius,
    );
    final secondCountPosition = _countPosition(
      points: stagingPositions,
      fallbackX: stagingRect.left + stagingRect.width * 0.7,
      fallbackY: stagingRect.top - 8,
      radius: radius,
    );
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
      stagingPositions: stagingPositions,
      dotRadius: radius,
      firstCountPosition: firstCountPosition,
      secondCountPosition: secondCountPosition,
      firstEquationNumberPosition: firstEquationNumberPosition,
      secondEquationNumberPosition: secondEquationNumberPosition,
      plusPosition: plusPosition,
      equalsPosition: equalsPosition,
      resultPosition: resultPosition,
      equationPosition: Vector2(width / 2, equationY),
    );
  }

  Vector2 _countPosition({
    required List<Vector2> points,
    required double fallbackX,
    required double fallbackY,
    required double radius,
  }) {
    if (points.isEmpty) {
      return Vector2(fallbackX, fallbackY);
    }

    var minY = points.first.y;
    var sumX = 0.0;
    for (final point in points) {
      minY = math.min(minY, point.y);
      sumX += point.x;
    }
    final averageX = sumX / points.length;
    return Vector2(averageX, minY - (radius * 2.8));
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
        _secondDots[index].revealInStaging(
          duration: _revealDurationSeconds,
          targetScale: _stagingScale,
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

  Future<void> _slideCountsIntoEquation() async {
    _removeEffects(_firstCountLabel);
    _removeEffects(_secondCountLabel);
    _firstCountLabel.scale = Vector2.all(1);
    _secondCountLabel.scale = Vector2.all(1);

    final slideFutures = <Future<void>>[
      _moveLabelTo(
        _firstCountLabel,
        _layout.firstEquationNumberPosition,
        delay: 0,
      ),
      _moveLabelTo(
        _secondCountLabel,
        _layout.secondEquationNumberPosition,
        delay: _countSlideStaggerSeconds,
      ),
    ];

    await Future.wait(slideFutures);
    _firstCountLabel.textRenderer = mathHelpTextPaint(
      color: _mergedDotColor,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    _secondCountLabel.textRenderer = mathHelpTextPaint(
      color: _mergedDotColor,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    _areCountsInEquation = true;
  }

  Future<void> _moveLabelTo(
    TextComponent label,
    Vector2 targetPosition, {
    required double delay,
  }) {
    final completer = Completer<void>();
    label.add(
      MoveEffect.to(
        targetPosition,
        EffectController(
          duration: _countSlideDurationSeconds,
          startDelay: delay,
          curve: Curves.easeInOutCubic,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> _showEquationTail() {
    _removeEffects(_plusLabel);
    _removeEffects(_equalsLabel);
    _removeEffects(_resultLabel);
    _plusLabel.scale = Vector2.zero();
    _equalsLabel.scale = Vector2.zero();
    _resultLabel.scale = Vector2.zero();
    _resultLabel.text = '$_totalDots';
    _resultLabel.textRenderer = mathHelpTextPaint(
      color: _mergedDotColor,
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );

    final completer = Completer<void>();
    _plusLabel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.36, curve: Curves.easeOutBack),
      ),
    );
    _equalsLabel.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: 0.36,
          startDelay: 0.16,
          curve: Curves.easeOutBack,
        ),
      ),
    );
    _resultLabel.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: 0.51,
            startDelay: 0.28,
            curve: Curves.easeOutBack,
          ),
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

  Future<void> animateTo({
    required Vector2 targetPosition,
    required double duration,
    required double targetScale,
    double delay = 0,
  }) {
    final completer = Completer<void>();
    _addAxisAlignedMove(
      targetPosition: targetPosition,
      duration: duration,
      delay: delay,
      curve: Curves.easeInOutCubic,
      onComplete: completer.complete,
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
    return completer.future;
  }

  Future<void> revealInStaging({
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

  void _addAxisAlignedMove({
    required Vector2 targetPosition,
    required double duration,
    required double delay,
    required Curve curve,
    void Function()? onComplete,
  }) {
    final startPosition = position.clone();
    final horizontalDistance = (targetPosition.x - startPosition.x).abs();
    final verticalDistance = (targetPosition.y - startPosition.y).abs();
    final totalDistance = horizontalDistance + verticalDistance;

    if (totalDistance == 0) {
      onComplete?.call();
      return;
    }

    if (horizontalDistance == 0 || verticalDistance == 0) {
      add(
        MoveEffect.to(
          targetPosition,
          EffectController(duration: duration, startDelay: delay, curve: curve),
          onComplete: onComplete,
        ),
      );
      return;
    }

    final bendPoint = Vector2(targetPosition.x, startPosition.y);
    final horizontalDuration = duration * (horizontalDistance / totalDistance);
    final verticalDuration = duration - horizontalDuration;

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
      ], onComplete: onComplete),
    );
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
    required this.stagingPositions,
    required this.dotRadius,
    required this.firstCountPosition,
    required this.secondCountPosition,
    required this.firstEquationNumberPosition,
    required this.secondEquationNumberPosition,
    required this.plusPosition,
    required this.equalsPosition,
    required this.resultPosition,
    required this.equationPosition,
  });

  final int rows;
  final int columns;
  final Vector2 gridOrigin;
  final Vector2 gridSize;
  final List<Vector2> targetPositions;
  final List<Vector2> stagingPositions;
  final double dotRadius;
  final Vector2 firstCountPosition;
  final Vector2 secondCountPosition;
  final Vector2 firstEquationNumberPosition;
  final Vector2 secondEquationNumberPosition;
  final Vector2 plusPosition;
  final Vector2 equalsPosition;
  final Vector2 resultPosition;
  final Vector2 equationPosition;
}
