import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/checkout_entity.dart';
import '../../domain/usecases/get_checkout_data.dart';
import '../../domain/usecases/save_checkout_data.dart';
import '../../domain/usecases/get_user_basic_info.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final GetCheckoutData getCheckoutData;
  final SaveCheckoutData saveCheckoutData;
  final GetUserBasicInfo getUserBasicInfo;

  CheckoutEntity _currentData = const CheckoutEntity();

  CheckoutBloc({
    required this.getCheckoutData,
    required this.saveCheckoutData,
    required this.getUserBasicInfo,
  }) : super(const CheckoutInitial()) {
    on<LoadCheckoutDataEvent>(_onLoadCheckoutData);
    on<UpdateCheckoutFieldEvent>(_onUpdateCheckoutField);
    on<SubmitCheckoutDataEvent>(_onSubmitCheckoutData);
    on<LoadUserBasicInfoEvent>(_onLoadUserBasicInfo);
    on<ResetCheckoutEvent>(_onResetCheckout);
  }

  Future<void> _onLoadCheckoutData(
    LoadCheckoutDataEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    try {
      // First try to load existing checkout data
      final checkoutData = await getCheckoutData(event.uid);

      if (checkoutData != null) {
        _currentData = checkoutData;
        emit(CheckoutLoaded(_currentData));
      } else {
        // If no checkout data exists, load user basic info and create new checkout data
        final userBasicInfo = await getUserBasicInfo(event.uid);
        _currentData = CheckoutEntity(
          fullName: userBasicInfo['fullName'],
          email: userBasicInfo['email'],
        );
        emit(CheckoutLoaded(_currentData));
      }
    } catch (e) {
      emit(CheckoutError('Failed to load checkout data: $e'));
    }
  }

  Future<void> _onLoadUserBasicInfo(
    LoadUserBasicInfoEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    try {
      final userBasicInfo = await getUserBasicInfo(event.uid);
      _currentData = _currentData.copyWith(
        fullName: userBasicInfo['fullName'] ?? _currentData.fullName,
        email: userBasicInfo['email'] ?? _currentData.email,
      );
      emit(CheckoutFieldUpdated(_currentData));
    } catch (e) {
      emit(CheckoutError('Failed to load user basic info: $e'));
    }
  }

  void _onUpdateCheckoutField(
    UpdateCheckoutFieldEvent event,
    Emitter<CheckoutState> emit,
  ) {
    switch (event.fieldName) {
      case 'fullName':
        _currentData = _currentData.copyWith(fullName: event.value);
        break;
      case 'phoneNumber':
        _currentData = _currentData.copyWith(phoneNumber: event.value);
        break;
      case 'email':
        _currentData = _currentData.copyWith(email: event.value);
        break;
      case 'addressLine1':
        _currentData = _currentData.copyWith(addressLine1: event.value);
        break;
      case 'addressLine2':
        _currentData = _currentData.copyWith(addressLine2: event.value);
        break;
      case 'city':
        _currentData = _currentData.copyWith(city: event.value);
        break;
      case 'pincode':
        _currentData = _currentData.copyWith(pincode: event.value);
        break;
      case 'state':
        _currentData = _currentData.copyWith(state: event.value);
        break;
      case 'country':
        _currentData = _currentData.copyWith(country: event.value);
        break;
    }
    emit(CheckoutFieldUpdated(_currentData));
  }

  Future<void> _onSubmitCheckoutData(
    SubmitCheckoutDataEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutLoading());
    try {
      await saveCheckoutData(event.uid, _currentData);
      emit(CheckoutSubmitted(_currentData));
    } catch (e) {
      emit(CheckoutError('Failed to save checkout data: $e'));
    }
  }

  void _onResetCheckout(ResetCheckoutEvent event, Emitter<CheckoutState> emit) {
    _currentData = const CheckoutEntity();
    emit(const CheckoutInitial());
  }

  CheckoutEntity get currentData => _currentData;
}
