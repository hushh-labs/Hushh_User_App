import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../data/models/countries_model.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import '../../domain/usecases/create_user_card_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/entities/user_card.dart';
import '../../domain/enums.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/routing/app_router.dart';
import '../pages/otp_verification.dart';
import '../../../../shared/utils/app_local_storage.dart';
import '../../../notifications/data/services/fcm_service.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/firebase_service.dart';

// Events
abstract class AuthEvent {}

class InitializeEvent extends AuthEvent {
  final bool shouldInitialize;
  InitializeEvent(this.shouldInitialize);
}

class OnCountryUpdateEvent extends AuthEvent {
  final BuildContext context;
  OnCountryUpdateEvent(this.context);
}

class OnPhoneUpdateEvent extends AuthEvent {
  final String value;
  OnPhoneUpdateEvent(this.value);
}

class SendPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  SendPhoneOtpEvent(this.phoneNumber);
}

class VerifyPhoneOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String otp;
  VerifyPhoneOtpEvent({required this.phoneNumber, required this.otp});
}

class CheckUserCardEvent extends AuthEvent {
  final String userId;
  CheckUserCardEvent(this.userId);
}

class CheckUserProfileCompletionEvent extends AuthEvent {
  final String userId;
  CheckUserProfileCompletionEvent(this.userId);
}

class CreateUserCardEvent extends AuthEvent {
  final UserCard userCard;
  CreateUserCardEvent(this.userCard);
}

class SignOutEvent extends AuthEvent {}

class CheckAuthStateEvent extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class InitializingState extends AuthState {
  final bool isInitState;
  InitializingState(this.isInitState);
}

class InitializedState extends AuthState {}

class CountryUpdatingState extends AuthState {}

class CountryUpdatedState extends AuthState {}

class PhoneUpdatingState extends AuthState {}

class PhoneUpdatedState extends AuthState {}

class SendingOtpState extends AuthState {}

class OtpSentState extends AuthState {}

class OtpSentFailureState extends AuthState {
  final String message;
  OtpSentFailureState(this.message);
}

class VerifyingOtpState extends AuthState {}

class OtpVerifiedState extends AuthState {
  final firebase_auth.UserCredential userCredential;
  OtpVerifiedState(this.userCredential);
}

class OtpVerificationFailureState extends AuthState {
  final String message;
  OtpVerificationFailureState(this.message);
}

class CheckingUserCardState extends AuthState {}

class UserCardExistsState extends AuthState {
  final bool exists;
  UserCardExistsState(this.exists);
}

class UserCardCheckFailureState extends AuthState {
  final String message;
  UserCardCheckFailureState(this.message);
}

class UserProfileCompletedState extends AuthState {
  final bool isCompleted;
  UserProfileCompletedState(this.isCompleted);
}

class UserProfileCheckFailureState extends AuthState {
  final String message;
  UserProfileCheckFailureState(this.message);
}

class CreatingUserCardState extends AuthState {}

class UserCardCreatedState extends AuthState {}

class UserCardCreationFailureState extends AuthState {
  final String message;
  UserCardCreationFailureState(this.message);
}

class SigningOutState extends AuthState {}

class SignedOutState extends AuthState {}

class SignOutFailureState extends AuthState {
  final String message;
  SignOutFailureState(this.message);
}

class AuthStateCheckedState extends AuthState {
  final bool isAuthenticated;
  final firebase_auth.User? user;
  AuthStateCheckedState({required this.isAuthenticated, this.user});
}

// Country Masks
const Map<String, String> countryMasks = {
  'US': '+1 (###) ###-####',
  'IN': '+91 ##### #####',
  'GB': '+44 #### ######',
  'CA': '+1 (###) ###-####',
  'AU': '+61 ### ### ###',
  'DE': '+49 ### #######',
  'FR': '+33 # ## ## ## ##',
  'IT': '+39 ### ### ####',
  'ES': '+34 ### ### ###',
  'BR': '+55 ## ##### ####',
  'MX': '+52 ### ### ####',
  'JP': '+81 ## #### ####',
  'KR': '+82 ## #### ####',
  'CN': '+86 ### #### ####',
  'RU': '+7 ### ### ####',
  'ZA': '+27 ## ### ####',
  'NG': '+234 ### ### ####',
  'EG': '+20 ### ### ####',
  'KE': '+254 ### ### ###',
  'GH': '+233 ## ### ####',
};

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late List<Country> _countryList;
  late List<Country> filteredCountries;
  late TextEditingController phoneController;
  MaskTextInputFormatter? formatter;
  var phoneNumberWithoutCountryCode = "";
  Country? selectedCountry;

  // Use cases
  final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;
  final CreateUserCardUseCase _createUserCardUseCase;
  final SignOutUseCase _signOutUseCase;

  // FCM Service
  final FCMService _fcmService;

  AuthBloc({
    required SendPhoneOtpUseCase sendPhoneOtpUseCase,
    required VerifyPhoneOtpUseCase verifyPhoneOtpUseCase,
    required CreateUserCardUseCase createUserCardUseCase,
    required SignOutUseCase signOutUseCase,
    required FCMService fcmService,
  }) : _sendPhoneOtpUseCase = sendPhoneOtpUseCase,
       _verifyPhoneOtpUseCase = verifyPhoneOtpUseCase,
       _createUserCardUseCase = createUserCardUseCase,
       _signOutUseCase = signOutUseCase,
       _fcmService = fcmService,
       super(AuthInitialState()) {
    on<InitializeEvent>(onInitializeEvent);
    on<OnCountryUpdateEvent>(onCountryUpdateEvent);
    on<OnPhoneUpdateEvent>(onPhoneUpdateEvent);
    on<SendPhoneOtpEvent>(onSendPhoneOtpEvent);
    on<VerifyPhoneOtpEvent>(onVerifyPhoneOtpEvent);
    on<CreateUserCardEvent>(onCreateUserCardEvent);
    on<SignOutEvent>(onSignOutEvent);
    on<CheckAuthStateEvent>(onCheckAuthStateEvent);
    on<CheckUserProfileCompletionEvent>(onCheckUserProfileCompletionEvent);

    // Initialize immediately
    _initializeCountries();

    // Listen to authentication state changes
    _listenToAuthStateChanges();
  }

  void _initializeCountries() {
    _countryList = countries;
    selectedCountry = _countryList.firstWhere(
      (item) => item.code == "IN",
      orElse: () => _countryList.first,
    );
    formatter = MaskTextInputFormatter(
      mask: countryMasks[selectedCountry!.code] ?? '+# ### ### ####',
      filter: {"#": RegExp(r'[0-9]')},
    );
    filteredCountries = _countryList;
    phoneController = TextEditingController();
  }

  bool _isSigningOut = false;

  void _listenToAuthStateChanges() {
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // User is signed in - initialize FCM
        try {
          await _fcmService.initialize();
          debugPrint('FCM initialized for user: ${user.uid}');

          // Force generate token for testing
          await _fcmService.forceTokenGeneration();
        } catch (e) {
          debugPrint('Failed to initialize FCM: $e');
        }

        // User is signed in
        add(CheckAuthStateEvent());
      } else {
        // User is signed out - only trigger if we're not already signing out
        if (!_isSigningOut) {
          add(SignOutEvent());
        }
      }
    });
  }

  FutureOr<void> onInitializeEvent(
    InitializeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(InitializingState(event.shouldInitialize));

    _countryList = countries;
    selectedCountry = _countryList.firstWhere(
      (item) => item.code == "IN",
      orElse: () => _countryList.first,
    );
    formatter = MaskTextInputFormatter(
      mask: countryMasks[selectedCountry!.code] ?? '+# ### ### ####',
      filter: {"#": RegExp(r'[0-9]')},
    );
    _countryList = countries;
    filteredCountries = _countryList;

    // Clear the phone controller to prevent auto-fill
    phoneController.clear();
    phoneNumberWithoutCountryCode = "";

    emit(InitializedState());
  }

  FutureOr<void> onPhoneUpdateEvent(
    OnPhoneUpdateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(PhoneUpdatingState());

    // Store only the digits from the phone number (without country code)
    final phoneDigits = phoneController.text
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    phoneNumberWithoutCountryCode = phoneDigits;

    // Check if phone number is complete based on country
    int phoneLengthBasedOnCountryCode = countries
        .firstWhere((element) => element.code == selectedCountry!.code)
        .maxLength;

    if (phoneDigits.length == phoneLengthBasedOnCountryCode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    emit(PhoneUpdatedState());
  }

  FutureOr<void> onSendPhoneOtpEvent(
    SendPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(SendingOtpState());

    final params = SendPhoneOtpParams(
      phoneNumber: event.phoneNumber,
      onOtpSent: (phoneNumber) {
        // Navigate to OTP verification page
        AppRouter.router.goNamed(
          RouteNames.otpVerification,
          extra: OtpVerificationPageArgs(
            emailOrPhone: phoneNumber,
            type: OtpVerificationType.phone,
          ),
        );
      },
    );

    final result = await _sendPhoneOtpUseCase(params);

    result.fold(
      (failure) {
        emit(OtpSentFailureState(failure.message));
      },
      (_) {
        emit(OtpSentState());
      },
    );
  }

  FutureOr<void> onVerifyPhoneOtpEvent(
    VerifyPhoneOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(VerifyingOtpState());

    final params = VerifyPhoneOtpParams(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
    );

    final result = await _verifyPhoneOtpUseCase(params);

    await result.fold(
      (failure) async {
        emit(OtpVerificationFailureState(failure.message));
      },
      (userCredential) async {
        // Store the login type as phone
        await AppLocalStorage.setLoginType(OtpVerificationType.phone);
        if (!emit.isDone) {
          emit(OtpVerifiedState(userCredential));
        }
      },
    );
  }

  FutureOr<void> onCheckUserProfileCompletionEvent(
    CheckUserProfileCompletionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(CheckingUserCardState()); // Reuse existing state for now

    try {
      // Check if user has completed their profile by looking for required fields
      final firebaseService = GetIt.instance<FirebaseService>();
      final userData = await firebaseService.getUserData(event.userId);

      if (userData != null) {
        // Check if user has completed required profile fields
        final hasName =
            userData['fullName'] != null &&
            userData['fullName'].toString().isNotEmpty;
        final hasEmail =
            userData['email'] != null &&
            userData['email'].toString().isNotEmpty;

        final isProfileCompleted = hasName && hasEmail;
        emit(UserProfileCompletedState(isProfileCompleted));
      } else {
        // No user data found, profile not completed
        emit(UserProfileCompletedState(false));
      }
    } catch (e) {
      emit(UserProfileCheckFailureState(e.toString()));
    }
  }

  FutureOr<void> onCreateUserCardEvent(
    CreateUserCardEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(CreatingUserCardState());

    final result = await _createUserCardUseCase(event.userCard);

    result.fold(
      (failure) => emit(UserCardCreationFailureState(failure.message)),
      (_) => emit(UserCardCreatedState()),
    );
  }

  FutureOr<void> onSignOutEvent(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    _isSigningOut = true;
    emit(SigningOutState());

    final result = await _signOutUseCase(const NoParams());

    await result.fold(
      (failure) async {
        _isSigningOut = false;
        emit(SignOutFailureState(failure.message));
      },
      (_) async {
        // Clear the stored login type when user signs out
        await AppLocalStorage.clearLoginType();
        if (!emit.isDone) {
          emit(SignedOutState());
        }
        _isSigningOut = false;
      },
    );
  }

  FutureOr<void> onCheckAuthStateEvent(
    CheckAuthStateEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final isAuthenticated = currentUser != null;
    emit(
      AuthStateCheckedState(
        isAuthenticated: isAuthenticated,
        user: currentUser,
      ),
    );
  }

  FutureOr<void> onCountryUpdateEvent(
    OnCountryUpdateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(CountryUpdatingState());
    bool isNumeric(String s) => s.isNotEmpty && double.tryParse(s) != null;

    filteredCountries = _countryList;
    await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      context: event.context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (ctx, setStateCountry) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF7f7f97), width: 0.5),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              topLeft: Radius.circular(15),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Container(
                height: 40,
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                child: TextField(
                  onChanged: (value) {
                    filteredCountries = isNumeric(value)
                        ? _countryList
                              .where(
                                (country) => country.dialCode.contains(value),
                              )
                              .toList()
                        : _countryList
                              .where(
                                (country) => country.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .toList();
                    setStateCountry(() {});
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: 'Search country',
                    hintStyle: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset(
                        'assets/search_new.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCountries.length,
                  itemBuilder: (ctx, index) => Column(
                    children: <Widget>[
                      ListTile(
                        onTap: () {
                          selectedCountry = filteredCountries[index];
                          formatter = MaskTextInputFormatter(
                            mask:
                                countryMasks[selectedCountry!.code] ??
                                '+# ### ### ####',
                            filter: {"#": RegExp(r'[0-9]')},
                          );
                          // Clear phone controller when country changes to prevent auto-fill
                          phoneController.clear();
                          phoneNumberWithoutCountryCode = "";
                          Navigator.of(context).pop();
                          FocusScope.of(context).unfocus();
                        },
                        leading: Text(
                          filteredCountries[index].flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          filteredCountries[index].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        trailing: Text(
                          '+${filteredCountries[index].dialCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Divider(thickness: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    emit(CountryUpdatedState());
  }

  @override
  Future<void> close() {
    phoneController.dispose();
    return super.close();
  }
}
