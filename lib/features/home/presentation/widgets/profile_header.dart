import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../profile/data/profile_model.dart';

/// Avatar + greeting + store badge at the top of home.
class ProfileHeader extends StatelessWidget {
  final Profile profile;
  final VoidCallback onAvatarTap;
  final VoidCallback onStoreTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onAvatarTap,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AvatarCircle(emoji: profile.emoji, size: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hei, ${profile.name}!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                Text(
                  'Klar for å lære?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onStoreTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.orangeDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '⭐ ${profile.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
