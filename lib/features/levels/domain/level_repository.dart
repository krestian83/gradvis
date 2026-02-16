import 'dart:convert';

import '../../../core/services/storage_service.dart';
import '../data/level_progress_model.dart';

/// Persists per-profile level progress.
///
/// Key format: `levels_{profileId}_{subject}_{trinn}`.
class LevelRepository {
  final StorageService _storage;

  LevelRepository(this._storage);

  String _key(String profileId, String subject, int trinn) =>
      'levels_${profileId}_${subject}_$trinn';

  /// Returns a list of [LevelProgress] for each level node.
  List<LevelProgress> load(
    String profileId,
    String subject,
    int trinn,
    int count,
  ) {
    final raw = _storage.getString(_key(profileId, subject, trinn));
    if (raw == null) {
      return List.generate(count, (_) => const LevelProgress());
    }
    final list = jsonDecode(raw) as List;
    final loaded = list
        .map((e) => LevelProgress.fromJson(e as Map<String, dynamic>))
        .toList();
    // Pad if curriculum grew
    while (loaded.length < count) {
      loaded.add(const LevelProgress());
    }
    return loaded;
  }

  Future<void> save(
    String profileId,
    String subject,
    int trinn,
    List<LevelProgress> progress,
  ) =>
      _storage.setString(_key(profileId, subject, trinn), jsonEncode(progress));
}
