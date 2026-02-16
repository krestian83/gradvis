import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_gradvis_logo.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/gradvis_title.dart';
import '../domain/profile_state.dart';
import 'widgets/profile_card.dart';

class ProfileSelectScreen extends StatelessWidget {
  final ProfileState profileState;

  const ProfileSelectScreen({super.key, required this.profileState});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: ListenableBuilder(
        listenable: profileState,
        builder: (context, _) {
          final profiles = profileState.profiles;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 14),
                    child: const AnimatedGradVisLogo(scale: 1.1),
                  ),
                  const SizedBox(height: 0),
                  const GradVisTitle(),
                  if (profiles.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lag din spiller!',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.subtitle),
                    ),
                  ],
                  const SizedBox(height: 40),
                  ...profiles.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProfileCard(
                        profile: p,
                        onTap: () {
                          profileState.setActive(p);
                          context.go(RouteNames.home);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NewPlayerButton(
                    label:
                        profiles.isEmpty ? 'Lag spiller' : 'Ny spiller',
                    onTap: () => context.go(RouteNames.wizard),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewPlayerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NewPlayerButton({required this.label, required this.onTap});

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
