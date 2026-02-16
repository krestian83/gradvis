import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final nunito = GoogleFonts.nunitoTextTheme();
    final fredoka = GoogleFonts.fredokaTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: nunito.copyWith(
        displayLarge: fredoka.displayLarge?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: fredoka.displayMedium?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: fredoka.headlineLarge?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: fredoka.headlineMedium?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: fredoka.headlineSmall?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: fredoka.titleLarge?.copyWith(
          color: AppColors.heading,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: nunito.titleMedium?.copyWith(
          color: AppColors.body,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: nunito.titleSmall?.copyWith(
          color: AppColors.body,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: nunito.bodyLarge?.copyWith(
          color: AppColors.body,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: nunito.bodyMedium?.copyWith(
          color: AppColors.body,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: nunito.bodySmall?.copyWith(
          color: AppColors.subtitle,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: nunito.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
