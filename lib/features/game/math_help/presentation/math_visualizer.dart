import 'package:flame/game.dart';

import '../domain/math_help_context.dart';

/// Base Flame game used by all math-help visualizers.
abstract class MathVisualizer extends FlameGame {
  final MathHelpContext context;

  MathVisualizer({required this.context});
}
