class User {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? name;
  final String? profileImage;
  final DateTime? createdAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const User({
    required this.id,
    this.email,
    this.phoneNumber,
    this.name,
    this.profileImage,
    this.createdAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? name,
    String? profileImage,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
