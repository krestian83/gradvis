import '../domain/math_topic_family.dart';
import 'addition_visualizer.dart';
import 'area_units_visualizer.dart';
import 'division_visualizer.dart';
import 'logic_flow_visualizer.dart';
import 'multiplication_visualizer.dart';
import 'shape_3d_visualizer.dart';
import 'shape_sides_visualizer.dart';
import 'step_sequence_visualizer.dart';
import 'subtraction_visualizer.dart';
import 'unit_choice_visualizer.dart';
import 'visualizer_registry.dart';
import 'volume_units_visualizer.dart';

bool _registered = false;

/// Registers built-in math-help visualizers once at app startup.
void registerBuiltInMathVisualizers([VisualizerRegistry? registry]) {
  final targetRegistry = registry ?? mathVisualizerRegistry;
  if (identical(targetRegistry, mathVisualizerRegistry) && _registered) return;

  targetRegistry.register(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'addition',
    factory: (helpContext) => AdditionVisualizer(context: helpContext),
  );
  targetRegistry.register(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'subtraction',
    factory: (helpContext) => SubtractionVisualizer(context: helpContext),
  );
  targetRegistry.register(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'multiplication',
    factory: (helpContext) => MultiplicationVisualizer(context: helpContext),
  );
  targetRegistry.register(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'division',
    factory: (helpContext) => DivisionVisualizer(context: helpContext),
  );

  const shapeSidesOperations = [
    'triangleSides',
    'squareSides',
    'rectangleSides',
    'circleSides',
    'pentagonSides',
    'hexagonSides',
  ];

  for (final operation in shapeSidesOperations) {
    targetRegistry.register(
      topicFamily: MathTopicFamily.geometry,
      operation: operation,
      factory: (helpContext) => ShapeSidesVisualizer(context: helpContext),
    );
  }

  const shape3dOperations = [
    'cubeFaces',
    'cubeEdges',
    'cylinderFaces',
    'sphereFaces',
    'pyramidFaces',
    'pyramidEdges',
    'coneFaces',
  ];

  for (final operation in shape3dOperations) {
    targetRegistry.register(
      topicFamily: MathTopicFamily.geometry,
      operation: operation,
      factory: (helpContext) => Shape3DVisualizer(context: helpContext),
    );
  }

  const measurementOperations = ['areaUnits', 'volumeUnits', 'unitChoice'];

  for (final operation in measurementOperations) {
    targetRegistry.register(
      topicFamily: MathTopicFamily.measurement,
      operation: operation,
      factory: (helpContext) {
        switch (operation) {
          case 'areaUnits':
            return AreaUnitsVisualizer(context: helpContext);
          case 'volumeUnits':
            return VolumeUnitsVisualizer(context: helpContext);
          case 'unitChoice':
            return UnitChoiceVisualizer(context: helpContext);
        }
        return UnitChoiceVisualizer(context: helpContext);
      },
    );
  }

  const algorithmicOperations = ['stepSequence', 'logicFlow'];

  for (final operation in algorithmicOperations) {
    targetRegistry.register(
      topicFamily: MathTopicFamily.algorithmicThinking,
      operation: operation,
      factory: (helpContext) {
        switch (operation) {
          case 'stepSequence':
            return StepSequenceVisualizer(context: helpContext);
          case 'logicFlow':
            return LogicFlowVisualizer(context: helpContext);
        }
        return StepSequenceVisualizer(context: helpContext);
      },
    );
  }

  if (identical(targetRegistry, mathVisualizerRegistry)) {
    _registered = true;
  }
}
