import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/agent_product_model.dart';

// Events
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final AgentProductModel product;
  final String agentId;
  final String agentName;

  const AddToCartEvent({
    required this.product,
    required this.agentId,
    required this.agentName,
  });

  @override
  List<Object?> get props => [product, agentId, agentName];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateCartItemQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

class LoadCartEvent extends CartEvent {
  const LoadCartEvent();
}

// States
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? currentAgentId;
  final String? currentAgentName;
  final int totalItems;
  final double totalPrice;

  const CartLoaded({
    required this.items,
    this.currentAgentId,
    this.currentAgentName,
    required this.totalItems,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
    items,
    currentAgentId,
    currentAgentName,
    totalItems,
    totalPrice,
  ];

  CartLoaded copyWith({
    List<CartItem>? items,
    String? currentAgentId,
    String? currentAgentName,
    int? totalItems,
    double? totalPrice,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      currentAgentName: currentAgentName ?? this.currentAgentName,
      totalItems: totalItems ?? this.totalItems,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartAgentConflict extends CartState {
  final String currentAgentName;
  final String newAgentName;
  final AgentProductModel product;

  const CartAgentConflict({
    required this.currentAgentName,
    required this.newAgentName,
    required this.product,
  });

  @override
  List<Object?> get props => [currentAgentName, newAgentName, product];
}

// Cart Item Model
class CartItem extends Equatable {
  final String id;
  final AgentProductModel product;
  final int quantity;
  final String agentId;
  final String agentName;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.agentId,
    required this.agentName,
  });

  @override
  List<Object?> get props => [id, product, quantity, agentId, agentName];

  CartItem copyWith({
    String? id,
    AgentProductModel? product,
    int? quantity,
    String? agentId,
    String? agentName,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
    );
  }
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<LoadCartEvent>(_onLoadCart);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final currentState = state;

    if (currentState is CartLoaded) {
      // Check if cart is empty or if the product is from the same agent
      if (currentState.items.isEmpty) {
        // Cart is empty, add the product
        final newItem = CartItem(
          id: event.product.id,
          product: event.product,
          quantity: 1,
          agentId: event.agentId,
          agentName: event.agentName,
        );

        final newItems = [...currentState.items, newItem];
        final newTotalItems = newItems.fold(
          0,
          (sum, item) => sum + item.quantity,
        );
        final newTotalPrice = newItems.fold(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );

        emit(
          CartLoaded(
            items: newItems,
            currentAgentId: event.agentId,
            currentAgentName: event.agentName,
            totalItems: newTotalItems,
            totalPrice: newTotalPrice,
          ),
        );
      } else if (currentState.currentAgentId == event.agentId) {
        // Same agent, check if product already exists
        final existingItemIndex = currentState.items.indexWhere(
          (item) => item.id == event.product.id,
        );

        if (existingItemIndex != -1) {
          // Product exists, increment quantity
          final updatedItems = List<CartItem>.from(currentState.items);
          final existingItem = updatedItems[existingItemIndex];
          updatedItems[existingItemIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + 1,
          );

          final newTotalItems = updatedItems.fold(
            0,
            (sum, item) => sum + item.quantity,
          );
          final newTotalPrice = updatedItems.fold(
            0.0,
            (sum, item) => sum + (item.product.price * item.quantity),
          );

          emit(
            CartLoaded(
              items: updatedItems,
              currentAgentId: currentState.currentAgentId,
              currentAgentName: currentState.currentAgentName,
              totalItems: newTotalItems,
              totalPrice: newTotalPrice,
            ),
          );
        } else {
          // New product from same agent
          final newItem = CartItem(
            id: event.product.id,
            product: event.product,
            quantity: 1,
            agentId: event.agentId,
            agentName: event.agentName,
          );

          final newItems = [...currentState.items, newItem];
          final newTotalItems = newItems.fold(
            0,
            (sum, item) => sum + item.quantity,
          );
          final newTotalPrice = newItems.fold(
            0.0,
            (sum, item) => sum + (item.product.price * item.quantity),
          );

          emit(
            CartLoaded(
              items: newItems,
              currentAgentId: currentState.currentAgentId,
              currentAgentName: currentState.currentAgentName,
              totalItems: newTotalItems,
              totalPrice: newTotalPrice,
            ),
          );
        }
      } else {
        // Different agent, emit conflict state
        emit(
          CartAgentConflict(
            currentAgentName: currentState.currentAgentName!,
            newAgentName: event.agentName,
            product: event.product,
          ),
        );
      }
    } else {
      // Initial state, add first item
      final newItem = CartItem(
        id: event.product.id,
        product: event.product,
        quantity: 1,
        agentId: event.agentId,
        agentName: event.agentName,
      );

      emit(
        CartLoaded(
          items: [newItem],
          currentAgentId: event.agentId,
          currentAgentName: event.agentName,
          totalItems: 1,
          totalPrice: event.product.price,
        ),
      );
    }
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final currentState = state;

    if (currentState is CartLoaded) {
      final updatedItems = currentState.items
          .where((item) => item.id != event.productId)
          .toList();

      if (updatedItems.isEmpty) {
        // Cart is now empty
        emit(
          CartLoaded(
            items: [],
            currentAgentId: null,
            currentAgentName: null,
            totalItems: 0,
            totalPrice: 0.0,
          ),
        );
      } else {
        final newTotalItems = updatedItems.fold(
          0,
          (sum, item) => sum + item.quantity,
        );
        final newTotalPrice = updatedItems.fold(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );

        emit(
          CartLoaded(
            items: updatedItems,
            currentAgentId: currentState.currentAgentId,
            currentAgentName: currentState.currentAgentName,
            totalItems: newTotalItems,
            totalPrice: newTotalPrice,
          ),
        );
      }
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) {
    final currentState = state;

    if (currentState is CartLoaded) {
      final updatedItems = currentState.items.map((item) {
        if (item.id == event.productId) {
          return item.copyWith(quantity: event.quantity);
        }
        return item;
      }).toList();

      final newTotalItems = updatedItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
      final newTotalPrice = updatedItems.fold(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

      emit(
        CartLoaded(
          items: updatedItems,
          currentAgentId: currentState.currentAgentId,
          currentAgentName: currentState.currentAgentName,
          totalItems: newTotalItems,
          totalPrice: newTotalPrice,
        ),
      );
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(
      CartLoaded(
        items: [],
        currentAgentId: null,
        currentAgentName: null,
        totalItems: 0,
        totalPrice: 0.0,
      ),
    );
  }

  void _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) {
    // For now, just emit the current state
    // In a real app, you might load from local storage or API
    if (state is CartInitial) {
      emit(
        CartLoaded(
          items: [],
          currentAgentId: null,
          currentAgentName: null,
          totalItems: 0,
          totalPrice: 0.0,
        ),
      );
    }
  }
}
