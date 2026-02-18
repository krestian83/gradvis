import '../domain/game_interface.dart';
// [MINIGAME_IMPORTS_START]
import '../games/math/trinn1/addition_quiz/presentation/addition_quiz_game.dart';
import '../games/math/trinn1/subtraction_quiz/presentation/subtraction_quiz_game.dart';
import '../games/math/trinn4/addition_quiz_trinn4/presentation/addition_quiz_trinn4_game.dart';
import '../games/math/trinn4/subtraction_quiz_trinn4/presentation/subtraction_quiz_trinn4_game.dart';
import '../games/math/trinn3/multiplication_quiz_trinn3/presentation/multiplication_quiz_trinn3_game.dart';
// [MINIGAME_IMPORTS_END]

// [MINIGAME_FACTORY_KEYS_START]
const additionQuizFactoryKey = 'addition_quiz';
const subtractionQuizFactoryKey = 'subtraction_quiz';
const additionQuizTrinn4FactoryKey = 'addition_quiz_trinn4';
const subtractionQuizTrinn4FactoryKey = 'subtraction_quiz_trinn4';
const multiplicationQuizTrinn3FactoryKey = 'multiplication_quiz_trinn3';
// [MINIGAME_FACTORY_KEYS_END]

final Map<String, GameFactory> builtInGameFactories = {
  // [MINIGAME_FACTORIES_START]
  additionQuizFactoryKey: ({required onComplete}) =>
      AdditionQuizGame(onComplete: onComplete),
  subtractionQuizFactoryKey: ({required onComplete}) =>
      SubtractionQuizGame(onComplete: onComplete),
  additionQuizTrinn4FactoryKey: ({required onComplete}) =>
      AdditionQuizTrinn4Game(onComplete: onComplete),
  subtractionQuizTrinn4FactoryKey: ({required onComplete}) =>
      SubtractionQuizTrinn4Game(onComplete: onComplete),
  multiplicationQuizTrinn3FactoryKey: ({required onComplete}) =>
      MultiplicationQuizTrinn3Game(onComplete: onComplete),
  // [MINIGAME_FACTORIES_END]
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
