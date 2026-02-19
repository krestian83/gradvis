import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' show Colors, TextDirection, TextPainter,
    TextSpan, TextStyle, FontWeight, Alignment, LinearGradient, Radius,
    Curves;

/// Animation state for the runner character.
enum RunnerState { running, throwing, hit, celebrating, defeated }

/// The GradVis pyramid character rendered as a Flame component.
class RunnerCharacter extends PositionComponent {
  RunnerCharacter({this.onFootstep})
    : super(size: Vector2(60, 75), anchor: Anchor.bottomCenter);

  /// Called each time a foot lands (twice per stride cycle).
  final VoidCallback? onFootstep;

  RunnerState state = RunnerState.running;
  double _wobblePhase = 0;
  double _bouncePhase = 0;
  double _runSpeed = 120;
  double _leanAngle = 0.05;
  double _stepPhase = 0;
  bool _lastStepLeft = false;

  static const _blockGradients = [
    [Color(0xFFFF6B35), Color(0xFFFF3366), Color(0xFFFF7E4A)],
    [Color(0xFF00B4D8), Color(0xFF48CAE4), Color(0xFF18B5E0)],
    [Color(0xFF7B2FF7), Color(0xFF9B5FF8), Color(0xFF8B42F7)],
    [Color(0xFFFFB627), Color(0xFFFFCF56), Color(0xFFF5A623)],
  ];

  set runSpeed(double value) => _runSpeed = value;

  @override
  void update(double dt) {
    super.update(dt);
    final speedFactor = (_runSpeed / 120).clamp(0.5, 3.0);
    _wobblePhase += dt * 1.2 * speedFactor;
    _bouncePhase += dt * 3.0 * speedFactor;
    _leanAngle = (state == RunnerState.running)
        ? 0.05 + sin(_bouncePhase) * 0.02
        : 0;

    // Feet step cycle — fires callback on each foot landing.
    if (state == RunnerState.running && _runSpeed > 0) {
      final prevPhase = _stepPhase;
      _stepPhase += dt * 2.8 * speedFactor;
      final prevStep = (prevPhase * 2).floor();
      final currStep = (_stepPhase * 2).floor();
      if (currStep > prevStep) {
        _lastStepLeft = !_lastStepLeft;
        onFootstep?.call();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final sx = w / 60;
    final sy = h / 65;

    canvas.save();

    // Running lean
    if (state == RunnerState.running) {
      final bounceY = sin(_bouncePhase) * 3.0 * sy;
      canvas.translate(w / 2, h);
      canvas.rotate(_leanAngle);
      canvas.translate(-w / 2, -h + bounceY);
    }

    // Bounce scale
    if (state == RunnerState.running) {
      final breathe = 1.0 + sin(_bouncePhase * 0.8) * 0.015;
      canvas.translate(w / 2, h);
      canvas.scale(1.0, breathe);
      canvas.translate(-w / 2, -h);
    }

    for (var i = 0; i < 4; i++) {
      _drawBlock(canvas, i, sx, sy);
    }

    // Tiny feet below the bottom block.
    if (state == RunnerState.running || state == RunnerState.throwing) {
      _drawFeet(canvas, sx, sy);
    }

    canvas.restore();
  }

  void _drawBlock(Canvas canvas, int index, double sx, double sy) {
    final wobbleAngle = _wobbleAngleForBlock(index);
    final wobbleY = _wobbleYForBlock(index);

    canvas.save();

    final pivotX = 30 * sx;
    final pivotY = [54, 39, 25, 13][index] * sy;
    canvas.translate(pivotX, pivotY);
    canvas.rotate(wobbleAngle * pi / 180);
    canvas.translate(0, wobbleY * sy);
    canvas.translate(-pivotX, -pivotY);

    final colors = _blockGradients[index];

    // Block rect
    final rects = [
      [8.0, 42.0, 44.0, 18.0, 4.0],
      [13.0, 30.0, 34.0, 16.0, 3.5],
      [17.0, 18.0, 26.0, 14.0, 3.0],
      [21.0, 6.0, 18.0, 14.0, 3.0],
    ];
    final r = rects[index];
    final rect = RRect.fromLTRBR(
      r[0] * sx,
      r[1] * sy,
      (r[0] + r[2]) * sx,
      (r[1] + r[3]) * sy,
      Radius.circular(r[4] * sx),
    );

    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors[0], colors[1]],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, gradPaint);

    // White overlay
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Highlight bar
    final hls = [
      [10.0, 43.0, 40.0, 2.5, 1.5],
      [15.0, 31.0, 30.0, 2.0, 1.2],
      [19.0, 19.0, 22.0, 2.0, 1.2],
      [23.0, 7.0, 14.0, 1.5, 1.0],
    ];
    final hl = hls[index];
    canvas.drawRRect(
      RRect.fromLTRBR(
        hl[0] * sx,
        hl[1] * sy,
        (hl[0] + hl[2]) * sx,
        (hl[1] + hl[3]) * sy,
        Radius.circular(hl[4] * sx),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Nubs
    final nubs = [
      [[16.0, 39.0, 8.0, 5.0, 2.5], [36.0, 39.0, 8.0, 5.0, 2.5]],
      [[19.0, 27.5, 6.0, 4.5, 2.0], [35.0, 27.5, 6.0, 4.5, 2.0]],
      [[22.0, 15.5, 5.5, 4.5, 2.0], [33.0, 15.5, 5.5, 4.5, 2.0]],
      [[25.0, 4.0, 4.5, 4.0, 1.5], [31.0, 4.0, 4.5, 4.0, 1.5]],
    ];
    final nubPaint = Paint()..color = colors[2];
    for (final n in nubs[index]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          n[0] * sx, n[1] * sy,
          (n[0] + n[2]) * sx, (n[1] + n[3]) * sy,
          Radius.circular(n[4] * sx),
        ),
        nubPaint,
      );
    }

    // Eyes
    const pupilColor = Color(0xFF3D2B30);
    final eyes = [
      [[16.0, 53.0, 1.6, 0.9], [44.0, 53.0, 1.6, 0.9]],
      [[19.0, 38.0, 1.4, 0.8], [41.0, 38.0, 1.4, 0.8]],
      [[22.0, 25.5, 1.2, 0.7], [38.0, 25.5, 1.2, 0.7]],
      [[26.0, 14.0, 1.1, 0.6], [34.0, 14.0, 1.1, 0.6]],
    ];
    final whiteEye = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final pupilPaint = Paint()..color = pupilColor;

    for (final e in eyes[index]) {
      canvas.drawCircle(
        Offset(e[0] * sx, e[1] * sy), e[2] * sx, whiteEye,
      );
      canvas.drawCircle(
        Offset(e[0] * sx, e[1] * sy), e[3] * sx, pupilPaint,
      );
    }

    // Smile
    final smiles = [
      [27.0, 55.5, 28.0, 57.0, 32.0, 57.0, 33.0, 55.5, 0.8],
      [27.5, 40.0, 28.5, 41.2, 31.5, 41.2, 32.5, 40.0, 0.7],
      [28.0, 27.5, 28.8, 28.5, 31.2, 28.5, 32.0, 27.5, 0.6],
      [28.5, 16.0, 29.2, 16.8, 30.8, 16.8, 31.5, 16.0, 0.5],
    ];
    final sm = smiles[index];
    final smilePaint = Paint()
      ..color = pupilColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sm[8] * sx
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(sm[0] * sx, sm[1] * sy)
      ..cubicTo(
        sm[2] * sx, sm[3] * sy,
        sm[4] * sx, sm[5] * sy,
        sm[6] * sx, sm[7] * sy,
      );
    canvas.drawPath(path, smilePaint);

    // Number
    final nums = [
      [30.0, 50.0, 8.0],
      [30.0, 35.0, 7.0],
      [30.0, 22.0, 6.5],
      [30.0, 11.0, 6.0],
    ];
    final n = nums[index];
    final tp = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: n[2] * sx,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(n[0] * sx - tp.width / 2, n[1] * sy - tp.height / 2),
    );

    canvas.restore();
  }

  void _drawFeet(Canvas canvas, double sx, double sy) {
    // Step cycle: _stepPhase drives a full stride.
    final cycle = _stepPhase * 2 * pi;

    // Left foot offset, right foot offset (alternating).
    final leftDx = sin(cycle) * 6.0 * sx;
    final rightDx = sin(cycle + pi) * 6.0 * sx;
    final leftDy = -max(0, -sin(cycle)) * 3.0 * sy;
    final rightDy = -max(0, -sin(cycle + pi)) * 3.0 * sy;

    const footW = 7.0;
    const footH = 4.0;
    const footR = 2.0;
    const footY = 62.0;

    final footPaint = Paint()
      ..color = const Color(0xFFFF6B35);
    final solePaint = Paint()
      ..color = const Color(0xFFCC5028);

    // Left foot
    canvas.save();
    canvas.translate(20 * sx + leftDx, footY * sy + leftDy);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, footW * sx, footH * sy,
          Radius.circular(footR * sx)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
          0.5 * sx, (footH - 1.2) * sy, (footW - 0.5) * sx,
          footH * sy, Radius.circular(1.0 * sx)),
      solePaint,
    );
    canvas.restore();

    // Right foot
    canvas.save();
    canvas.translate(33 * sx + rightDx, footY * sy + rightDy);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, footW * sx, footH * sy,
          Radius.circular(footR * sx)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
          0.5 * sx, (footH - 1.2) * sy, (footW - 0.5) * sx,
          footH * sy, Radius.circular(1.0 * sx)),
      solePaint,
    );
    canvas.restore();
  }

  double _wobbleAngleForBlock(int i) {
    final rad = _wobblePhase * 2 * pi;
    return switch (i) {
      0 => -1.5 + 1.0 * sin(rad),
      1 => 1.5 - 1.0 * sin(rad * 1.1),
      2 => -1.0 + 0.8 * sin(rad * 1.2),
      _ => 0.8 + 1.2 * sin(rad * 0.9),
    };
  }

  double _wobbleYForBlock(int i) {
    final rad = _wobblePhase * 2 * pi;
    return switch (i) {
      0 => -0.8 * sin(rad),
      1 => -0.5 * sin(rad * 1.1),
      2 => -0.4 * sin(rad * 1.2),
      _ => -0.6 * sin(rad * 0.9),
    };
  }

  /// Plays a throw pose (lean back then snap forward).
  void playThrow() {
    state = RunnerState.throwing;
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(-6, -8),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(6, 8),
          EffectController(duration: 0.15, curve: Curves.easeIn),
        ),
      ]),
    );
  }

  /// Plays a hit-recoil animation when the answer was wrong.
  void playHit() {
    state = RunnerState.hit;
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2(1.15, 0.85),
          EffectController(duration: 0.1),
        ),
        ScaleEffect.to(
          Vector2(1, 1),
          EffectController(duration: 0.2, curve: Curves.bounceOut),
        ),
      ], onComplete: () => state = RunnerState.running),
    );
  }

  /// Victory celebration animation.
  void playCelebration() {
    state = RunnerState.celebrating;
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -45),
          EffectController(duration: 0.3, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, 45),
          EffectController(duration: 0.35, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  /// Defeat slump animation.
  void playDefeat() {
    state = RunnerState.defeated;
    add(
      ScaleEffect.to(
        Vector2(1.2, 0.6),
        EffectController(duration: 0.5, curve: Curves.easeInOut),
      ),
    );
  }
}
