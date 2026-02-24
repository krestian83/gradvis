import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-grid visualizer for addition contexts.
///
/// For larger operands it switches to base-10 blocks to keep visuals clear.
class AdditionVisualizer extends MathVisualizer {
  static const _maxAddend = 500;
  static const _maxDotSum = 20;
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _dotRadiusFactor = 0.22;
  static const _minDotRadius = 3.6;
  static const _hiddenSecondTokenScale = 0.0;
  static const _countRevealStaggerDelaySeconds = 0.64;
  static const _countRevealPulseDurationSeconds = 0.54;
  static const _baseTenGroupPulseScale = 1.24;
  static const _baseTenGroupPulseCycleDurationSeconds = 0.45;
  static const _baseTenGroupPulseCycles = 4;
  static const _secondOperandPlacePulseScale = 1.22;
  static const _baseTenGroupPause = Duration(seconds: 2);
  static const _phasePause = Duration(milliseconds: 1050);
  static const _slowdownFactor = 1.3;
  static const _answerSlideDurationSeconds = 0.68;
  static const _answerPrePulseScale = 1.75;
  static const _answerPrePulseDurationSeconds = 0.42;
  static const _answerPulseDurationSeconds = 4.0;
  static const _answerPulseScale = 1.15;
  static const _answerPulseCycles = 6;
  static const _sortAnimationDurationSeconds = 0.55;
  static const _colorTransitionSeconds = 1.0;
  static const _baseTenDotFillFactor = 0.82;
  static const _baseTenMinSectionHeight = 14.0;

  static const _firstDotColor = Color(0xFF1B6DE2);
  static const _secondDotColor = Color(0xFFF18F01);
  static const _mergedDotColor = Color(0xFF2E7D32);
  static const _firstLabelColor = Color(0xFF1B4F9A);
  static const _secondLabelColor = Color(0xFFB36A00);
  static const _equationColor = Color(0xFF0A2463);

  final _firstTokens = <_AdditionToken>[];
  final _secondTokens = <_AdditionToken>[];
  final _secondOperandPlacePulseLabels = <TextComponent>[];

  bool _disposed = false;
  bool _isAnimating = false;
  bool _isFirstCountVisible = false;
  bool _isSecondCountVisible = false;
  bool _isPlusVisible = false;
  bool _isEqualsVisible = false;
  bool _isResultVisible = false;
  bool _isMerged = false;

  late final int _firstAddend;
  late final int _secondAddend;
  late final bool _usesBaseTenBlocks;
  late final int _firstHundreds;
  late final int _firstTens;
  late final int _firstOnes;
  late final int _secondHundreds;
  late final int _secondTens;
  late final int _secondOnes;

  _RoundedGridComponent? _grid;
  late final TextComponent _firstCountLabel;
  late final TextComponent _secondCountLabel;
  late final TextComponent _plusLabel;
  late final TextComponent _equalsLabel;
  late final TextComponent _resultLabel;
  late _SceneLayout _layout;

  AdditionVisualizer({required super.context}) {
    final (a, b) = _normalizedOperands();
    _firstAddend = a;
    _secondAddend = b;
    _usesBaseTenBlocks = _firstAddend + _secondAddend > _maxDotSum;
    _firstHundreds = _firstAddend ~/ 100;
    _firstTens = (_firstAddend % 100) ~/ 10;
    _firstOnes = _firstAddend % 10;
    _secondHundreds = _secondAddend ~/ 100;
    _secondTens = (_secondAddend % 100) ~/ 10;
    _secondOnes = _secondAddend % 10;
  }

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _sum => _firstAddend + _secondAddend;

  double _scaledSeconds(double seconds) => seconds * _slowdownFactor;

  Duration _scaledDuration(Duration duration) {
    return Duration(
      milliseconds: math.max(
        1,
        (duration.inMilliseconds * _slowdownFactor).round(),
      ),
    );
  }

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

      if (_secondAddend > 0) {
        await _revealSecondTokensAndCount();
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

      await _completeAdditionToAnswerState();
    } finally {
      _isAnimating = false;
    }
  }

  Future<bool> _pauseForNextStep() async {
    if (_disposed) {
      return false;
    }
    await Future<void>.delayed(_scaledDuration(_phasePause));
    return !_disposed;
  }

  void _buildScene() {
    _grid = _RoundedGridComponent(
      rows: _layout.rows,
      columns: _layout.columns,
      position: _layout.gridOrigin,
      size: _layout.gridSize,
      showGridLines: !_usesBaseTenBlocks,
    );
    add(_grid!);

    for (final tokenLayout in _layout.firstTokenLayouts) {
      final token = _createToken(tokenLayout, _firstDotColor);
      add(token.component);
      _firstTokens.add(token);
    }

    for (final tokenLayout in _layout.secondTokenLayouts) {
      final token = _createToken(tokenLayout, _secondDotColor);
      token
        ..scale = Vector2.all(_hiddenSecondTokenScale)
        ..setOpacity(0);
      add(token.component);
      _secondTokens.add(token);
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
      text: '$_sum',
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

  _AdditionToken _createToken(_TokenLayout tokenLayout, Color color) {
    if (tokenLayout.kind == _TokenKind.dot) {
      return _AdditionToken(
        kind: tokenLayout.kind,
        component: _AdditionDotComponent(
          center: tokenLayout.center,
          color: color,
          radius: tokenLayout.dotRadius,
        ),
      );
    }

    return _AdditionToken(
      kind: tokenLayout.kind,
      component: _AdditionBaseTenDotComponent(
        center: tokenLayout.center,
        radius: tokenLayout.dotRadius,
        color: color,
        kind: tokenLayout.kind,
        value: tokenLayout.blockValue,
      ),
    );
  }

  void _resetScene() {
    _clearSecondOperandPlacePulseLabels();

    for (var index = 0; index < _firstTokens.length; index++) {
      final token = _firstTokens[index];
      token.clearEffects();
      token.showValueLabel();
      token
        ..applyLayout(_layout.firstTokenLayouts[index])
        ..scale = Vector2.all(1)
        ..setOpacity(1)
        ..color = _firstDotColor;
    }

    for (var index = 0; index < _secondTokens.length; index++) {
      final token = _secondTokens[index];
      token.clearEffects();
      token.showValueLabel();
      token
        ..applyLayout(_layout.secondTokenLayouts[index])
        ..scale = Vector2.all(_hiddenSecondTokenScale)
        ..setOpacity(0)
        ..color = _secondDotColor;
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
      ..text = '$_sum'
      ..textRenderer = mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.resultPosition
      ..scale = Vector2.zero();

    _isFirstCountVisible = false;
    _isSecondCountVisible = false;
    _isPlusVisible = false;
    _isEqualsVisible = false;
    _isResultVisible = false;
    _isMerged = false;
  }

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  void _clearSecondOperandPlacePulseLabels() {
    for (final label in _secondOperandPlacePulseLabels) {
      _removeEffects(label);
      label.removeFromParent();
    }
    _secondOperandPlacePulseLabels.clear();
  }

  void _applyLayoutPreservingState() {
    _layout = _createLayout();
    _grid
      ?..position = _layout.gridOrigin
      ..size = _layout.gridSize
      ..setDimensions(rows: _layout.rows, columns: _layout.columns);

    for (var index = 0; index < _firstTokens.length; index++) {
      final token = _firstTokens[index];
      token
        ..applyLayout(_layout.firstTokenLayouts[index])
        ..scale = Vector2.all(1)
        ..setOpacity(1)
        ..color = _isMerged ? _mergedDotColor : _firstDotColor;
    }

    for (var index = 0; index < _secondTokens.length; index++) {
      final token = _secondTokens[index];
      final visible = _isSecondCountVisible;
      token
        ..applyLayout(_layout.secondTokenLayouts[index])
        ..scale = Vector2.all(visible ? 1 : _hiddenSecondTokenScale)
        ..setOpacity(visible ? 1 : 0)
        ..color = _isMerged ? _mergedDotColor : _secondDotColor;
    }

    _firstCountLabel
      ..position = _layout.firstCountPosition
      ..scale = _isFirstCountVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _isMerged ? _mergedDotColor : _firstLabelColor,
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
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      );
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  _SceneLayout _createLayout() {
    final width = size.x > 0 ? size.x : _fallbackWidth;
    final height = size.y > 0 ? size.y : _fallbackHeight;
    final horizontalPadding = math.max(12.0, width * 0.06);
    final bottomPadding = math.max(10.0, height * 0.06);
    final equationY = math.max(30.0, height * 0.14);

    final gridTop = height * (_usesBaseTenBlocks ? 0.31 : 0.34);
    final gridBottom = height - bottomPadding;

    final gridRect = Rect.fromLTWH(
      horizontalPadding,
      gridTop,
      math.max(80.0, width - (horizontalPadding * 2)),
      math.max(72.0, gridBottom - gridTop),
    );

    final (gridSpec, firstTokenLayouts, secondTokenLayouts) = _usesBaseTenBlocks
        ? _baseTenTokenLayouts(rect: gridRect)
        : _dotTokenLayouts(rect: gridRect);

    final equationInset = math.max(8.0, width * 0.04);
    final baseGap = math.max(8.0, math.min(16.0, width * 0.035));
    final firstWidth = _equationTextWidth(
      text: '$_firstAddend',
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    final plusWidth = _equationTextWidth(
      text: '+',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final secondWidth = _equationTextWidth(
      text: '$_secondAddend',
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    final equalsWidth = _equationTextWidth(
      text: '=',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final resultWidth = _equationTextWidth(
      text: '$_sum',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final widthsSum =
        firstWidth + plusWidth + secondWidth + equalsWidth + resultWidth;
    final availableEquationWidth = math.max(1.0, width - (equationInset * 2));
    final gapUpperBound = math.max(
      0.0,
      (availableEquationWidth - widthsSum) / 4,
    );
    final resolvedGap = math.min(baseGap, gapUpperBound);
    final totalEquationWidth = widthsSum + (resolvedGap * 4);
    var cursorX = (width - totalEquationWidth) * 0.5;
    final firstCountPosition = Vector2(cursorX + (firstWidth * 0.5), equationY);
    cursorX += firstWidth + resolvedGap;
    final plusPosition = Vector2(cursorX + (plusWidth * 0.5), equationY);
    cursorX += plusWidth + resolvedGap;
    final secondCountPosition = Vector2(
      cursorX + (secondWidth * 0.5),
      equationY,
    );
    cursorX += secondWidth + resolvedGap;
    final equalsPosition = Vector2(cursorX + (equalsWidth * 0.5), equationY);
    cursorX += equalsWidth + resolvedGap;
    final resultPosition = Vector2(cursorX + (resultWidth * 0.5), equationY);

    return _SceneLayout(
      rows: gridSpec.rows,
      columns: gridSpec.columns,
      gridOrigin: Vector2(gridRect.left, gridRect.top),
      gridSize: Vector2(gridRect.width, gridRect.height),
      firstTokenLayouts: firstTokenLayouts,
      secondTokenLayouts: secondTokenLayouts,
      firstCountPosition: firstCountPosition,
      secondCountPosition: secondCountPosition,
      plusPosition: plusPosition,
      equalsPosition: equalsPosition,
      resultPosition: resultPosition,
    );
  }

  double _equationTextWidth({
    required String text,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Fredoka One',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    painter.layout();
    return painter.width;
  }

  (_GridSpec, List<_TokenLayout>, List<_TokenLayout>) _dotTokenLayouts({
    required Rect rect,
  }) {
    final totalDots = _firstAddend + _secondAddend;
    final targetSpec = _bestGrid(
      count: math.max(1, totalDots),
      width: rect.width,
      height: rect.height,
    );
    final positions = _gridPositions(
      rect: rect,
      columns: targetSpec.columns,
      count: totalDots,
    );

    final radiusBase = math.min(targetSpec.cellWidth, targetSpec.cellHeight);
    final radius = math.max(_minDotRadius, radiusBase * _dotRadiusFactor);
    final firstLayouts = <_TokenLayout>[];
    final secondLayouts = <_TokenLayout>[];
    for (var i = 0; i < totalDots; i++) {
      final layout = _TokenLayout(
        kind: _TokenKind.dot,
        center: positions[i],
        dotRadius: radius,
      );
      if (i < _firstAddend) {
        firstLayouts.add(layout);
      } else {
        secondLayouts.add(layout);
      }
    }
    return (targetSpec, firstLayouts, secondLayouts);
  }

  (_GridSpec, List<_TokenLayout>, List<_TokenLayout>) _baseTenTokenLayouts({
    required Rect rect,
  }) {
    final horizontalInset = math.max(6.0, rect.width * 0.04);
    final verticalInset = math.max(6.0, rect.height * 0.05);
    final usableRect = Rect.fromLTWH(
      rect.left + horizontalInset,
      rect.top + verticalInset,
      math.max(40.0, rect.width - (horizontalInset * 2)),
      math.max(40.0, rect.height - (verticalInset * 2)),
    );

    final sectionGap = math.max(4.0, verticalInset * 0.4);
    final halfHeight = (usableRect.height - sectionGap) * 0.5;

    final firstHalf = Rect.fromLTWH(
      usableRect.left,
      usableRect.top,
      usableRect.width,
      halfHeight,
    );
    final secondHalf = Rect.fromLTWH(
      usableRect.left,
      usableRect.top + halfHeight + sectionGap,
      usableRect.width,
      halfHeight,
    );

    final firstLayouts = _baseTenLayoutsForHalf(
      rect: firstHalf,
      hundreds: _firstHundreds,
      tens: _firstTens,
      ones: _firstOnes,
    );
    final secondLayouts = _baseTenLayoutsForHalf(
      rect: secondHalf,
      hundreds: _secondHundreds,
      tens: _secondTens,
      ones: _secondOnes,
    );

    final totalTokens = firstLayouts.length + secondLayouts.length;
    final gridSpec = _bestGrid(
      count: math.max(1, totalTokens),
      width: rect.width,
      height: rect.height,
    );
    return (gridSpec, firstLayouts, secondLayouts);
  }

  List<_TokenLayout> _baseTenLayoutsForHalf({
    required Rect rect,
    required int hundreds,
    required int tens,
    required int ones,
  }) {
    final sectionGap = math.max(4.0, rect.height * 0.05);
    final sectionHeights = _resolveBaseTenSectionHeights(
      availableHeight: math.max(18.0, rect.height - (sectionGap * 2)),
      hundredsRows: _gridRows(count: hundreds, maxColumns: 3),
      tensRows: _gridRows(count: tens, maxColumns: 5),
      onesRows: _gridRows(count: ones, maxColumns: 10),
    );
    final hundredsRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      sectionHeights.hundreds,
    );
    final tensRect = Rect.fromLTWH(
      rect.left,
      hundredsRect.bottom + sectionGap,
      rect.width,
      sectionHeights.tens,
    );
    final onesRect = Rect.fromLTWH(
      rect.left,
      tensRect.bottom + sectionGap,
      rect.width,
      sectionHeights.ones,
    );
    final radii = _resolveBaseTenDotRadii(
      hundredsRect: hundredsRect,
      tensRect: tensRect,
      onesRect: onesRect,
      hundreds: hundreds,
      tens: tens,
      ones: ones,
    );

    return <_TokenLayout>[
      ..._hundredsLayouts(
        rect: hundredsRect,
        count: hundreds,
        radius: radii.hundreds,
      ),
      ..._tensLayouts(rect: tensRect, count: tens, radius: radii.tens),
      ..._onesLayouts(rect: onesRect, count: ones, radius: radii.ones),
    ];
  }

  List<_TokenLayout> _mergedBaseTenLayouts({
    required Rect rect,
    required List<_AdditionToken> tokens,
  }) {
    final hundreds = tokens.where((t) => t.kind == _TokenKind.hundreds).length;
    final tens = tokens.where((t) => t.kind == _TokenKind.tens).length;
    final ones = tokens
        .where(
          (t) => t.kind == _TokenKind.ones || t.kind == _TokenKind.dot,
        )
        .length;
    return _baseTenLayoutsForHalf(
      rect: Rect.fromLTWH(
        rect.left + math.max(6.0, rect.width * 0.04),
        rect.top + math.max(6.0, rect.height * 0.05),
        math.max(
          40.0,
          rect.width - (math.max(6.0, rect.width * 0.04) * 2),
        ),
        math.max(
          40.0,
          rect.height - (math.max(6.0, rect.height * 0.05) * 2),
        ),
      ),
      hundreds: hundreds,
      tens: tens,
      ones: ones,
    );
  }

  ({double hundreds, double tens, double ones}) _resolveBaseTenSectionHeights({
    required double availableHeight,
    required int hundredsRows,
    required int tensRows,
    required int onesRows,
  }) {
    final minSectionHeight = math.min(
      _baseTenMinSectionHeight,
      availableHeight / 3,
    );
    final minTotalHeight = minSectionHeight * 3;
    final extraHeight = math.max(0.0, availableHeight - minTotalHeight);
    final hundredsWeight = _sectionHeightWeight(rows: hundredsRows, scale: 4);
    final tensWeight = _sectionHeightWeight(rows: tensRows, scale: 2);
    final onesWeight = _sectionHeightWeight(rows: onesRows, scale: 1);
    final totalWeight = hundredsWeight + tensWeight + onesWeight;
    if (totalWeight <= 0) {
      final equalHeight = availableHeight / 3;
      return (
        hundreds: equalHeight,
        tens: equalHeight,
        ones: availableHeight - (equalHeight * 2),
      );
    }
    final hundredsHeight =
        minSectionHeight + (extraHeight * (hundredsWeight / totalWeight));
    final tensHeight =
        minSectionHeight + (extraHeight * (tensWeight / totalWeight));
    return (
      hundreds: hundredsHeight,
      tens: tensHeight,
      ones: math.max(
        minSectionHeight,
        availableHeight - hundredsHeight - tensHeight,
      ),
    );
  }

  double _sectionHeightWeight({required int rows, required int scale}) {
    if (rows <= 0) {
      return 1.0;
    }
    return rows * scale.toDouble();
  }

  int _gridRows({required int count, required int maxColumns}) {
    if (count <= 0) {
      return 0;
    }
    final columns = math.max(1, math.min(maxColumns, count));
    return (count / columns).ceil();
  }

  ({double hundreds, double tens, double ones}) _resolveBaseTenDotRadii({
    required Rect hundredsRect,
    required Rect tensRect,
    required Rect onesRect,
    required int hundreds,
    required int tens,
    required int ones,
  }) {
    final onesCellMin = _sectionCellMin(
      rect: onesRect,
      count: ones,
      maxColumns: 10,
    );
    final tensCellMin = _sectionCellMin(
      rect: tensRect,
      count: tens,
      maxColumns: 5,
    );
    final hundredsCellMin = _sectionCellMin(
      rect: hundredsRect,
      count: hundreds,
      maxColumns: 3,
    );

    final oneRadiusCandidates = <double>[
      if (onesCellMin.isFinite) onesCellMin * _baseTenDotFillFactor * 0.5,
      if (tensCellMin.isFinite) tensCellMin * _baseTenDotFillFactor * 0.25,
      if (hundredsCellMin.isFinite)
        hundredsCellMin * _baseTenDotFillFactor * 0.125,
    ];

    final onesRadius = oneRadiusCandidates.isEmpty
        ? 4.0
        : oneRadiusCandidates.reduce(math.min);
    return (hundreds: onesRadius * 4, tens: onesRadius * 2, ones: onesRadius);
  }

  double _sectionCellMin({
    required Rect rect,
    required int count,
    required int maxColumns,
  }) {
    if (count <= 0) {
      return double.infinity;
    }
    final columns = math.max(1, math.min(maxColumns, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;
    return math.min(cellWidth, cellHeight);
  }

  List<_TokenLayout> _hundredsLayouts({
    required Rect rect,
    required int count,
    required double radius,
  }) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(3, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;

    return List<_TokenLayout>.generate(count, (index) {
      final row = index ~/ columns;
      final column = index % columns;
      final center = Vector2(
        rect.left + (column * cellWidth) + (cellWidth * 0.5),
        rect.top + (row * cellHeight) + (cellHeight * 0.5),
      );
      return _TokenLayout(
        kind: _TokenKind.hundreds,
        center: center,
        dotRadius: radius,
        blockValue: 100,
      );
    });
  }

  List<_TokenLayout> _tensLayouts({
    required Rect rect,
    required int count,
    required double radius,
  }) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(5, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;

    return List<_TokenLayout>.generate(count, (index) {
      final row = index ~/ columns;
      final column = index % columns;
      final center = Vector2(
        rect.left + (column * cellWidth) + (cellWidth * 0.5),
        rect.top + (row * cellHeight) + (cellHeight * 0.5),
      );
      return _TokenLayout(
        kind: _TokenKind.tens,
        center: center,
        dotRadius: radius,
        blockValue: 10,
      );
    });
  }

  List<_TokenLayout> _onesLayouts({
    required Rect rect,
    required int count,
    required double radius,
  }) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(10, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;

    return List<_TokenLayout>.generate(count, (index) {
      final row = index ~/ columns;
      final column = index % columns;
      final center = Vector2(
        rect.left + (column * cellWidth) + (cellWidth * 0.5),
        rect.top + (row * cellHeight) + (cellHeight * 0.5),
      );
      return _TokenLayout(
        kind: _TokenKind.ones,
        center: center,
        dotRadius: radius,
        blockValue: 1,
      );
    });
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

  (int, int) _normalizedOperands() {
    int raw(int index) {
      if (index >= context.operands.length) return 0;
      final rounded = context.operands[index].round();
      return rounded < 0 ? 0 : rounded;
    }

    var a = raw(0);
    var b = raw(1);
    final sum = a + b;
    if (sum > _maxAddend) {
      final scale = _maxAddend / sum;
      a = (a * scale).round();
      b = _maxAddend - a;
    }
    return (a, b);
  }

  // ---------------------------------------------------------------------------
  // Animation helpers
  // ---------------------------------------------------------------------------

  Future<void> _showCountLabel(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final completer = Completer<void>();
    label.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _scaledSeconds(0.51),
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(
            duration: _scaledSeconds(0.21),
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 1,
          ),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  Future<void> _revealSecondTokensAndCount() async {
    _isSecondCountVisible = true;
    _secondCountLabel.text = '';
    await _showCountLabel(_secondCountLabel);

    if (_usesBaseTenBlocks) {
      await _revealSecondTokensByGroup();
    } else {
      await _revealSecondTokensSequentially();
    }
  }

  Future<void> _revealSecondTokensSequentially() async {
    var runningTotal = 0;
    final appearDuration = _scaledSeconds(0.25);
    final tokenStep = Duration(
      milliseconds: math.max(
        1,
        (_scaledSeconds(_countRevealStaggerDelaySeconds) * 1000).round(),
      ),
    );
    for (final token in _secondTokens) {
      if (_disposed) return;

      runningTotal += token.value;
      _secondCountLabel.text = '$runningTotal';

      final completer = Completer<void>();
      token.setOpacity(1);
      token.component.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: appearDuration,
            curve: Curves.easeOutBack,
          ),
          onComplete: completer.complete,
        ),
      );
      await completer.future;
      await Future<void>.delayed(tokenStep);
    }
  }

  Future<void> _revealSecondTokensByGroup() async {
    const kindOrder = <_TokenKind>[
      _TokenKind.ones,
      _TokenKind.tens,
      _TokenKind.hundreds,
    ];

    var runningTotal = 0;
    for (final kind in kindOrder) {
      final group = _secondTokens
          .where((token) => token.kind == kind)
          .toList(growable: false);
      if (group.isEmpty) {
        continue;
      }
      if (_disposed) {
        return;
      }

      for (final token in group) {
        token
          ..scale = Vector2.all(1)
          ..setOpacity(1);
      }

      final groupTotal = group.fold<int>(0, (sum, t) => sum + t.value);
      runningTotal += groupTotal;
      _secondCountLabel.text = '$runningTotal';

      // Show equals + running sum so the player sees the total grow.
      final runningSum = _firstAddend + runningTotal;
      _resultLabel.text = '$runningSum';
      if (!_isEqualsVisible) {
        await _showEqualsLabel();
        if (_disposed) return;
        await _showEquationSymbol(_resultLabel);
        _isResultVisible = true;
        if (_disposed) return;
      }

      final pulseDuration = _scaledSeconds(
        _baseTenGroupPulseCycleDurationSeconds,
      );
      for (
        var pulseIndex = 0;
        pulseIndex < _baseTenGroupPulseCycles;
        pulseIndex++
      ) {
        await Future.wait(<Future<void>>[
          ...group.map(
            (token) => token.pulse(
              duration: pulseDuration,
              targetScale: _baseTenGroupPulseScale,
            ),
          ),
          _pulseSecondOperandPlacesForKind(kind: kind, duration: pulseDuration),
        ]);
        if (_disposed) {
          return;
        }
      }

      if (kind != kindOrder.last) {
        await Future<void>.delayed(_baseTenGroupPause);
      }
    }
  }

  Future<void> _pulseSecondOperandPlacesForKind({
    required _TokenKind kind,
    required double duration,
  }) async {
    if (!_usesBaseTenBlocks || !_isSecondCountVisible) {
      return;
    }
    final highestPlaceFromRight = switch (kind) {
      _TokenKind.ones => 0,
      _TokenKind.tens => 1,
      _TokenKind.hundreds => 2,
      _TokenKind.dot => -1,
    };
    if (highestPlaceFromRight < 0) {
      return;
    }

    final text = _secondCountLabel.text;
    if (text.isEmpty) {
      return;
    }

    final digitCount = text.length;
    final placeValuesFromRight = List<int>.generate(
      highestPlaceFromRight + 1,
      (index) => index,
    );
    final pulseDigitIndexes = <int>{};
    for (final placeFromRight in placeValuesFromRight) {
      if (placeFromRight >= digitCount) {
        continue;
      }
      pulseDigitIndexes.add(digitCount - 1 - placeFromRight);
    }
    if (pulseDigitIndexes.isEmpty) {
      return;
    }

    _clearSecondOperandPlacePulseLabels();
    final overlayLabels = List<TextComponent>.generate(digitCount, (
      digitIndex,
    ) {
      return TextComponent(
        text: text[digitIndex],
        anchor: Anchor.center,
        position: _secondOperandDigitPosition(
          digitIndex: digitIndex,
          digitCount: digitCount,
        ),
        scale: _secondCountLabel.scale.clone(),
        textRenderer: mathHelpTextPaint(
          color: _secondLabelColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      );
    });
    final pulseLabels = <TextComponent>[];
    for (var index = 0; index < overlayLabels.length; index++) {
      final overlayLabel = overlayLabels[index];
      _secondOperandPlacePulseLabels.add(overlayLabel);
      add(overlayLabel);
      if (pulseDigitIndexes.contains(index)) {
        pulseLabels.add(overlayLabel);
      }
    }

    final baseScale = _secondCountLabel.scale.clone();
    _removeEffects(_secondCountLabel);
    _secondCountLabel.scale = Vector2.zero();

    void removeOverlayLabels() {
      for (final label in overlayLabels) {
        label.removeFromParent();
      }
      _secondOperandPlacePulseLabels.clear();
    }

    final halfDuration = math.max(0.001, duration * 0.5);
    await Future.wait(
      pulseLabels.map(
        (pulseLabel) => _scaleLabelTo(
          label: pulseLabel,
          targetScale: _secondOperandPlacePulseScale,
          duration: halfDuration,
          curve: Curves.easeOutBack,
        ),
      ),
    );
    if (_disposed) {
      removeOverlayLabels();
      return;
    }

    await Future.wait(
      pulseLabels.map(
        (pulseLabel) => _scaleLabelTo(
          label: pulseLabel,
          targetScale: 1,
          duration: halfDuration,
          curve: Curves.easeInOut,
        ),
      ),
    );
    removeOverlayLabels();
    if (_isSecondCountVisible) {
      _secondCountLabel.scale = baseScale;
    }
  }

  Vector2 _secondOperandDigitPosition({
    required int digitIndex,
    required int digitCount,
  }) {
    if (digitCount <= 0) {
      return _secondCountLabel.position.clone();
    }
    final measuredWidth = _secondCountLabel.size.x;
    final labelWidth = measuredWidth > 1 ? measuredWidth : digitCount * 18;
    final digitWidth = labelWidth / digitCount;
    final leftEdge = _secondCountLabel.position.x - (labelWidth * 0.5);
    return Vector2(
      leftEdge + (digitWidth * digitIndex) + (digitWidth * 0.5),
      _secondCountLabel.position.y,
    );
  }

  Future<void> _completeAdditionToAnswerState() async {
    _isMerged = true;

    // Smoothly transition all dots to green.
    final colorDuration = _scaledSeconds(_colorTransitionSeconds);
    for (final token in _firstTokens) {
      token.animateColorTo(_mergedDotColor, duration: colorDuration);
    }
    for (final token in _secondTokens) {
      token.animateColorTo(_mergedDotColor, duration: colorDuration);
    }

    // In base-10 mode, sort all tokens by value into a merged layout.
    if (_usesBaseTenBlocks) {
      await _animateTokensToMergedLayout();
      if (_disposed) return;
    }

    // Show or update the result label in green.
    _resultLabel
      ..text = '$_sum'
      ..textRenderer = mathHelpTextPaint(
        color: _mergedDotColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      );
    if (!_isResultVisible) {
      await _showEquationSymbol(_resultLabel);
      _isResultVisible = true;
      if (_disposed) return;
    }

    // Pause so the full equation is visible.
    await Future<void>.delayed(_scaledDuration(_phasePause));
    if (_disposed) return;

    // Hide first operand, plus, second operand, and equals.
    _removeEffects(_firstCountLabel);
    _firstCountLabel.scale = Vector2.zero();
    _isFirstCountVisible = false;

    if (_isPlusVisible) {
      _removeEffects(_plusLabel);
      _plusLabel.scale = Vector2.zero();
      _isPlusVisible = false;
    }
    if (_isSecondCountVisible) {
      _removeEffects(_secondCountLabel);
      _secondCountLabel.scale = Vector2.zero();
      _isSecondCountVisible = false;
    }
    _removeEffects(_equalsLabel);
    _equalsLabel.scale = Vector2.zero();
    _isEqualsVisible = false;

    await _slideAndPulseAnswer();
  }

  Future<void> _animateTokensToMergedLayout() async {
    final gridRect = Rect.fromLTWH(
      _layout.gridOrigin.x,
      _layout.gridOrigin.y,
      _layout.gridSize.x,
      _layout.gridSize.y,
    );
    // Build a single list sorted by descending value
    // (hundreds → tens → ones).
    final allTokens = <_AdditionToken>[
      ..._firstTokens,
      ..._secondTokens,
    ];
    allTokens.sort((a, b) => b.value.compareTo(a.value));

    final mergedLayouts = _mergedBaseTenLayouts(
      rect: gridRect,
      tokens: allTokens,
    );

    final moveDuration = _scaledSeconds(_sortAnimationDurationSeconds);
    final futures = <Future<void>>[];
    for (var i = 0; i < allTokens.length && i < mergedLayouts.length; i++) {
      final token = allTokens[i];
      final layout = mergedLayouts[i];
      token.clearEffects();

      // Smoothly resize to uniform radius for this kind.
      token.animateRadiusTo(layout.dotRadius, duration: moveDuration);

      final completer = Completer<void>();
      token.component.add(
        MoveEffect.to(
          layout.center,
          EffectController(
            duration: moveDuration,
            curve: Curves.easeInOutCubic,
          ),
          onComplete: completer.complete,
        ),
      );
      futures.add(completer.future);
    }
    await Future.wait(futures);
  }

  Future<void> _slideAndPulseAnswer() async {
    if (_disposed) return;
    _removeEffects(_resultLabel);

    // Slide result label to center of equation row.
    final centerX = size.x * 0.5;
    final targetPosition = Vector2(centerX, _layout.resultPosition.y);

    final moveCompleter = Completer<void>();
    _resultLabel.add(
      MoveEffect.to(
        targetPosition,
        EffectController(
          duration: _scaledSeconds(_answerSlideDurationSeconds),
          curve: Curves.easeInOutCubic,
        ),
        onComplete: moveCompleter.complete,
      ),
    );
    await moveCompleter.future;
    if (_disposed) return;

    await _scaleLabelTo(
      label: _resultLabel,
      targetScale: _answerPrePulseScale,
      duration: _scaledSeconds(_answerPrePulseDurationSeconds),
      curve: Curves.easeOutBack,
    );
    if (_disposed) return;

    final pulseHalfCycleSeconds = _scaledSeconds(
      _answerPulseDurationSeconds / (_answerPulseCycles * 2),
    );
    final pulseTargetScale = _answerPrePulseScale * _answerPulseScale;
    for (var cycle = 0; cycle < _answerPulseCycles; cycle++) {
      await _scaleLabelTo(
        label: _resultLabel,
        targetScale: pulseTargetScale,
        duration: pulseHalfCycleSeconds,
      );
      if (_disposed) return;
      await _scaleLabelTo(
        label: _resultLabel,
        targetScale: _answerPrePulseScale,
        duration: pulseHalfCycleSeconds,
      );
      if (_disposed) return;
    }
    _resultLabel.scale = Vector2.all(1);
  }

  Future<void> _scaleLabelTo({
    required TextComponent label,
    required double targetScale,
    required double duration,
    Curve curve = Curves.easeInOut,
  }) {
    final completer = Completer<void>();
    label.add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(duration: duration, curve: curve),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
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

  Future<void> _showEquationSymbol(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final completer = Completer<void>();
    label.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: _scaledSeconds(0.36),
          curve: Curves.easeOutBack,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }
}

// =============================================================================
// Supporting classes
// =============================================================================

class _RoundedGridComponent extends RectangleComponent {
  _RoundedGridComponent({
    required int rows,
    required int columns,
    required super.position,
    required super.size,
    this.showGridLines = true,
  }) : _rows = rows,
       _columns = columns;

  int _rows;
  int _columns;
  bool showGridLines;

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

    if (!showGridLines || _rows <= 0 || _columns <= 0) {
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

enum _TokenKind { dot, ones, tens, hundreds }

class _AdditionToken {
  _AdditionToken({required this.kind, required this.component});

  final _TokenKind kind;
  final PositionComponent component;

  int get value {
    return switch (kind) {
      _TokenKind.dot || _TokenKind.ones => 1,
      _TokenKind.tens => 10,
      _TokenKind.hundreds => 100,
    };
  }

  Color get color => _paint.color;
  set color(Color value) => _paint.color = value;

  void animateColorTo(Color target, {required double duration}) {
    switch (component) {
      case final _AdditionDotComponent dot:
        dot.animateColorTo(target, duration: duration);
      case final _AdditionBaseTenDotComponent dot:
        dot.animateColorTo(target, duration: duration);
      default:
        _paint.color = target;
    }
  }

  void animateRadiusTo(double target, {required double duration}) {
    switch (component) {
      case final _AdditionBaseTenDotComponent dot:
        dot.animateRadiusTo(target, duration: duration);
      default:
        break;
    }
  }

  Vector2 get scale => component.scale;
  set scale(Vector2 value) => component.scale = value;

  Paint get _paint {
    return switch (component) {
      _AdditionDotComponent dot => dot.paint,
      _AdditionBaseTenDotComponent dot => dot.paint,
      _ => throw StateError(
        'Unsupported addition token type: ${component.runtimeType}',
      ),
    };
  }

  void setOpacity(double value) {
    switch (component) {
      case final _AdditionDotComponent dot:
        dot.opacity = value;
      case final _AdditionBaseTenDotComponent dot:
        dot.opacity = value;
      default:
        throw StateError(
          'Unsupported addition token type: ${component.runtimeType}',
        );
    }
  }

  void hideValueLabel() {
    switch (component) {
      case final _AdditionBaseTenDotComponent dot:
        dot.hideValueLabel();
      case final _AdditionDotComponent _:
      default:
        return;
    }
  }

  void showValueLabel() {
    switch (component) {
      case final _AdditionBaseTenDotComponent dot:
        dot.showValueLabel();
      case final _AdditionDotComponent _:
      default:
        return;
    }
  }

  void applyLayout(_TokenLayout layout) {
    switch (component) {
      case final _AdditionDotComponent dot:
        dot.applyLayout(layout);
      case final _AdditionBaseTenDotComponent dot:
        dot.applyLayout(layout);
      default:
        throw StateError(
          'Unsupported addition token type: ${component.runtimeType}',
        );
    }
  }

  void clearEffects() {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  Future<void> pulse({
    required double duration,
    double delay = 0,
    double targetScale = 1.18,
  }) {
    final completer = Completer<void>();
    component.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(targetScale),
          EffectController(
            duration: duration * 0.5,
            startDelay: delay,
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: duration * 0.5, curve: Curves.easeInOut),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
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

  Color? _colorStart;
  Color? _colorTarget;
  double _colorT = 1;
  double _colorDuration = 0;

  void animateColorTo(Color target, {required double duration}) {
    _colorStart = paint.color;
    _colorTarget = target;
    _colorT = 0;
    _colorDuration = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_colorT < 1 && _colorTarget != null) {
      _colorT = (_colorT + dt / _colorDuration).clamp(0.0, 1.0);
      paint.color = Color.lerp(_colorStart!, _colorTarget!, _colorT)!;
    }
  }

  void applyLayout(_TokenLayout layout) {
    radius = layout.dotRadius;
    position = layout.center;
  }
}

class _AdditionBaseTenDotComponent extends CircleComponent {
  _AdditionBaseTenDotComponent({
    required Vector2 center,
    required double radius,
    required Color color,
    required _TokenKind kind,
    required int value,
  }) : _kind = kind,
       _value = value,
       super(
         radius: radius,
         anchor: Anchor.center,
         position: center,
         paint: Paint()..color = color,
       ) {
    _valueLabel = TextComponent(
      text: '$_value',
      anchor: Anchor.center,
      position: _labelPosition,
      textRenderer: _valueTextPaint(fontSize: _labelFontSize),
    );
    add(_valueLabel);
  }

  static const _valueLabelColor = Color(0xFF0A2463);

  _TokenKind _kind;
  int _value;
  bool _isValueLabelVisible = true;
  late final TextComponent _valueLabel;

  Color? _colorStart;
  Color? _colorTarget;
  double _colorT = 1;
  double _colorDuration = 0;

  double? _radiusStart;
  double? _radiusTarget;
  double _radiusT = 1;
  double _radiusDuration = 0;

  void animateColorTo(Color target, {required double duration}) {
    _colorStart = paint.color;
    _colorTarget = target;
    _colorT = 0;
    _colorDuration = duration;
  }

  void animateRadiusTo(double target, {required double duration}) {
    _radiusStart = radius;
    _radiusTarget = target;
    _radiusT = 0;
    _radiusDuration = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_colorT < 1 && _colorTarget != null) {
      _colorT = (_colorT + dt / _colorDuration).clamp(0.0, 1.0);
      paint.color = Color.lerp(_colorStart!, _colorTarget!, _colorT)!;
    }
    if (_radiusT < 1 && _radiusTarget != null) {
      _radiusT = (_radiusT + dt / _radiusDuration).clamp(0.0, 1.0);
      final t = Curves.easeInOutCubic.transform(_radiusT);
      radius = _radiusStart! + (_radiusTarget! - _radiusStart!) * t;
      _syncValueLabel();
    }
  }

  Vector2 get _labelPosition => Vector2.all(radius);

  double get _labelFontSize {
    final diameter = radius * 2;
    final scale = switch (_kind) {
      _TokenKind.ones => 0.7,
      _TokenKind.tens => 0.56,
      _TokenKind.hundreds => 0.42,
      _TokenKind.dot => 0.68,
    };
    return math.max(6.5, math.min(15.0, diameter * scale));
  }

  TextPaint _valueTextPaint({required double fontSize}) {
    return mathHelpTextPaint(
      color: _valueLabelColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      enforceMinimumSize: false,
    );
  }

  void _syncValueLabel() {
    _valueLabel
      ..text = _isValueLabelVisible ? '$_value' : ''
      ..position = _labelPosition
      ..textRenderer = _valueTextPaint(fontSize: _labelFontSize);
  }

  void hideValueLabel() {
    _isValueLabelVisible = false;
    _syncValueLabel();
  }

  void showValueLabel() {
    _isValueLabelVisible = true;
    _syncValueLabel();
  }

  void applyLayout(_TokenLayout layout) {
    position = layout.center;
    radius = layout.dotRadius;
    _kind = layout.kind;
    _value = layout.blockValue;
    _syncValueLabel();
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

class _TokenLayout {
  _TokenLayout({
    required this.kind,
    required this.center,
    this.dotRadius = 0,
    this.blockValue = 0,
  });

  final _TokenKind kind;
  final Vector2 center;
  final double dotRadius;
  final int blockValue;
}

class _SceneLayout {
  const _SceneLayout({
    required this.rows,
    required this.columns,
    required this.gridOrigin,
    required this.gridSize,
    required this.firstTokenLayouts,
    required this.secondTokenLayouts,
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
  final List<_TokenLayout> firstTokenLayouts;
  final List<_TokenLayout> secondTokenLayouts;
  final Vector2 firstCountPosition;
  final Vector2 secondCountPosition;
  final Vector2 plusPosition;
  final Vector2 equalsPosition;
  final Vector2 resultPosition;
}
