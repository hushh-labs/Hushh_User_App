import 'package:dartz/dartz.dart';

import '../entities/discover_revamp_item.dart';

abstract class DiscoverRevampRepository {
  Future<Either<String, List<DiscoverRevampItem>>> getItems();
}
