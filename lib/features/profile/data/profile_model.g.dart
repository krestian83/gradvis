// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  id: json['id'] as String,
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  trinn: (json['trinn'] as num).toInt(),
  points: (json['points'] as num?)?.toInt() ?? 0,
  createdAt: (json['createdAt'] as num).toInt(),
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'emoji': instance.emoji,
  'trinn': instance.trinn,
  'points': instance.points,
  'createdAt': instance.createdAt,
};
