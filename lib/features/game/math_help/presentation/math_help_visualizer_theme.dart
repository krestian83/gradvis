import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const mathHelpVisualizerBackgroundColor = Color(0xFFF5F5F5);

TextPaint mathHelpTextPaint({
  Color color = const Color(0xFF13315C),
  double fontSize = 32,
  FontWeight fontWeight = FontWeight.w800,
}) {
  final resolvedFontSize = (fontSize < 28 ? 28 : fontSize).toDouble();
  return TextPaint(
    style: TextStyle(
      color: color,
      fontSize: resolvedFontSize,
      fontWeight: fontWeight,
      fontFamily: 'Fredoka One',
    ),
  );
}
