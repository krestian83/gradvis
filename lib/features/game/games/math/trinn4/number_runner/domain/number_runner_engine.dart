import 'dart:math';

/// A single question in the number runner game.
class NumberRunnerQuestion {
  final int operandA;
  final int operandB;
  final String operator;
  final List<int> options;
  final int answer;
  final String expression;

  /// Key for the math-help visualizer registry.
  final String operationKey;

  const NumberRunnerQuestion({
    required this.operandA,
    required this.operandB,
    required this.operator,
    required this.options,
    required this.answer,
    required this.expression,
    required this.operationKey,
  });
}

/// Generates questions with progressive difficulty for the runner.
class NumberRunnerEngine {
  final Random _random;

  NumberRunnerEngine({Random? random}) : _random = random ?? Random();

  List<NumberRunnerQuestion> createQuestions({int count = 20}) {
    final safeCount = count < 1 ? 1 : count;
    return List<NumberRunnerQuestion>.generate(
      safeCount,
      (i) => _createForIndex(i, safeCount),
    );
  }

  NumberRunnerQuestion _createForIndex(int index, int total) {
    final fraction = index / total;
    if (fraction < 0.3) return _easyAddSub();
    if (fraction < 0.6) return _mediumAddSub();
    if (fraction < 0.8) return _easyMul();
    return _harderMulDiv();
  }

  // Q1–6: single-digit operands, sums <= 20.
  NumberRunnerQuestion _easyAddSub() {
    final useAdd = _random.nextBool();
    if (useAdd) {
      final a = _random.nextInt(9) + 1;
      final b = _random.nextInt(min(9, 20 - a)) + 1;
      return _build(a, b, '+', 'addition');
    }
    final a = _random.nextInt(14) + 6;
    final b = _random.nextInt(a - 1) + 1;
    return _build(a, b, '-', 'subtraction');
  }

  // Q7–12: two-digit operands, sums <= 100.
  NumberRunnerQuestion _mediumAddSub() {
    final useAdd = _random.nextBool();
    if (useAdd) {
      final a = _random.nextInt(41) + 10;
      final b = _random.nextInt(min(50, 100 - a)) + 10;
      return _build(a, b, '+', 'addition');
    }
    final a = _random.nextInt(61) + 30;
    final b = _random.nextInt(a - 10) + 10;
    return _build(a, b, '-', 'subtraction');
  }

  // Q13–16: multiplication 2–9 x 2–9.
  NumberRunnerQuestion _easyMul() {
    final a = _random.nextInt(8) + 2;
    final b = _random.nextInt(8) + 2;
    return _build(a, b, '\u00d7', 'multiplication');
  }

  // Q17–20: harder multiplication or exact division.
  NumberRunnerQuestion _harderMulDiv() {
    final useDiv = _random.nextBool();
    if (useDiv) {
      final divisor = _random.nextInt(8) + 2;
      final quotient = _random.nextInt(9) + 2;
      final dividend = divisor * quotient;
      return _build(dividend, divisor, '\u00f7', 'division');
    }
    final a = _random.nextInt(6) + 5;
    final b = _random.nextInt(8) + 3;
    return _build(a, b, '\u00d7', 'multiplication');
  }

  NumberRunnerQuestion _build(
    int a,
    int b,
    String op,
    String operationKey,
  ) {
    final answer = switch (op) {
      '+' => a + b,
      '-' => a - b,
      '\u00d7' => a * b,
      '\u00f7' => a ~/ b,
      _ => throw ArgumentError('Unknown operator: $op'),
    };
    return NumberRunnerQuestion(
      operandA: a,
      operandB: b,
      operator: op,
      answer: answer,
      expression: '$a $op $b',
      operationKey: operationKey,
      options: _buildOptions(answer),
    );
  }

  List<int> _buildOptions(int answer) {
    final offsets = <int>[-3, -2, -1, 1, 2, 3, 5, 10];
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
