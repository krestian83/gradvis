import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Dot-grid visualizer for subtraction contexts.
///
/// For larger operands it switches to base-10 blocks to keep visuals clear.
class SubtractionVisualizer extends MathVisualizer {
  static const _maxOperand = 500;
  static const _maxDotOperand = 9;
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _dotRadiusFactor = 0.22;
  static const _minDotRadius = 3.6;
  static const _removedDotScale = 0.5;
  static const _highlightPulseDurationSeconds = 0.54;
  static const _highlightStaggerDelaySeconds = 0.64;
  static const _removeDurationSeconds = 0.66;
  static const _removeStaggerDelaySeconds = 0.09;
  static const _baseTenGroupPulseScale = 1.24;
  static const _baseTenGroupPulseCycleDurationSeconds = 0.45;
  static const _baseTenGroupPulseCycles = 4;
  static const _secondOperandPlacePulseScale = 1.22;
  static const _baseTenGroupSlideDurationSeconds = 0.72;
  static const _baseTenSlidePadding = 120.0;
  static const _baseTenGroupPause = Duration(seconds: 2);
  static const _beforeResultColorPause = Duration(seconds: 1);
  static const _phasePause = Duration(milliseconds: 1050);
  static const _slowdownFactor = 1.3;
  static const _answerSlideDurationSeconds = 0.68;
  static const _answerPrePulseScale = 1.75;
  static const _answerPrePulseDurationSeconds = 0.42;
  static const _answerPulseDurationSeconds = 4.0;
  static const _answerPulseScale = 1.15;
  static const _answerPulseCycles = 6;
  static const _baseTenDotFillFactor = 0.82;
  static const _baseTenMinSectionHeight = 14.0;

  static const _baseDotColor = Color(0xFF1B6DE2);
  static const _removalDotColor = Color(0xFFE53935);
  static const _remainingDotColor = Color(0xFF2E7D32);
  static const _firstLabelColor = Color(0xFF1B4F9A);
  static const _secondLabelColor = Color(0xFFB71C1C);
  static const _equationColor = Color(0xFF0A2463);

  final _tokens = <_SubtractionToken>[];
  final _secondOperandPlacePulseLabels = <TextComponent>[];

  bool _disposed = false;
  bool _isAnimating = false;
  bool _areCountsInEquation = false;
  bool _areRemovalTokensHighlighted = false;
  bool _areRemovalTokensRemoved = false;
  bool _isResultColored = false;
  bool _isMinusVisible = false;
  bool _isEqualsVisible = false;
  bool _isResultVisible = false;
  bool _isSecondOperandVisible = false;

  late final int _minuend;
  late final int _rawSubtrahend;
  late final int _subtrahend;
  late final bool _usesBaseTenBlocks;
  late final int _displayHundreds;
  late final int _displayTens;
  late final int _displayOnes;
  late final int _subtrahendHundreds;
  late final int _subtrahendTens;
  late final int _subtrahendOnes;

  _RoundedGridComponent? _grid;
  late final TextComponent _firstCountLabel;
  late final TextComponent _secondCountLabel;
  late final TextComponent _minusLabel;
  late final TextComponent _equalsLabel;
  late final TextComponent _resultLabel;
  late _SceneLayout _layout;

  SubtractionVisualizer({required super.context}) {
    _minuend = _normalizedOperand(0);
    _rawSubtrahend = _normalizedOperand(1);
    _subtrahend = math.min(_minuend, _rawSubtrahend);
    _usesBaseTenBlocks = _minuend > _maxDotOperand;
    _subtrahendHundreds = _subtrahend ~/ 100;
    _subtrahendTens = (_subtrahend % 100) ~/ 10;
    _subtrahendOnes = _subtrahend % 10;
    final decomposedMinuend = _decomposedMinuend();
    _displayHundreds = decomposedMinuend.$1;
    _displayTens = decomposedMinuend.$2;
    _displayOnes = decomposedMinuend.$3;
  }

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  int get _difference => _minuend - _subtrahend;

  double _scaledSeconds(double seconds) => seconds * _slowdownFactor;

  Duration _scaledDuration(Duration duration) {
    return Duration(
      milliseconds: math.max(
        1,
        (duration.inMilliseconds * _slowdownFactor).round(),
      ),
    );
  }

  (int, int, int) _decomposedMinuend() {
    if (!_usesBaseTenBlocks) {
      return (0, 0, _minuend);
    }

    var hundreds = _minuend ~/ 100;
    var tens = (_minuend % 100) ~/ 10;
    var ones = _minuend % 10;

    if (ones < _subtrahendOnes) {
      if (tens == 0 && hundreds > 0) {
        hundreds -= 1;
        tens += 10;
      }
      if (tens > 0) {
        tens -= 1;
        ones += 10;
      }
    }

    if (tens < _subtrahendTens && hundreds > 0) {
      hundreds -= 1;
      tens += 10;
    }

    return (hundreds, tens, ones);
  }

  List<_SubtractionToken> get _removalTokens {
    if (_subtrahend == 0 || _tokens.isEmpty) {
      return const <_SubtractionToken>[];
    }
    if (!_usesBaseTenBlocks) {
      final start = math.max(0, _tokens.length - _subtrahend);
      return _tokensSmallestFirst(_tokens.sublist(start));
    }

    final removals = <_SubtractionToken>[];
    final ones = _tokens
        .where((token) => token.kind == _TokenKind.ones)
        .toList(growable: false);
    final tens = _tokens
        .where((token) => token.kind == _TokenKind.tens)
        .toList(growable: false);
    final hundreds = _tokens
        .where((token) => token.kind == _TokenKind.hundreds)
        .toList(growable: false);

    final onesStart = math.max(0, ones.length - _subtrahendOnes);
    final tensStart = math.max(0, tens.length - _subtrahendTens);
    final hundredsStart = math.max(0, hundreds.length - _subtrahendHundreds);

    removals
      ..addAll(hundreds.sublist(hundredsStart))
      ..addAll(tens.sublist(tensStart))
      ..addAll(ones.sublist(onesStart));
    return _tokensSmallestFirst(removals);
  }

  List<_SubtractionToken> get _remainingTokens {
    if (_difference <= 0 || _tokens.isEmpty) {
      return const <_SubtractionToken>[];
    }
    final removalSet = _removalTokens.toSet();
    return _tokensSmallestFirst(
      _tokens.where((token) => !removalSet.contains(token)),
    );
  }

  List<_SubtractionToken> _tokensSmallestFirst(
    Iterable<_SubtractionToken> tokens,
  ) {
    final sorted = tokens.toList();
    sorted.sort((left, right) => left.value.compareTo(right.value));
    return sorted;
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
      if (!await _pauseForNextStep()) {
        return;
      }

      await _showMinusLabel();
      if (!await _pauseForNextStep()) {
        return;
      }

      if (_subtrahend > 0) {
        await _highlightRemovalTokensAndCountSecondOperand();
        if (!await _pauseForNextStep()) {
          return;
        }
        await _removeRemovalTokens();
        if (!await _pauseBeforeResultColor()) {
          return;
        }
      } else {
        await _showCountLabel(_secondCountLabel);
      }

      await _completeSubtractionToAnswerState();
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

  Future<bool> _pauseBeforeResultColor() async {
    if (_disposed) {
      return false;
    }
    await Future<void>.delayed(_beforeResultColorPause);
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

    for (final tokenLayout in _layout.tokenLayouts) {
      final token = _createToken(tokenLayout);
      add(token.component);
      _tokens.add(token);
    }

    _firstCountLabel = TextComponent(
      text: '$_minuend',
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
      text: '$_subtrahend',
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

    _minusLabel = TextComponent(
      text: '-',
      anchor: Anchor.center,
      position: _layout.minusPosition,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_minusLabel);

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
      text: '$_difference',
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

  _SubtractionToken _createToken(_TokenLayout tokenLayout) {
    if (tokenLayout.kind == _TokenKind.dot) {
      return _SubtractionToken(
        kind: tokenLayout.kind,
        component: _SubtractionDotComponent(
          center: tokenLayout.center,
          color: _baseDotColor,
          radius: tokenLayout.dotRadius,
        ),
      );
    }

    return _SubtractionToken(
      kind: tokenLayout.kind,
      component: _SubtractionBaseTenDotComponent(
        center: tokenLayout.center,
        radius: tokenLayout.dotRadius,
        color: _baseDotColor,
        kind: tokenLayout.kind,
        value: tokenLayout.blockValue,
      ),
    );
  }

  void _resetScene() {
    _clearSecondOperandPlacePulseLabels();

    for (var index = 0; index < _tokens.length; index++) {
      final token = _tokens[index];
      token.clearEffects();
      token.showValueLabel();
      token
        ..applyLayout(_layout.tokenLayouts[index])
        ..scale = Vector2.all(1)
        ..setOpacity(1)
        ..color = _baseDotColor;
    }

    _removeEffects(_firstCountLabel);
    _firstCountLabel
      ..text = '$_minuend'
      ..textRenderer = mathHelpTextPaint(
        color: _firstLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.firstCountPosition
      ..scale = Vector2.zero();

    _removeEffects(_secondCountLabel);
    _secondCountLabel
      ..text = '$_subtrahend'
      ..textRenderer = mathHelpTextPaint(
        color: _secondLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.secondCountPosition
      ..scale = Vector2.zero();

    _removeEffects(_minusLabel);
    _minusLabel
      ..text = '-'
      ..position = _layout.minusPosition
      ..scale = Vector2.zero();

    _removeEffects(_equalsLabel);
    _equalsLabel
      ..text = '='
      ..position = _layout.equalsPosition
      ..scale = Vector2.zero();

    _removeEffects(_resultLabel);
    _resultLabel
      ..text = '$_difference'
      ..textRenderer = mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..position = _layout.resultPosition
      ..scale = Vector2.zero();

    _areCountsInEquation = false;
    _areRemovalTokensHighlighted = false;
    _areRemovalTokensRemoved = false;
    _isResultColored = false;
    _isMinusVisible = false;
    _isEqualsVisible = false;
    _isResultVisible = false;
    _isSecondOperandVisible = false;
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

    final removalSet = _removalTokens.toSet();
    for (var index = 0; index < _tokens.length; index++) {
      final token = _tokens[index];
      final isRemovalToken = removalSet.contains(token);
      var color = _baseDotColor;
      if (_isResultColored && !isRemovalToken) {
        color = _remainingDotColor;
      }
      if (_areRemovalTokensHighlighted &&
          isRemovalToken &&
          !_areRemovalTokensRemoved) {
        color = _removalDotColor;
      }
      final isHidden = _areRemovalTokensRemoved && isRemovalToken;
      token
        ..applyLayout(_layout.tokenLayouts[index])
        ..scale = Vector2.all(isHidden ? _removedDotScale : 1)
        ..setOpacity(isHidden ? 0 : 1)
        ..color = color;
    }

    _firstCountLabel
      ..position = _areCountsInEquation
          ? _layout.firstEquationNumberPosition
          : _layout.firstCountPosition
      ..scale = _areCountsInEquation ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _isResultColored ? _remainingDotColor : _firstLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

    _secondCountLabel
      ..position = _areCountsInEquation
          ? _layout.secondEquationNumberPosition
          : _layout.secondCountPosition
      ..scale = _isSecondOperandVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _secondLabelColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

    _minusLabel
      ..position = _layout.minusPosition
      ..scale = _isMinusVisible ? Vector2.all(1) : Vector2.zero();
    _equalsLabel
      ..position = _layout.equalsPosition
      ..scale = _isEqualsVisible ? Vector2.all(1) : Vector2.zero();
    _resultLabel
      ..position = _layout.resultPosition
      ..scale = _isResultVisible ? Vector2.all(1) : Vector2.zero()
      ..textRenderer = mathHelpTextPaint(
        color: _isResultVisible ? _remainingDotColor : _equationColor,
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

    final gridTop = height * (_usesBaseTenBlocks ? 0.31 : 0.34);
    final gridBottom = height - bottomPadding;

    final gridRect = Rect.fromLTWH(
      horizontalPadding,
      gridTop,
      math.max(80.0, width - (horizontalPadding * 2)),
      math.max(72.0, gridBottom - gridTop),
    );

    final (gridSpec, tokenLayouts) = _usesBaseTenBlocks
        ? _baseTenTokenLayouts(rect: gridRect)
        : _dotTokenLayouts(rect: gridRect);

    final equationInset = math.max(8.0, width * 0.04);
    final baseGap = math.max(8.0, math.min(16.0, width * 0.035));
    final firstWidth = _equationTextWidth(
      text: '$_minuend',
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    final minusWidth = _equationTextWidth(
      text: '-',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final secondWidth = _equationTextWidth(
      text: '$_subtrahend',
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
    final equalsWidth = _equationTextWidth(
      text: '=',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final resultWidth = _equationTextWidth(
      text: '$_difference',
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    final widthsSum =
        firstWidth + minusWidth + secondWidth + equalsWidth + resultWidth;
    final availableEquationWidth = math.max(1.0, width - (equationInset * 2));
    final gapUpperBound = math.max(
      0.0,
      (availableEquationWidth - widthsSum) / 4,
    );
    final resolvedGap = math.min(baseGap, gapUpperBound);
    final totalEquationWidth = widthsSum + (resolvedGap * 4);
    var cursorX = (width - totalEquationWidth) * 0.5;
    final firstEquationNumberPosition = Vector2(
      cursorX + (firstWidth * 0.5),
      equationY,
    );
    cursorX += firstWidth + resolvedGap;
    final minusPosition = Vector2(cursorX + (minusWidth * 0.5), equationY);
    cursorX += minusWidth + resolvedGap;
    final secondEquationNumberPosition = Vector2(
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
      tokenLayouts: tokenLayouts,
      firstCountPosition: firstEquationNumberPosition,
      secondCountPosition: secondEquationNumberPosition,
      firstEquationNumberPosition: firstEquationNumberPosition,
      secondEquationNumberPosition: secondEquationNumberPosition,
      minusPosition: minusPosition,
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

  (_GridSpec, List<_TokenLayout>) _dotTokenLayouts({required Rect rect}) {
    final targetSpec = _bestGrid(
      count: math.max(1, _minuend),
      width: rect.width,
      height: rect.height,
    );
    final targetPositions = _gridPositions(
      rect: rect,
      columns: targetSpec.columns,
      count: _minuend,
    );

    final radiusBase = math.min(targetSpec.cellWidth, targetSpec.cellHeight);
    final radius = math.max(_minDotRadius, radiusBase * _dotRadiusFactor);
    final tokenLayouts = targetPositions
        .map(
          (position) => _TokenLayout(
            kind: _TokenKind.dot,
            center: position,
            dotRadius: radius,
          ),
        )
        .toList(growable: false);

    return (targetSpec, tokenLayouts);
  }

  (_GridSpec, List<_TokenLayout>) _baseTenTokenLayouts({required Rect rect}) {
    final horizontalInset = math.max(6.0, rect.width * 0.04);
    final verticalInset = math.max(6.0, rect.height * 0.05);
    final usableRect = Rect.fromLTWH(
      rect.left + horizontalInset,
      rect.top + verticalInset,
      math.max(40.0, rect.width - (horizontalInset * 2)),
      math.max(40.0, rect.height - (verticalInset * 2)),
    );

    final sectionGap = math.max(4.0, verticalInset * 0.4);
    final sectionHeights = _resolveBaseTenSectionHeights(
      availableHeight: math.max(18.0, usableRect.height - (sectionGap * 2)),
      hundredsRows: _gridRows(count: _displayHundreds, maxColumns: 3),
      tensRows: _gridRows(count: _displayTens, maxColumns: 5),
      onesRows: _gridRows(count: _displayOnes, maxColumns: 10),
    );
    final hundredsRect = Rect.fromLTWH(
      usableRect.left,
      usableRect.top,
      usableRect.width,
      sectionHeights.hundreds,
    );
    final tensRect = Rect.fromLTWH(
      usableRect.left,
      hundredsRect.bottom + sectionGap,
      usableRect.width,
      sectionHeights.tens,
    );
    final onesRect = Rect.fromLTWH(
      usableRect.left,
      tensRect.bottom + sectionGap,
      usableRect.width,
      sectionHeights.ones,
    );
    final radii = _resolveBaseTenDotRadii(
      hundredsRect: hundredsRect,
      tensRect: tensRect,
      onesRect: onesRect,
    );

    final tokenLayouts = <_TokenLayout>[
      ..._hundredsLayouts(
        rect: hundredsRect,
        count: _displayHundreds,
        radius: radii.hundreds,
      ),
      ..._tensLayouts(rect: tensRect, count: _displayTens, radius: radii.tens),
      ..._onesLayouts(rect: onesRect, count: _displayOnes, radius: radii.ones),
    ];

    final gridSpec = _bestGrid(
      count: math.max(1, tokenLayouts.length),
      width: rect.width,
      height: rect.height,
    );
    return (gridSpec, tokenLayouts);
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
  }) {
    final onesCellMin = _sectionCellMin(
      rect: onesRect,
      count: _displayOnes,
      maxColumns: 10,
    );
    final tensCellMin = _sectionCellMin(
      rect: tensRect,
      count: _displayTens,
      maxColumns: 5,
    );
    final hundredsCellMin = _sectionCellMin(
      rect: hundredsRect,
      count: _displayHundreds,
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

  int _normalizedOperand(int index) {
    if (index >= context.operands.length) {
      return 0;
    }
    final rounded = context.operands[index].round();
    if (rounded < 0) {
      return 0;
    }
    if (rounded > _maxOperand) {
      return _maxOperand;
    }
    return rounded;
  }

  Future<void> _showCountLabel(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    if (identical(label, _secondCountLabel)) {
      _isSecondOperandVisible = true;
    }
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

  Future<void> _highlightRemovalTokensAndCountSecondOperand() async {
    final removalTokens = _removalTokens;
    if (removalTokens.isEmpty) {
      return;
    }

    _areRemovalTokensHighlighted = true;
    _secondCountLabel.text = '0';
    await _showCountLabel(_secondCountLabel);

    var runningTotal = 0;
    final tokenStep = Duration(
      milliseconds: math.max(
        1,
        (_scaledSeconds(_highlightStaggerDelaySeconds) * 1000).round(),
      ),
    );
    for (final token in removalTokens) {
      if (_disposed) {
        return;
      }
      token.color = _removalDotColor;
      runningTotal += token.value;
      _secondCountLabel.text = '$runningTotal';
      unawaited(
        token.pulse(duration: _scaledSeconds(_highlightPulseDurationSeconds)),
      );
      await Future<void>.delayed(tokenStep);
    }

    final pulseSettle = Duration(
      milliseconds: math.max(
        1,
        (_scaledSeconds(_highlightPulseDurationSeconds) * 1000).round(),
      ),
    );
    await Future<void>.delayed(pulseSettle);
  }

  Future<void> _removeRemovalTokens() async {
    final removalTokens = _removalTokens;
    if (removalTokens.isEmpty) {
      return;
    }

    _areRemovalTokensRemoved = true;
    if (_usesBaseTenBlocks) {
      await _removeBaseTenTokensByGroup(removalTokens);
      return;
    }

    await _removeTokensSequentially(removalTokens);
  }

  Future<void> _removeTokensSequentially(
    List<_SubtractionToken> removalTokens,
  ) async {
    var runningFirstOperand = _minuend;
    var runningSecondOperand = _subtrahend;
    final removeStagger = Duration(
      milliseconds: math.max(
        1,
        (_scaledSeconds(_removeStaggerDelaySeconds) * 1000).round(),
      ),
    );
    for (var index = 0; index < removalTokens.length; index++) {
      if (_disposed) {
        return;
      }
      final token = removalTokens[index];
      token.hideValueLabel();
      await token.removeWithFade(
        duration: _scaledSeconds(_removeDurationSeconds),
        targetScale: _removedDotScale,
      );
      runningFirstOperand = math.max(0, runningFirstOperand - token.value);
      runningSecondOperand = math.max(0, runningSecondOperand - token.value);
      _firstCountLabel.text = '$runningFirstOperand';
      _secondCountLabel.text = '$runningSecondOperand';
      _hideSecondOperandLabelWhenDone(runningSecondOperand);
      if (index < removalTokens.length - 1) {
        await Future<void>.delayed(removeStagger);
      }
    }
  }

  Future<void> _removeBaseTenTokensByGroup(
    List<_SubtractionToken> removalTokens,
  ) async {
    final groups = _orderedBaseTenRemovalGroups(removalTokens);
    if (groups.isEmpty) {
      return;
    }

    final width = size.x > 0 ? size.x : _fallbackWidth;
    final slideDelta = Vector2(width + _baseTenSlidePadding, 0);
    var runningFirstOperand = _minuend;
    var runningSecondOperand = _subtrahend;

    for (var index = 0; index < groups.length; index++) {
      if (_disposed) {
        return;
      }

      final group = groups[index];
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
          _pulseSecondOperandPlacesForKind(
            kind: group.first.kind,
            duration: pulseDuration,
          ),
        ]);
        if (_disposed) {
          return;
        }
      }
      if (_disposed) {
        return;
      }

      for (final token in group) {
        token.hideValueLabel();
      }

      await Future.wait(
        group.map(
          (token) => token.slideBy(
            duration: _scaledSeconds(_baseTenGroupSlideDurationSeconds),
            delta: slideDelta,
          ),
        ),
      );

      final groupTotal = group.fold<int>(0, (sum, token) {
        return sum + token.value;
      });
      runningFirstOperand = math.max(0, runningFirstOperand - groupTotal);
      runningSecondOperand = math.max(0, runningSecondOperand - groupTotal);
      _firstCountLabel.text = '$runningFirstOperand';
      _secondCountLabel.text = '$runningSecondOperand';
      _hideSecondOperandLabelWhenDone(runningSecondOperand);

      if (index < groups.length - 1) {
        await Future<void>.delayed(_baseTenGroupPause);
      }
    }
  }

  Future<void> _pulseSecondOperandPlacesForKind({
    required _TokenKind kind,
    required double duration,
  }) async {
    if (!_usesBaseTenBlocks || !_isSecondOperandVisible) {
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
    if (_isSecondOperandVisible) {
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

  List<List<_SubtractionToken>> _orderedBaseTenRemovalGroups(
    List<_SubtractionToken> removalTokens,
  ) {
    const kindOrder = <_TokenKind>[
      _TokenKind.ones,
      _TokenKind.tens,
      _TokenKind.hundreds,
    ];

    return kindOrder
        .map((kind) {
          return removalTokens
              .where((token) => token.kind == kind)
              .toList(growable: false);
        })
        .where((group) => group.isNotEmpty)
        .toList(growable: false);
  }

  void _hideSecondOperandLabelWhenDone(int runningSecondOperand) {
    if (runningSecondOperand != 0 || !_isSecondOperandVisible) {
      return;
    }
    _isSecondOperandVisible = false;
    _clearSecondOperandPlacePulseLabels();
    _removeEffects(_secondCountLabel);
    _secondCountLabel.scale = Vector2.zero();
  }

  Future<void> _completeSubtractionToAnswerState() async {
    _areCountsInEquation = true;
    _isResultColored = true;
    _isSecondOperandVisible = false;
    _firstCountLabel
      ..text = '$_difference'
      ..textRenderer = mathHelpTextPaint(
        color: _remainingDotColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

    for (final token in _remainingTokens) {
      token.color = _remainingDotColor;
    }

    if (_isMinusVisible) {
      _removeEffects(_minusLabel);
      _minusLabel.scale = Vector2.zero();
      _isMinusVisible = false;
    }

    await _slideAndPulseAnswerOperand();
  }

  Future<void> _slideAndPulseAnswerOperand() async {
    if (_disposed) {
      return;
    }
    _removeEffects(_firstCountLabel);

    final moveCompleter = Completer<void>();
    _firstCountLabel.add(
      MoveEffect.to(
        _layout.secondEquationNumberPosition,
        EffectController(
          duration: _scaledSeconds(_answerSlideDurationSeconds),
          curve: Curves.easeInOutCubic,
        ),
        onComplete: moveCompleter.complete,
      ),
    );
    await moveCompleter.future;
    if (_disposed) {
      return;
    }

    await _scaleLabelTo(
      label: _firstCountLabel,
      targetScale: _answerPrePulseScale,
      duration: _scaledSeconds(_answerPrePulseDurationSeconds),
      curve: Curves.easeOutBack,
    );
    if (_disposed) {
      return;
    }

    final pulseHalfCycleSeconds = _scaledSeconds(
      _answerPulseDurationSeconds / (_answerPulseCycles * 2),
    );
    final pulseTargetScale = _answerPrePulseScale * _answerPulseScale;
    for (var cycle = 0; cycle < _answerPulseCycles; cycle++) {
      await _scaleLabelTo(
        label: _firstCountLabel,
        targetScale: pulseTargetScale,
        duration: pulseHalfCycleSeconds,
      );
      if (_disposed) {
        return;
      }
      await _scaleLabelTo(
        label: _firstCountLabel,
        targetScale: _answerPrePulseScale,
        duration: pulseHalfCycleSeconds,
      );
      if (_disposed) {
        return;
      }
    }
    _firstCountLabel.scale = Vector2.all(1);
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

  Future<void> _showMinusLabel() async {
    if (_isMinusVisible) {
      return;
    }
    _isMinusVisible = true;
    await _showEquationSymbol(_minusLabel);
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

enum _TokenKind { dot, ones, tens, hundreds }

class _SubtractionToken {
  _SubtractionToken({required this.kind, required this.component});

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

  Vector2 get scale => component.scale;
  set scale(Vector2 value) => component.scale = value;

  Paint get _paint {
    return switch (component) {
      _SubtractionDotComponent dot => dot.paint,
      _SubtractionBaseTenDotComponent dot => dot.paint,
      _ => throw StateError(
        'Unsupported subtraction token type: ${component.runtimeType}',
      ),
    };
  }

  void setOpacity(double value) {
    switch (component) {
      case final _SubtractionDotComponent dot:
        dot.opacity = value;
      case final _SubtractionBaseTenDotComponent dot:
        dot.opacity = value;
      default:
        throw StateError(
          'Unsupported subtraction token type: ${component.runtimeType}',
        );
    }
  }

  void hideValueLabel() {
    switch (component) {
      case final _SubtractionBaseTenDotComponent dot:
        dot.hideValueLabel();
      case final _SubtractionDotComponent _:
      default:
        return;
    }
  }

  void showValueLabel() {
    switch (component) {
      case final _SubtractionBaseTenDotComponent dot:
        dot.showValueLabel();
      case final _SubtractionDotComponent _:
      default:
        return;
    }
  }

  void applyLayout(_TokenLayout layout) {
    switch (component) {
      case final _SubtractionDotComponent dot:
        dot.applyLayout(layout);
      case final _SubtractionBaseTenDotComponent dot:
        dot.applyLayout(layout);
      default:
        throw StateError(
          'Unsupported subtraction token type: ${component.runtimeType}',
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

  Future<void> scaleTo({
    required double duration,
    required double targetScale,
    double delay = 0,
  }) {
    final completer = Completer<void>();
    component.add(
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

  Future<void> slideBy({
    required double duration,
    required Vector2 delta,
    double delay = 0,
  }) {
    final completer = Completer<void>();
    component.add(
      MoveEffect.by(
        delta,
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeInOutCubic,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future<void> removeWithFade({
    required double duration,
    required double targetScale,
    double delay = 0,
  }) {
    final completer = Completer<void>();
    component.add(
      OpacityEffect.to(
        0,
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeInCubic,
        ),
      ),
    );
    component.add(
      ScaleEffect.to(
        Vector2.all(targetScale),
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeInBack,
        ),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }
}

class _SubtractionDotComponent extends CircleComponent {
  _SubtractionDotComponent({
    required Vector2 center,
    required Color color,
    required double radius,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         position: center,
         paint: Paint()..color = color,
       );

  void applyLayout(_TokenLayout layout) {
    radius = layout.dotRadius;
    position = layout.center;
  }
}

class _SubtractionBaseTenDotComponent extends CircleComponent {
  _SubtractionBaseTenDotComponent({
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
    required this.tokenLayouts,
    required this.firstCountPosition,
    required this.secondCountPosition,
    required this.firstEquationNumberPosition,
    required this.secondEquationNumberPosition,
    required this.minusPosition,
    required this.equalsPosition,
    required this.resultPosition,
  });

  final int rows;
  final int columns;
  final Vector2 gridOrigin;
  final Vector2 gridSize;
  final List<_TokenLayout> tokenLayouts;
  final Vector2 firstCountPosition;
  final Vector2 secondCountPosition;
  final Vector2 firstEquationNumberPosition;
  final Vector2 secondEquationNumberPosition;
  final Vector2 minusPosition;
  final Vector2 equalsPosition;
  final Vector2 resultPosition;
}
