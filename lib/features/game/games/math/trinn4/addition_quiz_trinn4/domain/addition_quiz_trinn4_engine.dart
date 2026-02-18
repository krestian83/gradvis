class AdditionQuizTrinn4Question {
  final int leftOperand;
  final int rightOperand;
  final int correctAnswer;

  const AdditionQuizTrinn4Question({
    required this.leftOperand,
    required this.rightOperand,
    required this.correctAnswer,
  });

  String get prompt => '$leftOperand + $rightOperand = ?';

  String get helpLabel => '$leftOperand + $rightOperand = $correctAnswer';
}

class AdditionQuizTrinn4Engine {
  const AdditionQuizTrinn4Engine();

  List<AdditionQuizTrinn4Question> buildQuestions() {
    final questions = <AdditionQuizTrinn4Question>[];

    for (var leftOperand = 10; leftOperand <= 20; leftOperand++) {
      for (var rightOperand = 5; rightOperand <= 20; rightOperand++) {
        final needsCarrying = (leftOperand % 10) + (rightOperand % 10) >= 10;
        if (!needsCarrying) {
          continue;
        }
        questions.add(
          AdditionQuizTrinn4Question(
            leftOperand: leftOperand,
            rightOperand: rightOperand,
            correctAnswer: leftOperand + rightOperand,
          ),
        );
        if (questions.length == 40) {
          return questions;
        }
      }
    }

    return questions;
  }

  List<int> buildOptions(AdditionQuizTrinn4Question question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-6, -4, -2, 2, 4, 6, 8];

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

    return options.toList()..sort();
  }
}
