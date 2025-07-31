import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationsLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationSettingsLoaded extends NotificationState {
  final Map<String, bool> settings;

  const NotificationSettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class NotificationSuccess extends NotificationState {
  final String message;

  const NotificationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationFailure extends NotificationState {
  final String message;

  const NotificationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class UnreadCountLoaded extends NotificationState {
  final int unreadCount;

  const UnreadCountLoaded(this.unreadCount);

  @override
  List<Object?> get props => [unreadCount];
}
