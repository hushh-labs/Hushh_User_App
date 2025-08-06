import '../models/brand_model.dart';
import '../datasources/firebase_discover_datasource.dart';

abstract class BrandRepository {
  Future<List<BrandModel>> getRandomBrands(int limit);
  Future<List<BrandModel>> getAllBrands();
}

class BrandRepositoryImpl implements BrandRepository {
  final FirebaseDiscoverDataSource _dataSource;

  BrandRepositoryImpl(this._dataSource);

  @override
  Future<List<BrandModel>> getRandomBrands(int limit) async {
    return await _dataSource.getRandomBrands(limit);
  }

  @override
  Future<List<BrandModel>> getAllBrands() async {
    return await _dataSource.getAllBrands();
  }
}
