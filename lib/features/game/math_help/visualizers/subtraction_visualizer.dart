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
  static const _phasePause = Duration(milliseconds: 1050);
  static const _loopPause = Duration(seconds: 3);
  static const _slowdownFactor = 1.3;
  static const _answerSlideDurationSeconds = 0.68;
  static const _answerPulseDurationSeconds = 4.0;
  static const _answerPulseScale = 1.15;
  static const _answerPulseCycles = 6;

  static const _baseDotColor = Color(0xFF1B6DE2);
  static const _removalDotColor = Color(0xFFE53935);
  static const _remainingDotColor = Color(0xFF2E7D32);
  static const _firstLabelColor = Color(0xFF1B4F9A);
  static const _secondLabelColor = Color(0xFFB71C1C);
  static const _equationColor = Color(0xFF0A2463);

  final _tokens = <_SubtractionToken>[];

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
      await Future<void>.delayed(_scaledDuration(_loopPause));
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
      } else {
        await _showCountLabel(_secondCountLabel);
      }

      await _completeSubtractionToAnswerState();
      if (!await _pauseForNextStep()) {
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
    await Future<void>.delayed(_scaledDuration(_phasePause));
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
      component: _SubtractionBaseTenBlockComponent(
        center: tokenLayout.center,
        size: tokenLayout.blockSize.clone(),
        color: _baseDotColor,
        cornerRadius: tokenLayout.cornerRadius,
        kind: tokenLayout.kind,
        value: tokenLayout.blockValue,
      ),
    );
  }

  void _resetScene() {
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

    final gridTop = height * 0.34;
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

    final equationCenterX = width / 2;
    final equationStep = math.max(26.0, math.min(46.0, width * 0.09));
    final firstEquationNumberPosition = Vector2(
      equationCenterX - (equationStep * 2.0),
      equationY,
    );
    final minusPosition = Vector2(equationCenterX - equationStep, equationY);
    final secondEquationNumberPosition = Vector2(equationCenterX, equationY);
    final equalsPosition = Vector2(equationCenterX + equationStep, equationY);
    final resultPosition = Vector2(
      equationCenterX + (equationStep * 2.2),
      equationY,
    );

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
    final verticalInset = math.max(6.0, rect.height * 0.06);
    final usableRect = Rect.fromLTWH(
      rect.left + horizontalInset,
      rect.top + verticalInset,
      math.max(40.0, rect.width - (horizontalInset * 2)),
      math.max(40.0, rect.height - (verticalInset * 2)),
    );

    final sectionGap = math.max(4.0, verticalInset * 0.4);
    final sectionHeight = math.max(
      16.0,
      (usableRect.height - (sectionGap * 2)) / 3,
    );
    final hundredsRect = Rect.fromLTWH(
      usableRect.left,
      usableRect.top,
      usableRect.width,
      sectionHeight,
    );
    final tensRect = Rect.fromLTWH(
      usableRect.left,
      hundredsRect.bottom + sectionGap,
      usableRect.width,
      sectionHeight,
    );
    final onesRect = Rect.fromLTWH(
      usableRect.left,
      tensRect.bottom + sectionGap,
      usableRect.width,
      math.max(16.0, usableRect.bottom - (tensRect.bottom + sectionGap)),
    );

    final tokenLayouts = <_TokenLayout>[
      ..._hundredsLayouts(rect: hundredsRect, count: _displayHundreds),
      ..._tensLayouts(rect: tensRect, count: _displayTens),
      ..._onesLayouts(rect: onesRect, count: _displayOnes),
    ];

    final columns = 10;
    const rows = 6;
    final gridSpec = _GridSpec(
      rows: rows,
      columns: columns,
      cellWidth: rect.width / columns,
      cellHeight: rect.height / rows,
    );
    return (gridSpec, tokenLayouts);
  }

  List<_TokenLayout> _hundredsLayouts({
    required Rect rect,
    required int count,
  }) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(3, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;
    final side = math.max(12.0, math.min(cellWidth, cellHeight) * 0.72);
    final cornerRadius = math.min(8.0, side * 0.16);

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
        blockSize: Vector2.all(side),
        cornerRadius: cornerRadius,
        blockValue: 100,
      );
    });
  }

  List<_TokenLayout> _tensLayouts({required Rect rect, required int count}) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(5, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;
    final rodWidth = math.max(22.0, cellWidth * 0.8);
    final rodHeight = math.max(
      10.0,
      math.min(cellHeight * 0.58, rodWidth * 0.34),
    );
    final cornerRadius = math.min(8.0, rodHeight * 0.42);

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
        blockSize: Vector2(rodWidth, rodHeight),
        cornerRadius: cornerRadius,
        blockValue: 10,
      );
    });
  }

  List<_TokenLayout> _onesLayouts({required Rect rect, required int count}) {
    if (count <= 0) {
      return const <_TokenLayout>[];
    }

    final columns = math.max(1, math.min(10, count));
    final rows = (count / columns).ceil();
    final cellWidth = rect.width / columns;
    final cellHeight = rect.height / rows;
    final side = math.max(8.0, math.min(cellWidth, cellHeight) * 0.62);
    final cornerRadius = math.min(6.0, side * 0.24);

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
        blockSize: Vector2.all(side),
        cornerRadius: cornerRadius,
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
      if (runningSecondOperand == 0 && _isSecondOperandVisible) {
        _isSecondOperandVisible = false;
        _removeEffects(_secondCountLabel);
        _secondCountLabel.scale = Vector2.zero();
      }
      if (index < removalTokens.length - 1) {
        await Future<void>.delayed(removeStagger);
      }
    }
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

    final pulseHalfCycleSeconds =
        _answerPulseDurationSeconds / (_answerPulseCycles * 2);
    final pulseCompleter = Completer<void>();
    _firstCountLabel.add(
      ScaleEffect.to(
        Vector2.all(_answerPulseScale),
        EffectController(
          duration: pulseHalfCycleSeconds,
          reverseDuration: pulseHalfCycleSeconds,
          curve: Curves.easeInOut,
          alternate: true,
          repeatCount: _answerPulseCycles,
        ),
        onComplete: pulseCompleter.complete,
      ),
    );
    await pulseCompleter.future;
    _firstCountLabel.scale = Vector2.all(1);
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
      _SubtractionBaseTenBlockComponent block => block.paint,
      _ => throw StateError(
        'Unsupported subtraction token type: ${component.runtimeType}',
      ),
    };
  }

  void setOpacity(double value) {
    switch (component) {
      case final _SubtractionDotComponent dot:
        dot.opacity = value;
      case final _SubtractionBaseTenBlockComponent block:
        block.opacity = value;
      default:
        throw StateError(
          'Unsupported subtraction token type: ${component.runtimeType}',
        );
    }
  }

  void hideValueLabel() {
    switch (component) {
      case final _SubtractionBaseTenBlockComponent block:
        block.hideValueLabel();
      case final _SubtractionDotComponent _:
      default:
        return;
    }
  }

  void showValueLabel() {
    switch (component) {
      case final _SubtractionBaseTenBlockComponent block:
        block.showValueLabel();
      case final _SubtractionDotComponent _:
      default:
        return;
    }
  }

  void applyLayout(_TokenLayout layout) {
    switch (component) {
      case final _SubtractionDotComponent dot:
        dot.applyLayout(layout);
      case final _SubtractionBaseTenBlockComponent block:
        block.applyLayout(layout);
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

  Future<void> pulse({required double duration, double delay = 0}) {
    final completer = Completer<void>();
    component.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(
          Vector2.all(1.18),
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

class _SubtractionBaseTenBlockComponent extends RectangleComponent {
  _SubtractionBaseTenBlockComponent({
    required Vector2 center,
    required Vector2 size,
    required Color color,
    required double cornerRadius,
    required _TokenKind kind,
    required int value,
  }) : _kind = kind,
       _value = value,
       _cornerRadius = cornerRadius,
       super(
         anchor: Anchor.center,
         position: center,
         size: size,
         paint: Paint()..color = color,
       ) {
    _valueLabel = TextComponent(
      text: '$_value',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: _valueTextPaint(fontSize: _labelFontSize),
    );
    add(_valueLabel);
  }

  static const _valueLabelColor = Color(0xFF0A2463);

  _TokenKind _kind;
  int _value;
  double _cornerRadius;
  bool _isValueLabelVisible = true;
  late final TextComponent _valueLabel;

  double get _labelFontSize {
    final shortSide = math.min(size.x, size.y);
    final scale = switch (_kind) {
      _TokenKind.ones => 0.68,
      _TokenKind.tens => 0.78,
      _TokenKind.hundreds => 0.42,
      _TokenKind.dot => 0.68,
    };
    return math.max(6.5, math.min(15.0, shortSide * scale));
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
      ..position = size / 2
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
    size = layout.blockSize;
    _cornerRadius = layout.cornerRadius;
    _kind = layout.kind;
    _value = layout.blockValue;
    _syncValueLabel();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(_cornerRadius),
    );

    final borderColor =
        Color.lerp(paint.color, Colors.black, 0.24) ?? paint.color;
    final colorAlpha = (paint.color.a * 255).round().clamp(0, 255);
    final borderPaint = Paint()
      ..color = borderColor.withAlpha(colorAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(roundedRect, borderPaint);

    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final separatorAlpha = (colorAlpha * 0.4).round().clamp(0, 255);
    final separatorPaint = Paint()
      ..color = borderColor.withAlpha(separatorAlpha)
      ..strokeWidth = 0.8;
    switch (_kind) {
      case _TokenKind.tens:
        final step = size.x / 10;
        final bottom = math.max(2.0, size.y - 2);
        for (var index = 1; index < 10; index++) {
          final x = step * index;
          canvas.drawLine(Offset(x, 2), Offset(x, bottom), separatorPaint);
        }
        break;
      case _TokenKind.hundreds:
        final widthStep = size.x / 10;
        final heightStep = size.y / 10;
        final bottom = math.max(2.0, size.y - 2);
        final right = math.max(2.0, size.x - 2);
        for (var index = 1; index < 10; index++) {
          final x = widthStep * index;
          final y = heightStep * index;
          canvas.drawLine(Offset(x, 2), Offset(x, bottom), separatorPaint);
          canvas.drawLine(Offset(2, y), Offset(right, y), separatorPaint);
        }
        break;
      case _TokenKind.ones:
      case _TokenKind.dot:
        break;
    }
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
    Vector2? blockSize,
    this.cornerRadius = 0,
    this.blockValue = 0,
  }) : blockSize = blockSize ?? Vector2.zero();

  final _TokenKind kind;
  final Vector2 center;
  final double dotRadius;
  final Vector2 blockSize;
  final double cornerRadius;
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
