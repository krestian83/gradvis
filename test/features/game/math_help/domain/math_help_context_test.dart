import 'package:flutter_test/flutter_test.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_help_context.dart';
import 'package:gradvis_v2/features/game/math_help/domain/math_topic_family.dart';

void main() {
  test('keeps operands immutable after construction', () {
    final operands = <num>[3, 4];
    final context = MathHelpContext(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'addition',
      operands: operands,
      correctAnswer: 7,
      label: '3 + 4',
    );

    operands.add(99);

    expect(context.operands, [3, 4]);
    expect(() => context.operands.add(5), throwsUnsupportedError);
  });

  test('supports value equality', () {
    final first = MathHelpContext(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'addition',
      operands: const [1, 2],
      correctAnswer: 3,
      label: '1 + 2',
    );
    final second = MathHelpContext(
      topicFamily: MathTopicFamily.arithmetic,
      operation: 'addition',
      operands: const [1, 2],
      correctAnswer: 3,
      label: '1 + 2',
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('allows empty operands', () {
    final context = MathHelpContext(
      topicFamily: MathTopicFamily.geometry,
      operation: 'triangleSides',
      operands: const [],
      correctAnswer: 3,
    );

    expect(context.operands, isEmpty);
    expect(context.correctAnswer, 3);
  });
}
