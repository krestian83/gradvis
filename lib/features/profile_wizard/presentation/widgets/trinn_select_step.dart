import 'package:flutter/material.dart';

import '../../../../core/constants/trinn_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/glass_card.dart';

/// Step 2: choose a grade level.
class TrinnSelectStep extends StatelessWidget {
  final String emoji;
  final String name;
  final int selectedTrinn;
  final ValueChanged<int> onTrinnChanged;
  final VoidCallback onStart;

  const TrinnSelectStep({
    super.key,
    required this.emoji,
    required this.name,
    required this.selectedTrinn,
    required this.onTrinnChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AvatarCircle(emoji: emoji, size: 64),
          const SizedBox(height: 10),
          Text('Hei, $name!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Hvilket trinn går du på?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: trinnInfo.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = trinnInfo[i];
                final selected = t.num == selectedTrinn;
                return GestureDetector(
                  onTap: () => onTrinnChanged(t.num),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    borderRadius: 18,
                    opacity: selected ? 0.65 : 0.45,
                    child: Container(
                      decoration: selected
                          ? BoxDecoration(
                              border: Border.all(
                                color: AppColors.orange,
                                width: 2.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      padding: selected
                          ? const EdgeInsets.all(10)
                          : const EdgeInsets.all(12.5),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.orange,
                                  AppColors.orangeDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${t.num}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trinn ${t.num}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${t.age} · ${t.desc}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _OrangeButton(label: 'Start!', onTap: onStart),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OrangeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, AppColors.orangeDark],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 17),
        ),
      ),
    );
  }
}
