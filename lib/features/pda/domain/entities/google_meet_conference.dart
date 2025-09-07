class GoogleMeetConference {
  final String id;
  final String userId;
  final String? spaceId;
  final String conferenceName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int participantCount;
  final bool wasRecorded;
  final bool wasTranscribed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoogleMeetConference({
    required this.id,
    required this.userId,
    this.spaceId,
    required this.conferenceName,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.participantCount,
    required this.wasRecorded,
    required this.wasTranscribed,
    required this.createdAt,
    required this.updatedAt,
  });

  GoogleMeetConference copyWith({
    String? id,
    String? userId,
    String? spaceId,
    String? conferenceName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? participantCount,
    bool? wasRecorded,
    bool? wasTranscribed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoogleMeetConference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spaceId: spaceId ?? this.spaceId,
      conferenceName: conferenceName ?? this.conferenceName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      participantCount: participantCount ?? this.participantCount,
      wasRecorded: wasRecorded ?? this.wasRecorded,
      wasTranscribed: wasTranscribed ?? this.wasTranscribed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleMeetConference &&
        other.id == id &&
        other.userId == userId &&
        other.conferenceName == conferenceName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ conferenceName.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetConference(id: $id, userId: $userId, conferenceName: $conferenceName, startTime: $startTime, participantCount: $participantCount)';
  }
}
