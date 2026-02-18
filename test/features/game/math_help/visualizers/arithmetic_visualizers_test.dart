import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/addition_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/division_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/multiplication_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/subtraction_visualizer.dart';

Future<T> _loadVisualizer<T extends MathVisualizer>(T visualizer) async {
  visualizer.onGameResize(Vector2(320, 220));
  await visualizer.onLoad();
  return visualizer;
}

void main() {
  test('AdditionVisualizer builds merged dot scene', () async {
    final visualizer = await _loadVisualizer(
      AdditionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'addition',
          operands: const [4, 3],
          correctAnswer: 7,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 7);
    expect(visualizer.children.whereType<RectangleComponent>(), isNotEmpty);
    expect(
      visualizer.children.whereType<TextComponent>().any(
        (component) => component.text == '4 + 3 = 7',
      ),
      isTrue,
    );
  });

  test('AdditionVisualizer normalizes negative and large operands', () async {
    final visualizer = await _loadVisualizer(
      AdditionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'addition',
          operands: const [25, -2],
          correctAnswer: 23,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 20);
    expect(
      visualizer.children.whereType<TextComponent>().any(
        (component) => component.text == '20 + 0 = 20',
      ),
      isTrue,
    );
  });

  test('SubtractionVisualizer builds number-line components', () async {
    final visualizer = await _loadVisualizer(
      SubtractionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'subtraction',
          operands: const [9, 3],
          correctAnswer: 6,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(
      visualizer.children.whereType<RectangleComponent>().length,
      greaterThan(2),
    );
    expect(visualizer.children.whereType<PolygonComponent>(), isNotEmpty);
    expect(
      visualizer.children.whereType<TextComponent>().length,
      greaterThan(1),
    );
  });

  test('MultiplicationVisualizer creates rows x columns dots', () async {
    final visualizer = await _loadVisualizer(
      MultiplicationVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'multiplication',
          operands: const [3, 4],
          correctAnswer: 12,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 12);
    expect(
      visualizer.children.whereType<TextComponent>().any(
        (component) => component.text == '= 12',
      ),
      isTrue,
    );
  });

  test('DivisionVisualizer builds total dots and group labels', () async {
    final visualizer = await _loadVisualizer(
      DivisionVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.arithmetic,
          operation: 'division',
          operands: const [12, 3],
          correctAnswer: 4,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<CircleComponent>().length, 12);
    expect(
      visualizer.children
          .whereType<TextComponent>()
          .where((component) => component.text == '4')
          .length,
      3,
    );
  });
}
