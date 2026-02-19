/// Immutable question for a single Math Dash round.
class MathDashQuestion {
  final int left;
  final int right;
  final String operator;
  final int answer;
  final List<int> options;

  const MathDashQuestion({
    required this.left,
    required this.right,
    required this.operator,
    required this.answer,
    required this.options,
  });

  /// Human-readable expression, e.g. `'34 + 58'`.
  String get expression => '$left $operator $right';

  /// Maps the operator symbol to a math-help visualizer key.
  String get operationKey => switch (operator) {
    '+' => 'addition',
    '-' => 'subtraction',
    '*' => 'multiplication',
    '/' => 'division',
    _ => 'addition',
  };
}
