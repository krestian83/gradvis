import 'dart:math';

import 'package:flutter/material.dart';

/// Animated logo text that mirrors the provided GradVis text spec.
class GradVisTitle extends StatefulWidget {
  const GradVisTitle({super.key});

  @override
  State<GradVisTitle> createState() => _GradVisTitleState();
}

class _GradVisTitleState extends State<GradVisTitle>
    with SingleTickerProviderStateMixin {
  static const _scale = 2.0;
  static const _fontSize = 34.0 * _scale;
  static const _glassesSize = Size(28 * _scale, 13 * _scale);
  static const _glassesTop = 12.0 * _scale;
  static const _sparkleTop = 2.0 * _scale;
  static const _sparkleFontSize = 10.0 * _scale;

  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1A1B2E);
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
    );

    const baseStyle = TextStyle(
      fontFamily: 'Fredoka One',
      fontSize: _fontSize,
      color: textColor,
      letterSpacing: -0.5,
      shadows: [
        Shadow(color: Color(0x142D3047), offset: Offset(0, 2), blurRadius: 8),
      ],
    );

    const textScaler = TextScaler.noScaling;
    final direction = Directionality.of(context);

    final metricsPainter = TextPainter(
      text: TextSpan(text: 'GradV\u0131s', style: baseStyle),
      textDirection: direction,
      textScaler: textScaler,
    )..layout();

    final vBox = _charBox(metricsPainter, 4);
    final dotlessIBox = _charBox(metricsPainter, 5);
    final sBox = _charBox(metricsPainter, 6);

    final vGradient = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(vBox.left, 0, vBox.width, _fontSize),
      );
    final dotlessIGradient = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(dotlessIBox.left, 0, dotlessIBox.width, _fontSize),
      );
    final sGradient = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(sBox.left, 0, sBox.width, _fontSize),
      );

    final textSpan = TextSpan(
      children: [
        TextSpan(text: 'Grad', style: baseStyle),
        TextSpan(
          text: 'V',
          style: baseStyle.copyWith(foreground: vGradient),
        ),
        TextSpan(
          text: '\u0131',
          style: baseStyle.copyWith(foreground: dotlessIGradient),
        ),
        TextSpan(
          text: 's',
          style: baseStyle.copyWith(foreground: sGradient),
        ),
      ],
    );

    final sparklePainter = TextPainter(
      text: const TextSpan(
        text: '\u2728',
        style: TextStyle(fontSize: _sparkleFontSize),
      ),
      textDirection: direction,
      textScaler: textScaler,
    )..layout();

    final glassesLeft = vBox.left + ((vBox.width - _glassesSize.width) / 2);
    final sparkleLeft =
        dotlessIBox.left + (dotlessIBox.width / 2) - (sparklePainter.width / 2);

    final contentHeight = [
      metricsPainter.height,
      _glassesTop + _glassesSize.height,
      _sparkleTop + sparklePainter.height,
    ].reduce(max);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        width: metricsPainter.width,
        height: contentHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RichText(text: textSpan, textScaler: textScaler),
            Positioned(
              left: glassesLeft,
              top: _glassesTop,
              child: CustomPaint(
                size: _glassesSize,
                painter: const _GlassesPainter(),
              ),
            ),
            Positioned(
              left: sparkleLeft,
              top: _sparkleTop,
              child: AnimatedBuilder(
                animation: _sparkleController,
                child: const Text(
                  '\u2728',
                  style: TextStyle(fontSize: _sparkleFontSize),
                ),
                builder: (context, child) {
                  final frame = _starFloatFrame(_sparkleController.value);
                  return Transform.translate(
                    offset: Offset(0, frame.dy),
                    child: Transform.rotate(
                      angle: frame.angleDeg * (pi / 180),
                      child: Opacity(opacity: frame.opacity, child: child),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Rect _charBox(TextPainter painter, int index) {
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + 1),
    );
    return boxes.first.toRect();
  }

  _StarFloatFrame _starFloatFrame(double t) {
    if (t <= 0.5) {
      final p = Curves.easeInOut.transform(t * 2);
      return _StarFloatFrame(
        dy: _lerp(0, -3 * _scale, p),
        angleDeg: _lerp(0, 15, p),
        opacity: _lerp(0.8, 0.4, p),
      );
    }

    final p = Curves.easeInOut.transform((t - 0.5) * 2);
    return _StarFloatFrame(
      dy: _lerp(-3 * _scale, 0, p),
      angleDeg: _lerp(15, 0, p),
      opacity: _lerp(0.4, 0.8, p),
    );
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}

class _StarFloatFrame {
  const _StarFloatFrame({
    required this.dy,
    required this.angleDeg,
    required this.opacity,
  });

  final double dy;
  final double angleDeg;
  final double opacity;
}

/// Paints the exact glasses shape from the provided SVG.
class _GlassesPainter extends CustomPainter {
  const _GlassesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 22;
    final sy = size.height / 10;

    final framePaint = Paint()
      ..color = const Color(0xFF3D2B30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * sx;

    final lensTintPaint = Paint()
      ..color = const Color(0x40C8E6FF)
      ..style = PaintingStyle.fill;

    final pupilPaint = Paint()
      ..color = const Color(0xFF3D2B30)
      ..style = PaintingStyle.fill;

    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const lensR = 4.2;
    final leftLensCenter = Offset(5.5 * sx, 5 * sy);
    final rightLensCenter = Offset(16.5 * sx, 5 * sy);

    canvas.drawCircle(leftLensCenter, lensR * sx, lensTintPaint);
    canvas.drawCircle(rightLensCenter, lensR * sx, lensTintPaint);
    canvas.drawCircle(leftLensCenter, lensR * sx, framePaint);
    canvas.drawCircle(rightLensCenter, lensR * sx, framePaint);

    final bridgePaint = Paint()
      ..color = const Color(0xFF3D2B30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * sx;
    final bridgePath = Path()
      ..moveTo(9.7 * sx, 5 * sy)
      ..cubicTo(10.3 * sx, 3.8 * sy, 11.7 * sx, 3.8 * sy, 12.3 * sx, 5 * sy);
    canvas.drawPath(bridgePath, bridgePaint);

    canvas.drawCircle(Offset(5.5 * sx, 5.2 * sy), 1.8 * sx, pupilPaint);
    canvas.drawCircle(Offset(6.2 * sx, 4.4 * sy), 0.6 * sx, glintPaint);
    canvas.drawCircle(Offset(16.5 * sx, 5.2 * sy), 1.8 * sx, pupilPaint);
    canvas.drawCircle(Offset(17.2 * sx, 4.4 * sy), 0.6 * sx, glintPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassesPainter oldDelegate) => false;
}
