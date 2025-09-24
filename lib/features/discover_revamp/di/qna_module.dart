import 'package:get_it/get_it.dart';

import '../domain/repositories/qna_repository.dart';
import '../domain/usecases/start_qna_session.dart';
import '../domain/usecases/submit_answer.dart';
import '../domain/usecases/complete_qna_session.dart';
import '../data/repositories/qna_repository_impl.dart';
import '../data/datasources/qna_remote_data_source.dart';
import '../presentation/bloc/qna_bloc.dart';

class QnAModule {
  static void init(GetIt getIt) {
    // Data sources
    getIt.registerLazySingleton<QnARemoteDataSource>(
      () => QnARemoteDataSourceImpl(),
    );

    // Repository
    getIt.registerLazySingleton<QnARepository>(
      () => QnARepositoryImpl(getIt<QnARemoteDataSource>()),
    );

    // Use cases
    getIt.registerFactory(() => StartQnASession(getIt<QnARepository>()));
    getIt.registerFactory(() => SubmitAnswer(getIt<QnARepository>()));
    getIt.registerFactory(() => CompleteQnASession(getIt<QnARepository>()));

    // BLoC
    getIt.registerFactory(
      () => QnABloc(
        startQnASession: getIt<StartQnASession>(),
        submitAnswer: getIt<SubmitAnswer>(),
        completeQnASession: getIt<CompleteQnASession>(),
      ),
    );
  }
}
