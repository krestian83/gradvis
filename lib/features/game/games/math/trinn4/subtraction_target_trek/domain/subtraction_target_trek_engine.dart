import 'dart:math';

class SubtractionTargetTrekQuestion {
  final int minuend;
  final int subtrahend;
  final List<int> options;

  const SubtractionTargetTrekQuestion({
    required this.minuend,
    required this.subtrahend,
    required this.options,
  });

  int get answer => minuend - subtrahend;

  String get expression => '$minuend - $subtrahend';
}

class SubtractionTargetTrekEngine {
  final Random _random;

  SubtractionTargetTrekEngine({Random? random}) : _random = random ?? Random();

  List<SubtractionTargetTrekQuestion> createQuestions({int count = 8}) {
    final safeCount = count < 1 ? 1 : count;
    return List<SubtractionTargetTrekQuestion>.generate(
      safeCount,
      (_) => _createQuestion(),
    );
  }

  SubtractionTargetTrekQuestion _createQuestion() {
    while (true) {
      final minuend = _random.nextInt(301) + 120;
      final subtrahend = _random.nextInt(171) + 28;
      final answer = minuend - subtrahend;
      final needsBorrowOnes = (minuend % 10) < (subtrahend % 10);
      final needsBorrowTens =
          ((minuend ~/ 10) % 10) < ((subtrahend ~/ 10) % 10);

      if (answer < 25 || answer > 280) {
        continue;
      }
      if (!needsBorrowOnes && !needsBorrowTens) {
        continue;
      }

      return SubtractionTargetTrekQuestion(
        minuend: minuend,
        subtrahend: subtrahend,
        options: _buildOptions(answer),
      );
    }
  }

  List<int> _buildOptions(int answer) {
    const offsets = [-30, -20, -10, -5, -1, 1, 5, 10, 20, 30];
    final options = <int>{answer};

    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 0 && candidate < 350) {
        options.add(candidate);
      }
    }

    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }
}
