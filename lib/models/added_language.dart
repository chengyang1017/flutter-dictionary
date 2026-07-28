class AddedLanguage {
  final String countryCode;
  final String languageCode;
  final String? variantCode;

  const AddedLanguage({
    required this.countryCode,
    required this.languageCode,
    this.variantCode,
  });

  String get id {
    return [
      countryCode.toUpperCase(),
      languageCode.toLowerCase(),
      variantCode?.toLowerCase() ?? 'all',
    ].join('_');
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'languageCode': languageCode,
      'variantCode': variantCode,
    };
  }

  factory AddedLanguage.fromJson(
    Map<String, dynamic> json,
  ) {
    return AddedLanguage(
      countryCode:
          json['countryCode']?.toString() ?? '',
      languageCode:
          json['languageCode']?.toString() ?? '',
      variantCode:
          _nullableText(json['variantCode']),
    );
  }

  static String? _nullableText(
    Object? value,
  ) {
    final text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? null : text;
  }
}