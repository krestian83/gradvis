import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/application/alphabet_session_controller.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/alphabet_quiz_engine.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/norwegian_letters.dart';

class _CyclingRoundProvider implements AlphabetRoundProvider {
  final List<AlphabetRound> _rounds;
  int _index = 0;

  _CyclingRoundProvider(this._rounds);

  @override
  AlphabetRound nextRound() {
    final round = _rounds[_index % _rounds.length];
    _index += 1;
    return round;
  }
}

void main() {
  final a = norwegianLetters.firstWhere((letter) => letter.upper == 'A');
  final b = norwegianLetters.firstWhere((letter) => letter.upper == 'B');
  final c = norwegianLetters.firstWhere((letter) => letter.upper == 'C');
  final d = norwegianLetters.firstWhere((letter) => letter.upper == 'D');
  final round = AlphabetRound(target: a, options: [a, b, c, d]);

  group('AlphabetSessionController', () {
    test('completes only after 12 correct answers', () {
      final session = AlphabetSessionController(
        roundProvider: _CyclingRoundProvider([round]),
        totalRounds: 12,
      );

      for (var i = 0; i < 11; i++) {
        expect(session.advanceAfterCorrectAnswer(), isFalse);
      }

      expect(session.currentRoundNumber, 12);
      expect(session.advanceAfterCorrectAnswer(), isTrue);
    });

    test('restart resets round number and increments restart count', () {
      final session = AlphabetSessionController(
        roundProvider: _CyclingRoundProvider([round]),
        totalRounds: 12,
      );

      session.advanceAfterCorrectAnswer();
      session.advanceAfterCorrectAnswer();
      expect(session.currentRoundNumber, 3);

      session.restartFromWrongAnswer();
      expect(session.currentRoundNumber, 1);
      expect(session.restartCount, 1);
    });

    test('maps restart count to stars and points', () {
      expect(AlphabetReward.fromRestartCount(0).stars, 3);
      expect(AlphabetReward.fromRestartCount(0).points, 14);

      expect(AlphabetReward.fromRestartCount(1).stars, 2);
      expect(AlphabetReward.fromRestartCount(1).points, 10);
      expect(AlphabetReward.fromRestartCount(2).stars, 2);
      expect(AlphabetReward.fromRestartCount(2).points, 10);

      expect(AlphabetReward.fromRestartCount(3).stars, 1);
      expect(AlphabetReward.fromRestartCount(3).points, 6);
      expect(AlphabetReward.fromRestartCount(9).stars, 1);
      expect(AlphabetReward.fromRestartCount(9).points, 6);
    });
  });
}
