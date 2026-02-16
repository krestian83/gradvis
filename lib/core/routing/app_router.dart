import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/presentation/game_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/levels/domain/level_repository.dart';
import '../../features/levels/presentation/levels_screen.dart';
import '../../features/profile/domain/profile_state.dart';
import '../../features/profile/presentation/profile_select_screen.dart';
import '../../features/profile_wizard/presentation/profile_wizard_screen.dart';
import '../../features/store/data/store_repository.dart';
import '../../features/store/presentation/store_screen.dart';
import '../constants/subject.dart';
import 'route_names.dart';

GoRouter buildRouter({
  required ProfileState profileState,
  required LevelRepository levelRepo,
  required StoreRepository storeRepo,
}) {
  return GoRouter(
    initialLocation: RouteNames.profileSelect,
    redirect: (context, state) {
      final path = state.uri.path;
      final onPublic =
          path == RouteNames.profileSelect || path == RouteNames.wizard;
      if (!profileState.hasActive && !onPublic) {
        return RouteNames.profileSelect;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.profileSelect,
        builder: (_, _) => ProfileSelectScreen(profileState: profileState),
      ),
      GoRoute(
        path: RouteNames.wizard,
        builder: (_, _) => ProfileWizardScreen(profileState: profileState),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (_, _) =>
            HomeScreen(profileState: profileState, levelRepo: levelRepo),
      ),
      GoRoute(
        path: RouteNames.levels,
        builder: (_, state) {
          final subject = Subject.values.firstWhere(
            (s) => s.name == state.pathParameters['subject'],
          );
          return LevelsScreen(
            profileState: profileState,
            levelRepo: levelRepo,
            subject: subject,
          );
        },
      ),
      GoRoute(
        path: RouteNames.game,
        builder: (_, state) {
          final subject = Subject.values.firstWhere(
            (s) => s.name == state.pathParameters['subject'],
          );
          final level = int.tryParse(state.pathParameters['level'] ?? '0') ?? 0;
          return GameScreen(
            subject: subject,
            level: level,
            trinn: profileState.active!.trinn,
          );
        },
      ),
      GoRoute(
        path: RouteNames.store,
        builder: (_, _) =>
            StoreScreen(profileState: profileState, storeRepo: storeRepo),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Side ikke funnet'))),
  );
}
