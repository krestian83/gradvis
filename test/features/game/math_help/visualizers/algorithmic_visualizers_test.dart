import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/logic_flow_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/step_sequence_visualizer.dart';

Future<T> _loadVisualizer<T extends MathVisualizer>(T visualizer) async {
  visualizer.onGameResize(Vector2(320, 220));
  await visualizer.onLoad();
  return visualizer;
}

void main() {
  test('StepSequenceVisualizer builds one box for each step operand', () async {
    final visualizer = await _loadVisualizer(
      StepSequenceVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.algorithmicThinking,
          operation: 'stepSequence',
          operands: const [3, 1, 4, 2],
          correctAnswer: 0,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<StepBoxComponent>().length, 4);
  });

  test(
    'LogicFlowVisualizer places the decision diamond at target index',
    () async {
      final visualizer = await _loadVisualizer(
        LogicFlowVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.algorithmicThinking,
            operation: 'logicFlow',
            operands: const [4, 3],
            correctAnswer: 2,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      final diamond = visualizer.children.whereType<DecisionDiamondComponent>();
      expect(diamond.length, 1);
      expect(diamond.first.stepIndex, 3);
    },
  );
}
