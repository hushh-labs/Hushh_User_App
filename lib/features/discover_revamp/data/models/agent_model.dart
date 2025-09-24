import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/agent_entity.dart';

class AgentModel {
  final String id;
  final String name;
  final String? company;
  final String? location;
  final String? description;
  final String? bio;
  final String? about;
  final String? profilePicUrl;
  final String? profilePicURL;
  final String? ProfilePicUrl;
  final String? profileImageUrl;
  final String? profile_image_url;
  final String? photoUrl;
  final String? photoURL;
  final String? avatarUrl;
  final String? brandName;
  final String? industry;
  final List<String> categories;
  final bool isActive;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AgentModel({
    required this.id,
    required this.name,
    this.company,
    this.location,
    this.description,
    this.bio,
    this.about,
    this.profilePicUrl,
    this.profilePicURL,
    this.ProfilePicUrl,
    this.profileImageUrl,
    this.profile_image_url,
    this.photoUrl,
    this.photoURL,
    this.avatarUrl,
    this.brandName,
    this.industry,
    this.categories = const [],
    this.isActive = false,
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AgentModel.fromFirestore(Map<String, dynamic> doc) {
    final data = doc;

    // Handle categories
    final categoriesData = data['categories'];
    List<String> categories = [];
    if (categoriesData is List) {
      categories = categoriesData.map((e) => e.toString()).toList();
    }

    // Handle timestamps
    DateTime? createdAt;
    DateTime? updatedAt;

    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']);
    }

    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(data['updatedAt']);
    }

    return AgentModel(
      id: data['id'] ?? '',
      name: data['name']?.toString() ?? '',
      company: data['company']?.toString(),
      location: data['location']?.toString(),
      description: data['description']?.toString(),
      bio: data['bio']?.toString(),
      about: data['about']?.toString(),
      profilePicUrl: data['profilePicUrl']?.toString(),
      profilePicURL: data['profilePicURL']?.toString(),
      ProfilePicUrl: data['ProfilePicUrl']?.toString(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      profile_image_url: data['profile_image_url']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      photoURL: data['photoURL']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      brandName: data['brandName']?.toString(),
      industry: data['industry']?.toString(),
      categories: categories,
      isActive: data['isActive'] == true,
      isProfileComplete: data['isProfileComplete'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AgentEntity toEntity() {
    // Find the first non-empty image URL
    String? imageUrl;
    final imageFields = [
      profilePicUrl,
      ProfilePicUrl,
      profilePicURL,
      profileImageUrl,
      profile_image_url,
      photoUrl,
      photoURL,
      avatarUrl,
    ];

    for (final field in imageFields) {
      if (field != null && field.trim().isNotEmpty) {
        imageUrl = field.trim();
        break;
      }
    }

    return AgentEntity(
      id: id,
      name: name,
      company: company,
      location: location,
      description: description,
      bio: bio,
      about: about,
      profilePicUrl: imageUrl,
      brandName: brandName,
      industry: industry,
      categories: categories,
      isActive: isActive,
      isProfileComplete: isProfileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'location': location,
      'description': description,
      'bio': bio,
      'about': about,
      'profilePicUrl': profilePicUrl,
      'brandName': brandName,
      'industry': industry,
      'categories': categories,
      'isActive': isActive,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
