import '../domain/game_interface.dart';
// [MINIGAME_IMPORTS_START]
// [MINIGAME_IMPORTS_END]

// [MINIGAME_FACTORY_KEYS_START]
// [MINIGAME_FACTORY_KEYS_END]

final Map<String, GameFactory> builtInGameFactories = {
  // [MINIGAME_FACTORIES_START]
  // [MINIGAME_FACTORIES_END]
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
