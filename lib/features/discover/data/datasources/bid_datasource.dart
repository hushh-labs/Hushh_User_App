import 'package:firebase_database/firebase_database.dart';
import '../models/bid_model.dart';

abstract class BidDataSource {
  Future<List<BidModel>> getValidBidsForUser(String userId);
  Future<BidModel?> getValidBidForProduct(
    String userId,
    String agentId,
    String productId,
  );
}

class BidDataSourceImpl implements BidDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Future<List<BidModel>> getValidBidsForUser(String userId) async {
    try {
      final DatabaseReference bidsRef = _database.ref().child('bids');
      final DatabaseEvent event = await bidsRef.once();

      if (event.snapshot.value == null) {
        return [];
      }

      final Map<dynamic, dynamic> bidsData =
          event.snapshot.value as Map<dynamic, dynamic>;
      final List<BidModel> validBids = [];

      for (final entry in bidsData.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        
        if (value is Map<dynamic, dynamic>) {
          final bidData = Map<String, dynamic>.from(value);
          bidData['id'] = key;

          try {
            final bid = BidModel.fromJson(bidData);
            if (bid.userId == userId && bid.isValid) {
              validBids.add(bid);
            }
          } catch (e) {
            // Skip invalid bid data
            continue;
          }
        }
      }

      return validBids;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BidModel?> getValidBidForProduct(
    String userId,
    String agentId,
    String productId,
  ) async {
    try {
      final DatabaseReference bidsRef = _database.ref().child('bids');
      final DatabaseEvent event = await bidsRef.once();

      if (event.snapshot.value == null) {
        return null;
      }

      final Map<dynamic, dynamic> bidsData =
          event.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in bidsData.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        if (value is Map<dynamic, dynamic>) {
          final bidData = Map<String, dynamic>.from(value);
          bidData['id'] = key;

          try {
            final bid = BidModel.fromJson(bidData);

            // Check each condition separately for debugging
            final userIdMatch = bid.userId == userId;
            final agentIdMatch = bid.agentId == agentId;
            final productIdMatch = bid.productId == productId;
            final isValid = bid.isValid;

            if (userIdMatch && agentIdMatch && productIdMatch && isValid) {
              return bid;
            }
          } catch (e) {
            // Skip invalid bid data
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
