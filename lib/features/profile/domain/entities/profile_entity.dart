import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const ProfileEntity({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.name,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  ProfileEntity copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? email,
    String? phoneNumber,
    String? avatar,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    name,
    email,
    phoneNumber,
    avatar,
    isEmailVerified,
    isPhoneVerified,
  ];
}
