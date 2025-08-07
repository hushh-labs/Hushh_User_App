import 'package:equatable/equatable.dart';

class ChatUserEntity extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime? createdAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const ChatUserEntity({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.profileImage,
    this.createdAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    profileImage,
    createdAt,
    isEmailVerified,
    isPhoneVerified,
  ];

  ChatUserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImage,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return ChatUserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
