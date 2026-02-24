import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_runner/presentation/number_runner_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Widget _buildGame({
  required MathHelpController controller,
  required ValueChanged<GameResult> onComplete,
}) {
  return MaterialApp(
    home: MathHelpScope(
      controller: controller,
      child: Scaffold(body: NumberRunnerGame(onComplete: onComplete)),
    ),
  );
}

void main() {
  testWidgets('publishes math help context on load', (tester) async {
    final helpController = MathHelpController();

    await tester.pumpWidget(
      _buildGame(controller: helpController, onComplete: (_) {}),
    );
    await tester.pump();

    final context = helpController.context;
    expect(context, isNotNull);
    expect(
      context!.operation,
      anyOf('addition', 'subtraction', 'multiplication', 'division'),
    );
    expect(context.operands.length, 2);
  });

  testWidgets('clears math help context on dispose', (tester) async {
    final helpController = MathHelpController();

    await tester.pumpWidget(
      _buildGame(controller: helpController, onComplete: (_) {}),
    );
    await tester.pump();

    expect(helpController.context, isNotNull);

    // Replace the widget tree to trigger dispose.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pump();

    expect(helpController.context, isNull);
  });
}
