// Base repository interface for shared repository patterns
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/base_entity.dart';

abstract class BaseRepository<T extends BaseEntity> {
  Future<Either<Failure, T>> getById(String id);
  Future<Either<Failure, List<T>>> getAll();
  Future<Either<Failure, T>> create(T entity);
  Future<Either<Failure, T>> update(T entity);
  Future<Either<Failure, bool>> delete(String id);
}
