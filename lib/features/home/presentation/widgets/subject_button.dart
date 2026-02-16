import 'package:flutter/material.dart';

import '../../../../core/constants/curriculum_data.dart';
import '../../../../core/constants/subject.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../levels/domain/level_repository.dart';

/// Colored subject button with icon, name, and progress bar.
class SubjectButton extends StatelessWidget {
  final Subject subject;
  final String profileId;
  final int trinn;
  final LevelRepository levelRepo;
  final VoidCallback onTap;

  const SubjectButton({
    super.key,
    required this.subject,
    required this.profileId,
    required this.trinn,
    required this.levelRepo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = curriculumData[subject]![trinn]!;
    final progress = levelRepo.load(
      profileId,
      subject.name,
      trinn,
      nodes.length,
    );
    final total = nodes.length * 3;
    final earned = progress.fold<int>(0, (s, l) => s + l.stars);
    final fraction = total > 0 ? earned / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [subject.color, subject.colorB]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: subject.shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(subject.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(
                    fraction: fraction,
                    height: 8,
                    color: Colors.white.withValues(alpha: 0.9),
                    colorEnd: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(fraction * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
