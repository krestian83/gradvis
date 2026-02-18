import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/addition_quiz/presentation/addition_quiz_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  final finder = find.byKey(ValueKey('addition-quiz-option-$value'));
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
  testWidgets('publishes addition help context and completes once', (
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
            body: AdditionQuizGame(
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

    expect(helpController.context?.operation, 'addition');
    expect(helpController.context?.operands, const [2, 3]);

    await _tapOption(tester, '5');
    expect(helpController.context?.operation, 'addition');
    expect(helpController.context?.operands, const [4, 5]);

    await _tapOption(tester, '9');
    expect(helpController.context?.operation, 'addition');
    expect(helpController.context?.operands, const [6, 7]);

    await _tapOption(tester, '13');
    expect(helpController.context?.operation, 'addition');
    expect(helpController.context?.operands, const [8, 9]);

    await _tapOption(tester, '17');

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 16);
    expect(helpController.context, isNull);
  });
}
