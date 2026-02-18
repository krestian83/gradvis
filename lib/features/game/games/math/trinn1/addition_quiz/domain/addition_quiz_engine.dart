class AdditionQuizQuestion {
  final int leftOperand;
  final int rightOperand;
  final int correctAnswer;

  const AdditionQuizQuestion({
    required this.leftOperand,
    required this.rightOperand,
    required this.correctAnswer,
  });

  String get prompt => '$leftOperand + $rightOperand = ?';

  String get helpLabel => '$leftOperand + $rightOperand = $correctAnswer';
}

class AdditionQuizEngine {
  const AdditionQuizEngine();

  List<AdditionQuizQuestion> buildQuestions() {
    return const [
      AdditionQuizQuestion(leftOperand: 2, rightOperand: 3, correctAnswer: 5),
      AdditionQuizQuestion(leftOperand: 4, rightOperand: 5, correctAnswer: 9),
      AdditionQuizQuestion(leftOperand: 6, rightOperand: 7, correctAnswer: 13),
      AdditionQuizQuestion(leftOperand: 8, rightOperand: 9, correctAnswer: 17),
    ];
  }

  List<int> buildOptions(AdditionQuizQuestion question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-3, -2, -1, 1, 2, 3, 4];

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
