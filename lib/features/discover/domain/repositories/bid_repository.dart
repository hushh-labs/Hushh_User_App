import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/bid_model.dart';

abstract class BidRepository {
  Future<Either<Failure, List<BidModel>>> getValidBidsForUser(String userId);
  Future<Either<Failure, BidModel?>> getValidBidForProduct(
    String userId,
    String agentId,
    String productId,
  );
}
