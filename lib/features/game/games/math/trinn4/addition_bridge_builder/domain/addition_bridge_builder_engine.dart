import 'dart:math';

class AdditionBridgeBuilderQuestion {
  final int left;
  final int right;
  final List<int> options;

  const AdditionBridgeBuilderQuestion({
    required this.left,
    required this.right,
    required this.options,
  });

  int get answer => left + right;

  String get expression => '$left + $right';
}

class AdditionBridgeBuilderEngine {
  final Random _random;

  AdditionBridgeBuilderEngine({Random? random}) : _random = random ?? Random();

  List<AdditionBridgeBuilderQuestion> createQuestions({int count = 8}) {
    final safeCount = count < 1 ? 1 : count;
    return List<AdditionBridgeBuilderQuestion>.generate(
      safeCount,
      (_) => _createQuestion(),
    );
  }

  AdditionBridgeBuilderQuestion _createQuestion() {
    while (true) {
      final left = _random.nextInt(69) + 28;
      final right = _random.nextInt(73) + 17;
      final total = left + right;
      final needsCarry = (left % 10) + (right % 10) >= 10;

      if (!needsCarry || total > 199) {
        continue;
      }

      return AdditionBridgeBuilderQuestion(
        left: left,
        right: right,
        options: _buildOptions(total),
      );
    }
  }

  List<int> _buildOptions(int answer) {
    const offsets = [-30, -20, -10, -5, -1, 1, 5, 10, 20, 30];
    final options = <int>{answer};

    while (options.length < 4) {
      final offset = offsets[_random.nextInt(offsets.length)];
      final candidate = answer + offset;
      if (candidate > 20 && candidate < 250) {
        options.add(candidate);
      }
    }

    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }
}
