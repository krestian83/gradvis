import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../presentation/math_help_visualizer_theme.dart';
import '../presentation/math_visualizer.dart';

/// Card-dealing visualizer for division contexts.
///
/// Dividend dots appear in the top half of a rounded frame, then get
/// "dealt" round-robin into distribution fields in the bottom half of
/// the same frame (one field per divisor unit).
class DivisionVisualizer extends MathVisualizer {
  static const _fallbackWidth = 320.0;
  static const _fallbackHeight = 220.0;
  static const _loopPause = Duration(seconds: 3);
  static const _phasePause = Duration(milliseconds: 1050);

  static const _labelRevealSeconds = 0.51;
  static const _labelPulseSeconds = 0.21;
  static const _symbolRevealSeconds = 0.36;
  static const _resultPulseSeconds = 0.27;
  static const _dotScaleInSeconds = 0.38;
  static const _dotStaggerSeconds = 0.025;
  static const _fieldRevealSeconds = 0.34;
  static const _dealMoveSeconds = 0.42;
  static const _dealStaggerSeconds = 0.06;

  static const _dotColor = Color(0xFF1B6DE2);
  static const _operandColor = Color(0xFF1B4F9A);
  static const _divisorColor = Color(0xFFB36A00);
  static const _equationColor = Color(0xFF0A2463);
  static const _frameFill = Color(0xFFF8FBFF);
  static const _frameStroke = Color(0xFFBBD0F6);
  static const _fieldFill = Color(0xFFFFF3E6);
  static const _fieldStroke = Color(0xFFDBA060);

  static const _fieldsPerRow = 6;

  late final int _dividend;
  late final int _divisor;
  late final int _quotient;
  late final int _dotCount;

  bool _disposed = false;
  bool _isAnimating = false;

  bool _isDividendVisible = false;
  bool _isDivisionSignVisible = false;
  bool _isDivisorVisible = false;
  bool _isEqualsVisible = false;
  bool _isResultVisible = false;

  late final TextComponent _dividendLabel;
  late final TextComponent _divisionSignLabel;
  late final TextComponent _divisorLabel;
  late final TextComponent _equalsLabel;
  late final TextComponent _resultLabel;

  _DividendFrameComponent? _frame;
  final _dots = <_DivisionDotComponent>[];
  final _fields = <_DistributionFieldComponent>[];

  DivisionVisualizer({required super.context}) {
    _dividend = _operand(0);
    _divisor = math.max(1, _operand(1));
    _quotient = context.correctAnswer.round().abs();
    _dotCount = _divisor * _quotient;
  }

  @override
  Color backgroundColor() => mathHelpVisualizerBackgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildScene();
    unawaited(_runLoop());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded || _isAnimating) return;
    _applyLayout();
  }

  @override
  void onRemove() {
    _disposed = true;
    super.onRemove();
  }

  // ── Loop ──────────────────────────────────────────────────────────

  Future<void> _runLoop() async {
    while (!_disposed) {
      await _playOnce();
      if (_disposed) return;
      await Future<void>.delayed(_loopPause);
      if (_disposed) return;
    }
  }

  Future<void> _playOnce() async {
    _isAnimating = true;
    _resetScene();

    try {
      // 1. Dividend label + dots together
      if (_dotCount > 0) {
        await Future.wait([
          _showOperandLabel(_dividendLabel),
          _scaleInDots(),
        ]);
      } else {
        await _showOperandLabel(_dividendLabel);
      }
      _isDividendVisible = true;
      if (!await _pause()) return;

      // 2. Division sign
      await _showEquationSymbol(_divisionSignLabel);
      _isDivisionSignVisible = true;
      if (!await _pause()) return;

      // 3. Divisor counts up from 1, each step reveals a field
      if (_dotCount > 0) {
        await _revealFieldsWithDivisorCount();
        if (!await _pause()) return;

        // 4. Deal dots
        await _dealDots();
        if (!await _pause()) return;
      } else {
        await _showOperandLabel(_divisorLabel);
        _isDivisorVisible = true;
        if (!await _pause()) return;
      }

      // 6. Equals sign
      await _showEquationSymbol(_equalsLabel);
      _isEqualsVisible = true;
      if (!await _pause()) return;

      // 7. Answer
      await _showResultLabel();
      _isResultVisible = true;
    } finally {
      _isAnimating = false;
    }
  }

  Future<bool> _pause() async {
    if (_disposed) return false;
    await Future<void>.delayed(_phasePause);
    return !_disposed;
  }

  // ── Scene build ───────────────────────────────────────────────────

  void _buildScene() {
    _dividendLabel = TextComponent(
      text: '$_dividend',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _operandColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_dividendLabel);

    _divisionSignLabel = TextComponent(
      text: '\u00F7',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _equationColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_divisionSignLabel);

    _divisorLabel = TextComponent(
      text: '$_divisor',
      anchor: Anchor.center,
      scale: Vector2.zero(),
      textRenderer: mathHelpTextPaint(
        color: _divisorColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_divisorLabel);

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
        color: _operandColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
    );
    add(_resultLabel);

    if (_dotCount > 0) {
      // Frame first (lowest z), then fields, then dots on top.
      _frame = _DividendFrameComponent()..priority = 0;
      add(_frame!);

      for (var i = 0; i < _divisor; i++) {
        final field = _DistributionFieldComponent()
          ..priority = 1
          ..scale = Vector2.zero();
        _fields.add(field);
        add(field);
      }

      final layout = _computeLayout();
      for (var i = 0; i < _dotCount; i++) {
        final dot = _DivisionDotComponent(
          center: layout.dividendDotPositions[i],
          color: _dotColor,
          radius: layout.dotRadius,
        )
          ..priority = 2
          ..scale = Vector2.zero();
        _dots.add(dot);
        add(dot);
      }
    }

    _applyLayout();
    _resetScene();
  }

  // ── Layout ────────────────────────────────────────────────────────

  _DivisionSceneLayout _computeLayout() {
    final w = size.x > 0 ? size.x : _fallbackWidth;
    final h = size.y > 0 ? size.y : _fallbackHeight;
    return _DivisionSceneLayout.compute(
      canvasWidth: w,
      canvasHeight: h,
      dotCount: _dotCount,
      divisor: _divisor,
      quotient: _quotient,
    );
  }

  void _applyLayout() {
    final layout = _computeLayout();

    _applyEquationLayout(layout);

    if (_frame != null) {
      _frame!
        ..position = layout.frameOrigin
        ..size = layout.frameSize;
    }

    for (var i = 0; i < _dots.length; i++) {
      _dots[i]
        ..radius = layout.dotRadius
        ..position = layout.dividendDotPositions[i];
    }

    for (var i = 0; i < _fields.length; i++) {
      _fields[i]
        ..position = layout.fieldOrigins[i]
        ..size = layout.fieldSize;
    }
  }

  void _applyEquationLayout(_DivisionSceneLayout layout) {
    _dividendLabel
      ..position = layout.equationPositions[0]
      ..scale = _isDividendVisible ? Vector2.all(1) : Vector2.zero();
    _divisionSignLabel
      ..position = layout.equationPositions[1]
      ..scale = _isDivisionSignVisible
          ? Vector2.all(1)
          : Vector2.zero();
    _divisorLabel
      ..position = layout.equationPositions[2]
      ..scale = _isDivisorVisible ? Vector2.all(1) : Vector2.zero();
    _equalsLabel
      ..position = layout.equationPositions[3]
      ..scale = _isEqualsVisible ? Vector2.all(1) : Vector2.zero();
    _resultLabel
      ..position = layout.equationPositions[4]
      ..scale = _isResultVisible ? Vector2.all(1) : Vector2.zero();
  }

  // ── Reset ─────────────────────────────────────────────────────────

  void _resetScene() {
    _isDividendVisible = false;
    _isDivisionSignVisible = false;
    _isDivisorVisible = false;
    _isEqualsVisible = false;
    _isResultVisible = false;

    _resetLabel(_dividendLabel, '$_dividend', _operandColor, 32);
    _resetLabel(_divisionSignLabel, '\u00F7', _equationColor, 34);
    _resetLabel(_divisorLabel, '$_divisor', _divisorColor, 32);
    _resetLabel(_equalsLabel, '=', _equationColor, 34);
    _resetLabel(
      _resultLabel,
      '${context.correctAnswer}',
      _operandColor,
      34,
    );

    final layout = _computeLayout();
    _applyEquationLayout(layout);

    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];
      dot.clearEffects();
      dot
        ..position = layout.dividendDotPositions[i]
        ..radius = layout.dotRadius
        ..scale = Vector2.zero();
    }

    for (final field in _fields) {
      _removeEffects(field);
      field.scale = Vector2.zero();
    }
  }

  void _resetLabel(
    TextComponent label,
    String text,
    Color color,
    double fontSize,
  ) {
    _removeEffects(label);
    label
      ..text = text
      ..textRenderer = mathHelpTextPaint(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();
  }

  // ── Animations ────────────────────────────────────────────────────

  Future<void> _scaleInDots() async {
    final completers = <Future<void>>[];

    for (var i = 0; i < _dots.length; i++) {
      final dot = _dots[i];
      final completer = Completer<void>();
      dot.clearEffects();
      dot.scale = Vector2.zero();
      dot.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _dotScaleInSeconds,
            startDelay: i * _dotStaggerSeconds,
            curve: Curves.easeOutBack,
          ),
          onComplete: completer.complete,
        ),
      );
      completers.add(completer.future);
    }

    await Future.wait(completers);
  }

  /// Reveals fields one by one while the divisor label counts up
  /// from 1 to the final divisor value.
  Future<void> _revealFieldsWithDivisorCount() async {
    for (var i = 0; i < _fields.length; i++) {
      if (_disposed) return;

      // Update divisor label to current count.
      final count = i + 1;
      _removeEffects(_divisorLabel);
      _divisorLabel
        ..text = '$count'
        ..textRenderer = mathHelpTextPaint(
          color: _divisorColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        )
        ..scale = Vector2.zero();

      // Reveal field and divisor label together.
      final field = _fields[i];
      _removeEffects(field);
      field.scale = Vector2.zero();

      final fieldCompleter = Completer<void>();
      field.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _fieldRevealSeconds,
            curve: Curves.easeOutBack,
          ),
          onComplete: fieldCompleter.complete,
        ),
      );

      final labelCompleter = Completer<void>();
      _divisorLabel.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _fieldRevealSeconds,
            curve: Curves.easeOutBack,
          ),
          onComplete: labelCompleter.complete,
        ),
      );

      await Future.wait([fieldCompleter.future, labelCompleter.future]);
      _isDivisorVisible = true;

      // Pause so a child can count along (~1 s per number).
      if (i < _fields.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 850));
        if (_disposed) return;
      }
    }
  }

  Future<void> _dealDots() async {
    if (_dotCount == 0 || _divisor == 0) return;

    final layout = _computeLayout();

    if (_dotCount <= 20) {
      await _dealOneByOne(layout);
    } else if (_dotCount <= 50) {
      await _dealByRound(layout);
    } else {
      await _dealAllStaggered(layout);
    }
  }

  /// Small counts: deal one dot at a time, round-robin.
  Future<void> _dealOneByOne(_DivisionSceneLayout layout) async {
    for (var i = 0; i < _dotCount; i++) {
      if (_disposed) return;
      final dot = _dots[i];
      final target = layout.dealtDotPositions[i];
      dot.clearEffects();
      dot.animateTo(
        targetPosition: target,
        duration: _dealMoveSeconds,
      );
      await Future<void>.delayed(
        Duration(
          milliseconds: ((_dealMoveSeconds + _dealStaggerSeconds) * 1000)
              .round(),
        ),
      );
    }
  }

  /// Medium counts: deal one full round at a time (all fields get one
  /// dot simultaneously, then wait, then next round).
  Future<void> _dealByRound(_DivisionSceneLayout layout) async {
    for (var round = 0; round < _quotient; round++) {
      if (_disposed) return;

      for (var field = 0; field < _divisor; field++) {
        final dotIndex = round * _divisor + field;
        if (dotIndex >= _dotCount) break;
        final dot = _dots[dotIndex];
        final target = layout.dealtDotPositions[dotIndex];
        dot.clearEffects();
        dot.animateTo(
          targetPosition: target,
          duration: _dealMoveSeconds,
          delay: field * _dealStaggerSeconds,
        );
      }

      final roundDuration =
          _dealMoveSeconds + (_divisor - 1) * _dealStaggerSeconds;
      await Future<void>.delayed(
        Duration(milliseconds: (roundDuration * 1000).round()),
      );
    }
  }

  /// Large counts: fire all rounds with staggered delays.
  Future<void> _dealAllStaggered(_DivisionSceneLayout layout) async {
    var maxDuration = 0.0;

    for (var i = 0; i < _dotCount; i++) {
      final dot = _dots[i];
      final target = layout.dealtDotPositions[i];
      final round = i ~/ _divisor;
      final field = i % _divisor;
      final delay =
          round * _dealStaggerSeconds * 2 + field * _dealStaggerSeconds;

      dot.clearEffects();
      dot.animateTo(
        targetPosition: target,
        duration: _dealMoveSeconds,
        delay: delay,
      );

      final total = _dealMoveSeconds + delay;
      if (total > maxDuration) maxDuration = total;
    }

    await Future<void>.delayed(
      Duration(milliseconds: (maxDuration * 1000).round()),
    );
  }

  Future<void> _showOperandLabel(TextComponent label) {
    _removeEffects(label);
    label.scale = Vector2.zero();
    final completer = Completer<void>();
    label.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _labelRevealSeconds,
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1.1),
          EffectController(
            duration: _labelPulseSeconds,
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
    final completer = Completer<void>();
    label.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(
          duration: _symbolRevealSeconds,
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
        color: _operandColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      )
      ..scale = Vector2.zero();

    final completer = Completer<void>();
    _resultLabel.add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(
            duration: _labelRevealSeconds,
            curve: Curves.easeOutBack,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(1.14),
          EffectController(
            duration: _resultPulseSeconds,
            curve: Curves.easeInOut,
            alternate: true,
            repeatCount: 2,
          ),
        ),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  // ── Helpers ───────────────────────────────────────────────────────

  void _removeEffects(PositionComponent component) {
    final effects = component.children.whereType<Effect>().toList();
    for (final effect in effects) {
      effect.removeFromParent();
    }
  }

  int _operand(int index) {
    if (index >= context.operands.length) return 0;
    return math.max(0, context.operands[index].round());
  }
}

// ════════════════════════════════════════════════════════════════════
//  Supporting components
// ════════════════════════════════════════════════════════════════════

class _DivisionDotComponent extends CircleComponent {
  _DivisionDotComponent({
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

  void animateTo({
    required Vector2 targetPosition,
    required double duration,
    double delay = 0,
  }) {
    add(
      MoveEffect.to(
        targetPosition,
        EffectController(
          duration: duration,
          startDelay: delay,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }
}

/// Single rounded-rect frame that wraps both the dividend dot area
/// and the distribution fields below.
class _DividendFrameComponent extends PositionComponent {
  final _fillPaint = Paint()..color = DivisionVisualizer._frameFill;
  final _strokePaint = Paint()
    ..color = DivisionVisualizer._frameStroke
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas
      ..drawRRect(rr, _fillPaint)
      ..drawRRect(rr, _strokePaint);
  }
}

class _DistributionFieldComponent extends PositionComponent {
  final _fillPaint = Paint()..color = DivisionVisualizer._fieldFill;
  final _strokePaint = Paint()
    ..color = DivisionVisualizer._fieldStroke
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas
      ..drawRRect(rr, _fillPaint)
      ..drawRRect(rr, _strokePaint);
  }
}

// ════════════════════════════════════════════════════════════════════
//  Layout data class
// ════════════════════════════════════════════════════════════════════

class _DivisionSceneLayout {
  const _DivisionSceneLayout({
    required this.equationPositions,
    required this.frameOrigin,
    required this.frameSize,
    required this.dotRadius,
    required this.dividendDotPositions,
    required this.fieldOrigins,
    required this.fieldSize,
    required this.dealtDotPositions,
  });

  /// Five equation element positions: dividend, div, divisor, =, answer.
  final List<Vector2> equationPositions;

  /// Origin & size of the outer white frame (wraps dots + fields).
  final Vector2 frameOrigin;
  final Vector2 frameSize;
  final double dotRadius;

  /// Dot positions inside the top (dividend) area of the frame.
  final List<Vector2> dividendDotPositions;

  /// Top-left of each green distribution field (inside the frame).
  final List<Vector2> fieldOrigins;
  final Vector2 fieldSize;

  /// Dot positions inside the distribution fields (dealt order).
  final List<Vector2> dealtDotPositions;

  static _DivisionSceneLayout compute({
    required double canvasWidth,
    required double canvasHeight,
    required int dotCount,
    required int divisor,
    required int quotient,
  }) {
    final w = canvasWidth;
    final h = canvasHeight;

    // ── Equation row ────────────────────────────────────────────
    final equationY = math.max(30.0, h * 0.10);
    final centerX = w / 2;
    final step = math.max(26.0, math.min(46.0, w * 0.09));
    final eqPositions = [
      Vector2(centerX - step * 2, equationY),
      Vector2(centerX - step, equationY),
      Vector2(centerX, equationY),
      Vector2(centerX + step, equationY),
      Vector2(centerX + step * 2.2, equationY),
    ];

    // ── Dot sizing ──────────────────────────────────────────────
    final baseRadius = dotCount <= 20
        ? 8.0
        : dotCount <= 50
            ? 6.0
            : 4.5;
    final dotRadius = math.max(3.0, baseRadius);
    final dotGap = dotRadius * 2.8;

    // ── Outer frame bounds ──────────────────────────────────────
    final framePadH = math.max(12.0, w * 0.035);
    final frameTop = h * 0.20;
    final frameWidth = math.max(80.0, w - framePadH * 2);
    final innerPad = math.max(12.0, frameWidth * 0.04);

    // ── Dividend dot grid (top section of frame) ────────────────
    final innerW = frameWidth - innerPad * 2;
    final frameCols = dotCount == 0
        ? 1
        : math.max(1, (innerW / dotGap).floor().clamp(1, dotCount));
    final frameRows = dotCount == 0 ? 1 : (dotCount / frameCols).ceil();
    final dotSectionH =
        math.max(dotGap, frameRows * dotGap) + dotRadius * 2;

    // ── Distribution fields (bottom section of frame) ───────────
    final fieldsPerRow =
        math.min(DivisionVisualizer._fieldsPerRow, divisor);
    final fieldRowCount = (divisor / fieldsPerRow).ceil();
    final fieldGapY = math.max(6.0, h * 0.015);

    // Dot grid inside each field
    final fieldDotCols =
        quotient == 0 ? 1 : math.max(1, math.sqrt(quotient).ceil());
    final fieldDotRows =
        quotient == 0 ? 1 : (quotient / fieldDotCols).ceil();
    final fieldDotGap = dotRadius * 2.8;

    // Size fields to snugly fit dots with comfortable padding.
    final fieldPad = dotRadius * 1.6;
    final fieldContentW = math.max(
      fieldDotGap,
      (fieldDotCols - 1) * fieldDotGap,
    ) + dotRadius * 2;
    final fieldContentH = math.max(
      fieldDotGap,
      (fieldDotRows - 1) * fieldDotGap,
    ) + dotRadius * 2;
    final fieldW = fieldContentW + fieldPad * 2;
    final fieldH = fieldContentH + fieldPad * 2;
    final fieldSize = Vector2(fieldW, fieldH);

    final fieldSectionH =
        fieldRowCount * fieldH + (fieldRowCount - 1) * fieldGapY;

    // Separator gap between dot section and field section.
    final sectionGap = math.max(8.0, h * 0.025);

    // ── Total frame height ──────────────────────────────────────
    final frameHeight =
        innerPad + dotSectionH + sectionGap + fieldSectionH + innerPad;
    final frameOrigin = Vector2(framePadH, frameTop);
    final frameSize = Vector2(frameWidth, frameHeight);

    // ── Dividend dot positions (absolute coords) ────────────────
    final dotAreaTop = frameTop + innerPad;
    final dividendPositions = <Vector2>[];
    for (var i = 0; i < dotCount; i++) {
      final row = i ~/ frameCols;
      final col = i % frameCols;
      final dotsInRow = (row < frameRows - 1)
          ? frameCols
          : dotCount - (frameRows - 1) * frameCols;
      final rowWidth = (dotsInRow - 1) * dotGap;
      final xStart = framePadH + innerPad + (innerW - rowWidth) / 2;
      dividendPositions.add(
        Vector2(
          xStart + col * dotGap,
          dotAreaTop + dotRadius + row * dotGap,
        ),
      );
    }

    // ── Field origins (evenly distributed inside the frame) ─────
    final fieldAreaTop = dotAreaTop + dotSectionH + sectionGap;
    final fieldOrigins = <Vector2>[];
    for (var i = 0; i < divisor; i++) {
      final fRow = i ~/ fieldsPerRow;
      final fCol = i % fieldsPerRow;
      final rowFieldCount = (fRow < fieldRowCount - 1)
          ? fieldsPerRow
          : divisor - (fieldRowCount - 1) * fieldsPerRow;

      // Distribute fields evenly: equal space before, between, and
      // after each field within the inner width.
      final totalFieldsW = rowFieldCount * fieldW;
      final remainingSpace = innerW - totalFieldsW;
      final spacerCount = rowFieldCount + 1;
      final spacer = remainingSpace / spacerCount;
      final xStart = framePadH + innerPad + spacer + fCol * (fieldW + spacer);

      fieldOrigins.add(
        Vector2(xStart, fieldAreaTop + fRow * (fieldH + fieldGapY)),
      );
    }

    // ── Dealt dot positions (round-robin into fields) ───────────
    final dealtPositions = <Vector2>[];
    for (var i = 0; i < dotCount; i++) {
      final fieldIdx = i % divisor;
      final slotIdx = i ~/ divisor;
      final fOrigin = fieldOrigins[fieldIdx];
      final slotRow = slotIdx ~/ fieldDotCols;
      final slotCol = slotIdx % fieldDotCols;
      final dotsInSlotRow = (slotRow < fieldDotRows - 1)
          ? fieldDotCols
          : quotient - (fieldDotRows - 1) * fieldDotCols;
      final rowWidth = math.max(0, dotsInSlotRow - 1) * fieldDotGap;
      final xStart = fOrigin.x + (fieldW - rowWidth) / 2;
      dealtPositions.add(
        Vector2(
          xStart + slotCol * fieldDotGap,
          fOrigin.y + fieldPad + dotRadius + slotRow * fieldDotGap,
        ),
      );
    }

    return _DivisionSceneLayout(
      equationPositions: eqPositions,
      frameOrigin: frameOrigin,
      frameSize: frameSize,
      dotRadius: dotRadius,
      dividendDotPositions: dividendPositions,
      fieldOrigins: fieldOrigins,
      fieldSize: fieldSize,
      dealtDotPositions: dealtPositions,
    );
  }
}
