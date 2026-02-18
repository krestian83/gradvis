import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/subtraction_quiz_trinn4/domain/subtraction_quiz_trinn4_engine.dart';

void main() {
  test('buildQuestions returns 40 unique trinn 4 subtraction questions', () {
    final questions = const SubtractionQuizTrinn4Engine().buildQuestions();

    expect(questions.length, 40);

    final uniqueQuestions = questions
        .map((question) => '${question.minuend}-${question.subtrahend}')
        .toSet();
    expect(uniqueQuestions.length, 40);
    expect(questions.every((question) => question.minuend <= 20), isTrue);
    expect(questions.every((question) => question.subtrahend <= 20), isTrue);
    expect(
      questions.every(
        (question) =>
            question.subtrahend < question.minuend &&
            (question.minuend % 10) < (question.subtrahend % 10),
      ),
      isTrue,
    );
  });
}
