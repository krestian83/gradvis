import 'package:flutter/material.dart';

import '../constants/avatar_colors.dart';

/// Circular emoji avatar with deterministic gradient background.
class AvatarCircle extends StatelessWidget {
  final String emoji;
  final double size;

  const AvatarCircle({super.key, required this.emoji, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final (a, b) = gradientForEmoji(emoji);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, b],
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
