import '../../domain/entities/user_card.dart';

class UserCardModel extends UserCard {
  const UserCardModel({
    required super.id,
    required super.userId,
    super.email,
    super.fullName,
    super.videoUrl,
    super.createdAt,
    super.updatedAt,
    super.isActive,
  });

  factory UserCardModel.fromJson(Map<String, dynamic> json) {
    return UserCardModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      videoUrl: json['videoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'videoUrl': videoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  UserCardModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
