import 'package:flutter/material.dart';

import '../../../../core/constants/subject.dart';

/// "Kommer snart" placeholder shown when no game is registered.
class GamePlaceholder extends StatelessWidget {
  final Subject subject;
  final String levelLabel;

  const GamePlaceholder({
    super.key,
    required this.subject,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🚧', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Kommer snart!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${subject.displayName} – $levelLabel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
