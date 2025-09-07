class GoogleMeetSpace {
  final String id;
  final String userId;
  final String spaceName;
  final String? meetingCode;
  final String? meetingUri;
  final Map<String, dynamic>? config;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoogleMeetSpace({
    required this.id,
    required this.userId,
    required this.spaceName,
    this.meetingCode,
    this.meetingUri,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  GoogleMeetSpace copyWith({
    String? id,
    String? userId,
    String? spaceName,
    String? meetingCode,
    String? meetingUri,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoogleMeetSpace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spaceName: spaceName ?? this.spaceName,
      meetingCode: meetingCode ?? this.meetingCode,
      meetingUri: meetingUri ?? this.meetingUri,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleMeetSpace &&
        other.id == id &&
        other.userId == userId &&
        other.spaceName == spaceName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ spaceName.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetSpace(id: $id, userId: $userId, spaceName: $spaceName, meetingCode: $meetingCode)';
  }
}
