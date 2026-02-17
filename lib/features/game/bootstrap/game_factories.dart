import '../domain/game_interface.dart';
// [MINIGAME_IMPORTS_START]
import '../games/reading/trinn1/alphabet_sound_quiz/presentation/alphabet_sound_quiz_game.dart';
// [MINIGAME_IMPORTS_END]

// [MINIGAME_FACTORY_KEYS_START]
const alphabetSoundQuizFactoryKey = 'alphabet_sound_quiz';
// [MINIGAME_FACTORY_KEYS_END]

final Map<String, GameFactory> builtInGameFactories = {
  // [MINIGAME_FACTORIES_START]
  alphabetSoundQuizFactoryKey: ({required onComplete}) =>
      AlphabetSoundQuizGame(onComplete: onComplete),
  // [MINIGAME_FACTORIES_END]
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
