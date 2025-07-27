import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../data/models/countries_model.dart';

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

  AuthBloc() : super(AuthInitialState()) {
    on<InitializeEvent>(onInitializeEvent);
    on<OnCountryUpdateEvent>(onCountryUpdateEvent);
    on<OnPhoneUpdateEvent>(onPhoneUpdateEvent);

    // Initialize immediately
    _initializeCountries();
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
    phoneController = TextEditingController();

    emit(InitializedState());
  }

  FutureOr<void> onPhoneUpdateEvent(
    OnPhoneUpdateEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(PhoneUpdatingState());
    final initialPhoneNumber = PhoneNumber(
      countryISOCode: selectedCountry!.code,
      countryCode: '+${selectedCountry!.dialCode}',
      number: phoneController.text
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', ''),
    );
    int phoneLengthBasedOnCountryCode = countries
        .firstWhere(
          (element) => element.code == initialPhoneNumber.countryISOCode,
        )
        .maxLength;

    if (initialPhoneNumber.number.length == phoneLengthBasedOnCountryCode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    phoneNumberWithoutCountryCode = phoneController.text;
    emit(PhoneUpdatedState());
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
