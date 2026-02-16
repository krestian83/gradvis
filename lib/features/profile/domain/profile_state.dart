import 'package:flutter/foundation.dart';

import '../data/profile_model.dart';
import 'profile_repository.dart';

/// App-wide state: profile list + active profile.
class ProfileState extends ChangeNotifier {
  final ProfileRepository _repo;

  List<Profile> _profiles = [];
  Profile? _active;

  ProfileState(this._repo) {
    _profiles = _repo.loadAll();
  }

  List<Profile> get profiles => List.unmodifiable(_profiles);
  Profile? get active => _active;

  bool get hasActive => _active != null;

  void setActive(Profile profile) {
    _active = profile;
    notifyListeners();
  }

  Future<void> add(Profile profile) async {
    await _repo.add(profile);
    _profiles = _repo.loadAll();
    _active = profile;
    notifyListeners();
  }

  Future<void> update(Profile profile) async {
    await _repo.update(profile);
    _profiles = _repo.loadAll();
    if (_active?.id == profile.id) _active = profile;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _profiles = _repo.loadAll();
    if (_active?.id == id) _active = null;
    notifyListeners();
  }

  /// Award points to the active profile.
  Future<void> addPoints(int amount) async {
    if (_active == null) return;
    final updated = _active!.copyWith(points: _active!.points + amount);
    await update(updated);
  }

  /// Upgrade active profile to the next trinn.
  Future<void> levelUp() async {
    if (_active == null || _active!.trinn >= 4) return;
    final updated = _active!.copyWith(trinn: _active!.trinn + 1);
    await update(updated);
  }
}
