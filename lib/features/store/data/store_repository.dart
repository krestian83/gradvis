import 'dart:convert';

import '../../../core/services/storage_service.dart';

/// Persists the set of owned store item IDs per profile.
class StoreRepository {
  final StorageService _storage;

  StoreRepository(this._storage);

  String _key(String profileId) => 'store_$profileId';

  Set<String> loadOwned(String profileId) {
    final raw = _storage.getString(_key(profileId));
    if (raw == null) return {};
    final list = jsonDecode(raw) as List;
    return list.cast<String>().toSet();
  }

  Future<void> saveOwned(String profileId, Set<String> ids) =>
      _storage.setString(_key(profileId), jsonEncode(ids.toList()));
}
