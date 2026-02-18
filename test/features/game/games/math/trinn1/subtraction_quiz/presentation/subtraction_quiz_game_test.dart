import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/subtraction_quiz/presentation/subtraction_quiz_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  final finder = find.byKey(ValueKey('subtraction-quiz-option-$value'));
  expect(finder, findsOneWidget);

  VoidCallback? onPressed;
  for (var i = 0; i < 5; i++) {
    onPressed = tester.widget<FilledButton>(finder).onPressed;
    if (onPressed != null) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 10));
  }

  expect(onPressed, isNotNull);
  onPressed!.call();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('publishes subtraction help context and completes once', (
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
            body: SubtractionQuizGame(
              feedbackDelay: const Duration(milliseconds: 1),
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

    expect(helpController.context?.operation, 'subtraction');
    expect(helpController.context?.operands, const [8, 3]);

    await _tapOption(tester, '5');
    expect(helpController.context?.operation, 'subtraction');
    expect(helpController.context?.operands, const [10, 4]);

    await _tapOption(tester, '6');
    expect(helpController.context?.operation, 'subtraction');
    expect(helpController.context?.operands, const [12, 5]);

    await _tapOption(tester, '7');
    expect(helpController.context?.operation, 'subtraction');
    expect(helpController.context?.operands, const [14, 6]);

    await _tapOption(tester, '8');

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 16);
    expect(helpController.context, isNull);
  });
}
