import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/agent_product_model.dart';

// Events
abstract class LookBookProductEvent extends Equatable {
  const LookBookProductEvent();

  @override
  List<Object?> get props => [];
}

class DeleteProductEvent extends LookBookProductEvent {
  final String productId;

  const DeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class LoadLookBookProducts extends LookBookProductEvent {
  const LoadLookBookProducts();
}

// States
abstract class LookBookProductState extends Equatable {
  const LookBookProductState();

  @override
  List<Object?> get props => [];
}

class LookBookProductInitial extends LookBookProductState {}

class LookBookProductLoading extends LookBookProductState {}

class LookBookProductLoaded extends LookBookProductState {
  final List<AgentProductModel> products;

  const LookBookProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class LookBookProductError extends LookBookProductState {
  final String message;

  const LookBookProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class LookBookProductBloc
    extends Bloc<LookBookProductEvent, LookBookProductState> {
  LookBookProductBloc() : super(LookBookProductInitial()) {
    on<DeleteProductEvent>(_onDeleteProduct);
    on<LoadLookBookProducts>(_onLoadLookBookProducts);
  }

  void _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<LookBookProductState> emit,
  ) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      final currentState = state;
      if (currentState is LookBookProductLoaded) {
        final updatedProducts = currentState.products
            .where((product) => product.id != event.productId)
            .toList();

        emit(LookBookProductLoaded(updatedProducts));
      }
    } catch (e) {
      emit(LookBookProductError('Failed to delete product: $e'));
    }
  }

  void _onLoadLookBookProducts(
    LoadLookBookProducts event,
    Emitter<LookBookProductState> emit,
  ) async {
    emit(LookBookProductLoading());

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      final products = _getDummyLookBookProducts();

      emit(LookBookProductLoaded(products));
    } catch (e) {
      emit(LookBookProductError('Failed to load lookbook products: $e'));
    }
  }

  // Dummy data generator
  List<AgentProductModel> _getDummyLookBookProducts() {
    return [
      AgentProductModel(
        id: '1',
        productName: 'Fashion Collection',
        productDescription: 'Trendy fashion items for the modern lifestyle',
        productPrice: 89.99,
        stockQuantity: 50,
        productImage: 'https://picsum.photos/300/200?random=4',
        category: 'Fashion',
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      AgentProductModel(
        id: '2',
        productName: 'Home Decor Set',
        productDescription: 'Beautiful home decoration items',
        productPrice: 129.99,
        stockQuantity: 20,
        productImage: 'https://picsum.photos/300/200?random=5',
        category: 'Home & Garden',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
      ),
    ];
  }
}
