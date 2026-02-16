import 'package:flutter/foundation.dart';

import '../../../core/constants/store_data.dart';
import '../../profile/domain/profile_state.dart';
import '../data/store_repository.dart';

/// Manages store purchases for the active profile.
class StoreState extends ChangeNotifier {
  final StoreRepository _repo;
  final ProfileState _profileState;
  late Set<String> _owned;

  StoreState({
    required StoreRepository repo,
    required ProfileState profileState,
  }) : _repo = repo,
       _profileState = profileState {
    final id = _profileState.active?.id ?? '';
    _owned = _repo.loadOwned(id);
  }

  Set<String> get owned => Set.unmodifiable(_owned);

  bool isOwned(String itemId) => _owned.contains(itemId);

  bool canAfford(StoreItem item) =>
      (_profileState.active?.points ?? 0) >= item.price;

  Future<void> buy(StoreItem item) async {
    if (!canAfford(item) || isOwned(item.id)) return;
    final profile = _profileState.active!;
    _owned.add(item.id);
    await _repo.saveOwned(profile.id, _owned);
    await _profileState.addPoints(-item.price);
    notifyListeners();
  }
}
