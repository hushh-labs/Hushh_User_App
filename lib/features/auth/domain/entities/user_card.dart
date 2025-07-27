class UserCard {
  final String id;
  final String userId;
  final String? email;
  final String? fullName;
  final String? videoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const UserCard({
    required this.id,
    required this.userId,
    this.email,
    this.fullName,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  UserCard copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserCard(
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

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
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
}
