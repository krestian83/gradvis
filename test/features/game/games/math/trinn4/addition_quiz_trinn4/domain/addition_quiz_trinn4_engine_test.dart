import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn4/addition_quiz_trinn4/domain/addition_quiz_trinn4_engine.dart';

void main() {
  test('buildQuestions returns 40 unique trinn 4 addition questions', () {
    final questions = const AdditionQuizTrinn4Engine().buildQuestions();

    expect(questions.length, 40);

    final uniqueQuestions = questions
        .map((question) => '${question.leftOperand}-${question.rightOperand}')
        .toSet();
    expect(uniqueQuestions.length, 40);
    expect(questions.every((question) => question.leftOperand <= 20), isTrue);
    expect(questions.every((question) => question.rightOperand <= 20), isTrue);
    expect(
      questions.every(
        (question) =>
            (question.leftOperand % 10) + (question.rightOperand % 10) >= 10,
      ),
      isTrue,
    );
  });
}
