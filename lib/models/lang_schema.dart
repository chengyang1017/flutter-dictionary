class DictionarySectionSchema {
  final String id;
  final String? title;
  final List<String> keys;

  const DictionarySectionSchema({
    required this.id,
    required this.title,
    required this.keys,
  });

  factory DictionarySectionSchema.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    final rawKeys = json['keys'];

    return DictionarySectionSchema(
      id: id,
      title: _nullableText(json['title']),
      keys: rawKeys is List
          ? rawKeys
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class DictionaryTypeSchema {
  final String sheetName;
  final List<DictionarySectionSchema> sections;

  const DictionaryTypeSchema({
    required this.sheetName,
    required this.sections,
  });

  factory DictionaryTypeSchema.fromJson(
    String sheetName,
    Map<String, dynamic> json,
  ) {
    final sections = <DictionarySectionSchema>[];

    for (final entry in json.entries) {
      final value = entry.value;

      if (value is! Map) {
        continue;
      }

      final sectionJson =
          Map<String, dynamic>.from(value);

      if (sectionJson['keys'] is! List) {
        continue;
      }

      sections.add(
        DictionarySectionSchema.fromJson(
          entry.key,
          sectionJson,
        ),
      );
    }

    return DictionaryTypeSchema(
      sheetName: sheetName,
      sections: sections,
    );
  }
}

class LangSchema {
  final String languageCode;
  final Map<String, DictionaryTypeSchema> types;

  const LangSchema({
    required this.languageCode,
    required this.types,
  });

  factory LangSchema.fromJson(
    String languageCode,
    Map<String, dynamic> json,
  ) {
    final types = <String, DictionaryTypeSchema>{};

    for (final entry in json.entries) {
      final value = entry.value;

      if (value is! Map) {
        continue;
      }

      types[entry.key] =
          DictionaryTypeSchema.fromJson(
        entry.key,
        Map<String, dynamic>.from(value),
      );
    }

    return LangSchema(
      languageCode: languageCode,
      types: types,
    );
  }

  DictionaryTypeSchema? typeOf(
    String sheetName,
  ) {
    return types[sheetName];
  }
}
