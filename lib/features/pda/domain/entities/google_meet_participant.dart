class GoogleMeetParticipant {
  final String id;
  final String userId;
  final String conferenceId;
  final String participantName;
  final String? displayName;
  final String? email;
  final DateTime? joinTime;
  final DateTime? leaveTime;
  final int? durationMinutes;
  final String role; // host, co-host, participant
  final DateTime createdAt;

  const GoogleMeetParticipant({
    required this.id,
    required this.userId,
    required this.conferenceId,
    required this.participantName,
    this.displayName,
    this.email,
    this.joinTime,
    this.leaveTime,
    this.durationMinutes,
    required this.role,
    required this.createdAt,
  });

  GoogleMeetParticipant copyWith({
    String? id,
    String? userId,
    String? conferenceId,
    String? participantName,
    String? displayName,
    String? email,
    DateTime? joinTime,
    DateTime? leaveTime,
    int? durationMinutes,
    String? role,
    DateTime? createdAt,
  }) {
    return GoogleMeetParticipant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conferenceId: conferenceId ?? this.conferenceId,
      participantName: participantName ?? this.participantName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      joinTime: joinTime ?? this.joinTime,
      leaveTime: leaveTime ?? this.leaveTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoogleMeetParticipant &&
        other.id == id &&
        other.userId == userId &&
        other.conferenceId == conferenceId &&
        other.participantName == participantName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        conferenceId.hashCode ^
        participantName.hashCode;
  }

  @override
  String toString() {
    return 'GoogleMeetParticipant(id: $id, userId: $userId, participantName: $participantName, role: $role)';
  }
}
