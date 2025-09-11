enum SensitiveFlowType {
  login,
  onboarding,
  upload,
  payment;

  String get value {
    switch (this) {
      case SensitiveFlowType.login:
        return 'login';
      case SensitiveFlowType.onboarding:
        return 'onboarding';
      case SensitiveFlowType.upload:
        return 'upload';
      case SensitiveFlowType.payment:
        return 'payment';
    }
  }

  static SensitiveFlowType fromString(String value) {
    switch (value) {
      case 'login':
        return SensitiveFlowType.login;
      case 'onboarding':
        return SensitiveFlowType.onboarding;
      case 'upload':
        return SensitiveFlowType.upload;
      case 'payment':
        return SensitiveFlowType.payment;
      default:
        throw ArgumentError('Invalid sensitive flow type: $value');
    }
  }
}

class UserAppState {
  final String id;
  final String userId;
  final String? currentScreen;
  final bool isInSensitiveFlow;
  final SensitiveFlowType? sensitiveFlowType;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAppState({
    required this.id,
    required this.userId,
    this.currentScreen,
    this.isInSensitiveFlow = false,
    this.sensitiveFlowType,
    required this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
  });

  UserAppState copyWith({
    String? id,
    String? userId,
    String? currentScreen,
    bool? isInSensitiveFlow,
    SensitiveFlowType? sensitiveFlowType,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAppState(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentScreen: currentScreen ?? this.currentScreen,
      isInSensitiveFlow: isInSensitiveFlow ?? this.isInSensitiveFlow,
      sensitiveFlowType: sensitiveFlowType ?? this.sensitiveFlowType,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAppState &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserAppState{id: $id, userId: $userId, currentScreen: $currentScreen, isInSensitiveFlow: $isInSensitiveFlow}';
  }
}
