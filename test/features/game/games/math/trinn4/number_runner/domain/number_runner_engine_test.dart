import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_runner/domain/number_runner_engine.dart';

void main() {
  group('NumberRunnerEngine', () {
    late NumberRunnerEngine engine;

    setUp(() {
      engine = NumberRunnerEngine(random: Random(42));
    });

    test('creates the requested number of questions', () {
      final questions = engine.createQuestions(count: 20);
      expect(questions.length, 20);
    });

    test('each question has exactly 4 options', () {
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        expect(q.options.length, 4);
      }
    });

    test('correct answer is always among options', () {
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        expect(q.options, contains(q.answer));
      }
    });

    test('options are distinct', () {
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        expect(q.options.toSet().length, q.options.length);
      }
    });

    test('all options are positive', () {
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        for (final opt in q.options) {
          expect(opt, greaterThan(0));
        }
      }
    });

    test('early questions use addition or subtraction', () {
      final questions = engine.createQuestions(count: 20);
      for (var i = 0; i < 6; i++) {
        expect(
          questions[i].operationKey,
          anyOf('addition', 'subtraction'),
        );
      }
    });

    test('later questions include multiplication or division', () {
      final questions = engine.createQuestions(count: 20);
      final laterOps = questions
          .sublist(13)
          .map((q) => q.operationKey)
          .toSet();
      expect(
        laterOps,
        anyOf(
          contains('multiplication'),
          contains('division'),
        ),
      );
    });

    test('division questions have remainder-free answers', () {
      // Generate many questions to get some division ones.
      for (var seed = 0; seed < 20; seed++) {
        final e = NumberRunnerEngine(random: Random(seed));
        final questions = e.createQuestions(count: 20);
        for (final q in questions) {
          if (q.operationKey == 'division') {
            expect(
              q.operandA % q.operandB,
              0,
              reason: '${q.operandA} / ${q.operandB} has remainder',
            );
            expect(q.answer, q.operandA ~/ q.operandB);
          }
        }
      }
    });

    test('expression format matches operator', () {
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        expect(q.expression, contains(q.operator));
        expect(q.expression, contains('${q.operandA}'));
        expect(q.expression, contains('${q.operandB}'));
      }
    });

    test('operation keys are valid visualizer registry keys', () {
      const validKeys = {
        'addition',
        'subtraction',
        'multiplication',
        'division',
      };
      final questions = engine.createQuestions(count: 20);
      for (final q in questions) {
        expect(validKeys, contains(q.operationKey));
      }
    });

    test('count less than 1 clamps to 1', () {
      final questions = engine.createQuestions(count: 0);
      expect(questions.length, 1);
    });
  });
}
