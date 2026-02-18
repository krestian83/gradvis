import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/subtraction_target_trek/presentation/subtraction_target_trek_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Widget _buildGame({
  required MathHelpController controller,
  required ValueChanged<GameResult> onComplete,
}) {
  return MaterialApp(
    home: MathHelpScope(
      controller: controller,
      child: Scaffold(body: SubtractionTargetTrekGame(onComplete: onComplete)),
    ),
  );
}

void main() {
  testWidgets('publishes subtraction help context with operands', (
    tester,
  ) async {
    final helpController = MathHelpController();

    await tester.pumpWidget(
      _buildGame(controller: helpController, onComplete: (_) {}),
    );
    await tester.pump();

    final context = helpController.context;
    expect(context, isNotNull);
    expect(context!.operation, 'subtraction');
    expect(context.operands.length, 2);
    expect(context.correctAnswer, context.operands[0] - context.operands[1]);
  });

  testWidgets('completes and clears math help context', (tester) async {
    final helpController = MathHelpController();
    GameResult? result;

    await tester.pumpWidget(
      _buildGame(
        controller: helpController,
        onComplete: (value) => result = value,
      ),
    );
    await tester.pump();

    var safetyCounter = 0;
    while (result == null && safetyCounter < 12) {
      final context = helpController.context;
      expect(context, isNotNull);
      final answer = context!.correctAnswer.toInt();
      final finder = find.byKey(Key('answer-$answer'));

      await tester.ensureVisible(finder);
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();
      safetyCounter += 1;
    }

    expect(result, isNotNull);
    expect(result!.stars, inInclusiveRange(1, 3));
    expect(result!.pointsEarned, greaterThan(0));
    expect(helpController.context, isNull);
  });
}
