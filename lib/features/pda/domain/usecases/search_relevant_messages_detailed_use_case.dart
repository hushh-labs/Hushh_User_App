import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

class SearchRelevantMessagesDetailedUseCase {
  final PdaRepository repository;

  SearchRelevantMessagesDetailedUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required String userId,
    required String query,
    int topK = 5,
  }) async {
    return await repository.searchRelevantMessagesDetailed(
      userId,
      query,
      topK: topK,
    );
  }
}
