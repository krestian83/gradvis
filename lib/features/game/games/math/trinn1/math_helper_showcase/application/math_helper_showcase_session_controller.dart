import '../../../../../math_help/domain/math_help_context.dart';
import '../../../../../math_help/domain/math_topic_family.dart';
import '../domain/math_helper_showcase_engine.dart';

class MathHelperShowcaseReward {
  final int stars;
  final int points;

  const MathHelperShowcaseReward({required this.stars, required this.points});
}

class MathHelperShowcaseSessionController {
  final List<MathHelperShowcaseQuestion> _questions;

  int _currentIndex = 0;
  int _correctAnswers = 0;

  MathHelperShowcaseSessionController({MathHelperShowcaseEngine? engine})
    : _questions = (engine ?? const MathHelperShowcaseEngine())
          .buildQuestions();

  int get currentRoundNumber => _currentIndex + 1;

  int get totalRounds => _questions.length;

  int get correctAnswers => _correctAnswers;

  MathHelperShowcaseQuestion get currentQuestion => _questions[_currentIndex];

  List<int> get currentOptions => currentQuestion.options;

  MathHelpContext get helpContext {
    final question = currentQuestion;
    return MathHelpContext(
      topicFamily: _toMathTopicFamily(question.topicFamily),
      operation: question.operation,
      operands: question.operands,
      correctAnswer: question.correctAnswer,
      label: question.helpLabel,
    );
  }

  bool submitAnswer(int answer) {
    final isCorrect = answer == currentQuestion.correctAnswer;
    if (isCorrect) {
      _correctAnswers += 1;
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

  MathHelperShowcaseReward get reward {
    final accuracy = totalRounds == 0 ? 0 : _correctAnswers / totalRounds;
    final stars = switch (accuracy) {
      >= 0.8 => 3,
      >= 0.5 => 2,
      _ => 1,
    };
    final points = _correctAnswers * 4 + totalRounds;
    return MathHelperShowcaseReward(stars: stars, points: points);
  }

  MathTopicFamily _toMathTopicFamily(ShowcaseTopicFamily topicFamily) {
    return switch (topicFamily) {
      ShowcaseTopicFamily.geometry => MathTopicFamily.geometry,
      ShowcaseTopicFamily.measurement => MathTopicFamily.measurement,
      ShowcaseTopicFamily.algorithmicThinking =>
        MathTopicFamily.algorithmicThinking,
    };
  }
}
