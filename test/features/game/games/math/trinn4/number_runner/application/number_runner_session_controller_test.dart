import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_runner/application/number_runner_session_controller.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_runner/domain/number_runner_engine.dart';

void main() {
  group('NumberRunnerSessionController', () {
    late NumberRunnerSessionController session;
    late NumberRunnerEngine engine;

    setUp(() {
      engine = NumberRunnerEngine(random: Random(42));
      session = NumberRunnerSessionController(
        engine: engine,
        questionCount: 5,
        lives: 3,
      );
    });

    test('starts with correct initial state', () {
      expect(session.lives, 3);
      expect(session.correctAnswers, 0);
      expect(session.currentStreak, 0);
      expect(session.bestStreak, 0);
      expect(session.currentIndex, 0);
      expect(session.isGameOver, false);
      expect(session.isFinished, false);
      expect(session.isVictory, false);
    });

    test('correct answer increments score and streak', () {
      final answer = session.currentQuestion.answer;
      final result = session.submitAnswer(answer);

      expect(result, true);
      expect(session.correctAnswers, 1);
      expect(session.currentStreak, 1);
      expect(session.currentIndex, 1);
    });

    test('wrong answer decrements lives and resets streak', () {
      // Answer correctly once to build streak.
      session.submitAnswer(session.currentQuestion.answer);
      expect(session.currentStreak, 1);

      // Now answer wrong.
      final wrong = session.currentQuestion.options
          .firstWhere((o) => o != session.currentQuestion.answer);
      final result = session.submitAnswer(wrong);

      expect(result, false);
      expect(session.lives, 2);
      expect(session.currentStreak, 0);
    });

    test('game over when lives reach 0', () {
      for (var i = 0; i < 3; i++) {
        final wrong = session.currentQuestion.options
            .firstWhere((o) => o != session.currentQuestion.answer);
        session.submitAnswer(wrong);
      }

      expect(session.isGameOver, true);
      expect(session.lives, 0);
    });

    test('submit does nothing after game over', () {
      for (var i = 0; i < 3; i++) {
        final wrong = session.currentQuestion.options
            .firstWhere((o) => o != session.currentQuestion.answer);
        session.submitAnswer(wrong);
      }

      final result = session.submitAnswer(0);
      expect(result, false);
    });

    test('victory when all questions answered while alive', () {
      for (var i = 0; i < 5; i++) {
        session.submitAnswer(session.currentQuestion.answer);
      }

      expect(session.isFinished, true);
      expect(session.isVictory, true);
      expect(session.isGameOver, false);
    });

    test('best streak tracks maximum consecutive correct', () {
      // 2 correct, 1 wrong, 2 correct.
      session.submitAnswer(session.currentQuestion.answer);
      session.submitAnswer(session.currentQuestion.answer);

      final wrong = session.currentQuestion.options
          .firstWhere((o) => o != session.currentQuestion.answer);
      session.submitAnswer(wrong);

      session.submitAnswer(session.currentQuestion.answer);
      session.submitAnswer(session.currentQuestion.answer);

      expect(session.bestStreak, 2);
    });

    test('notifies listeners on submit', () {
      var notified = 0;
      session.addListener(() => notified++);

      session.submitAnswer(session.currentQuestion.answer);
      expect(notified, 1);
    });

    group('buildResult', () {
      test('3 stars for >= 88% accuracy', () {
        final s = NumberRunnerSessionController(
          engine: engine,
          questionCount: 5,
          lives: 3,
        );
        // 5/5 = 100%.
        for (var i = 0; i < 5; i++) {
          s.submitAnswer(s.currentQuestion.answer);
        }
        final result = s.buildResult();
        expect(result.stars, 3);
      });

      test('2 stars for >= 63% accuracy', () {
        final s = NumberRunnerSessionController(
          engine: NumberRunnerEngine(random: Random(42)),
          questionCount: 5,
          lives: 5,
        );
        // 4/5 = 80%.
        for (var i = 0; i < 4; i++) {
          s.submitAnswer(s.currentQuestion.answer);
        }
        final wrong = s.currentQuestion.options
            .firstWhere((o) => o != s.currentQuestion.answer);
        s.submitAnswer(wrong);
        final result = s.buildResult();
        expect(result.stars, 2);
      });

      test('1 star for < 63% accuracy', () {
        final s = NumberRunnerSessionController(
          engine: NumberRunnerEngine(random: Random(42)),
          questionCount: 5,
          lives: 5,
        );
        // 2/5 = 40%.
        for (var i = 0; i < 2; i++) {
          s.submitAnswer(s.currentQuestion.answer);
        }
        for (var i = 0; i < 3; i++) {
          final wrong = s.currentQuestion.options
              .firstWhere((o) => o != s.currentQuestion.answer);
          s.submitAnswer(wrong);
        }
        final result = s.buildResult();
        expect(result.stars, 1);
      });

      test('points = (correct x 16) + (bestStreak x 6)', () {
        for (var i = 0; i < 5; i++) {
          session.submitAnswer(session.currentQuestion.answer);
        }
        final result = session.buildResult();
        // 5 correct, best streak 5.
        expect(result.pointsEarned, 5 * 16 + 5 * 6);
      });
    });
  });
}
