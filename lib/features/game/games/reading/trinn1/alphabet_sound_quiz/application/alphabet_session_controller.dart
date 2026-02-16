import '../domain/alphabet_quiz_engine.dart';
import '../domain/norwegian_letters.dart';

class AlphabetReward {
  final int stars;
  final int points;

  const AlphabetReward({required this.stars, required this.points});

  static AlphabetReward fromRestartCount(int restartCount) {
    if (restartCount <= 0) {
      return const AlphabetReward(stars: 3, points: 14);
    }
    if (restartCount <= 2) {
      return const AlphabetReward(stars: 2, points: 10);
    }
    return const AlphabetReward(stars: 1, points: 6);
  }
}

/// Stateful session logic for one alphabet game run.
class AlphabetSessionController {
  final AlphabetRoundProvider _roundProvider;
  final int totalRounds;

  int _currentRoundNumber = 1;
  int _restartCount = 0;
  late AlphabetRound _currentRound;

  AlphabetSessionController({
    required AlphabetRoundProvider roundProvider,
    this.totalRounds = 12,
  }) : assert(totalRounds > 0),
       _roundProvider = roundProvider {
    _currentRound = _roundProvider.nextRound();
  }

  int get currentRoundNumber => _currentRoundNumber;
  int get restartCount => _restartCount;
  AlphabetRound get currentRound => _currentRound;
  AlphabetReward get reward => AlphabetReward.fromRestartCount(_restartCount);

  bool isCorrectAnswer(NorwegianLetter selected) =>
      selected == _currentRound.target;

  /// Returns true when the session is completed.
  bool advanceAfterCorrectAnswer() {
    if (_currentRoundNumber >= totalRounds) {
      return true;
    }

    _currentRoundNumber += 1;
    _currentRound = _roundProvider.nextRound();
    return false;
  }

  void restartFromWrongAnswer() {
    _restartCount += 1;
    _currentRoundNumber = 1;
    _currentRound = _roundProvider.nextRound();
  }
}
