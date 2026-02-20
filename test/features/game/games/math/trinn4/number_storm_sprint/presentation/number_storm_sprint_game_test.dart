import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/application/number_storm_sprint_session_controller.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/domain/number_storm_sprint_engine.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/presentation/number_storm_sprint_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';

const _fastConfig = NumberStormSprintConfig(
  baseSpeed: 1400,
  spawnMinSeconds: 0,
  spawnMaxSeconds: 0,
  obstacleStartOffset: 20,
  decelerationDuration: Duration(milliseconds: 20),
  throwDuration: Duration(milliseconds: 20),
  confettiDuration: Duration(milliseconds: 20),
  collisionDuration: Duration(milliseconds: 20),
  accelerationDuration: Duration(milliseconds: 20),
);

Widget _buildGame({
  required MathHelpController helpController,
  required NumberStormSprintSessionController sessionController,
  required ValueChanged<GameResult> onComplete,
}) {
  return MaterialApp(
    home: MathHelpScope(
      controller: helpController,
      child: Scaffold(
        body: NumberStormSprintGame(
          onComplete: onComplete,
          sessionController: sessionController,
          config: _fastConfig,
        ),
      ),
    ),
  );
}

NumberStormSprintQuestion _question({
  required NumberStormOperation operation,
  required int leftOperand,
  required int rightOperand,
  required List<int> options,
}) {
  return NumberStormSprintQuestion(
    operation: operation,
    leftOperand: leftOperand,
    rightOperand: rightOperand,
    options: options,
  );
}

Future<void> _pumpUntilQuiz(
  WidgetTester tester,
  MathHelpController helpController,
) async {
  var safetyCounter = 0;
  while (helpController.context == null && safetyCounter < 180) {
    await tester.pump(const Duration(milliseconds: 16));
    safetyCounter += 1;
  }
  expect(helpController.context, isNotNull);
}

Future<void> _pumpUntilEndOverlay(WidgetTester tester) async {
  var safetyCounter = 0;
  while (find.byKey(const Key('continue-button')).evaluate().isEmpty &&
      safetyCounter < 220) {
    await tester.pump(const Duration(milliseconds: 16));
    safetyCounter += 1;
  }
  expect(find.byKey(const Key('continue-button')), findsOneWidget);
}

void main() {
  testWidgets('publishes math-help context when runner pauses for a question', (
    tester,
  ) async {
    final helpController = MathHelpController();
    final sessionController = NumberStormSprintSessionController(
      questions: [
        _question(
          operation: NumberStormOperation.addition,
          leftOperand: 8,
          rightOperand: 5,
          options: const [13, 11, 14, 10],
        ),
      ],
    );

    await tester.pumpWidget(
      _buildGame(
        helpController: helpController,
        sessionController: sessionController,
        onComplete: (_) {},
      ),
    );

    await _pumpUntilQuiz(tester, helpController);
    final help = helpController.context!;
    expect(help.topicFamily, MathTopicFamily.arithmetic);
    expect(help.operation, 'addition');
    expect(help.label, '8 + 5');
    expect(find.byKey(const Key('answer-13')), findsOneWidget);
  });

  testWidgets('correct answer advances to next encounter', (tester) async {
    final helpController = MathHelpController();
    final sessionController = NumberStormSprintSessionController(
      questions: [
        _question(
          operation: NumberStormOperation.addition,
          leftOperand: 8,
          rightOperand: 5,
          options: const [13, 11, 14, 10],
        ),
        _question(
          operation: NumberStormOperation.multiplication,
          leftOperand: 6,
          rightOperand: 4,
          options: const [24, 21, 28, 19],
        ),
      ],
    );

    await tester.pumpWidget(
      _buildGame(
        helpController: helpController,
        sessionController: sessionController,
        onComplete: (_) {},
      ),
    );

    await _pumpUntilQuiz(tester, helpController);
    expect(helpController.context!.label, '8 + 5');

    await tester.tap(find.byKey(const Key('answer-13')));
    await tester.pump();

    var safetyCounter = 0;
    while ((helpController.context == null ||
            helpController.context!.label == '8 + 5') &&
        safetyCounter < 220) {
      await tester.pump(const Duration(milliseconds: 16));
      safetyCounter += 1;
    }

    expect(helpController.context, isNotNull);
    expect(helpController.context!.label, '6 x 4');
    expect(find.text('Sporsmal 2/2'), findsOneWidget);
  });

  testWidgets('wrong answer removes one life', (tester) async {
    final helpController = MathHelpController();
    final sessionController = NumberStormSprintSessionController(
      questions: [
        _question(
          operation: NumberStormOperation.subtraction,
          leftOperand: 21,
          rightOperand: 8,
          options: const [13, 10, 11, 9],
        ),
        _question(
          operation: NumberStormOperation.addition,
          leftOperand: 7,
          rightOperand: 9,
          options: const [16, 14, 18, 15],
        ),
      ],
    );

    await tester.pumpWidget(
      _buildGame(
        helpController: helpController,
        sessionController: sessionController,
        onComplete: (_) {},
      ),
    );

    await _pumpUntilQuiz(tester, helpController);
    expect(find.text('Liv 3/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('answer-10')));
    await tester.pump();
    expect(find.text('Liv 2/3'), findsOneWidget);
  });

  testWidgets('completion state clears math-help context', (tester) async {
    final helpController = MathHelpController();
    final sessionController = NumberStormSprintSessionController(
      questions: [
        _question(
          operation: NumberStormOperation.division,
          leftOperand: 24,
          rightOperand: 6,
          options: const [4, 5, 3, 2],
        ),
      ],
    );

    await tester.pumpWidget(
      _buildGame(
        helpController: helpController,
        sessionController: sessionController,
        onComplete: (_) {},
      ),
    );

    await _pumpUntilQuiz(tester, helpController);
    await tester.tap(find.byKey(const Key('answer-4')));
    await tester.pump();
    await _pumpUntilEndOverlay(tester);

    expect(helpController.context, isNull);
  });

  testWidgets('onComplete emits once from end overlay button', (tester) async {
    final helpController = MathHelpController();
    final sessionController = NumberStormSprintSessionController(
      questions: [
        _question(
          operation: NumberStormOperation.multiplication,
          leftOperand: 6,
          rightOperand: 7,
          options: const [42, 40, 35, 49],
        ),
      ],
    );
    GameResult? result;
    var calls = 0;

    await tester.pumpWidget(
      _buildGame(
        helpController: helpController,
        sessionController: sessionController,
        onComplete: (value) {
          calls += 1;
          result = value;
        },
      ),
    );

    await _pumpUntilQuiz(tester, helpController);
    await tester.tap(find.byKey(const Key('answer-42')));
    await tester.pump();
    await _pumpUntilEndOverlay(tester);

    await tester.tap(find.byKey(const Key('continue-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('continue-button')));
    await tester.pump();

    expect(calls, 1);
    expect(result, isNotNull);
    expect(result!.stars, inInclusiveRange(1, 3));
    expect(result!.pointsEarned, greaterThan(0));
  });
}
