import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isRead;
  final NotificationType type;
  final NotificationPriority priority;

  const NotificationEntity({
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

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    NotificationType? type,
    NotificationPriority? priority,
  }) {
    return NotificationEntity(
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

enum NotificationType { chat, system, marketing, reminder, update }

enum NotificationPriority { low, normal, high, urgent }
