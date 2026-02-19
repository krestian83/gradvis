import 'dart:math';

import 'math_dash_question.dart';

/// Generates 20 mixed-operation questions (5 per operation).
class MathDashEngine {
  final Random _random;

  MathDashEngine({Random? random}) : _random = random ?? Random();

  List<MathDashQuestion> createQuestions() {
    final questions = <MathDashQuestion>[
      for (var i = 0; i < 5; i++) _createAddition(),
      for (var i = 0; i < 5; i++) _createSubtraction(),
      for (var i = 0; i < 5; i++) _createMultiplication(),
      for (var i = 0; i < 5; i++) _createDivision(),
    ];
    questions.shuffle(_random);
    return questions;
  }

  /// Two-digit + single-digit, sum ≤ 99.
  MathDashQuestion _createAddition() {
    final left = _random.nextInt(60) + 12;
    final right = _random.nextInt(8) + 2;
    final sum = left + right;
    return MathDashQuestion(
      left: left,
      right: right,
      operator: '+',
      answer: sum,
      options: _buildAdditiveOptions(sum),
    );
  }

  /// Two-digit − single-digit, result > 10.
  MathDashQuestion _createSubtraction() {
    final left = _random.nextInt(60) + 20;
    final right = _random.nextInt(8) + 2;
    final diff = left - right;
    return MathDashQuestion(
      left: left,
      right: right,
      operator: '-',
      answer: diff,
      options: _buildAdditiveOptions(diff),
    );
  }

  /// Tables 6-10.
  MathDashQuestion _createMultiplication() {
    final left = _random.nextInt(5) + 6;
    final right = _random.nextInt(10) + 3;
    final product = left * right;
    return MathDashQuestion(
      left: left,
      right: right,
      operator: '*',
      answer: product,
      options: _buildMultiplicationOptions(left, right, product),
    );
  }

  /// Reverse multiplication: product / a = b.
  MathDashQuestion _createDivision() {
    final a = _random.nextInt(5) + 6;
    final b = _random.nextInt(10) + 3;
    final product = a * b;
    return MathDashQuestion(
      left: product,
      right: a,
      operator: '/',
      answer: b,
      options: _buildDivisionOptions(b),
    );
  }

  List<int> _buildAdditiveOptions(int answer) {
    const offsets = [-30, -20, -10, -5, -1, 1, 5, 10, 20, 30];
    final options = <int>{answer};
    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 0) options.add(candidate);
    }
    return options.toList()..shuffle(_random);
  }

  List<int> _buildMultiplicationOptions(
    int left,
    int right,
    int answer,
  ) {
    final options = <int>{answer};
    final nearRight = right == 12 ? right - 1 : right + 1;
    final nearLeft = left == 10 ? left - 1 : left + 1;
    options.add(left * nearRight);
    options.add(nearLeft * right);
    const offsets = [-12, -10, -6, -4, 4, 6, 10, 12];
    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 0) options.add(candidate);
    }
    return options.toList()..shuffle(_random);
  }

  List<int> _buildDivisionOptions(int answer) {
    const offsets = [-3, -2, -1, 1, 2, 3];
    final options = <int>{answer};
    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 0) options.add(candidate);
    }
    return options.toList()..shuffle(_random);
  }
}
