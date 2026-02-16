import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class Profile {
  final String id;
  final String name;
  final String emoji;
  final int trinn;
  final int points;
  final int createdAt;

  const Profile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.trinn,
    this.points = 0,
    required this.createdAt,
  });

  Profile copyWith({String? name, String? emoji, int? trinn, int? points}) =>
      Profile(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        trinn: trinn ?? this.trinn,
        points: points ?? this.points,
        createdAt: createdAt,
      );

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
