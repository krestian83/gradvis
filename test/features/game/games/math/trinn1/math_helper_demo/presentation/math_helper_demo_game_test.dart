import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/domain/game_interface.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/math_helper_demo/presentation/math_helper_demo_game.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_controller.dart';
import 'package:gradvis_v2/features/game/math_help/application/math_help_scope.dart';

Future<void> _tapOption(WidgetTester tester, String value) async {
  await tester.tap(find.widgetWithText(FilledButton, value).first);
  await tester.pumpAndSettle();
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
            body: MathHelperDemoGame(
              feedbackDelay: Duration.zero,
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
    expect(helpController.context?.operation, 'subtraction');

    await _tapOption(tester, '5');
    expect(helpController.context?.operation, 'multiplication');

    await _tapOption(tester, '12');
    expect(helpController.context?.operation, 'division');

    await _tapOption(tester, '4');

    expect(completeCalls, 1);
    expect(result, isNotNull);
    expect(result!.stars, 3);
    expect(result!.pointsEarned, 16);
    expect(helpController.context, isNull);
  });
}
