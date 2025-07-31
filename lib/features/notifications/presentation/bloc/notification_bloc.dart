import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/initialize_notifications_usecase.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../core/usecases/usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationAsReadUseCase markNotificationAsReadUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final InitializeNotificationsUseCase initializeNotificationsUseCase;
  final NotificationRepository notificationRepository;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.markNotificationAsReadUseCase,
    required this.getUnreadCountUseCase,
    required this.initializeNotificationsUseCase,
    required this.notificationRepository,
  }) : super(const NotificationInitial()) {
    on<GetNotificationsRequested>(_onGetNotificationsRequested);
    on<MarkNotificationAsReadRequested>(_onMarkNotificationAsReadRequested);
    on<MarkAllNotificationsAsReadRequested>(
      _onMarkAllNotificationsAsReadRequested,
    );
    on<DeleteNotificationRequested>(_onDeleteNotificationRequested);
    on<DeleteAllNotificationsRequested>(_onDeleteAllNotificationsRequested);
    on<GetUnreadCountRequested>(_onGetUnreadCountRequested);
    on<GetNotificationSettingsRequested>(_onGetNotificationSettingsRequested);
    on<UpdateNotificationSettingsRequested>(
      _onUpdateNotificationSettingsRequested,
    );
    on<InitializeNotificationsRequested>(_onInitializeNotificationsRequested);
    on<RefreshNotificationsRequested>(_onRefreshNotificationsRequested);
  }

  Future<void> _onGetNotificationsRequested(
    GetNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    final result = await getNotificationsUseCase(NoParams());
    final unreadCountResult = await getUnreadCountUseCase(NoParams());

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      notifications,
    ) {
      unreadCountResult.fold(
        (failure) => emit(NotificationFailure(failure.message)),
        (unreadCount) => emit(
          NotificationsLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          ),
        ),
      );
    });
  }

  Future<void> _onMarkNotificationAsReadRequested(
    MarkNotificationAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await markNotificationAsReadUseCase(event.notificationId);

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('Notification marked as read'));
        // Refresh notifications to update the UI
        add(const GetNotificationsRequested());
      } else {
        emit(const NotificationFailure('Failed to mark notification as read'));
      }
    });
  }

  Future<void> _onMarkAllNotificationsAsReadRequested(
    MarkAllNotificationsAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationRepository.markAllAsRead();

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('All notifications marked as read'));
        // Refresh notifications to update the UI
        add(const GetNotificationsRequested());
      } else {
        emit(
          const NotificationFailure('Failed to mark all notifications as read'),
        );
      }
    });
  }

  Future<void> _onDeleteNotificationRequested(
    DeleteNotificationRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationRepository.deleteNotification(
      event.notificationId,
    );

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('Notification deleted'));
        // Refresh notifications to update the UI
        add(const GetNotificationsRequested());
      } else {
        emit(const NotificationFailure('Failed to delete notification'));
      }
    });
  }

  Future<void> _onDeleteAllNotificationsRequested(
    DeleteAllNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationRepository.deleteAllNotifications();

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('All notifications deleted'));
        // Refresh notifications to update the UI
        add(const GetNotificationsRequested());
      } else {
        emit(const NotificationFailure('Failed to delete all notifications'));
      }
    });
  }

  Future<void> _onGetUnreadCountRequested(
    GetUnreadCountRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await getUnreadCountUseCase(NoParams());

    result.fold(
      (failure) => emit(NotificationFailure(failure.message)),
      (unreadCount) => emit(UnreadCountLoaded(unreadCount)),
    );
  }

  Future<void> _onGetNotificationSettingsRequested(
    GetNotificationSettingsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationRepository.getNotificationSettings();

    result.fold(
      (failure) => emit(NotificationFailure(failure.message)),
      (settings) => emit(NotificationSettingsLoaded(settings)),
    );
  }

  Future<void> _onUpdateNotificationSettingsRequested(
    UpdateNotificationSettingsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await notificationRepository.updateNotificationSettings(
      event.settings,
    );

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('Notification settings updated'));
      } else {
        emit(
          const NotificationFailure('Failed to update notification settings'),
        );
      }
    });
  }

  Future<void> _onInitializeNotificationsRequested(
    InitializeNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await initializeNotificationsUseCase(NoParams());

    result.fold((failure) => emit(NotificationFailure(failure.message)), (
      success,
    ) {
      if (success) {
        emit(const NotificationSuccess('Notifications initialized'));
        // Load notifications after initialization
        add(const GetNotificationsRequested());
      } else {
        emit(const NotificationFailure('Failed to initialize notifications'));
      }
    });
  }

  Future<void> _onRefreshNotificationsRequested(
    RefreshNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    add(const GetNotificationsRequested());
  }
}
