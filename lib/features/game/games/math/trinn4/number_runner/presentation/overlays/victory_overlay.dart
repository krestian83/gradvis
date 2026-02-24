import 'package:flutter/material.dart';

import '../../application/number_runner_session_controller.dart';
import '../../../../../../domain/game_interface.dart';

/// "Gratulerer!" overlay with star rating, stats, and a close button.
class VictoryOverlay extends StatelessWidget {
  final NumberRunnerSessionController session;
  final GameResult result;
  final VoidCallback onClose;

  const VictoryOverlay({
    super.key,
    required this.session,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          elevation: 12,
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Stars(count: result.stars),
                const SizedBox(height: 12),
                Text(
                  'Gratulerer!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Riktige svar: ${session.correctAnswers}'
                  '/${session.totalQuestions}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Poeng: ${result.pointsEarned}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Beste streak: ${session.bestStreak}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onClose,
                  child: const Text('Lukk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int count;

  const _Stars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(
          i < count ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 40,
        );
      }),
    );
  }
}
