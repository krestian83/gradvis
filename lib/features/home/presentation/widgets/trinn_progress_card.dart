import 'package:flutter/material.dart';

import '../../../../core/constants/curriculum_data.dart';
import '../../../../core/constants/subject.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../levels/domain/level_repository.dart';

/// Card showing trinn mastery with per-subject breakdown.
class TrinnProgressCard extends StatelessWidget {
  final int trinn;
  final String profileId;
  final LevelRepository levelRepo;

  const TrinnProgressCard({
    super.key,
    required this.trinn,
    required this.profileId,
    required this.levelRepo,
  });

  double _subjectMastery(Subject subject) {
    final nodes = curriculumData[subject]![trinn]!;
    final progress = levelRepo.load(
      profileId,
      subject.name,
      trinn,
      nodes.length,
    );
    final total = nodes.length * 3;
    if (total == 0) return 0;
    final earned = progress.fold<int>(0, (s, l) => s + l.stars);
    return earned / total;
  }

  @override
  Widget build(BuildContext context) {
    final overall =
        Subject.values.map(_subjectMastery).fold<double>(0, (s, m) => s + m) /
        Subject.values.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        opacity: 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.orangeDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$trinn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trinn $trinn',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(overall * 100).round()}% fullført',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProgressBar(fraction: overall),
            const SizedBox(height: 14),
            // Per-subject breakdown
            ...Subject.values.map((s) {
              final m = _subjectMastery(s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 58,
                      child: Text(
                        s.displayName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: ProgressBar(
                        fraction: m,
                        height: 6,
                        color: s.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(m * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
