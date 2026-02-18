import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/shape_3d_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/shape_sides_visualizer.dart';

Future<T> _loadVisualizer<T extends MathVisualizer>(T visualizer) async {
  visualizer.onGameResize(Vector2(320, 220));
  await visualizer.onLoad();
  return visualizer;
}

void main() {
  test('ShapeSidesVisualizer builds triangle side segments', () async {
    final visualizer = await _loadVisualizer(
      ShapeSidesVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.geometry,
          operation: 'triangleSides',
          operands: const [3],
          correctAnswer: 3,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<RectangleComponent>().length, 3);
    expect(visualizer.children.whereType<PolygonComponent>(), isNotEmpty);
  });

  test('ShapeSidesVisualizer builds square side segments', () async {
    final visualizer = await _loadVisualizer(
      ShapeSidesVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.geometry,
          operation: 'squareSides',
          operands: const [4],
          correctAnswer: 4,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<RectangleComponent>().length, 4);
  });

  test('ShapeSidesVisualizer builds hexagon side segments', () async {
    final visualizer = await _loadVisualizer(
      ShapeSidesVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.geometry,
          operation: 'hexagonSides',
          operands: const [6],
          correctAnswer: 6,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<RectangleComponent>().length, 6);
  });

  test('Shape3DVisualizer builds cube face net components', () async {
    final visualizer = await _loadVisualizer(
      Shape3DVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.geometry,
          operation: 'cubeFaces',
          operands: const [6],
          correctAnswer: 6,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(
      visualizer.children.whereType<RectangleComponent>().length,
      greaterThanOrEqualTo(6),
    );
    expect(
      visualizer.children.whereType<TextComponent>().any(
        (component) => component.text.startsWith('Faces'),
      ),
      isTrue,
    );
  });
}
