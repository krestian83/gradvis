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
  // [MINIGAME_MANIFEST_END]
];
