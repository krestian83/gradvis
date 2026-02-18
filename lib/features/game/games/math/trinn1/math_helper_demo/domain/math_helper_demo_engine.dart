enum MathDemoOperation {
  addition(helpKey: 'addition', symbol: '+'),
  subtraction(helpKey: 'subtraction', symbol: '-'),
  multiplication(helpKey: 'multiplication', symbol: '*'),
  division(helpKey: 'division', symbol: '/');

  final String helpKey;
  final String symbol;

  const MathDemoOperation({required this.helpKey, required this.symbol});
}

class MathDemoQuestion {
  final MathDemoOperation operation;
  final int leftOperand;
  final int rightOperand;
  final int correctAnswer;

  const MathDemoQuestion({
    required this.operation,
    required this.leftOperand,
    required this.rightOperand,
    required this.correctAnswer,
  });

  String get prompt => '$leftOperand ${operation.symbol} $rightOperand = ?';

  String get helpLabel =>
      '$leftOperand ${operation.symbol} $rightOperand = $correctAnswer';
}

class MathHelperDemoEngine {
  const MathHelperDemoEngine();

  List<MathDemoQuestion> buildQuestions() {
    return const [
      MathDemoQuestion(
        operation: MathDemoOperation.addition,
        leftOperand: 2,
        rightOperand: 3,
        correctAnswer: 5,
      ),
      MathDemoQuestion(
        operation: MathDemoOperation.subtraction,
        leftOperand: 9,
        rightOperand: 4,
        correctAnswer: 5,
      ),
      MathDemoQuestion(
        operation: MathDemoOperation.multiplication,
        leftOperand: 3,
        rightOperand: 4,
        correctAnswer: 12,
      ),
      MathDemoQuestion(
        operation: MathDemoOperation.division,
        leftOperand: 12,
        rightOperand: 3,
        correctAnswer: 4,
      ),
    ];
  }

  List<int> buildOptions(MathDemoQuestion question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-3, -2, -1, 1, 2, 3, 4];

    for (final offset in offsets) {
      final candidate = question.correctAnswer + offset;
      if (candidate <= 0) continue;
      options.add(candidate);
      if (options.length == 4) break;
    }

    final sorted = options.toList()..sort();
    return sorted;
  }
}
