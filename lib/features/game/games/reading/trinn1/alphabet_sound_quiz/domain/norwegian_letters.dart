/// One letter in the Norwegian alphabet with its audio asset key.
class NorwegianLetter {
  final String upper;
  final String lower;
  final String audioKey;

  const NorwegianLetter({
    required this.upper,
    required this.lower,
    required this.audioKey,
  });

  @override
  int get hashCode => Object.hash(upper, lower, audioKey);

  @override
  bool operator ==(Object other) =>
      other is NorwegianLetter &&
      other.upper == upper &&
      other.lower == lower &&
      other.audioKey == audioKey;
}

/// Full Norwegian alphabet (29 letters).
const List<NorwegianLetter> norwegianLetters = [
  NorwegianLetter(upper: 'A', lower: 'a', audioKey: 'a'),
  NorwegianLetter(upper: 'B', lower: 'b', audioKey: 'b'),
  NorwegianLetter(upper: 'C', lower: 'c', audioKey: 'c'),
  NorwegianLetter(upper: 'D', lower: 'd', audioKey: 'd'),
  NorwegianLetter(upper: 'E', lower: 'e', audioKey: 'e'),
  NorwegianLetter(upper: 'F', lower: 'f', audioKey: 'f'),
  NorwegianLetter(upper: 'G', lower: 'g', audioKey: 'g'),
  NorwegianLetter(upper: 'H', lower: 'h', audioKey: 'h'),
  NorwegianLetter(upper: 'I', lower: 'i', audioKey: 'i'),
  NorwegianLetter(upper: 'J', lower: 'j', audioKey: 'j'),
  NorwegianLetter(upper: 'K', lower: 'k', audioKey: 'k'),
  NorwegianLetter(upper: 'L', lower: 'l', audioKey: 'l'),
  NorwegianLetter(upper: 'M', lower: 'm', audioKey: 'm'),
  NorwegianLetter(upper: 'N', lower: 'n', audioKey: 'n'),
  NorwegianLetter(upper: 'O', lower: 'o', audioKey: 'o'),
  NorwegianLetter(upper: 'P', lower: 'p', audioKey: 'p'),
  NorwegianLetter(upper: 'Q', lower: 'q', audioKey: 'q'),
  NorwegianLetter(upper: 'R', lower: 'r', audioKey: 'r'),
  NorwegianLetter(upper: 'S', lower: 's', audioKey: 's'),
  NorwegianLetter(upper: 'T', lower: 't', audioKey: 't'),
  NorwegianLetter(upper: 'U', lower: 'u', audioKey: 'u'),
  NorwegianLetter(upper: 'V', lower: 'v', audioKey: 'v'),
  NorwegianLetter(upper: 'W', lower: 'w', audioKey: 'w'),
  NorwegianLetter(upper: 'X', lower: 'x', audioKey: 'x'),
  NorwegianLetter(upper: 'Y', lower: 'y', audioKey: 'y'),
  NorwegianLetter(upper: 'Z', lower: 'z', audioKey: 'z'),
  NorwegianLetter(upper: 'Æ', lower: 'æ', audioKey: 'ae'),
  NorwegianLetter(upper: 'Ø', lower: 'ø', audioKey: 'oe'),
  NorwegianLetter(upper: 'Å', lower: 'å', audioKey: 'aa'),
];
