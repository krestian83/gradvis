import 'package:flutter/material.dart';

import '../../application/number_runner_session_controller.dart';

/// "Spillet er over" overlay with stats and a close button.
class GameOverOverlay extends StatelessWidget {
  final NumberRunnerSessionController session;
  final VoidCallback onClose;

  const GameOverOverlay({
    super.key,
    required this.session,
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
                const Icon(Icons.heart_broken, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Spillet er over',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'Riktige svar: ${session.correctAnswers}',
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
