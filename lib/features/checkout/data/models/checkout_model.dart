import '../../domain/entities/checkout_entity.dart';

class CheckoutModel extends CheckoutEntity {
  const CheckoutModel({
    super.fullName,
    super.phoneNumber,
    super.email,
    super.addressLine1,
    super.addressLine2,
    super.city,
    super.pincode,
    super.state,
    super.country,
    super.lastUpdated,
  });

  factory CheckoutModel.fromMap(Map<String, dynamic> map) {
    return CheckoutModel(
      fullName: map['fullName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      addressLine1: map['addressLine1'] as String?,
      addressLine2: map['addressLine2'] as String?,
      city: map['city'] as String?,
      pincode: map['pincode'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'pincode': pincode,
      'state': state,
      'country': country,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  factory CheckoutModel.fromEntity(CheckoutEntity entity) {
    return CheckoutModel(
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      pincode: entity.pincode,
      state: entity.state,
      country: entity.country,
      lastUpdated: entity.lastUpdated,
    );
  }

  CheckoutEntity toEntity() {
    return CheckoutEntity(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      pincode: pincode,
      state: state,
      country: country,
      lastUpdated: lastUpdated,
    );
  }

  @override
  String toString() {
    return 'CheckoutModel(fullName: $fullName, phoneNumber: $phoneNumber, email: $email, addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, pincode: $pincode, state: $state, country: $country, lastUpdated: $lastUpdated)';
  }
}
