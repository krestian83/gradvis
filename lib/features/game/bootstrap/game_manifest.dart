import '../../../core/constants/subject.dart';
import '../domain/game_interface.dart';

/// Describes a built-in mini-game slot mapping.
class GameManifestEntry {
  final String id;
  final GameSlot slot;
  final bool enabled;
  final String factoryKey;

  const GameManifestEntry({
    required this.id,
    required this.slot,
    required this.factoryKey,
    this.enabled = true,
  });
}

/// Data-driven list of bundled mini-games.
const List<GameManifestEntry> builtInGameManifest = [
  // [MINIGAME_MANIFEST_START]
  GameManifestEntry(
    id: 'reading_trinn1_level0_alphabet_sound_quiz',
    slot: GameSlot(subject: Subject.reading, trinn: 1, level: 0),
    factoryKey: 'alphabet_sound_quiz',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level0_math_helper_demo',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 0),
    factoryKey: 'math_helper_demo',
    enabled: false,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level1_math_helper_showcase',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 1),
    factoryKey: 'math_helper_showcase',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level0_addition_quiz',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 0),
    factoryKey: 'addition_quiz',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level2_subtraction_quiz',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 2),
    factoryKey: 'subtraction_quiz',
    enabled: true,
  ),
  // [MINIGAME_MANIFEST_END]
];
