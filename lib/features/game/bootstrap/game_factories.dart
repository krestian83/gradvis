import '../domain/game_interface.dart';
import '../games/reading/trinn1/alphabet_sound_quiz/presentation/alphabet_sound_quiz_game.dart';

const alphabetSoundQuizFactoryKey = 'alphabet_sound_quiz';

final Map<String, GameFactory> builtInGameFactories = {
  alphabetSoundQuizFactoryKey: ({required onComplete}) =>
      AlphabetSoundQuizGame(onComplete: onComplete),
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
