class CheckoutEntity {
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? pincode;
  final String? state;
  final String? country;
  final DateTime? lastUpdated;

  const CheckoutEntity({
    this.fullName,
    this.phoneNumber,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.pincode,
    this.state,
    this.country,
    this.lastUpdated,
  });

  CheckoutEntity copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? pincode,
    String? state,
    String? country,
    DateTime? lastUpdated,
  }) {
    return CheckoutEntity(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      state: state ?? this.state,
      country: country ?? this.country,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isValid {
    return fullName != null &&
        fullName!.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        addressLine1 != null &&
        addressLine1!.isNotEmpty &&
        city != null &&
        city!.isNotEmpty &&
        pincode != null &&
        pincode!.isNotEmpty &&
        state != null &&
        state!.isNotEmpty &&
        country != null &&
        country!.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CheckoutEntity &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.addressLine1 == addressLine1 &&
        other.addressLine2 == addressLine2 &&
        other.city == city &&
        other.pincode == pincode &&
        other.state == state &&
        other.country == country &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return fullName.hashCode ^
        phoneNumber.hashCode ^
        email.hashCode ^
        addressLine1.hashCode ^
        addressLine2.hashCode ^
        city.hashCode ^
        pincode.hashCode ^
        state.hashCode ^
        country.hashCode ^
        lastUpdated.hashCode;
  }

  @override
  String toString() {
    return 'CheckoutEntity(fullName: $fullName, phoneNumber: $phoneNumber, email: $email, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, pincode: $pincode, state: $state, country: $country, lastUpdated: $lastUpdated)';
  }
}
