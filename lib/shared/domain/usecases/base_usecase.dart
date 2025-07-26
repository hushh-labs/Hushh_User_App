// Base usecase for shared usecase patterns
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';

abstract class BaseUseCase<Type, Params> implements UseCase<Type, Params> {
  @override
  Future<Either<Failure, Type>> call(Params params);
}

// Base usecase for single parameter
abstract class SingleUseCase<Type, Param> implements UseCase<Type, Param> {
  @override
  Future<Either<Failure, Type>> call(Param param);
}

// Base usecase for no parameters
abstract class NoParamUseCase<Type> implements UseCase<Type, NoParams> {
  @override
  Future<Either<Failure, Type>> call(NoParams params);
}
