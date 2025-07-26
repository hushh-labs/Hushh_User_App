// Base widget for shared widget patterns
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/base_bloc.dart';

// Base widget with BLoC support
abstract class BaseWidget<
  B extends BaseBloc<E, S>,
  E extends BaseEvent,
  S extends BaseState
>
    extends StatelessWidget {
  const BaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>(
      create: (context) => createBloc(context),
      child: BlocListener<B, S>(
        listener: (context, state) => onStateChanged(context, state),
        child: BlocBuilder<B, S>(
          builder: (context, state) => buildWidget(context, state),
        ),
      ),
    );
  }

  // Create BLoC instance
  B createBloc(BuildContext context);

  // Handle state changes
  void onStateChanged(BuildContext context, S state) {
    // Override in subclasses for specific state handling
  }

  // Build widget based on state
  Widget buildWidget(BuildContext context, S state);

  // Common loading widget
  Widget buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  // Common error widget
  Widget buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
