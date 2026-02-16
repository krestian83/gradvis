import 'package:json_annotation/json_annotation.dart';

part 'level_progress_model.g.dart';

/// Per-level progress: how many stars earned, whether completed.
@JsonSerializable()
class LevelProgress {
  final int stars;
  final bool done;

  const LevelProgress({this.stars = 0, this.done = false});

  LevelProgress copyWith({int? stars, bool? done}) =>
      LevelProgress(stars: stars ?? this.stars, done: done ?? this.done);

  factory LevelProgress.fromJson(Map<String, dynamic> json) =>
      _$LevelProgressFromJson(json);

  Map<String, dynamic> toJson() => _$LevelProgressToJson(this);
}
