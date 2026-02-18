import 'package:flutter/material.dart';

import '../domain/math_help_context.dart';
import 'math_visualizer.dart';
import 'math_visualizer_game_widget.dart';

/// Bottom-sheet surface showing the visual explanation.
class MathHelpOverlay extends StatelessWidget {
  final MathHelpContext helpContext;
  final MathVisualizer visualizer;

  const MathHelpOverlay({
    super.key,
    required this.helpContext,
    required this.visualizer,
  });

  @override
  Widget build(BuildContext context) {
    final label = helpContext.label?.trim();
    final header = label == null || label.isEmpty ? 'Matematikkhjelp' : label;

    return SafeArea(
      child: Container(
        key: const Key('math-help-overlay'),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220A2463),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    header,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0A2463),
                      fontFamily: 'Fredoka One',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Lukk hjelpevindu',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (label != null && label.isNotEmpty)
              Text(
                'Visualisering',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF355070),
                  fontFamily: 'Fredoka One',
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: MathVisualizerGameWidget(visualizer: visualizer),
            ),
          ],
        ),
      ),
    );
  }
}
