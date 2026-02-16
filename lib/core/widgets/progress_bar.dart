import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated horizontal progress bar.
class ProgressBar extends StatelessWidget {
  final double fraction;
  final double height;
  final Color? color;
  final Color? colorEnd;

  const ProgressBar({
    super.key,
    required this.fraction,
    this.height = 10,
    this.color,
    this.colorEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.orange;
    final cEnd = colorEnd ?? c.withValues(alpha: 0.8);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(height),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0, 1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c, cEnd]),
            borderRadius: BorderRadius.circular(height),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
