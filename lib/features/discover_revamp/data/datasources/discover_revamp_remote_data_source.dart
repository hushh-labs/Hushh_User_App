import '../models/discover_revamp_item_model.dart';

abstract class DiscoverRevampRemoteDataSource {
  Future<List<DiscoverRevampItemModel>> fetchItems();
}

class DiscoverRevampRemoteDataSourceImpl
    implements DiscoverRevampRemoteDataSource {
  @override
  Future<List<DiscoverRevampItemModel>> fetchItems() async {
    // TODO: Replace with real API/Firestore
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DiscoverRevampItemModel(id: '1', title: 'Sample Item 1'),
      DiscoverRevampItemModel(id: '2', title: 'Sample Item 2'),
    ];
  }
}
