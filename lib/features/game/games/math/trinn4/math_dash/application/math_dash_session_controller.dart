import '../../../../../domain/game_interface.dart';
import '../domain/math_dash_engine.dart';
import '../domain/math_dash_question.dart';

/// Manages the 20-question Math Dash session with lives and speed.
class MathDashSessionController {
  final List<MathDashQuestion> _questions;
  int _index = 0;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _lives = 3;
  double _speed = 120.0;

  static const _speedMultiplier = 1.20;

  MathDashSessionController({MathDashEngine? engine})
    : _questions = (engine ?? MathDashEngine()).createQuestions();

  MathDashQuestion get currentQuestion => _questions[_index];

  int get totalRounds => _questions.length;
  int get currentRound => (_index + 1).clamp(1, _questions.length);
  int get correctAnswers => _correctAnswers;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get lives => _lives;
  double get speed => _speed;
  int get questionIndex => _index;

  bool get isGameOver => _lives <= 0;
  bool get isVictory => _index >= _questions.length && _lives > 0;
  bool get isFinished => isGameOver || isVictory;

  /// Returns the theme index (0-3) based on current question block.
  int get environmentThemeIndex => (_index ~/ 5).clamp(0, 3);

  /// Submit an answer. Returns `true` if correct.
  bool submitAnswer(int selectedAnswer) {
    if (isFinished) return false;

    final isCorrect = selectedAnswer == currentQuestion.answer;
    if (isCorrect) {
      _correctAnswers += 1;
      _currentStreak += 1;
      if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
      _speed *= _speedMultiplier;
    } else {
      _lives -= 1;
      _currentStreak = 0;
    }

    _index += 1;
    return isCorrect;
  }

  GameResult buildResult() {
    final accuracy =
        totalRounds > 0 ? _correctAnswers / totalRounds : 0.0;
    final stars = _starsFromAccuracy(accuracy);
    final points = (_correctAnswers * 12) + (_bestStreak * 8);
    return GameResult(stars: stars, pointsEarned: points);
  }

  int _starsFromAccuracy(double accuracy) {
    if (accuracy >= 0.88) return 3;
    if (accuracy >= 0.63) return 2;
    return 1;
  }
}
