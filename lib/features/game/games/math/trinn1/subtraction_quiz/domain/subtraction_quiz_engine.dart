class SubtractionQuizQuestion {
  final int minuend;
  final int subtrahend;
  final int correctAnswer;

  const SubtractionQuizQuestion({
    required this.minuend,
    required this.subtrahend,
    required this.correctAnswer,
  });

  String get prompt => '$minuend - $subtrahend = ?';

  String get helpLabel => '$minuend - $subtrahend = $correctAnswer';
}

class SubtractionQuizEngine {
  const SubtractionQuizEngine();

  List<SubtractionQuizQuestion> buildQuestions() {
    return const [
      SubtractionQuizQuestion(minuend: 8, subtrahend: 3, correctAnswer: 5),
      SubtractionQuizQuestion(minuend: 10, subtrahend: 4, correctAnswer: 6),
      SubtractionQuizQuestion(minuend: 12, subtrahend: 5, correctAnswer: 7),
      SubtractionQuizQuestion(minuend: 14, subtrahend: 6, correctAnswer: 8),
    ];
  }

  List<int> buildOptions(SubtractionQuizQuestion question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-3, -2, -1, 1, 2, 3, 4];

    for (final offset in offsets) {
      final candidate = question.correctAnswer + offset;
      if (candidate < 0) {
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
