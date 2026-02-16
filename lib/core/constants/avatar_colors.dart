import 'dart:ui';

/// 10 gradient pairs for avatar backgrounds.
const avatarGradients = [
  (Color(0xFFFF6B35), Color(0xFFFF3366)), // orange -> pink
  (Color(0xFFFF3366), Color(0xFFFF6B8A)), // pink -> light pink
  (Color(0xFF7B2FF7), Color(0xFF9B5FF8)), // purple -> light purple
  (Color(0xFF00B4D8), Color(0xFF48CAE4)), // cyan -> light cyan
  (Color(0xFF2ED573), Color(0xFF7BED9F)), // green -> light green
  (Color(0xFFFFB627), Color(0xFFFFCF56)), // gold -> light gold
  (Color(0xFFFF4757), Color(0xFFFF6B81)), // red -> light red
  (Color(0xFF3742FA), Color(0xFF5352ED)), // blue -> indigo
  (Color(0xFFFF9FF3), Color(0xFFF368E0)), // pink -> magenta
  (Color(0xFF00D2D3), Color(0xFF54E4C7)), // teal -> mint
];

/// Deterministic gradient for a given emoji string.
(Color, Color) gradientForEmoji(String emoji) {
  var hash = 0;
  for (var i = 0; i < emoji.length; i++) {
    hash = ((hash << 5) - hash) + emoji.codeUnitAt(i);
  }
  return avatarGradients[hash.abs() % avatarGradients.length];
}
