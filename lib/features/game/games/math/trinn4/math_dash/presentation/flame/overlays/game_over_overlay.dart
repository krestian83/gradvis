import 'package:flutter/material.dart';

/// Overlay shown when the player runs out of lives.
class GameOverOverlay extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int bestStreak;
  final VoidCallback onDone;

  const GameOverOverlay({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.bestStreak,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xBBB71C1C),
      child: Center(
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Spillet er over',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Fredoka One',
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Riktige: $correctAnswers / $totalQuestions',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Beste streak: $bestStreak',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onDone,
                  child: const Text('Ferdig'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
