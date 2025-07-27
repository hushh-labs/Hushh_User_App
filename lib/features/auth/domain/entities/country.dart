class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  Country copyWith({
    String? name,
    String? code,
    String? dialCode,
    String? flag,
  }) {
    return Country(
      name: name ?? this.name,
      code: code ?? this.code,
      dialCode: dialCode ?? this.dialCode,
      flag: flag ?? this.flag,
    );
  }
}
