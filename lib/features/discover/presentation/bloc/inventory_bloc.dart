import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/agent_product_model.dart';

// Events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class UpdateInventoryProductsEvent extends InventoryEvent {
  final List<AgentProductModel> products;

  const UpdateInventoryProductsEvent(this.products);

  @override
  List<Object?> get props => [products];
}

class UpdateProductStockQuantityEvent extends InventoryEvent {
  final String productId;
  final int newQuantity;

  const UpdateProductStockQuantityEvent({
    required this.productId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [productId, newQuantity];
}

// States
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<AgentProductModel> products;

  const InventoryLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc() : super(InventoryInitial()) {
    on<UpdateInventoryProductsEvent>(_onUpdateInventoryProducts);
    on<UpdateProductStockQuantityEvent>(_onUpdateProductStockQuantity);
  }

  void _onUpdateInventoryProducts(
    UpdateInventoryProductsEvent event,
    Emitter<InventoryState> emit,
  ) {
    emit(InventoryLoaded(event.products));
  }

  void _onUpdateProductStockQuantity(
    UpdateProductStockQuantityEvent event,
    Emitter<InventoryState> emit,
  ) {
    final currentState = state;
    if (currentState is InventoryLoaded) {
      final updatedProducts = currentState.products.map((product) {
        if (product.id == event.productId) {
          return product.copyWith(stockQuantity: event.newQuantity);
        }
        return product;
      }).toList();

      emit(InventoryLoaded(updatedProducts));
    }
  }
}
