import '../domain/math_help_context.dart';
import '../domain/math_topic_family.dart';
import '../presentation/math_visualizer.dart';

typedef MathVisualizerFactory =
    MathVisualizer Function(MathHelpContext helpContext);

final mathVisualizerRegistry = VisualizerRegistry();

/// Maps topic/operation keys to Flame visualizer factories.
class VisualizerRegistry {
  final _factories = <_VisualizerKey, MathVisualizerFactory>{};

  void register({
    required MathTopicFamily topicFamily,
    required String? operation,
    required MathVisualizerFactory factory,
  }) {
    _factories[_VisualizerKey(topicFamily, _normalizeOperation(operation))] =
        factory;
  }

  MathVisualizerFactory? lookup({
    required MathTopicFamily topicFamily,
    required String? operation,
  }) {
    final normalizedOperation = _normalizeOperation(operation);
    final exact = _factories[_VisualizerKey(topicFamily, normalizedOperation)];
    if (exact != null) return exact;
    if (normalizedOperation == null) return null;
    return _factories[_VisualizerKey(topicFamily, null)];
  }

  MathVisualizer? create(MathHelpContext context) {
    final factory = lookup(
      topicFamily: context.topicFamily,
      operation: context.operation,
    );
    return factory?.call(context);
  }
}

class _VisualizerKey {
  final MathTopicFamily topicFamily;
  final String? operation;

  const _VisualizerKey(this.topicFamily, this.operation);

  @override
  bool operator ==(Object other) {
    return other is _VisualizerKey &&
        other.topicFamily == topicFamily &&
        other.operation == operation;
  }

  @override
  int get hashCode => Object.hash(topicFamily, operation);
}

String? _normalizeOperation(String? operation) {
  final trimmed = operation?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.toLowerCase();
}
