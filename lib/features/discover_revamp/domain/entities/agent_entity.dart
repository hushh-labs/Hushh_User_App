import 'package:equatable/equatable.dart';

class AgentEntity extends Equatable {
  final String id;
  final String name;
  final String? company;
  final String? location;
  final String? description;
  final String? bio;
  final String? about;
  final String? profilePicUrl;
  final String? brandName;
  final String? industry;
  final List<String> categories;
  final bool isActive;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AgentEntity({
    required this.id,
    required this.name,
    this.company,
    this.location,
    this.description,
    this.bio,
    this.about,
    this.profilePicUrl,
    this.brandName,
    this.industry,
    this.categories = const [],
    this.isActive = false,
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  String get displayDescription =>
      description ?? bio ?? about ?? 'No description available';

  String get displayImageUrl {
    if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
      return profilePicUrl!;
    }
    return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=1080';
  }

  String getInitials() {
    if (name.isEmpty) return 'A';

    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return 'A';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    company,
    location,
    description,
    bio,
    about,
    profilePicUrl,
    brandName,
    industry,
    categories,
    isActive,
    isProfileComplete,
    createdAt,
    updatedAt,
  ];
}
