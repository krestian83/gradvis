import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn3/multiplication_quiz_trinn3/presentation/multiplication_quiz_trinn3_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  final finder = find.byKey(
    ValueKey('multiplication-quiz-trinn3-option-$value'),
  );
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

Future<void> _answerCurrentQuestion(WidgetTester tester) async {
  final promptFinder = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!.contains(' x ') &&
        widget.data!.contains('= ?'),
  );
  expect(promptFinder, findsOneWidget);

  final prompt = tester.widget<Text>(promptFinder).data!;
  final match = RegExp(r'(\d+)\s*x\s*(\d+)').firstMatch(prompt);
  expect(match, isNotNull);

  final leftOperand = int.parse(match!.group(1)!);
  final rightOperand = int.parse(match.group(2)!);
  final correctAnswer = leftOperand * rightOperand;

  await _tapOption(tester, '$correctAnswer');
}

void main() {
  testWidgets('publishes multiplication help context and completes once', (
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
            body: MultiplicationQuizTrinn3Game(
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

    expect(helpController.context?.operation, 'multiplication');
    expect(helpController.context?.operands, const [2, 2]);

    for (var round = 0; round < 24; round++) {
      await _answerCurrentQuestion(tester);
    }

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 96);
    expect(helpController.context, isNull);
  });
}
