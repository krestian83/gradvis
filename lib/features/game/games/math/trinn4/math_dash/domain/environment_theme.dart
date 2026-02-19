import 'dart:ui';

/// Visual theme for each biome section of the Math Dash runner.
enum EnvironmentTheme {
  meadow(
    skyTop: Color(0xFF87CEEB),
    skyBottom: Color(0xFFD4F1F9),
    groundColor: Color(0xFF4CAF50),
    groundAccent: Color(0xFF388E3C),
    farColor: Color(0xFFA5D6A7),
    midColor: Color(0xFF66BB6A),
    nearColor: Color(0xFF43A047),
  ),
  beach(
    skyTop: Color(0xFF29B6F6),
    skyBottom: Color(0xFFB3E5FC),
    groundColor: Color(0xFFF9E4B7),
    groundAccent: Color(0xFFE8C97A),
    farColor: Color(0xFF4FC3F7),
    midColor: Color(0xFF039BE5),
    nearColor: Color(0xFFF9E4B7),
  ),
  snow(
    skyTop: Color(0xFFB0BEC5),
    skyBottom: Color(0xFFECEFF1),
    groundColor: Color(0xFFE8EAF6),
    groundAccent: Color(0xFFC5CAE9),
    farColor: Color(0xFFCFD8DC),
    midColor: Color(0xFFB0BEC5),
    nearColor: Color(0xFFE0E0E0),
  ),
  volcano(
    skyTop: Color(0xFF1A0033),
    skyBottom: Color(0xFF4A148C),
    groundColor: Color(0xFF424242),
    groundAccent: Color(0xFF616161),
    farColor: Color(0xFF311B92),
    midColor: Color(0xFF4A148C),
    nearColor: Color(0xFF3E2723),
  );

  const EnvironmentTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.groundColor,
    required this.groundAccent,
    required this.farColor,
    required this.midColor,
    required this.nearColor,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color groundColor;
  final Color groundAccent;
  final Color farColor;
  final Color midColor;
  final Color nearColor;
}
