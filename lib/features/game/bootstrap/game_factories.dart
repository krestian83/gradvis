import '../domain/game_interface.dart';
// [MINIGAME_IMPORTS_START]
import '../games/reading/trinn1/alphabet_sound_quiz/presentation/alphabet_sound_quiz_game.dart';
import '../games/math/trinn1/math_helper_demo/presentation/math_helper_demo_game.dart';
import '../games/math/trinn1/math_helper_showcase/presentation/math_helper_showcase_game.dart';
import '../games/math/trinn1/addition_quiz/presentation/addition_quiz_game.dart';
// [MINIGAME_IMPORTS_END]

// [MINIGAME_FACTORY_KEYS_START]
const alphabetSoundQuizFactoryKey = 'alphabet_sound_quiz';
const mathHelperDemoFactoryKey = 'math_helper_demo';
const mathHelperShowcaseFactoryKey = 'math_helper_showcase';
const additionQuizFactoryKey = 'addition_quiz';
// [MINIGAME_FACTORY_KEYS_END]

final Map<String, GameFactory> builtInGameFactories = {
  // [MINIGAME_FACTORIES_START]
  alphabetSoundQuizFactoryKey: ({required onComplete}) =>
      AlphabetSoundQuizGame(onComplete: onComplete),
  mathHelperDemoFactoryKey: ({required onComplete}) =>
      MathHelperDemoGame(onComplete: onComplete),
  mathHelperShowcaseFactoryKey: ({required onComplete}) =>
      MathHelperShowcaseGame(onComplete: onComplete),
  additionQuizFactoryKey: ({required onComplete}) =>
      AdditionQuizGame(onComplete: onComplete),
  // [MINIGAME_FACTORIES_END]
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
