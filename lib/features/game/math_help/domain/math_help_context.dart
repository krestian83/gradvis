import 'package:flutter/foundation.dart';

import 'math_topic_family.dart';

/// Context contract published by math mini-games to the help module.
@immutable
class MathHelpContext {
  final MathTopicFamily topicFamily;
  final String? operation;
  final List<num> operands;
  final num correctAnswer;
  final String? label;

  MathHelpContext({
    required this.topicFamily,
    required this.correctAnswer,
    this.operation,
    List<num> operands = const [],
    this.label,
  }) : operands = List<num>.unmodifiable(operands);

  @override
  bool operator ==(Object other) {
    return other is MathHelpContext &&
        other.topicFamily == topicFamily &&
        other.operation == operation &&
        listEquals(other.operands, operands) &&
        other.correctAnswer == correctAnswer &&
        other.label == label;
  }

  @override
  int get hashCode {
    return Object.hash(
      topicFamily,
      operation,
      Object.hashAll(operands),
      correctAnswer,
      label,
    );
  }
}
