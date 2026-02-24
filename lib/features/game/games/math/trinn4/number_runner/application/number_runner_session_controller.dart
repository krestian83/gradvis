import 'package:flutter/foundation.dart';

import '../../../../../domain/game_interface.dart';
import '../domain/number_runner_engine.dart';

/// Manages game session state: lives, scoring, streaks, completion.
class NumberRunnerSessionController extends ChangeNotifier {
  final List<NumberRunnerQuestion> _questions;
  int _index = 0;
  int _lives;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  NumberRunnerSessionController({
    NumberRunnerEngine? engine,
    int questionCount = 20,
    int lives = 3,
  })  : _lives = lives < 1 ? 1 : lives,
        _questions = (engine ?? NumberRunnerEngine())
            .createQuestions(count: questionCount < 1 ? 1 : questionCount);

  NumberRunnerQuestion get currentQuestion => _questions[_index];

  int get totalQuestions => _questions.length;
  int get currentIndex => _index;
  int get lives => _lives;
  int get correctAnswers => _correctAnswers;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  bool get isGameOver => _lives <= 0;
  bool get isFinished => _index >= _questions.length;
  bool get isVictory => isFinished && !isGameOver;

  /// Returns `true` when the selected answer is correct.
  bool submitAnswer(int selectedAnswer) {
    if (isFinished || isGameOver) return false;

    final isCorrect = selectedAnswer == currentQuestion.answer;
    if (isCorrect) {
      _correctAnswers += 1;
      _currentStreak += 1;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _lives -= 1;
      _currentStreak = 0;
    }

    _index += 1;
    notifyListeners();
    return isCorrect;
  }

  GameResult buildResult() {
    final accuracy =
        totalQuestions > 0 ? _correctAnswers / totalQuestions : 0.0;
    final stars = _starsFromAccuracy(accuracy);
    final points = (_correctAnswers * 16) + (_bestStreak * 6);
    return GameResult(stars: stars, pointsEarned: points);
  }

  int _starsFromAccuracy(double accuracy) {
    if (accuracy >= 0.88) return 3;
    if (accuracy >= 0.63) return 2;
    return 1;
  }
}
