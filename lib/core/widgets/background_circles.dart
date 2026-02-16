import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Three decorative semi-transparent circles matching the prototype.
class BackgroundCircles extends StatelessWidget {
  const BackgroundCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        // Orange circle — top-right
        Positioned(
          top: 40,
          right: -25,
          child: _Circle(size: 90, color: AppColors.circleOrange),
        ),
        // Green circle — bottom-left
        Positioned(
          bottom: 120,
          left: -30,
          child: _Circle(size: 80, color: AppColors.circleGreen),
        ),
        // Gold circle — mid-right
        Positioned(
          top: 0,
          bottom: 0,
          right: 20,
          child: Center(child: _Circle(size: 50, color: AppColors.circleGold)),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;

  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
