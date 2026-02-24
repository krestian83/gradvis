import '../../../../../domain/game_interface.dart';
import '../domain/division_dash_engine.dart';

class DivisionDashSessionController {
  final List<DivisionDashQuestion> _questions;
  int _index = 0;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  DivisionDashSessionController({
    DivisionDashEngine? engine,
    int roundCount = 10,
  }) : _questions = (engine ?? DivisionDashEngine()).createQuestions(
         count: roundCount < 1 ? 1 : roundCount,
       );

  DivisionDashQuestion get currentQuestion => _questions[_index];

  int get totalRounds => _questions.length;
  int get correctAnswers => _correctAnswers;
  int get bestStreak => _bestStreak;
  bool get isFinished => _index >= _questions.length;

  int get currentRound {
    final round = _index + 1;
    if (round > _questions.length) {
      return _questions.length;
    }
    return round;
  }

  bool submitAnswer(int selectedAnswer) {
    if (isFinished) {
      return false;
    }

    final isCorrect = selectedAnswer == currentQuestion.answer;
    if (isCorrect) {
      _correctAnswers += 1;
      _currentStreak += 1;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    _index += 1;
    return isCorrect;
  }

  GameResult buildResult() {
    final accuracy = _correctAnswers / totalRounds;
    final stars = _starsFromAccuracy(accuracy);
    final pointsEarned = (_correctAnswers * 15) + (_bestStreak * 6);
    return GameResult(stars: stars, pointsEarned: pointsEarned);
  }

  int _starsFromAccuracy(double accuracy) {
    if (accuracy >= 0.88) {
      return 3;
    }
    if (accuracy >= 0.63) {
      return 2;
    }
    return 1;
  }
}
