import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../domain/subtraction_quiz_trinn4_engine.dart';

class SubtractionQuizTrinn4Reward {
  final int stars;
  final int points;

  const SubtractionQuizTrinn4Reward({
    required this.stars,
    required this.points,
  });
}

class SubtractionQuizTrinn4SessionController {
  final SubtractionQuizTrinn4Engine _engine;
  final List<SubtractionQuizTrinn4Question> _questions;

  int _currentIndex = 0;
  int _correctCount = 0;

  SubtractionQuizTrinn4SessionController({SubtractionQuizTrinn4Engine? engine})
    : this._(engine ?? const SubtractionQuizTrinn4Engine());

  SubtractionQuizTrinn4SessionController._(this._engine)
    : _questions = _engine.buildQuestions();

  int get currentRoundNumber => _currentIndex + 1;

  int get totalRounds => _questions.length;

  int get correctCount => _correctCount;

  SubtractionQuizTrinn4Question get currentQuestion =>
      _questions[_currentIndex];

  List<int> get currentOptions => _engine.buildOptions(currentQuestion);

  MathHelpContext get helpContext {
    final question = currentQuestion;
    return MathHelpContext(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'subtraction',
      operands: [question.minuend, question.subtrahend],
      correctAnswer: question.correctAnswer,
      label: question.helpLabel,
    );
  }

  bool submitAnswer(int answer) {
    final isCorrect = answer == currentQuestion.correctAnswer;
    if (isCorrect) {
      _correctCount += 1;
    }
    return isCorrect;
  }

  bool advanceRound() {
    if (_currentIndex >= totalRounds - 1) {
      return true;
    }
    _currentIndex += 1;
    return false;
  }

  SubtractionQuizTrinn4Reward get reward {
    final stars = _starsFromAccuracy();
    final points = _correctCount * 3 + totalRounds;
    return SubtractionQuizTrinn4Reward(stars: stars, points: points);
  }

  int _starsFromAccuracy() {
    if (totalRounds == 0) {
      return 1;
    }
    final accuracy = _correctCount / totalRounds;
    if (accuracy >= 0.75) {
      return 3;
    }
    if (accuracy >= 0.4) {
      return 2;
    }
    return 1;
  }
}
