import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/card_wallet_bloc.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/lookbook_product_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/agents_products_bloc.dart';
import '../../data/datasources/firebase_discover_datasource.dart';
import '../../data/repositories/discover_repository_impl.dart';
import 'discover_page.dart';
import '../../../../shared/presentation/widgets/debug_wrapper.dart';

class DiscoverPageWrapper extends StatelessWidget {
  const DiscoverPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DiscoverBloc>(create: (context) => DiscoverBloc()),
        BlocProvider<CardWalletBloc>(create: (context) => CardWalletBloc()),
        BlocProvider<InventoryBloc>(create: (context) => InventoryBloc()),
        BlocProvider<LookBookProductBloc>(
          create: (context) => LookBookProductBloc(),
        ),
        BlocProvider<CartBloc>(create: (context) => CartBloc()),
        BlocProvider<AgentsProductsBloc>(
          create: (context) => AgentsProductsBloc(
            DiscoverRepositoryImpl(FirebaseDiscoverDataSourceImpl()),
          ),
        ),
      ],
      child: const DebugWrapper(child: DiscoverPage()),
    );
  }
}
