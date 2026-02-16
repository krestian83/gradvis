import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays 0–3 filled/empty stars.
class StarDisplay extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;

  const StarDisplay({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.08),
          child: Icon(
            Icons.star_rounded,
            size: size,
            color: i < stars ? AppColors.starFilled : AppColors.starEmpty,
          ),
        );
      }),
    );
  }
}
