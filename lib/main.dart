import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/routing/app_router.dart';
import 'core/services/storage_service.dart';
import 'features/game/bootstrap/register_builtin_games.dart';
import 'features/levels/domain/level_repository.dart';
import 'features/profile/domain/profile_repository.dart';
import 'features/profile/domain/profile_state.dart';
import 'features/store/data/store_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);

  final profileRepo = ProfileRepository(storage);
  final profileState = ProfileState(profileRepo);
  final levelRepo = LevelRepository(storage);
  final storeRepo = StoreRepository(storage);
  registerBuiltInGames();

  final router = buildRouter(
    profileState: profileState,
    levelRepo: levelRepo,
    storeRepo: storeRepo,
  );

  runApp(GradVisApp(router: router));
}
