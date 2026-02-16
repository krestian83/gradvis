import 'dart:math';

import 'norwegian_letters.dart';

class AlphabetRound {
  final NorwegianLetter target;
  final List<NorwegianLetter> options;

  const AlphabetRound({required this.target, required this.options});
}

/// Source of quiz rounds.
abstract interface class AlphabetRoundProvider {
  AlphabetRound nextRound();
}

/// Creates random "hear letter -> pick letter" rounds.
class AlphabetQuizEngine implements AlphabetRoundProvider {
  final List<NorwegianLetter> _letters;
  final Random _random;
  final int optionCount;

  AlphabetQuizEngine({
    List<NorwegianLetter> letters = norwegianLetters,
    Random? random,
    this.optionCount = 4,
  }) : assert(optionCount > 1),
       assert(letters.length >= optionCount),
       _letters = List.unmodifiable(letters),
       _random = random ?? Random();

  @override
  AlphabetRound nextRound() {
    final target = _letters[_random.nextInt(_letters.length)];
    final options = <NorwegianLetter>[target];

    while (options.length < optionCount) {
      final candidate = _letters[_random.nextInt(_letters.length)];
      if (!options.contains(candidate)) {
        options.add(candidate);
      }
    }

    _shuffle(options);
    return AlphabetRound(target: target, options: List.unmodifiable(options));
  }

  void _shuffle(List<NorwegianLetter> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}
