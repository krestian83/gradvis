import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/games/reading/trinn1/alphabet_sound_quiz/domain/norwegian_letters.dart';

void main() {
  group('norwegianLetters', () {
    test('contains all 29 unique letters and audio keys', () {
      expect(norwegianLetters.length, 29);
      expect(norwegianLetters.map((e) => e.upper).toSet().length, 29);
      expect(norwegianLetters.map((e) => e.audioKey).toSet().length, 29);
    });

    test('includes A-Z plus AE/OE/AA mapping for Norwegian letters', () {
      expect(
        norwegianLetters.any(
          (letter) => letter.upper == 'Æ' && letter.audioKey == 'ae',
        ),
        isTrue,
      );
      expect(
        norwegianLetters.any(
          (letter) => letter.upper == 'Ø' && letter.audioKey == 'oe',
        ),
        isTrue,
      );
      expect(
        norwegianLetters.any(
          (letter) => letter.upper == 'Å' && letter.audioKey == 'aa',
        ),
        isTrue,
      );
    });
  });
}
