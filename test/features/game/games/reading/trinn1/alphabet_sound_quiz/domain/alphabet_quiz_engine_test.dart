import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/alphabet_quiz_engine.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/norwegian_letters.dart';

void main() {
  group('AlphabetQuizEngine', () {
    test('creates rounds with target included and unique options', () {
      final engine = AlphabetQuizEngine(
        letters: norwegianLetters,
        random: Random(7),
        optionCount: 4,
      );

      for (var i = 0; i < 200; i++) {
        final round = engine.nextRound();
        expect(round.options.length, 4);
        expect(round.options.toSet().length, 4);
        expect(round.options, contains(round.target));
      }
    });
  });
}
