import '../domain/game_registry.dart';
import 'game_factories.dart';
import 'game_manifest.dart';

bool _registered = false;

/// Registers all bundled mini-games once at app startup.
void registerBuiltInGames() {
  if (_registered) return;
  final issues = _validateManifest();
  if (issues.isNotEmpty) {
    throw StateError(
      'Invalid game manifest:\n${issues.map((i) => '- $i').join('\n')}',
    );
  }

  for (final entry in builtInGameManifest.where((entry) => entry.enabled)) {
    final factory = lookupBuiltInGameFactory(entry.factoryKey)!;
    GameRegistry.instance.register(entry.slot, factory);
  }

  _registered = true;
}

List<String> _validateManifest() {
  final issues = <String>[];

  final seenIds = <String>{};
  for (final entry in builtInGameManifest) {
    if (!seenIds.add(entry.id)) {
      issues.add('Duplicate game id "${entry.id}"');
    }
  }

  final seenSlots = <Object>{};
  for (final entry in builtInGameManifest.where((entry) => entry.enabled)) {
    if (!seenSlots.add(entry.slot)) {
      issues.add(
        'Duplicate enabled slot ${entry.slot.subject.name}/'
        'trinn${entry.slot.trinn}/level${entry.slot.level}',
      );
    }
  }

  for (final entry in builtInGameManifest.where((entry) => entry.enabled)) {
    if (lookupBuiltInGameFactory(entry.factoryKey) == null) {
      issues.add(
        'Unknown factory key "${entry.factoryKey}" for game id "${entry.id}"',
      );
    }
  }

  return issues;
}
