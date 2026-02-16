import 'package:flutter/foundation.dart';

import '../../../core/constants/curriculum_data.dart';
import '../../../core/constants/subject.dart';
import '../data/level_progress_model.dart';
import 'level_repository.dart';

/// Per-subject level progress for the active profile.
class LevelsState extends ChangeNotifier {
  final LevelRepository _repo;
  final String _profileId;
  final Subject _subject;
  final int _trinn;

  late List<LevelProgress> _levels;

  LevelsState({
    required LevelRepository repo,
    required String profileId,
    required Subject subject,
    required int trinn,
  }) : _repo = repo,
       _profileId = profileId,
       _subject = subject,
       _trinn = trinn {
    final nodeCount = curriculumData[subject]![trinn]!.length;
    _levels = _repo.load(profileId, subject.name, trinn, nodeCount);
  }

  List<LevelProgress> get levels => List.unmodifiable(_levels);

  /// Index of the first incomplete level (the "current" node).
  int get currentIndex {
    final idx = _levels.indexWhere((l) => !l.done);
    return idx == -1 ? _levels.length - 1 : idx;
  }

  /// Overall mastery percentage (0.0 – 1.0).
  double get mastery {
    if (_levels.isEmpty) return 0;
    final total = _levels.length * 3;
    final earned = _levels.fold<int>(0, (sum, l) => sum + l.stars);
    return earned / total;
  }

  /// Complete a level with given stars.
  Future<void> complete(int index, int stars) async {
    if (index < 0 || index >= _levels.length) return;
    final old = _levels[index];
    _levels[index] = old.copyWith(
      done: true,
      stars: stars > old.stars ? stars : old.stars,
    );
    await _repo.save(_profileId, _subject.name, _trinn, _levels);
    notifyListeners();
  }
}
