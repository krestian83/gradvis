import 'package:flutter/material.dart';

/// Overlay shown when the player completes all 20 questions.
class VictoryOverlay extends StatelessWidget {
  final int stars;
  final int correctAnswers;
  final int totalQuestions;
  final int bestStreak;
  final int points;
  final VoidCallback onDone;

  const VictoryOverlay({
    super.key,
    required this.stars,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.bestStreak,
    required this.points,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xAA1B5E20),
      child: Center(
        child: Card(
          elevation: 16,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gratulerer!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Fredoka One',
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),
                _StarDisplay(stars: stars),
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
                const SizedBox(height: 4),
                Text(
                  'Poeng: $points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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

class _StarDisplay extends StatelessWidget {
  final int stars;

  const _StarDisplay({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 40,
            color: filled
                ? const Color(0xFFFFB300)
                : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}
