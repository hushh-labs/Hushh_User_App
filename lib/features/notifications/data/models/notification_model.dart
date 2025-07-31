import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/notification_entity.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'is_read')
  final bool isRead;
  final String type;
  final String priority;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.createdAt,
    this.readAt,
    required this.isRead,
    required this.type,
    required this.priority,
  });

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      createdAt: createdAt,
      readAt: readAt,
      isRead: isRead,
      type: _stringToNotificationType(type),
      priority: _stringToNotificationPriority(priority),
    );
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      imageUrl: entity.imageUrl,
      data: entity.data,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
      isRead: entity.isRead,
      type: _notificationTypeToString(entity.type),
      priority: _notificationPriorityToString(entity.priority),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  static NotificationType _stringToNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'chat':
        return NotificationType.chat;
      case 'system':
        return NotificationType.system;
      case 'marketing':
        return NotificationType.marketing;
      case 'reminder':
        return NotificationType.reminder;
      case 'update':
        return NotificationType.update;
      default:
        return NotificationType.system;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return 'chat';
      case NotificationType.system:
        return 'system';
      case NotificationType.marketing:
        return 'marketing';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.update:
        return 'update';
    }
  }

  static NotificationPriority _stringToNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static String _notificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

    NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    String? type,
    String? priority,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        imageUrl,
        data,
        createdAt,
        readAt,
        isRead,
        type,
        priority,
      ];
}
