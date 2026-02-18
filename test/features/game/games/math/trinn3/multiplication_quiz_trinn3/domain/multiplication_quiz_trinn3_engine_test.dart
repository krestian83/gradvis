import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/math/trinn3/multiplication_quiz_trinn3/domain/multiplication_quiz_trinn3_engine.dart';

void main() {
  test('buildQuestions returns 24 multiplication questions', () {
    final questions = const MultiplicationQuizTrinn3Engine().buildQuestions();

    expect(questions.length, 24);
    expect(questions.first.prompt, '2 x 2 = ?');
    expect(questions.last.prompt, '9 x 4 = ?');
    expect(questions.every((question) => question.correctAnswer > 0), isTrue);
  });

  test('buildOptions includes correct answer and 4 positive values', () {
    const question = MultiplicationQuizTrinn3Question(
      leftOperand: 2,
      rightOperand: 2,
      correctAnswer: 4,
    );

    final options = const MultiplicationQuizTrinn3Engine().buildOptions(
      question,
    );

    expect(options.length, 4);
    expect(options.toSet().length, 4);
    expect(options.contains(question.correctAnswer), isTrue);
    expect(options.every((option) => option > 0), isTrue);
  });
}
