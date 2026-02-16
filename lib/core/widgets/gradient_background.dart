import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'background_circles.dart';

/// Peach vertical gradient with decorative circles, used as the
/// root scaffold wrapper for every screen.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgTop,
              AppColors.bgUpperMid,
              AppColors.bgLowerMid,
              AppColors.bgBottom,
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const BackgroundCircles(),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
