import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/addition_quiz/domain/addition_quiz_engine.dart';

void main() {
  test('buildQuestions returns 40 unique addition questions', () {
    final questions = const AdditionQuizEngine().buildQuestions();

    expect(questions.length, 40);

    final uniqueQuestions = questions
        .map((question) => '${question.leftOperand}-${question.rightOperand}')
        .toSet();
    expect(uniqueQuestions.length, 40);
  });
}
