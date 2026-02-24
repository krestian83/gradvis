import 'package:flutter/material.dart';

import '../../application/number_runner_session_controller.dart';

/// Always-visible HUD showing lives, question counter, and streak.
class HudOverlay extends StatelessWidget {
  final NumberRunnerSessionController session;

  const HudOverlay({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Hearts(lives: session.lives),
                const SizedBox(width: 12),
                _Chip(
                  label:
                      '${session.currentIndex}/${session.totalQuestions}',
                ),
                const Spacer(),
                if (session.currentStreak > 1)
                  _Chip(label: '${session.currentStreak}x streak'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hearts extends StatelessWidget {
  final int lives;

  const _Hearts({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            i < lives ? Icons.favorite : Icons.favorite_border,
            color: i < lives ? Colors.red : Colors.grey,
            size: 24,
          ),
        );
      }),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
