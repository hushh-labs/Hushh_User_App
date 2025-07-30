import 'package:get_it/get_it.dart';
import '../presentation/bloc/discover_bloc.dart';
import '../presentation/bloc/card_wallet_bloc.dart';
import '../presentation/bloc/inventory_bloc.dart';
import '../presentation/bloc/lookbook_product_bloc.dart';

class DiscoverModule {
  static void init() {
    final sl = GetIt.instance;

    // BLoCs
    sl.registerFactory<DiscoverBloc>(() => DiscoverBloc());
    sl.registerFactory<CardWalletBloc>(() => CardWalletBloc());
    sl.registerFactory<InventoryBloc>(() => InventoryBloc());
    sl.registerFactory<LookBookProductBloc>(() => LookBookProductBloc());
  }
}
