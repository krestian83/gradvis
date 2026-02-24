import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/math_help_context.dart';
import 'math_visualizer.dart';
import 'math_visualizer_game_widget.dart';

/// Centered surface showing the visual explanation.
class MathHelpOverlay extends StatefulWidget {
  final MathHelpContext helpContext;
  final MathVisualizer visualizer;

  const MathHelpOverlay({
    super.key,
    required this.helpContext,
    required this.visualizer,
  });

  @override
  State<MathHelpOverlay> createState() => _MathHelpOverlayState();
}

class _MathHelpOverlayState extends State<MathHelpOverlay> {
  bool _paused = false;

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      widget.visualizer.paused = _paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                math.min(920.0, constraints.maxWidth * 0.94);
            final maxHeight = constraints.maxHeight * 0.86;
            final minHeight = math.min(420.0, maxHeight);

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                minHeight: minHeight,
              ),
              child: Container(
                key: const Key('math-help-overlay'),
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'Visualisering',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color:
                                      const Color(0xFF0A2463),
                                  fontFamily: 'Fredoka One',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: _paused
                                      ? 'Spill av'
                                      : 'Pause',
                                  onPressed: _togglePause,
                                  icon: Icon(
                                    _paused
                                        ? Icons
                                            .play_arrow_rounded
                                        : Icons.pause_rounded,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Lukk hjelpevindu',
                                  onPressed: () =>
                                      Navigator.of(context)
                                          .maybePop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: MathVisualizerGameWidget(
                          visualizer: widget.visualizer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
