import '../../../domain/entities/google_meet_space.dart';

class GoogleMeetSpaceModel {
  final String id;
  final String userId;
  final String spaceName;
  final String? meetingCode;
  final String? meetingUri;
  final Map<String, dynamic>? config;
  final String createdAt;
  final String updatedAt;

  const GoogleMeetSpaceModel({
    required this.id,
    required this.userId,
    required this.spaceName,
    this.meetingCode,
    this.meetingUri,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoogleMeetSpaceModel.fromJson(Map<String, dynamic> json) {
    return GoogleMeetSpaceModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      spaceName: json['space_name'] ?? '',
      meetingCode: json['meeting_code'],
      meetingUri: json['meeting_uri'],
      config: json['config'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'space_name': spaceName,
      'meeting_code': meetingCode,
      'meeting_uri': meetingUri,
      'config': config,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  GoogleMeetSpace toEntity() {
    return GoogleMeetSpace(
      id: id,
      userId: userId,
      spaceName: spaceName,
      meetingCode: meetingCode,
      meetingUri: meetingUri,
      config: config,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  factory GoogleMeetSpaceModel.fromEntity(GoogleMeetSpace entity) {
    return GoogleMeetSpaceModel(
      id: entity.id,
      userId: entity.userId,
      spaceName: entity.spaceName,
      meetingCode: entity.meetingCode,
      meetingUri: entity.meetingUri,
      config: entity.config,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }
}
