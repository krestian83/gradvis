import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'math_visualizer.dart';

/// Hosts a Flame-based math visualizer inside regular Flutter layout.
class MathVisualizerGameWidget extends StatelessWidget {
  final MathVisualizer visualizer;

  const MathVisualizerGameWidget({super.key, required this.visualizer});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GameWidget(game: visualizer),
    );
  }
}
