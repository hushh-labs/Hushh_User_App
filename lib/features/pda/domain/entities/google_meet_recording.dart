class GoogleMeetRecording {
  final String id;
  final String userId;
  final String conferenceId;
  final String recordingName;
  final Map<String, dynamic>? driveDestination;
  final String state; // RECORDING_STATE enum
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  const GoogleMeetRecording({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.recordingName,
    this.driveDestination,
    required this.state,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  GoogleMeetRecording copyWith({
    String? id,
    String? userId,
    String? conferenceId,
    String? recordingName,
    Map<String, dynamic>? driveDestination,
    String? state,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return GoogleMeetRecording(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conferenceId: conferenceId ?? this.conferenceId,
      recordingName: recordingName ?? this.recordingName,
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
    return other is GoogleMeetRecording &&
        other.id == id &&
        other.userId == userId &&
        other.conferenceId == conferenceId &&
        other.recordingName == recordingName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        conferenceId.hashCode ^
        recordingName.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetRecording(id: $id, userId: $userId, recordingName: $recordingName, state: $state)';
  }
}
