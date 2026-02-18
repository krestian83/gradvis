import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/register_builtin_math_visualizers.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/visualizer_registry.dart';

class _FakeVisualizer extends MathVisualizer {
  _FakeVisualizer({required super.context});
}

void main() {
  final context = MathHelpContext(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'addition',
    operands: const [2, 5],
    correctAnswer: 7,
  );

  test('registers and looks up visualizer factories', () {
    final registry = VisualizerRegistry();

    registry.register(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'addition',
      factory: (helpContext) => _FakeVisualizer(context: helpContext),
    );

    final factory = registry.lookup(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'addition',
    );
    final visualizer = registry.create(context);

    expect(factory, isNotNull);
    expect(visualizer, isA<_FakeVisualizer>());
  });

  test('returns null for missing keys', () {
    final registry = VisualizerRegistry();

    final factory = registry.lookup(
      topicFamily: MathTopicFamily.measurement,
      operation: 'volume',
    );
    final visualizer = registry.create(
      MathHelpContext(
        topicFamily: MathTopicFamily.measurement,
        operation: 'volume',
        operands: const [1, 2, 3],
        correctAnswer: 6,
      ),
    );

    expect(factory, isNull);
    expect(visualizer, isNull);
  });

  test('registers all built-in math-help keys', () {
    final registry = VisualizerRegistry();
    registerBuiltInMathVisualizers(registry);

    const arithmeticOps = [
      'addition',
      'subtraction',
      'multiplication',
      'division',
    ];
    const geometryOps = [
      'triangleSides',
      'squareSides',
      'rectangleSides',
      'circleSides',
      'pentagonSides',
      'hexagonSides',
      'cubeFaces',
      'cubeEdges',
      'cylinderFaces',
      'sphereFaces',
      'pyramidFaces',
      'pyramidEdges',
      'coneFaces',
    ];
    const measurementOps = ['areaUnits', 'volumeUnits', 'unitChoice'];
    const algorithmicOps = ['stepSequence', 'logicFlow'];

    for (final operation in arithmeticOps) {
      final factory = registry.lookup(
        topicFamily: MathTopicFamily.arithmetic,
        operation: operation,
      );
      expect(factory, isNotNull);
    }

    for (final operation in geometryOps) {
      final factory = registry.lookup(
        topicFamily: MathTopicFamily.geometry,
        operation: operation,
      );
      expect(factory, isNotNull);
    }

    for (final operation in measurementOps) {
      final factory = registry.lookup(
        topicFamily: MathTopicFamily.measurement,
        operation: operation,
      );
      expect(factory, isNotNull);
    }

    for (final operation in algorithmicOps) {
      final factory = registry.lookup(
        topicFamily: MathTopicFamily.algorithmicThinking,
        operation: operation,
      );
      expect(factory, isNotNull);
    }
  });
}
