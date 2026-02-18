import 'package:flutter/material.dart';

import '../../../../core/constants/curriculum_data.dart';
import '../../../../core/constants/subject.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/star_display.dart';
import '../../../levels/data/level_progress_model.dart';

/// Card-style level tile used by the levels grid layout.
class LevelNodeWidget extends StatelessWidget {
  final LevelNode node;
  final LevelProgress progress;
  final Subject subject;
  final bool isCurrent;
  final VoidCallback? onTap;

  const LevelNodeWidget({
    super.key,
    required this.node,
    required this.progress,
    required this.subject,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = progress.done;
    final showPlay = !isDone;
    final showRetry = isDone && progress.stars < 3;

    final borderColor = isDone
        ? subject.color.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: isCurrent ? 0.88 : 0.74);
    final cardColor = isDone
        ? subject.color.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.58);

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            height: 220,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: subject.shadowColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 78,
                    child: Stack(
                      children: [
                        Align(
                          child: _LevelIconTile(
                            icon: node.icon,
                            subject: subject,
                            isDone: isDone,
                          ),
                        ),
                        if (isDone)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _DoneBadge(color: subject.color),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.heading),
                  ),
                  const SizedBox(height: 4),
                  StarDisplay(stars: progress.stars, size: 18),
                  const Spacer(),
                  if (showPlay)
                    _ActionPill(
                      subject: subject,
                      label: 'Spill ▶',
                      filled: true,
                    ),
                  if (showRetry)
                    _ActionPill(
                      subject: subject,
                      label: 'Prøv igjen',
                      filled: false,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelIconTile extends StatelessWidget {
  final String icon;
  final Subject subject;
  final bool isDone;

  const _LevelIconTile({
    required this.icon,
    required this.subject,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDone
        ? LinearGradient(colors: [subject.color, subject.colorB])
        : LinearGradient(
            colors: [
              subject.lightBg.withValues(alpha: 0.95),
              subject.lightBg.withValues(alpha: 0.8),
            ],
          );

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: subject.shadowColor.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 34)),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  final Color color;

  const _DoneBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final Subject subject;
  final String label;
  final bool filled;

  const _ActionPill({
    required this.subject,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: filled ? Colors.white : subject.color,
      fontWeight: FontWeight.w900,
      fontSize: 18,
    );

    final decoration = filled
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [subject.color, subject.colorB]),
            boxShadow: [
              BoxShadow(
                color: subject.shadowColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(
              color: subject.color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 102),
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(label, textAlign: TextAlign.center, style: textStyle),
        ),
      ),
    );
  }
}
