class GoogleMeetTranscript {
  final String id;
  final String userId;
  final String conferenceId;
  final String transcriptName;
  final Map<String, dynamic>? driveDestination;
  final String state; // TRANSCRIPT_STATE enum
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  const GoogleMeetTranscript({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.transcriptName,
    this.driveDestination,
    required this.state,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  GoogleMeetTranscript copyWith({
    String? id,
    String? userId,
    String? conferenceId,
    String? transcriptName,
    Map<String, dynamic>? driveDestination,
    String? state,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return GoogleMeetTranscript(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conferenceId: conferenceId ?? this.conferenceId,
      transcriptName: transcriptName ?? this.transcriptName,
      driveDestination: driveDestination ?? this.driveDestination,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleMeetTranscript &&
        other.id == id &&
        other.userId == userId &&
        other.conferenceId == conferenceId &&
        other.transcriptName == transcriptName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        conferenceId.hashCode ^
        transcriptName.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetTranscript(id: $id, userId: $userId, transcriptName: $transcriptName, state: $state)';
  }
}
