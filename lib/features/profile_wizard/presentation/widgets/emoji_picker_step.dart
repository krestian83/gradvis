import 'package:flutter/material.dart';

import '../../../../core/constants/emoji_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_circle.dart';

/// Step 0: pick an avatar emoji from 6 categories.
class EmojiPickerStep extends StatefulWidget {
  final String selectedEmoji;
  final ValueChanged<String> onEmojiChanged;
  final VoidCallback onNext;

  const EmojiPickerStep({
    super.key,
    required this.selectedEmoji,
    required this.onEmojiChanged,
    required this.onNext,
  });

  @override
  State<EmojiPickerStep> createState() => _EmojiPickerStepState();
}

class _EmojiPickerStepState extends State<EmojiPickerStep> {
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final category = emojiCategories[_categoryIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text('Velg avatar', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          AvatarCircle(emoji: widget.selectedEmoji, size: 80),
          const SizedBox(height: 16),
          // Category tabs
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: emojiCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = emojiCategories[i];
                final selected = i == _categoryIndex;
                return GestureDetector(
                  onTap: () => setState(() => _categoryIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.orange.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: selected
                          ? Border.all(color: AppColors.orange, width: 2)
                          : null,
                    ),
                    child: Text(
                      '${cat.label} ${cat.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Emoji grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: category.emojis.length,
              itemBuilder: (_, i) {
                final emoji = category.emojis[i];
                final selected = emoji == widget.selectedEmoji;
                return GestureDetector(
                  onTap: () => widget.onEmojiChanged(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.orange.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(color: AppColors.orange, width: 2.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: selected ? 28 : 26),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _OrangeButton(label: 'Neste', onTap: widget.onNext),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OrangeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OrangeButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.5,
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 17),
          ),
        ),
      ),
    );
  }
}
