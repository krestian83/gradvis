import 'dart:math';

class DivisionDashQuestion {
  final int dividend;
  final int divisor;
  final List<int> options;

  const DivisionDashQuestion({
    required this.dividend,
    required this.divisor,
    required this.options,
  });

  int get answer => dividend ~/ divisor;

  String get expression => '$dividend \u00F7 $divisor';
}

class DivisionDashEngine {
  final Random _random;

  DivisionDashEngine({Random? random}) : _random = random ?? Random();

  List<DivisionDashQuestion> createQuestions({int count = 10}) {
    final safeCount = count < 1 ? 1 : count;
    return List<DivisionDashQuestion>.generate(
      safeCount,
      (i) => _createQuestion(i / safeCount),
    );
  }

  DivisionDashQuestion _createQuestion(double fraction) {
    final (divisorMin, divisorMax, quotientMin, quotientMax) = _difficultyRange(
      fraction,
    );

    final divisor = _random.nextInt(divisorMax - divisorMin + 1) + divisorMin;
    final quotient =
        _random.nextInt(quotientMax - quotientMin + 1) + quotientMin;
    final dividend = divisor * quotient;

    return DivisionDashQuestion(
      dividend: dividend,
      divisor: divisor,
      options: _buildOptions(quotient),
    );
  }

  (int, int, int, int) _difficultyRange(double fraction) {
    if (fraction < 0.4) {
      return (2, 5, 2, 5);
    }
    if (fraction < 0.75) {
      return (2, 9, 2, 9);
    }
    return (2, 9, 5, 12);
  }

  List<int> _buildOptions(int answer) {
    const offsets = [-5, -3, -2, -1, 1, 2, 3, 5];
    final options = <int>{answer};

    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 0) {
        options.add(candidate);
      }
    }

    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }
}
