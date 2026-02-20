import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/application/number_storm_sprint_session_controller.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/domain/number_storm_sprint_engine.dart';

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

List<NumberStormSprintQuestion> _repeatedQuestions(int count) {
  return List<NumberStormSprintQuestion>.generate(
    count,
    (index) => _question(
      operation: NumberStormOperation.addition,
      leftOperand: 10 + index,
      rightOperand: 5,
      options: [15 + index, 14 + index, 13 + index, 16 + index],
    ),
  );
}

void main() {
  group('NumberStormSprintSessionController', () {
    test('every submitted answer increments encounter progress', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(3),
      );

      expect(controller.answeredCount, 0);
      controller.submitAnswer(controller.currentQuestion.answer);
      expect(controller.answeredCount, 1);
      controller.submitAnswer(-999);
      expect(controller.answeredCount, 2);
      controller.submitAnswer(controller.currentQuestion.answer);
      expect(controller.answeredCount, 3);
      expect(controller.isComplete, isTrue);
    });

    test('wrong answers reduce lives', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(5),
      );

      expect(controller.livesRemaining, 3);
      controller.submitAnswer(-1000);
      expect(controller.livesRemaining, 2);
      controller.submitAnswer(-1000);
      expect(controller.livesRemaining, 1);
    });

    test('speed multiplier ramps and caps at 2.2x', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(40),
      );

      controller.submitAnswer(controller.currentQuestion.answer);
      expect(controller.speedMultiplier, closeTo(1.07, 0.0001));

      for (var i = 0; i < 39; i += 1) {
        if (controller.isComplete) {
          break;
        }
        controller.submitAnswer(controller.currentQuestion.answer);
      }

      expect(controller.speedMultiplier, closeTo(2.2, 0.0001));
    });

    test('session reaches victory when all 20 encounters are answered', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(20),
      );

      while (!controller.isComplete) {
        controller.submitAnswer(controller.currentQuestion.answer);
      }

      expect(controller.answeredCount, 20);
      expect(controller.isVictory, isTrue);
      expect(controller.isGameOver, isFalse);
      expect(controller.livesRemaining, 3);
    });

    test('session reaches game over after three wrong collisions', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(20),
      );

      controller.submitAnswer(-5);
      controller.submitAnswer(-5);
      controller.submitAnswer(-5);

      expect(controller.isGameOver, isTrue);
      expect(controller.isComplete, isTrue);
      expect(controller.answeredCount, 3);
      expect(controller.livesRemaining, 0);
    });

    test('result uses fixed mastery denominator and partial scoring', () {
      final controller = NumberStormSprintSessionController(
        questions: _repeatedQuestions(5),
      );

      while (!controller.isComplete) {
        controller.submitAnswer(controller.currentQuestion.answer);
      }

      final result = controller.buildResult();
      expect(result.stars, 1);
      expect(result.pointsEarned, (5 * 18) + (5 * 4) + (3 * 12));
    });
  });
}
