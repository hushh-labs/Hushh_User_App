import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/bid_model.dart';
import '../repositories/bid_repository.dart';

class GetValidBidForProductUseCase
    implements UseCase<BidModel?, GetValidBidForProductParams> {
  final BidRepository _bidRepository;

  GetValidBidForProductUseCase(this._bidRepository);

  @override
  Future<Either<Failure, BidModel?>> call(
    GetValidBidForProductParams params,
  ) async {
    return await _bidRepository.getValidBidForProduct(
      params.userId,
      params.agentId,
      params.productId,
    );
  }
}

class GetValidBidForProductParams {
  final String userId;
  final String agentId;
  final String productId;

  GetValidBidForProductParams({
    required this.userId,
    required this.agentId,
    required this.productId,
  });
}
