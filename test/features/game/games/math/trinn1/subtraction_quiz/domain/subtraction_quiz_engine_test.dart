import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn1/subtraction_quiz/domain/subtraction_quiz_engine.dart';

void main() {
  test('buildQuestions returns 40 unique subtraction questions', () {
    final questions = const SubtractionQuizEngine().buildQuestions();

    expect(questions.length, 40);

    final uniqueQuestions = questions
        .map((question) => '${question.minuend}-${question.subtrahend}')
        .toSet();
    expect(uniqueQuestions.length, 40);
  });
}
