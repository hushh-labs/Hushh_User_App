import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/agent_product_model.dart';

// Events
abstract class CardWalletEvent extends Equatable {
  const CardWalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends CardWalletEvent {
  const LoadProducts();
}

class UpdateProductStock extends CardWalletEvent {
  final String productId;
  final int newStock;

  const UpdateProductStock({required this.productId, required this.newStock});

  @override
  List<Object?> get props => [productId, newStock];
}

// States
abstract class CardWalletState extends Equatable {
  const CardWalletState();

  @override
  List<Object?> get props => [];
}

class CardWalletInitial extends CardWalletState {}

class CardWalletLoading extends CardWalletState {}

class CardWalletLoaded extends CardWalletState {
  final List<AgentProductModel> products;
  final bool isAgent;

  const CardWalletLoaded({required this.products, this.isAgent = false});

  @override
  List<Object?> get props => [products, isAgent];
}

class CardWalletError extends CardWalletState {
  final String message;

  const CardWalletError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CardWalletBloc extends Bloc<CardWalletEvent, CardWalletState> {
  CardWalletBloc() : super(CardWalletInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<UpdateProductStock>(_onUpdateProductStock);
  }

  void _onLoadProducts(
    LoadProducts event,
    Emitter<CardWalletState> emit,
  ) async {
    emit(CardWalletLoading());

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      final products = _getDummyProducts();

      emit(
        CardWalletLoaded(
          products: products,
          isAgent: false, // For now, set as user
        ),
      );
    } catch (e) {
      emit(CardWalletError('Failed to load products: $e'));
    }
  }

  void _onUpdateProductStock(
    UpdateProductStock event,
    Emitter<CardWalletState> emit,
  ) {
    final currentState = state;
    if (currentState is CardWalletLoaded) {
      final updatedProducts = currentState.products.map((product) {
        if (product.id == event.productId) {
          return product.copyWith(stockQuantity: event.newStock);
        }
        return product;
      }).toList();

      emit(
        CardWalletLoaded(
          products: updatedProducts,
          isAgent: currentState.isAgent,
        ),
      );
    }
  }

  // Dummy data generator
  List<AgentProductModel> _getDummyProducts() {
    return [
      AgentProductModel(
        id: '1',
        productName: 'Premium Headphones',
        productDescription:
            'High-quality wireless headphones with noise cancellation',
        productPrice: 299.99,
        stockQuantity: 15,
        productImage: 'https://picsum.photos/300/200?random=1',
        category: 'Electronics',
        createdAt: DateTime.now().subtract(Duration(days: 5)),
      ),
      AgentProductModel(
        id: '2',
        productName: 'Smart Watch',
        productDescription: 'Feature-rich smartwatch with health monitoring',
        productPrice: 199.99,
        stockQuantity: 8,
        productImage: 'https://picsum.photos/300/200?random=2',
        category: 'Electronics',
        createdAt: DateTime.now().subtract(Duration(days: 3)),
      ),
      AgentProductModel(
        id: '3',
        productName: 'Wireless Earbuds',
        productDescription:
            'Compact wireless earbuds with premium sound quality',
        productPrice: 149.99,
        stockQuantity: 25,
        productImage: 'https://picsum.photos/300/200?random=3',
        category: 'Electronics',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
      ),
    ];
  }
}
