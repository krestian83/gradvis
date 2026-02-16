import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/curriculum_data.dart';
import '../../../core/constants/subject.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../domain/game_interface.dart';
import '../domain/game_registry.dart';
import 'widgets/game_placeholder.dart';

/// Host shell: shows a registered game or the placeholder.
class GameScreen extends StatelessWidget {
  final Subject subject;
  final int level;
  final int trinn;

  const GameScreen({
    super.key,
    required this.subject,
    required this.level,
    required this.trinn,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = curriculumData[subject]![trinn]!;
    final node = nodes[level.clamp(0, nodes.length - 1)];
    final slot = GameSlot(subject: subject, trinn: trinn, level: level);

    return GradientBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                AppBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Text(
                  '${node.icon} ${node.label}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: GameRegistry.instance.hasGame(slot)
                ? GameRegistry.instance.build(
                    slot,
                    onComplete: (result) => context.pop(result),
                  )!
                : GamePlaceholder(subject: subject, levelLabel: node.label),
          ),
        ],
      ),
    );
  }
}
