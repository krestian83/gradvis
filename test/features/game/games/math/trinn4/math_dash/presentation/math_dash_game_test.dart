import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/math_dash/presentation/math_dash_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Widget _buildGame({
  required MathHelpController controller,
  required ValueChanged<GameResult> onComplete,
}) {
  return MaterialApp(
    home: MathHelpScope(
      controller: controller,
      child: Scaffold(
        body: MathDashGame(onComplete: onComplete),
      ),
    ),
  );
}

void main() {
  testWidgets('publishes MathHelpContext on mount with correct operation', (
    tester,
  ) async {
    final helpController = MathHelpController();

    await tester.pumpWidget(
      _buildGame(controller: helpController, onComplete: (_) {}),
    );
    await tester.pump();

    final context = helpController.context;
    expect(context, isNotNull);
    expect(
      context!.operation,
      isIn(['addition', 'subtraction', 'multiplication', 'division']),
    );
    expect(context.operands.length, 2);
  });

  testWidgets('clears MathHelpContext on dispose', (tester) async {
    final helpController = MathHelpController();

    await tester.pumpWidget(
      _buildGame(controller: helpController, onComplete: (_) {}),
    );
    await tester.pump();

    expect(helpController.context, isNotNull);

    // Replace with a different widget to trigger dispose.
    // The clear happens in a post-frame callback, so we need
    // to pump twice: once to swap the tree, once for the callback.
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const SizedBox())),
    );
    await tester.pump();

    expect(helpController.context, isNull);
  });
}
