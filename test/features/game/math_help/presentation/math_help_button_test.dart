import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/core/constants/subject.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';
import 'package:gradvis_v2/features/game/math_help/presentation/math_visualizer.dart';
import 'package:gradvis_v2/features/game/math_help/visualizers/visualizer_registry.dart';
import 'package:gradvis_v2/features/game/presentation/game_screen.dart';

class _FakeVisualizer extends MathVisualizer {
  _FakeVisualizer({required super.context});
}

MathHelpContext _additionContext() {
  return MathHelpContext(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'addition',
    operands: const [1, 2],
    correctAnswer: 3,
    label: '1 + 2',
  );
}

VisualizerRegistry _buildRegistry() {
  final registry = VisualizerRegistry();
  registry.register(
    topicFamily: MathTopicFamily.arithmetic,
    operation: 'addition',
    factory: (helpContext) => _FakeVisualizer(context: helpContext),
  );
  return registry;
}

Widget _buildGameScreen({
  required Subject subject,
  required MathHelpController controller,
  required VisualizerRegistry registry,
}) {
  return MaterialApp(
    home: GameScreen(
      subject: subject,
      level: 0,
      trinn: 1,
      mathHelpController: controller,
      visualizerRegistry: registry,
    ),
  );
}

void main() {
  testWidgets('help button is visible only for math with active context', (
    tester,
  ) async {
    final controller = MathHelpController()..setContext(_additionContext());
    final registry = _buildRegistry();

    await tester.pumpWidget(
      _buildGameScreen(
        subject: Subject.math,
        controller: controller,
        registry: registry,
      ),
    );

    expect(find.byTooltip('Vis hjelp'), findsOneWidget);

    await tester.pumpWidget(
      _buildGameScreen(
        subject: Subject.reading,
        controller: controller,
        registry: registry,
      ),
    );

    expect(find.byTooltip('Vis hjelp'), findsNothing);

    controller.clearContext();
    await tester.pumpWidget(
      _buildGameScreen(
        subject: Subject.math,
        controller: controller,
        registry: registry,
      ),
    );

    expect(find.byTooltip('Vis hjelp'), findsNothing);
  });

  testWidgets('tap opens the math-help overlay', (tester) async {
    final controller = MathHelpController()..setContext(_additionContext());
    final registry = _buildRegistry();

    await tester.pumpWidget(
      _buildGameScreen(
        subject: Subject.math,
        controller: controller,
        registry: registry,
      ),
    );

    await tester.tap(find.byTooltip('Vis hjelp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('math-help-overlay')), findsOneWidget);
    expect(find.text('Visualisering'), findsOneWidget);
    expect(find.byTooltip('Lukk hjelpevindu'), findsOneWidget);
  });
}
