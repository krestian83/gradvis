import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/number_storm_sprint/domain/number_storm_sprint_engine.dart';

void main() {
  group('NumberStormSprintEngine', () {
    test('creates 20 questions by default', () {
      final engine = NumberStormSprintEngine(random: Random(5));

      final questions = engine.createQuestions();

      expect(questions, hasLength(20));
    });

    test('creates four unique options and includes the correct answer', () {
      final engine = NumberStormSprintEngine(random: Random(22));

      final questions = engine.createQuestions(count: 60);

      for (final question in questions) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet().length, 4);
        expect(question.options, contains(question.answer));
      }
    });

    test('division questions always use exact integer division', () {
      final engine = NumberStormSprintEngine(random: Random(121));

      final questions = engine.createQuestions(count: 240);
      final divisionQuestions = questions
          .where((q) => q.operation == NumberStormOperation.division)
          .toList();

      expect(divisionQuestions, isNotEmpty);

      for (final question in divisionQuestions) {
        expect(question.leftOperand % question.rightOperand, 0);
        expect(question.answer * question.rightOperand, question.leftOperand);
      }
    });
  });
}
