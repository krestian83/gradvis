import '../domain/game_interface.dart';
// [MINIGAME_IMPORTS_START]
import '../games/math/trinn4/multiplication_table_sprint/presentation/multiplication_table_sprint_game.dart';
import '../games/math/trinn4/addition_bridge_builder/presentation/addition_bridge_builder_game.dart';
import '../games/math/trinn4/subtraction_target_trek/presentation/subtraction_target_trek_game.dart';
import '../games/math/trinn4/number_runner/presentation/number_runner_game.dart';
import '../games/math/trinn4/division_dash/presentation/division_dash_game.dart';
// [MINIGAME_IMPORTS_END]

// [MINIGAME_FACTORY_KEYS_START]
const multiplicationTableSprintFactoryKey = 'multiplication_table_sprint';
const additionBridgeBuilderFactoryKey = 'addition_bridge_builder';
const subtractionTargetTrekFactoryKey = 'subtraction_target_trek';
const numberRunnerFactoryKey = 'number_runner';
const divisionDashFactoryKey = 'division_dash';
// [MINIGAME_FACTORY_KEYS_END]

final Map<String, GameFactory> builtInGameFactories = {
  // [MINIGAME_FACTORIES_START]
  multiplicationTableSprintFactoryKey: ({required onComplete}) =>
      MultiplicationTableSprintGame(onComplete: onComplete),
  additionBridgeBuilderFactoryKey: ({required onComplete}) =>
      AdditionBridgeBuilderGame(onComplete: onComplete),
  subtractionTargetTrekFactoryKey: ({required onComplete}) =>
      SubtractionTargetTrekGame(onComplete: onComplete),
  numberRunnerFactoryKey: ({required onComplete}) =>
      NumberRunnerGame(onComplete: onComplete),
  divisionDashFactoryKey: ({required onComplete}) =>
      DivisionDashGame(onComplete: onComplete),
  // [MINIGAME_FACTORIES_END]
};

GameFactory? lookupBuiltInGameFactory(String key) => builtInGameFactories[key];
