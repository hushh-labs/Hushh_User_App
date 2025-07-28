import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class UploadProfileImageUseCase implements UseCase<String, String> {
  final ProfileRepository repository;

  const UploadProfileImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String imagePath) async {
    try {
      final imageUrl = await repository.uploadProfileImage(imagePath);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
