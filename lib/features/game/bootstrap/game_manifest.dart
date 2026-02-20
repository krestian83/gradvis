import '../domain/game_interface.dart';
import '../../../core/constants/subject.dart';

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
    id: 'math_trinn4_level0_multiplication_table_sprint',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 0),
    factoryKey: 'multiplication_table_sprint',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn4_level1_addition_bridge_builder',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 1),
    factoryKey: 'addition_bridge_builder',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn4_level2_subtraction_target_trek',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 2),
    factoryKey: 'subtraction_target_trek',
    enabled: true,
  ),
  GameManifestEntry(
    id: 'math_trinn4_level3_number_storm_sprint',
    slot: GameSlot(subject: Subject.math, trinn: 4, level: 3),
    factoryKey: 'number_storm_sprint',
    enabled: true,
  ),
  // [MINIGAME_MANIFEST_END]
];
