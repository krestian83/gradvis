import 'dart:math';

enum NumberStormOperation { addition, subtraction, multiplication, division }

extension NumberStormOperationX on NumberStormOperation {
  String get symbol {
    switch (this) {
      case NumberStormOperation.addition:
        return '+';
      case NumberStormOperation.subtraction:
        return '-';
      case NumberStormOperation.multiplication:
        return 'x';
      case NumberStormOperation.division:
        return '/';
    }
  }

  String get mathHelpOperation {
    switch (this) {
      case NumberStormOperation.addition:
        return 'addition';
      case NumberStormOperation.subtraction:
        return 'subtraction';
      case NumberStormOperation.multiplication:
        return 'multiplication';
      case NumberStormOperation.division:
        return 'division';
    }
  }
}

class NumberStormSprintQuestion {
  final NumberStormOperation operation;
  final int leftOperand;
  final int rightOperand;
  final List<int> options;

  const NumberStormSprintQuestion({
    required this.operation,
    required this.leftOperand,
    required this.rightOperand,
    required this.options,
  });

  int get answer {
    switch (operation) {
      case NumberStormOperation.addition:
        return leftOperand + rightOperand;
      case NumberStormOperation.subtraction:
        return leftOperand - rightOperand;
      case NumberStormOperation.multiplication:
        return leftOperand * rightOperand;
      case NumberStormOperation.division:
        return leftOperand ~/ rightOperand;
    }
  }

  String get expression => '$leftOperand ${operation.symbol} $rightOperand';
  String get mathHelpOperation => operation.mathHelpOperation;
}

class NumberStormSprintEngine {
  final Random _random;

  NumberStormSprintEngine({Random? random}) : _random = random ?? Random();

  List<NumberStormSprintQuestion> createQuestions({int count = 20}) {
    final safeCount = count < 1 ? 1 : count;
    return List<NumberStormSprintQuestion>.generate(
      safeCount,
      (_) => _createQuestion(),
    );
  }

  NumberStormSprintQuestion _createQuestion() {
    final operation = NumberStormOperation
        .values[_random.nextInt(NumberStormOperation.values.length)];
    switch (operation) {
      case NumberStormOperation.addition:
        return _createAdditionQuestion();
      case NumberStormOperation.subtraction:
        return _createSubtractionQuestion();
      case NumberStormOperation.multiplication:
        return _createMultiplicationQuestion();
      case NumberStormOperation.division:
        return _createDivisionQuestion();
    }
  }

  NumberStormSprintQuestion _createAdditionQuestion() {
    final leftOperand = _random.nextInt(161) + 20;
    final rightOperand = _random.nextInt(91) + 8;
    final answer = leftOperand + rightOperand;
    return NumberStormSprintQuestion(
      operation: NumberStormOperation.addition,
      leftOperand: leftOperand,
      rightOperand: rightOperand,
      options: _buildOptions(answer: answer, minValue: 10, maxValue: 280),
    );
  }

  NumberStormSprintQuestion _createSubtractionQuestion() {
    final minuend = _random.nextInt(171) + 55;
    final maxSubtrahend = min(minuend - 6, 120);
    final subtrahend = _random.nextInt(maxSubtrahend - 4) + 5;
    final answer = minuend - subtrahend;
    return NumberStormSprintQuestion(
      operation: NumberStormOperation.subtraction,
      leftOperand: minuend,
      rightOperand: subtrahend,
      options: _buildOptions(answer: answer, minValue: 4, maxValue: 220),
    );
  }

  NumberStormSprintQuestion _createMultiplicationQuestion() {
    final leftFactor = _random.nextInt(10) + 3;
    final rightFactor = _random.nextInt(10) + 3;
    final answer = leftFactor * rightFactor;
    return NumberStormSprintQuestion(
      operation: NumberStormOperation.multiplication,
      leftOperand: leftFactor,
      rightOperand: rightFactor,
      options: _buildOptions(answer: answer, minValue: 6, maxValue: 180),
    );
  }

  NumberStormSprintQuestion _createDivisionQuestion() {
    final divisor = _random.nextInt(11) + 2;
    final quotient = _random.nextInt(11) + 2;
    final dividend = divisor * quotient;
    return NumberStormSprintQuestion(
      operation: NumberStormOperation.division,
      leftOperand: dividend,
      rightOperand: divisor,
      options: _buildOptions(answer: quotient, minValue: 1, maxValue: 24),
    );
  }

  List<int> _buildOptions({
    required int answer,
    required int minValue,
    required int maxValue,
  }) {
    const offsets = <int>[
      -30,
      -20,
      -12,
      -10,
      -8,
      -6,
      -4,
      -3,
      -2,
      -1,
      1,
      2,
      3,
      4,
      6,
      8,
      10,
      12,
      20,
      30,
    ];
    final options = <int>{answer};

    var attempts = 0;
    while (options.length < 4 && attempts < 80) {
      attempts += 1;
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate >= minValue && candidate <= maxValue) {
        options.add(candidate);
      }
    }

    var fallback = minValue;
    while (options.length < 4) {
      if (fallback != answer) {
        options.add(fallback);
      }
      fallback += 1;
      if (fallback > maxValue) {
        fallback = minValue;
      }
    }

    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }
}
