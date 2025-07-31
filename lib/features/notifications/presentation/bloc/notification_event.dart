import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class GetNotificationsRequested extends NotificationEvent {
  const GetNotificationsRequested();
}

class MarkNotificationAsReadRequested extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsReadRequested extends NotificationEvent {
  const MarkAllNotificationsAsReadRequested();
}

class DeleteNotificationRequested extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class DeleteAllNotificationsRequested extends NotificationEvent {
  const DeleteAllNotificationsRequested();
}

class GetUnreadCountRequested extends NotificationEvent {
  const GetUnreadCountRequested();
}

class GetNotificationSettingsRequested extends NotificationEvent {
  const GetNotificationSettingsRequested();
}

class UpdateNotificationSettingsRequested extends NotificationEvent {
  final Map<String, bool> settings;

  const UpdateNotificationSettingsRequested(this.settings);

  @override
  List<Object?> get props => [settings];
}

class InitializeNotificationsRequested extends NotificationEvent {
  const InitializeNotificationsRequested();
}

class RefreshNotificationsRequested extends NotificationEvent {
  const RefreshNotificationsRequested();
}
