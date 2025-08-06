import 'package:get_it/get_it.dart';
import '../presentation/bloc/discover_bloc.dart';
import '../presentation/bloc/card_wallet_bloc.dart';
import '../presentation/bloc/inventory_bloc.dart';
import '../presentation/bloc/lookbook_product_bloc.dart';
import '../presentation/bloc/cart_bloc.dart';
import '../presentation/bloc/brand_bloc.dart';
import '../data/datasources/cart_notification_remote_datasource.dart';
import '../data/repositories/cart_notification_repository_impl.dart';
import '../domain/repositories/cart_notification_repository.dart';
import '../domain/usecases/send_cart_notification_usecase.dart';
import '../data/datasources/bid_datasource.dart';
import '../data/repositories/bid_repository_impl.dart';
import '../domain/repositories/bid_repository.dart';
import '../domain/usecases/get_valid_bid_for_product_usecase.dart';
import '../data/datasources/firebase_discover_datasource.dart';
import '../data/repositories/brand_repository.dart';

class DiscoverModule {
  static void init() {
    final sl = GetIt.instance;

    // Data Sources
    sl.registerLazySingleton<CartNotificationRemoteDataSource>(
      () => CartNotificationRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<BidDataSource>(() => BidDataSourceImpl());
    sl.registerLazySingleton<FirebaseDiscoverDataSource>(
      () => FirebaseDiscoverDataSourceImpl(),
    );

    // Repositories
    sl.registerLazySingleton<CartNotificationRepository>(
      () => CartNotificationRepositoryImpl(sl()),
    );
    sl.registerLazySingleton<BidRepository>(() => BidRepositoryImpl(sl()));
    sl.registerLazySingleton<BrandRepository>(() => BrandRepositoryImpl(sl()));

    // Use Cases
    sl.registerFactory<SendCartNotificationUseCase>(
      () => SendCartNotificationUseCase(sl()),
    );
    sl.registerFactory<GetValidBidForProductUseCase>(
      () => GetValidBidForProductUseCase(sl()),
    );

    // BLoCs
    sl.registerFactory<DiscoverBloc>(() => DiscoverBloc());
    sl.registerFactory<CardWalletBloc>(() => CardWalletBloc());
    sl.registerFactory<InventoryBloc>(() => InventoryBloc());
    sl.registerFactory<LookBookProductBloc>(() => LookBookProductBloc());
    sl.registerFactory<CartBloc>(() => CartBloc(sl(), sl()));
    sl.registerFactory<BrandBloc>(() => BrandBloc(sl()));
  }
}
