import 'package:dartz/dartz.dart';

import '../../domain/entities/discover_revamp_item.dart';
import '../../domain/repositories/discover_revamp_repository.dart';
import '../datasources/discover_revamp_remote_data_source.dart';

class DiscoverRevampRepositoryImpl implements DiscoverRevampRepository {
  final DiscoverRevampRemoteDataSource remoteDataSource;

  DiscoverRevampRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<DiscoverRevampItem>>> getItems() async {
    try {
      final items = await remoteDataSource.fetchItems();
      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
