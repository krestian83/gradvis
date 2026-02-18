import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/math_helper_showcase/presentation/math_helper_showcase_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  final finder = find.byKey(ValueKey('math-helper-showcase-option-$value'));
  expect(finder, findsOneWidget);

  VoidCallback? onPressed;
  for (var i = 0; i < 5; i++) {
    onPressed = tester.widget<FilledButton>(finder).onPressed;
    if (onPressed != null) break;
    await tester.pump(const Duration(milliseconds: 10));
  }

  expect(onPressed, isNotNull);
  onPressed!.call();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows non-arithmetic contexts and completes once', (
    tester,
  ) async {
    final helpController = MathHelpController();
    GameResult? result;
    var completeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MathHelpScope(
          controller: helpController,
          child: Scaffold(
            body: MathHelperShowcaseGame(
              feedbackDelay: Duration(milliseconds: 1),
              onComplete: (value) {
                completeCalls += 1;
                result = value;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(helpController.context?.operation, 'triangleSides');
    expect(helpController.context?.topicFamily.name, 'geometry');

    await _tapOption(tester, '3');
    expect(helpController.context?.operation, 'cubeFaces');
    expect(helpController.context?.topicFamily.name, 'geometry');

    await _tapOption(tester, '6');
    expect(helpController.context?.operation, 'areaUnits');
    expect(helpController.context?.topicFamily.name, 'measurement');

    await _tapOption(tester, '12');
    expect(helpController.context?.operation, 'volumeUnits');
    expect(helpController.context?.topicFamily.name, 'measurement');

    await _tapOption(tester, '12');
    expect(helpController.context?.operation, 'stepSequence');
    expect(helpController.context?.topicFamily.name, 'algorithmicThinking');

    await _tapOption(tester, '1');
    expect(helpController.context?.operation, 'logicFlow');
    expect(helpController.context?.topicFamily.name, 'algorithmicThinking');

    await _tapOption(tester, '2');

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 30);
    expect(helpController.context, isNull);
  });
}
