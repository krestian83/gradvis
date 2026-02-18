class SubtractionQuizTrinn4Question {
  final int minuend;
  final int subtrahend;
  final int correctAnswer;

  const SubtractionQuizTrinn4Question({
    required this.minuend,
    required this.subtrahend,
    required this.correctAnswer,
  });

  String get prompt => '$minuend - $subtrahend = ?';

  String get helpLabel => '$minuend - $subtrahend = $correctAnswer';
}

class SubtractionQuizTrinn4Engine {
  const SubtractionQuizTrinn4Engine();

  List<SubtractionQuizTrinn4Question> buildQuestions() {
    final questions = <SubtractionQuizTrinn4Question>[];

    for (var minuend = 12; minuend <= 20; minuend++) {
      for (var subtrahend = 2; subtrahend <= 20; subtrahend++) {
        if (subtrahend >= minuend) {
          continue;
        }
        final needsBorrowing = (minuend % 10) < (subtrahend % 10);
        if (!needsBorrowing) {
          continue;
        }
        questions.add(
          SubtractionQuizTrinn4Question(
            minuend: minuend,
            subtrahend: subtrahend,
            correctAnswer: minuend - subtrahend,
          ),
        );
        if (questions.length == 40) {
          return questions;
        }
      }
    }

    return questions;
  }

  List<int> buildOptions(SubtractionQuizTrinn4Question question) {
    final options = <int>{question.correctAnswer};
    const offsets = [-6, -4, -2, 2, 4, 6, 8];

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
