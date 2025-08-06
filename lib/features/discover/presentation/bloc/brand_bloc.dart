import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/brand_model.dart';
import '../../data/repositories/brand_repository.dart';

// Events
abstract class BrandEvent extends Equatable {
  const BrandEvent();

  @override
  List<Object?> get props => [];
}

class LoadRandomBrands extends BrandEvent {
  final int limit;

  const LoadRandomBrands({this.limit = 6});

  @override
  List<Object?> get props => [limit];
}

class LoadAllBrands extends BrandEvent {
  const LoadAllBrands();
}

// States
abstract class BrandState extends Equatable {
  const BrandState();

  @override
  List<Object?> get props => [];
}

class BrandInitial extends BrandState {}

class BrandLoading extends BrandState {}

class BrandLoaded extends BrandState {
  final List<BrandModel> brands;

  const BrandLoaded(this.brands);

  @override
  List<Object?> get props => [brands];
}

class BrandError extends BrandState {
  final String message;

  const BrandError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class BrandBloc extends Bloc<BrandEvent, BrandState> {
  final BrandRepository _brandRepository;

  BrandBloc(this._brandRepository) : super(BrandInitial()) {
    on<LoadRandomBrands>(_onLoadRandomBrands);
    on<LoadAllBrands>(_onLoadAllBrands);
  }

  Future<void> _onLoadRandomBrands(
    LoadRandomBrands event,
    Emitter<BrandState> emit,
  ) async {
    emit(BrandLoading());
    try {
      final brands = await _brandRepository.getRandomBrands(event.limit);
      emit(BrandLoaded(brands));
    } catch (e) {
      emit(BrandError(e.toString()));
    }
  }

  Future<void> _onLoadAllBrands(
    LoadAllBrands event,
    Emitter<BrandState> emit,
  ) async {
    emit(BrandLoading());
    try {
      final brands = await _brandRepository.getAllBrands();
      emit(BrandLoaded(brands));
    } catch (e) {
      emit(BrandError(e.toString()));
    }
  }
}
