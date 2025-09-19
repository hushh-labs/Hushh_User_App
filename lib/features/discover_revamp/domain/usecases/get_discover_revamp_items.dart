import 'package:dartz/dartz.dart';

import '../entities/discover_revamp_item.dart';
import '../repositories/discover_revamp_repository.dart';

class GetDiscoverRevampItems {
  final DiscoverRevampRepository repository;
  GetDiscoverRevampItems(this.repository);

  Future<Either<String, List<DiscoverRevampItem>>> call() {
    return repository.getItems();
  }
}
