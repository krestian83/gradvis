import 'dart:math';

import 'package:flutter/material.dart';

/// Animated 4-block pyramid logo with wobble + bounce animations.
/// Shows blocks 1...[maxTrinn] (1 = bottom coral, 4 = top yellow).
class AnimatedGradVisLogo extends StatefulWidget {
  final int maxTrinn;
  final double scale;

  const AnimatedGradVisLogo({super.key, this.maxTrinn = 4, this.scale = 1.0});

  @override
  State<AnimatedGradVisLogo> createState() => _AnimatedGradVisLogoState();
}

class _AnimatedGradVisLogoState extends State<AnimatedGradVisLogo>
    with TickerProviderStateMixin {
  late final List<AnimationController> _wobbleControllers;
  late final AnimationController _bounceController;

  static const _durations = [
    Duration(milliseconds: 5000),
    Duration(milliseconds: 4500),
    Duration(milliseconds: 5200),
    Duration(milliseconds: 4800),
  ];

  @override
  void initState() {
    super.initState();
    _wobbleControllers = List.generate(4, (i) {
      return AnimationController(vsync: this, duration: _durations[i])
        ..repeat();
    });
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    for (final c in _wobbleControllers) {
      c.dispose();
    }
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return SizedBox(
      width: 195 * s,
      height: 210 * s,
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          final bounceVal = sin(_bounceController.value * 2 * pi) * 0.015;
          return Transform(
            alignment: Alignment(0, 1),
            // ignore: deprecated_member_use
            transform: Matrix4.identity()..scale(1.0, 1.0 + bounceVal),
            child: child,
          );
        },
        child: CustomPaint(
          size: Size(195 * s, 210 * s),
          painter: _LogoPainter(
            maxTrinn: widget.maxTrinn,
            wobbleControllers: _wobbleControllers,
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final int maxTrinn;
  final List<AnimationController> wobbleControllers;

  _LogoPainter({required this.maxTrinn, required this.wobbleControllers})
    : super(repaint: Listenable.merge(wobbleControllers));

  // Block data: [gradA, gradB, nubColor, rect, highlight, leftNub, rightNub,
  //   leftEye, rightEye, smile, numberPos, fontSize, wobbleAmplitudes]
  static const _blockGradients = [
    [Color(0xFFFF6B35), Color(0xFFFF3366), Color(0xFFFF7E4A)],
    [Color(0xFF00B4D8), Color(0xFF48CAE4), Color(0xFF18B5E0)],
    [Color(0xFF7B2FF7), Color(0xFF9B5FF8), Color(0xFF8B42F7)],
    [Color(0xFFFFB627), Color(0xFFFFCF56), Color(0xFFF5A623)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 160;
    final sy = size.height / 180;

    for (var i = 0; i < maxTrinn.clamp(0, 4); i++) {
      _drawBlock(canvas, i, sx, sy);
    }
  }

  void _drawBlock(Canvas canvas, int index, double sx, double sy) {
    // Wobble transform
    final t = wobbleControllers[index].value;
    final wobbleAngle = _wobbleAngle(index, t);
    final wobbleY = _wobbleTranslateY(index, t);

    canvas.save();

    // Pivot point per block
    final pivotX = 80 * sx;
    final pivotY = [150, 106, 65, 32][index] * sy;
    canvas.translate(pivotX, pivotY);
    canvas.rotate(wobbleAngle * pi / 180);
    canvas.translate(0, wobbleY * sy);
    canvas.translate(-pivotX, -pivotY);

    final colors = _blockGradients[index];

    // Block rect params
    final rects = [
      [24.0, 128.0, 112.0, 44.0, 10.0],
      [34.0, 86.0, 92.0, 40.0, 9.0],
      [44.0, 46.0, 72.0, 38.0, 8.0],
      [56.0, 14.0, 48.0, 36.0, 8.0],
    ];
    final r = rects[index];
    final rect = RRect.fromLTRBR(
      r[0] * sx,
      r[1] * sy,
      (r[0] + r[2]) * sx,
      (r[1] + r[3]) * sy,
      Radius.circular(r[4] * sx),
    );

    // Gradient fill
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
      [28.0, 131.0, 104.0, 6.0, 3.0],
      [38.0, 89.0, 84.0, 5.0, 2.5],
      [48.0, 49.0, 64.0, 5.0, 2.5],
      [60.0, 17.0, 40.0, 4.0, 2.0],
    ];
    final h = hls[index];
    canvas.drawRRect(
      RRect.fromLTRBR(
        h[0] * sx,
        h[1] * sy,
        (h[0] + h[2]) * sx,
        (h[1] + h[3]) * sy,
        Radius.circular(h[4] * sx),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Nubs
    final nubs = [
      [
        [44.0, 120.0, 20.0, 14.0, 6.0],
        [96.0, 120.0, 20.0, 14.0, 6.0],
      ],
      [
        [52.0, 79.0, 16.0, 12.0, 5.0],
        [92.0, 79.0, 16.0, 12.0, 5.0],
      ],
      [
        [58.0, 39.0, 14.0, 12.0, 5.0],
        [88.0, 39.0, 14.0, 12.0, 5.0],
      ],
      [
        [66.0, 8.0, 12.0, 10.0, 4.0],
        [82.0, 8.0, 12.0, 10.0, 4.0],
      ],
    ];
    final nubPaint = Paint()..color = colors[2];
    for (final n in nubs[index]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          n[0] * sx,
          n[1] * sy,
          (n[0] + n[2]) * sx,
          (n[1] + n[3]) * sy,
          Radius.circular(n[4] * sx),
        ),
        nubPaint,
      );
    }

    // Eyes
    const pupilColor = Color(0xFF3D2B30);
    final eyes = [
      [
        [44.0, 153.0, 4.0, 2.2, 45.2, 152.0, 0.9],
        [116.0, 153.0, 4.0, 2.2, 117.2, 152.0, 0.9],
      ],
      [
        [50.0, 110.0, 3.5, 1.9, 51.0, 109.0, 0.8],
        [110.0, 110.0, 3.5, 1.9, 111.0, 109.0, 0.8],
      ],
      [
        [57.0, 70.0, 3.0, 1.7, 57.8, 69.2, 0.7],
        [103.0, 70.0, 3.0, 1.7, 103.8, 69.2, 0.7],
      ],
      [
        [68.0, 37.0, 2.8, 1.5, 68.7, 36.3, 0.65],
        [92.0, 37.0, 2.8, 1.5, 92.7, 36.3, 0.65],
      ],
    ];
    final whiteEye = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final pupilPaint = Paint()..color = pupilColor;
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);

    for (final e in eyes[index]) {
      canvas.drawCircle(Offset(e[0] * sx, e[1] * sy), e[2] * sx, whiteEye);
      canvas.drawCircle(Offset(e[0] * sx, e[1] * sy), e[3] * sx, pupilPaint);
      canvas.drawCircle(
        Offset(e[4] * sx, e[5] * sy),
        e[6] * sx,
        highlightPaint,
      );
    }

    // Smile
    final smiles = [
      [72.0, 159.0, 74.5, 163.0, 85.5, 163.0, 88.0, 159.0, 2.0],
      [73.0, 115.0, 75.0, 118.0, 85.0, 118.0, 87.0, 115.0, 1.8],
      [74.0, 75.0, 75.5, 77.5, 84.5, 77.5, 86.0, 75.0, 1.6],
      [75.0, 41.5, 76.5, 43.5, 83.5, 43.5, 85.0, 41.5, 1.5],
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
        sm[2] * sx,
        sm[3] * sy,
        sm[4] * sx,
        sm[5] * sy,
        sm[6] * sx,
        sm[7] * sy,
      );
    canvas.drawPath(path, smilePaint);

    // Number
    final nums = [
      [80.0, 148.0, 20.0],
      [80.0, 102.0, 18.0],
      [80.0, 62.0, 16.0],
      [80.0, 30.0, 15.0],
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

  double _wobbleAngle(int i, double t) {
    final rad = t * 2 * pi;
    return switch (i) {
      0 => -2 + 1.5 * sin(rad) + 0.5 * sin(rad * 2),
      1 => 2.5 - 1.5 * sin(rad * 1.1) + sin(rad * 0.6),
      2 => -1.5 - 1.5 * sin(rad * 0.8) + 0.5 * sin(rad * 1.4),
      _ => 1 + 2 * sin(rad * 0.9) - sin(rad * 1.7),
    };
  }

  double _wobbleTranslateY(int i, double t) {
    final rad = t * 2 * pi;
    return switch (i) {
      0 => -1.5 * sin(rad) + 0.5 * cos(rad * 2),
      1 => -sin(rad * 1.2) + 0.5 * cos(rad * 0.7),
      2 => -sin(rad * 0.9) + 0.5 * cos(rad * 1.3),
      _ => -2 * sin(rad * 1.1) + 0.5 * cos(rad * 0.8),
    };
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.maxTrinn != maxTrinn;
}
