import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/bid_datasource.dart';
import '../models/bid_model.dart';
import '../../domain/repositories/bid_repository.dart';

class BidRepositoryImpl implements BidRepository {
  final BidDataSource _bidDataSource;

  BidRepositoryImpl(this._bidDataSource);

  @override
  Future<Either<Failure, List<BidModel>>> getValidBidsForUser(
    String userId,
  ) async {
    try {
      final bids = await _bidDataSource.getValidBidsForUser(userId);
      return Right(bids);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch bids: $e'));
    }
  }

  @override
  Future<Either<Failure, BidModel?>> getValidBidForProduct(
    String userId,
    String agentId,
    String productId,
  ) async {
    try {
      final bid = await _bidDataSource.getValidBidForProduct(
        userId,
        agentId,
        productId,
      );
      return Right(bid);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch bid for product: $e'));
    }
  }
}
