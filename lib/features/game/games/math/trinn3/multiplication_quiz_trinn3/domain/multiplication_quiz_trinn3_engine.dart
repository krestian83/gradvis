class MultiplicationQuizTrinn3Question {
  final int leftOperand;
  final int rightOperand;
  final int correctAnswer;

  const MultiplicationQuizTrinn3Question({
    required this.leftOperand,
    required this.rightOperand,
    required this.correctAnswer,
  });

  String get prompt => '$leftOperand x $rightOperand = ?';

  String get helpLabel => '$leftOperand x $rightOperand = $correctAnswer';
}

class MultiplicationQuizTrinn3Engine {
  const MultiplicationQuizTrinn3Engine();

  List<MultiplicationQuizTrinn3Question> buildQuestions() {
    final questions = <MultiplicationQuizTrinn3Question>[];

    for (var rightOperand = 2; rightOperand <= 4; rightOperand++) {
      for (var leftOperand = 2; leftOperand <= 9; leftOperand++) {
        questions.add(
          MultiplicationQuizTrinn3Question(
            leftOperand: leftOperand,
            rightOperand: rightOperand,
            correctAnswer: leftOperand * rightOperand,
          ),
        );
      }
    }

    return questions;
  }

  List<int> buildOptions(MultiplicationQuizTrinn3Question question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-12, -8, -6, -4, -3, -2, 2, 3, 4, 6, 8, 12];

    for (final offset in offsets) {
      final candidate = question.correctAnswer + offset;
      if (candidate <= 0) {
        continue;
      }
      options.add(candidate);
      if (options.length == 4) {
        break;
      }
    }

    var fallbackOffset = 1;
    while (options.length < 4) {
      options.add(question.correctAnswer + fallbackOffset);
      fallbackOffset += 1;
    }

    return options.toList()..sort();
  }
}
