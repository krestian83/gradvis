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
    id: 'math_trinn1_level0_addition_quiz',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 0),
    factoryKey: 'addition_quiz',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level1_subtraction_quiz',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 1),
    factoryKey: 'subtraction_quiz',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn1_level2_subtraction_quiz',
    slot: GameSlot(subject: Subject.math, trinn: 1, level: 2),
    factoryKey: 'subtraction_quiz',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn4_level0_addition_quiz_trinn4',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 0),
    factoryKey: 'addition_quiz_trinn4',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn4_level1_subtraction_quiz_trinn4',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 1),
    factoryKey: 'subtraction_quiz_trinn4',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn3_level0_multiplication_quiz_trinn3',
    slot: GameSlot(subject: Subject.math, trinn: 3, level: 0),
    factoryKey: 'multiplication_quiz_trinn3',
    enabled: true,
  ),
  // [MINIGAME_MANIFEST_END]
];
