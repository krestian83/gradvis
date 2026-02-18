import 'dart:math';

class MultiplicationTableSprintQuestion {
  final int leftFactor;
  final int rightFactor;
  final List<int> options;

  const MultiplicationTableSprintQuestion({
    required this.leftFactor,
    required this.rightFactor,
    required this.options,
  });

  int get answer => leftFactor * rightFactor;

  String get expression => '$leftFactor x $rightFactor';
}

class MultiplicationTableSprintEngine {
  final Random _random;

  MultiplicationTableSprintEngine({Random? random})
    : _random = random ?? Random();

  List<MultiplicationTableSprintQuestion> createQuestions({int count = 8}) {
    final safeCount = count < 1 ? 1 : count;
    return List<MultiplicationTableSprintQuestion>.generate(
      safeCount,
      (_) => _createQuestion(),
    );
  }

  MultiplicationTableSprintQuestion _createQuestion() {
    final leftFactor = _random.nextInt(5) + 6;
    final rightFactor = _random.nextInt(10) + 3;
    final answer = leftFactor * rightFactor;

    return MultiplicationTableSprintQuestion(
      leftFactor: leftFactor,
      rightFactor: rightFactor,
      options: _buildOptions(leftFactor, rightFactor, answer),
    );
  }

  List<int> _buildOptions(int leftFactor, int rightFactor, int answer) {
    final options = <int>{answer};
    final nearRight = rightFactor == 12 ? rightFactor - 1 : rightFactor + 1;
    final nearLeft = leftFactor == 10 ? leftFactor - 1 : leftFactor + 1;
    options.add(leftFactor * nearRight);
    options.add(nearLeft * rightFactor);

    const offsets = [-12, -10, -6, -4, 4, 6, 10, 12];
    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 10 && candidate <= 120) {
        options.add(candidate);
      }
    }

    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }
}
