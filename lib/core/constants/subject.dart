import 'dart:ui';

enum Subject {
  reading,
  math,
  english,
  science;

  String get displayName => switch (this) {
    Subject.reading => 'Norsk',
    Subject.math => 'Matte',
    Subject.english => 'Engelsk',
    Subject.science => 'Naturfag',
  };

  String get icon => switch (this) {
    Subject.reading => '📖',
    Subject.math => '🔢',
    Subject.english => '🇬🇧',
    Subject.science => '🔬',
  };

  Color get color => switch (this) {
    Subject.reading => const Color(0xFFFF3366),
    Subject.math => const Color(0xFF00B4D8),
    Subject.english => const Color(0xFF7B2FF7),
    Subject.science => const Color(0xFFFFB627),
  };

  Color get colorB => switch (this) {
    Subject.reading => const Color(0xFFFF6B8A),
    Subject.math => const Color(0xFF48CAE4),
    Subject.english => const Color(0xFF9B5FF8),
    Subject.science => const Color(0xFFFFCF56),
  };

  Color get hoverColor => switch (this) {
    Subject.reading => const Color(0xFFE6204E),
    Subject.math => const Color(0xFF0096C7),
    Subject.english => const Color(0xFF6311E0),
    Subject.science => const Color(0xFFE5A000),
  };

  Color get lightBg => switch (this) {
    Subject.reading => const Color(0xFFFFE0EA),
    Subject.math => const Color(0xFFD6F0F8),
    Subject.english => const Color(0xFFEDE0FF),
    Subject.science => const Color(0xFFFFF3D6),
  };

  Color get shadowColor => switch (this) {
    Subject.reading => const Color(0x40FF3366),
    Subject.math => const Color(0x4000B4D8),
    Subject.english => const Color(0x407B2FF7),
    Subject.science => const Color(0x40FFB627),
  };
}
