// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelProgress _$LevelProgressFromJson(Map<String, dynamic> json) =>
    LevelProgress(
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      done: json['done'] as bool? ?? false,
    );

Map<String, dynamic> _$LevelProgressToJson(LevelProgress instance) =>
    <String, dynamic>{'stars': instance.stars, 'done': instance.done};
