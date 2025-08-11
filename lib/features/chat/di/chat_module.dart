import 'package:get_it/get_it.dart';
import '../../../../core/network/network_info.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/are_users_active.dart';
import '../domain/usecases/chat_usecase.dart';
import '../data/datasources/firebase_realtime_chat_datasource.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../presentation/bloc/chat_bloc.dart';

final getIt = GetIt.instance;

class ChatModule {
  static void init() {
    // Data sources
    getIt.registerLazySingleton<FirebaseRealtimeChatDataSource>(
      () => FirebaseRealtimeChatDataSource(),
    );

    // Repository
    getIt.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(
        remoteDataSource: getIt(),
        networkInfo: getIt<NetworkInfo>(),
      ),
    );

    // Use cases
    getIt.registerLazySingleton(() => GetUserChats(getIt()));
    getIt.registerLazySingleton(() => GetChatMessages(getIt()));
    getIt.registerLazySingleton(() => SendMessage(getIt()));
    getIt.registerLazySingleton(() => CreateChat(getIt()));
    getIt.registerLazySingleton(() => GetExistingChatId(getIt()));
    getIt.registerLazySingleton(() => GetChatById(getIt()));
    getIt.registerLazySingleton(() => SetTypingStatus(getIt()));
    getIt.registerLazySingleton(() => MarkMessageAsSeen(getIt()));
    getIt.registerLazySingleton(() => MarkLastMessageAsSeen(getIt()));
    getIt.registerLazySingleton(() => MarkChatAsSeen(getIt()));

    // Stream use cases
    getIt.registerLazySingleton(() => StreamUserChats(getIt()));
    getIt.registerLazySingleton(() => StreamChatMessages(getIt()));
    getIt.registerLazySingleton(() => StreamTypingStatus(getIt()));

    // User information use cases
    getIt.registerLazySingleton(() => GetUserDisplayName(getIt()));
    getIt.registerLazySingleton(() => GetUsers(getIt()));
    getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
    getIt.registerLazySingleton(() => SearchUsers(getIt()));
    getIt.registerLazySingleton(() => AreUsersActive(getIt()));

    // Blocking use cases
    getIt.registerLazySingleton(() => BlockUser(getIt()));
    getIt.registerLazySingleton(() => UnblockUser(getIt()));
    getIt.registerLazySingleton(() => IsUserBlocked(getIt()));

    // BLoC - Register with factory constructor
    getIt.registerFactory(() => ChatBloc());
  }
}
