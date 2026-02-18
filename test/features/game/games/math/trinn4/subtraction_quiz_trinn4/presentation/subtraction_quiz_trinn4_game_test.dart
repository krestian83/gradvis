import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/subtraction_quiz_trinn4/presentation/subtraction_quiz_trinn4_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  final finder = find.byKey(ValueKey('subtraction-quiz-trinn4-option-$value'));
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
        widget.data!.contains(' - ') &&
        widget.data!.contains('= ?'),
  );
  expect(promptFinder, findsOneWidget);

  final prompt = tester.widget<Text>(promptFinder).data!;
  final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(prompt);
  expect(match, isNotNull);

  final minuend = int.parse(match!.group(1)!);
  final subtrahend = int.parse(match.group(2)!);
  final correctAnswer = minuend - subtrahend;

  await _tapOption(tester, '$correctAnswer');
}

void main() {
  testWidgets('publishes help context and completes once', (tester) async {
    final helpController = MathHelpController();
    GameResult? result;
    var completeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MathHelpScope(
          controller: helpController,
          child: Scaffold(
            body: SubtractionQuizTrinn4Game(
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
    expect(helpController.context?.operands, const [12, 3]);

    for (var round = 0; round < 40; round++) {
      await _answerCurrentQuestion(tester);
    }

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 160);
    expect(helpController.context, isNull);
  });
}
