import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/features/pda/domain/repository/pda_repository.dart';
import 'package:hushh_user_app/core/errors/failures.dart';

class SearchRelevantMessagesUseCase {
  final PdaRepository repository;

  SearchRelevantMessagesUseCase(this.repository);

  Future<Either<Failure, List<String>>> call({
    required String userId,
    required String query,
    int topK = 5,
    double similarityThreshold = 0.5,
  }) async {
    return await repository.searchRelevantMessages(
      userId,
      query,
      topK: topK,
      similarityThreshold: similarityThreshold,
    );
  }
}
