import '../../domain/entities/user_app_state.dart';

class UserAppStateModel extends UserAppState {
  const UserAppStateModel({
    required super.id,
    required super.userId,
    super.currentScreen,
    super.isInSensitiveFlow,
    super.sensitiveFlowType,
    required super.lastActivityAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserAppStateModel.fromJson(Map<String, dynamic> json) {
    return UserAppStateModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      currentScreen: json['current_screen'] as String?,
      isInSensitiveFlow: json['is_in_sensitive_flow'] as bool? ?? false,
      sensitiveFlowType: json['sensitive_flow_type'] != null
          ? SensitiveFlowType.fromString(json['sensitive_flow_type'] as String)
          : null,
      lastActivityAt: DateTime.parse(json['last_activity_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'current_screen': currentScreen,
      'is_in_sensitive_flow': isInSensitiveFlow,
      'sensitive_flow_type': sensitiveFlowType?.value,
      'last_activity_at': lastActivityAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserAppStateModel.fromEntity(UserAppState entity) {
    return UserAppStateModel(
      id: entity.id,
      userId: entity.userId,
      currentScreen: entity.currentScreen,
      isInSensitiveFlow: entity.isInSensitiveFlow,
      sensitiveFlowType: entity.sensitiveFlowType,
      lastActivityAt: entity.lastActivityAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserAppState toEntity() {
    return UserAppState(
      id: id,
      userId: userId,
      currentScreen: currentScreen,
      isInSensitiveFlow: isInSensitiveFlow,
      sensitiveFlowType: sensitiveFlowType,
      lastActivityAt: lastActivityAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
