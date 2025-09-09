import 'package:dartz/dartz.dart';
import 'package:hushh_user_app/core/errors/failures.dart';
import 'package:hushh_user_app/core/usecases/usecase.dart';
import 'package:hushh_user_app/features/vault/domain/repositories/vault_repository.dart';

class ClearAllDocumentsUseCase
    implements UseCase<void, ClearAllDocumentsParams> {
  final VaultRepository repository;

  ClearAllDocumentsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ClearAllDocumentsParams params) async {
    try {
      await repository.clearAllDocuments(params.userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class ClearAllDocumentsParams {
  final String userId;

  ClearAllDocumentsParams({required this.userId});
}
