import 'package:get_it/get_it.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/get_notifications_usecase.dart';
import '../domain/usecases/mark_notification_as_read_usecase.dart';
import '../domain/usecases/get_unread_count_usecase.dart';
import '../domain/usecases/initialize_notifications_usecase.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/datasources/notification_local_datasource.dart';
import '../data/services/fcm_service.dart';
import '../data/services/notification_service.dart';
import '../presentation/bloc/notification_bloc.dart';

class NotificationModule {
  static bool _isRegistered = false;

  static void register() {
    if (_isRegistered) return;

    final sl = GetIt.instance;

    // BLoC
    sl.registerFactory(
      () => NotificationBloc(
        getNotificationsUseCase: sl(),
        markNotificationAsReadUseCase: sl(),
        getUnreadCountUseCase: sl(),
        initializeNotificationsUseCase: sl(),
        notificationRepository: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
    sl.registerLazySingleton(() => MarkNotificationAsReadUseCase(sl()));
    sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
    sl.registerLazySingleton(() => InitializeNotificationsUseCase(sl()));

    // Repository
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );

    // Data sources
    sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<NotificationLocalDataSource>(
      () => NotificationLocalDataSourceImpl(),
    );

    // Services
    sl.registerLazySingleton(() => FCMService());
    sl.registerLazySingleton(() => NotificationService());

    _isRegistered = true;
  }
}
