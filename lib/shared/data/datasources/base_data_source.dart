// Base data source for shared data source patterns
import '../models/base_model.dart';

abstract class BaseDataSource<T extends BaseModel> {
  Future<T> getById(String id);
  Future<List<T>> getAll();
  Future<T> create(T model);
  Future<T> update(T model);
  Future<bool> delete(String id);
}

// Remote data source interface
abstract class BaseRemoteDataSource<T extends BaseModel>
    extends BaseDataSource<T> {
  // Add remote-specific methods here
}

// Local data source interface
abstract class BaseLocalDataSource<T extends BaseModel>
    extends BaseDataSource<T> {
  // Add local-specific methods here
  Future<void> cacheData(List<T> data);
  Future<void> clearCache();
}
