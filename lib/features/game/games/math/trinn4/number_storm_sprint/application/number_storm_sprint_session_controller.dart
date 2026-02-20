import 'dart:math';

import '../../../../../domain/game_interface.dart';
import '../domain/number_storm_sprint_engine.dart';

class NumberStormAnswerOutcome {
  final NumberStormSprintQuestion question;
  final int selectedAnswer;
  final bool isCorrect;
  final int answeredCount;
  final int livesRemaining;
  final double speedMultiplier;
  final bool isComplete;
  final bool isVictory;

  const NumberStormAnswerOutcome({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.answeredCount,
    required this.livesRemaining,
    required this.speedMultiplier,
    required this.isComplete,
    required this.isVictory,
  });
}

class NumberStormSprintSessionController {
  final List<NumberStormSprintQuestion> _questions;
  final int _masteryDenominator;

  int _index = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _livesRemaining = 3;
  double _speedMultiplier = 1.0;

  NumberStormSprintSessionController({
    NumberStormSprintEngine? engine,
    int questionCount = 20,
    List<NumberStormSprintQuestion>? questions,
    int masteryDenominator = 20,
  }) : _questions = List<NumberStormSprintQuestion>.unmodifiable(
         questions ??
             (engine ?? NumberStormSprintEngine()).createQuestions(
               count: questionCount < 1 ? 1 : questionCount,
             ),
       ),
       _masteryDenominator = masteryDenominator < 1 ? 1 : masteryDenominator;

  int get totalQuestions => _questions.length;
  int get answeredCount => _index;
  int get correctAnswers => _correctAnswers;
  int get wrongAnswers => _wrongAnswers;
  int get livesRemaining => _livesRemaining;
  double get speedMultiplier => _speedMultiplier;

  bool get isVictory => _index >= _questions.length && _livesRemaining > 0;
  bool get isGameOver => _livesRemaining < 1;
  bool get isComplete => isVictory || isGameOver;

  NumberStormSprintQuestion get currentQuestion {
    if (_index >= _questions.length) {
      return _questions.last;
    }
    return _questions[_index];
  }

  NumberStormAnswerOutcome submitAnswer(int selectedAnswer) {
    if (isComplete) {
      throw StateError('Session already completed.');
    }

    final question = currentQuestion;
    final isCorrect = selectedAnswer == question.answer;
    if (isCorrect) {
      _correctAnswers += 1;
    } else {
      _wrongAnswers += 1;
      _livesRemaining = max(0, _livesRemaining - 1);
    }

    _index += 1;
    _speedMultiplier = (_speedMultiplier * 1.07).clamp(1.0, 2.2).toDouble();

    return NumberStormAnswerOutcome(
      question: question,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      answeredCount: _index,
      livesRemaining: _livesRemaining,
      speedMultiplier: _speedMultiplier,
      isComplete: isComplete,
      isVictory: isVictory,
    );
  }

  GameResult buildResult() {
    final mastery = _correctAnswers / _masteryDenominator;
    final stars = _starsFromMastery(mastery);
    final pointsEarned =
        (_correctAnswers * 18) + (_index * 4) + (_livesRemaining * 12);
    return GameResult(stars: stars, pointsEarned: pointsEarned);
  }

  int _starsFromMastery(double mastery) {
    if (mastery >= 0.85) {
      return 3;
    }
    if (mastery >= 0.60) {
      return 2;
    }
    return 1;
  }
}
