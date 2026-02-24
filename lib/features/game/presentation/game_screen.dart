import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/curriculum_data.dart';
import '../../../core/constants/subject.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../math_help/application/math_help_controller.dart';
import '../math_help/application/math_help_scope.dart';
import '../math_help/presentation/math_help_button.dart';
import '../math_help/visualizers/visualizer_registry.dart';
import '../domain/game_interface.dart';
import '../domain/game_registry.dart';
import 'widgets/game_placeholder.dart';

/// Host shell: shows a registered game or the placeholder.
class GameScreen extends StatefulWidget {
  final Subject subject;
  final int level;
  final int trinn;
  final MathHelpController? mathHelpController;
  final VisualizerRegistry visualizerRegistry;

  GameScreen({
    super.key,
    required this.subject,
    required this.level,
    required this.trinn,
    this.mathHelpController,
    VisualizerRegistry? visualizerRegistry,
  }) : visualizerRegistry = visualizerRegistry ?? mathVisualizerRegistry;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MathHelpController _mathHelpController;
  late final bool _ownsMathHelpController;

  @override
  void initState() {
    super.initState();
    _ownsMathHelpController = widget.mathHelpController == null;
    _mathHelpController = widget.mathHelpController ?? MathHelpController();
  }

  @override
  void dispose() {
    if (_ownsMathHelpController) {
      _mathHelpController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodes = curriculumData[widget.subject]![widget.trinn]!;
    final node = nodes[widget.level.clamp(0, nodes.length - 1)];
    final slot = GameSlot(
      subject: widget.subject,
      trinn: widget.trinn,
      level: widget.level,
    );

    return MathHelpScope(
      controller: _mathHelpController,
      child: GradientBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    AppBackButton(onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    Text(
                      '${node.icon} ${node.label}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    MathHelpButton(
                      subject: widget.subject,
                      registry: widget.visualizerRegistry,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GameRegistry.instance.hasGame(slot)
                  ? GameRegistry.instance.build(
                      slot,
                      onComplete: (result) => context.pop(result),
                    )!
                  : GamePlaceholder(
                      subject: widget.subject,
                      levelLabel: node.label,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
