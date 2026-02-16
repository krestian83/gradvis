import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/subject.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/animated_gradvis_logo.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../levels/domain/level_repository.dart';
import '../../profile/domain/profile_state.dart';
import 'widgets/profile_header.dart';
import 'widgets/subject_button.dart';
import 'widgets/trinn_progress_card.dart';

class HomeScreen extends StatelessWidget {
  final ProfileState profileState;
  final LevelRepository levelRepo;

  const HomeScreen({
    super.key,
    required this.profileState,
    required this.levelRepo,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: ListenableBuilder(
        listenable: profileState,
        builder: (context, _) {
          final profile = profileState.active;
          if (profile == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                ProfileHeader(
                  profile: profile,
                  onAvatarTap: () => context.go(RouteNames.profileSelect),
                  onStoreTap: () => context.push(RouteNames.store),
                ),
                const SizedBox(height: 12),
                AnimatedGradVisLogo(maxTrinn: profile.trinn, scale: 0.55),
                const SizedBox(height: 12),
                TrinnProgressCard(
                  trinn: profile.trinn,
                  profileId: profile.id,
                  levelRepo: levelRepo,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: Subject.values.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SubjectButton(
                          subject: s,
                          profileId: profile.id,
                          trinn: profile.trinn,
                          levelRepo: levelRepo,
                          onTap: () =>
                              context.push(RouteNames.levelsPath(s.name)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
