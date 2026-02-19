import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/math_dash/domain/math_dash_engine.dart';

void main() {
  group('MathDashEngine', () {
    late MathDashEngine engine;

    setUp(() {
      engine = MathDashEngine(random: Random(42));
    });

    test('generates exactly 20 questions', () {
      final questions = engine.createQuestions();
      expect(questions.length, 20);
    });

    test('all 4 operations are represented with at least 4 each', () {
      final questions = engine.createQuestions();
      final operators = questions.map((q) => q.operator).toList();
      expect(operators.where((o) => o == '+').length, greaterThanOrEqualTo(4));
      expect(operators.where((o) => o == '-').length, greaterThanOrEqualTo(4));
      expect(operators.where((o) => o == '*').length, greaterThanOrEqualTo(4));
      expect(operators.where((o) => o == '/').length, greaterThanOrEqualTo(4));
    });

    test('all answers are mathematically correct', () {
      final questions = engine.createQuestions();
      for (final q in questions) {
        final expected = switch (q.operator) {
          '+' => q.left + q.right,
          '-' => q.left - q.right,
          '*' => q.left * q.right,
          '/' => q.left ~/ q.right,
          _ => -1,
        };
        expect(q.answer, expected,
            reason: '${q.expression} should equal ${q.answer}');
      }
    });

    test('division results are clean integers', () {
      final questions = engine.createQuestions();
      final divisionQuestions =
          questions.where((q) => q.operator == '/');
      for (final q in divisionQuestions) {
        expect(q.left % q.right, 0,
            reason: '${q.left} / ${q.right} should divide evenly');
      }
    });

    test('each question has 4 unique options including the answer', () {
      final questions = engine.createQuestions();
      for (final q in questions) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4,
            reason: 'options should be unique: ${q.options}');
        expect(q.options.contains(q.answer), isTrue,
            reason: 'options should contain the answer');
      }
    });

    test('all options are positive', () {
      final questions = engine.createQuestions();
      for (final q in questions) {
        for (final option in q.options) {
          expect(option, greaterThan(0),
              reason: 'option $option should be positive');
        }
      }
    });
  });
}
