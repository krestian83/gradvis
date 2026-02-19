import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/math_dash/application/math_dash_session_controller.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/math_dash/domain/math_dash_engine.dart';

void main() {
  group('MathDashSessionController', () {
    late MathDashSessionController session;

    setUp(() {
      session = MathDashSessionController(
        engine: MathDashEngine(random: Random(42)),
      );
    });

    test('starts with 3 lives, index 0, speed 120', () {
      expect(session.lives, 3);
      expect(session.questionIndex, 0);
      expect(session.speed, 120.0);
      expect(session.currentStreak, 0);
      expect(session.correctAnswers, 0);
    });

    test('correct answer increments score and streak, multiplies speed', () {
      final answer = session.currentQuestion.answer;
      final isCorrect = session.submitAnswer(answer);

      expect(isCorrect, isTrue);
      expect(session.correctAnswers, 1);
      expect(session.currentStreak, 1);
      expect(session.speed, closeTo(120.0 * 1.20, 0.01));
      expect(session.lives, 3);
    });

    test('wrong answer decrements lives, resets streak, keeps speed', () {
      // First, get a correct answer to build a streak
      session.submitAnswer(session.currentQuestion.answer);
      final speedAfterCorrect = session.speed;

      // Now submit a wrong answer
      final wrong = session.currentQuestion.options.firstWhere(
        (o) => o != session.currentQuestion.answer,
      );
      final isCorrect = session.submitAnswer(wrong);

      expect(isCorrect, isFalse);
      expect(session.lives, 2);
      expect(session.currentStreak, 0);
      expect(session.speed, speedAfterCorrect);
    });

    test('isGameOver when lives reach 0', () {
      expect(session.isGameOver, isFalse);

      for (var i = 0; i < 3; i++) {
        final wrong = session.currentQuestion.options.firstWhere(
          (o) => o != session.currentQuestion.answer,
        );
        session.submitAnswer(wrong);
      }

      expect(session.isGameOver, isTrue);
      expect(session.lives, 0);
    });

    test('isVictory when 20 answered with lives > 0', () {
      for (var i = 0; i < 20; i++) {
        expect(session.isVictory, isFalse);
        session.submitAnswer(session.currentQuestion.answer);
      }

      expect(session.isVictory, isTrue);
      expect(session.lives, 3);
    });

    test('environmentThemeIndex returns 0-3 based on question index', () {
      expect(session.environmentThemeIndex, 0);

      for (var i = 0; i < 5; i++) {
        session.submitAnswer(session.currentQuestion.answer);
      }
      expect(session.environmentThemeIndex, 1);

      for (var i = 0; i < 5; i++) {
        session.submitAnswer(session.currentQuestion.answer);
      }
      expect(session.environmentThemeIndex, 2);

      for (var i = 0; i < 5; i++) {
        session.submitAnswer(session.currentQuestion.answer);
      }
      expect(session.environmentThemeIndex, 3);
    });

    test('buildResult gives correct stars and points', () {
      // Answer all 20 correctly
      for (var i = 0; i < 20; i++) {
        session.submitAnswer(session.currentQuestion.answer);
      }

      final result = session.buildResult();
      expect(result.stars, 3);
      expect(result.pointsEarned, (20 * 12) + (20 * 8));
    });

    test('buildResult gives 1 star for low accuracy', () {
      // Answer 10 correct, 3 wrong (game over after 3 wrong)
      for (var i = 0; i < 3; i++) {
        session.submitAnswer(session.currentQuestion.answer);
        final wrong = session.currentQuestion.options.firstWhere(
          (o) => o != session.currentQuestion.answer,
        );
        session.submitAnswer(wrong);
      }

      final result = session.buildResult();
      expect(result.stars, 1);
    });
  });
}
