import 'package:flutter/material.dart';

import '../../../../core/constants/curriculum_data.dart';
import '../../../../core/constants/subject.dart';
import '../../../../core/widgets/star_display.dart';
import '../../../levels/data/level_progress_model.dart';

/// Individual level node: done, current, or locked.
class LevelNodeWidget extends StatelessWidget {
  final LevelNode node;
  final LevelProgress progress;
  final Subject subject;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  const LevelNodeWidget({
    super.key,
    required this.node,
    required this.progress,
    required this.subject,
    required this.isCurrent,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress.done;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: done
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              subject.color,
                              subject.color.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: done
                        ? null
                        : isLocked
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: isCurrent
                        ? Border.all(color: subject.color, width: 3)
                        : null,
                    boxShadow: isLocked
                        ? null
                        : [
                            BoxShadow(
                              color: subject.color.withValues(alpha: 0.19),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLocked ? '🔒' : node.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        node.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: done ? Colors.white : null,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Pulse indicator for current node
                if (isCurrent)
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '▶',
                        style: TextStyle(fontSize: 10, color: subject.color),
                      ),
                    ),
                  ),
              ],
            ),
            if (done) ...[
              const SizedBox(height: 4),
              StarDisplay(stars: progress.stars, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
