import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/area_units_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/volume_units_visualizer.dart';

Future<T> _loadVisualizer<T extends MathVisualizer>(T visualizer) async {
  visualizer.onGameResize(Vector2(320, 220));
  await visualizer.onLoad();
  return visualizer;
}

void main() {
  test('AreaUnitsVisualizer builds width x height unit tiles', () async {
    final visualizer = await _loadVisualizer(
      AreaUnitsVisualizer(
        context: MathHelpContext(
          topicFamily: MathTopicFamily.measurement,
          operation: 'areaUnits',
          operands: const [4, 3],
          correctAnswer: 12,
        ),
      ),
    );
    addTearDown(visualizer.onRemove);

    expect(visualizer.children.whereType<AreaUnitTileComponent>().length, 12);
  });

  test(
    'VolumeUnitsVisualizer builds width x height x depth unit cubes',
    () async {
      final visualizer = await _loadVisualizer(
        VolumeUnitsVisualizer(
          context: MathHelpContext(
            topicFamily: MathTopicFamily.measurement,
            operation: 'volumeUnits',
            operands: const [3, 2, 2],
            correctAnswer: 12,
          ),
        ),
      );
      addTearDown(visualizer.onRemove);

      expect(
        visualizer.children.whereType<VolumeUnitCubeComponent>().length,
        12,
      );
    },
  );
}
