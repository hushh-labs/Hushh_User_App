import '../../domain/entities/user_entity.dart';

class ChatUserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime? createdAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const ChatUserModel({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.profileImage,
    this.createdAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber, // For agents
      'profileImage': profileImage,
      'photoUrl': profileImage,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  factory ChatUserModel.fromJson(String id, Map<String, dynamic> json) {
    DateTime? parseCreatedAt(dynamic value) {
      if (value == null) return null;

      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return ChatUserModel(
      id: id,
      name: json['fullName'] ?? json['name'] ?? json['displayName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      profileImage: json['photoUrl'] ?? json['profileImage'],
      createdAt: parseCreatedAt(json['createdAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
    );
  }

  ChatUserEntity toEntity() {
    return ChatUserEntity(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profileImage: profileImage,
      createdAt: createdAt,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
    );
  }
}
