import 'package:flutter/material.dart';

import '../../../../core/constants/subject.dart';
import '../application/math_help_scope.dart';
import '../domain/math_help_context.dart';
import '../visualizers/visualizer_registry.dart';
import 'math_help_overlay.dart';

/// Context-aware help trigger for math mini-games.
class MathHelpButton extends StatelessWidget {
  final Subject subject;
  final VisualizerRegistry registry;

  MathHelpButton({
    super.key,
    required this.subject,
    VisualizerRegistry? registry,
  }) : registry = registry ?? mathVisualizerRegistry;

  @override
  Widget build(BuildContext context) {
    final controller = MathHelpScope.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final helpContext = controller.context;
        final canShow = subject == Subject.math && helpContext != null;
        if (!canShow) {
          return const SizedBox.shrink();
        }

        return IconButton(
          tooltip: 'Vis hjelp',
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () => _openHelp(context, helpContext),
        );
      },
    );
  }

  Future<void> _openHelp(
    BuildContext context,
    MathHelpContext? helpContext,
  ) async {
    if (helpContext == null) return;

    final visualizer = registry.create(helpContext);
    if (visualizer == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          MathHelpOverlay(helpContext: helpContext, visualizer: visualizer),
    );
  }
}
