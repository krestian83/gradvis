import 'dart:convert';

import '../../../core/services/storage_service.dart';
import '../data/profile_model.dart';

/// CRUD operations for profiles backed by [StorageService].
class ProfileRepository {
  static const _key = 'profiles';
  final StorageService _storage;

  ProfileRepository(this._storage);

  List<Profile> loadAll() {
    final raw = _storage.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Profile> profiles) =>
      _storage.setString(_key, jsonEncode(profiles));

  Future<void> add(Profile profile) async {
    final all = loadAll()..add(profile);
    await saveAll(all);
  }

  Future<void> update(Profile profile) async {
    final all = loadAll();
    final idx = all.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      all[idx] = profile;
      await saveAll(all);
    }
  }

  Future<void> delete(String id) async {
    final all = loadAll()..removeWhere((p) => p.id == id);
    await saveAll(all);
  }
}
