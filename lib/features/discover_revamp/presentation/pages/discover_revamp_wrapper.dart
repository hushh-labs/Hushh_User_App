import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/discover_revamp_bloc.dart';
import '../../domain/usecases/get_discover_revamp_items.dart';
import 'discover_revamp_page.dart';

class DiscoverRevampWrapper extends StatelessWidget {
  const DiscoverRevampWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final getItems = GetIt.instance<GetDiscoverRevampItems>();
    return BlocProvider(
      create: (_) => DiscoverRevampBloc(getItems: getItems),
      child: const DiscoverRevampPage(),
    );
  }
}
