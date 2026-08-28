import 'dart:convert';

class DictionarySense {
  final int number;
  final List<String> glosses;

  const DictionarySense({
    required this.number,
    required this.glosses,
  });
}

class MorphologyAnalysis {
  final String form;
  final String canonicalKey;
  final String partOfSpeech;
  final Map<String, dynamic> features;

  const MorphologyAnalysis({
    required this.form,
    required this.canonicalKey,
    required this.partOfSpeech,
    required this.features,
  });
}

class WordEntry {
  final String word;
  final String meanings;
  final String type;
  final String tableName;
  final Map<String, dynamic> details;

  final String? lexemeId;
  final String? languageCode;
  final String? primaryMatch;
  final List<String> matchTypes;
  final List<DictionarySense> senses;
  final List<MorphologyAnalysis> matchedForms;
  final List<MorphologyAnalysis> allForms;
  final int formCount;

  const WordEntry({
    required this.word,
    required this.meanings,
    required this.type,
    required this.tableName,
    required this.details,
    this.lexemeId,
    this.languageCode,
    this.primaryMatch,
    this.matchTypes = const [],
    this.senses = const [],
    this.matchedForms = const [],
    this.allForms = const [],
    this.formCount = 0,
  });

  bool get isCanonical => lexemeId != null;

  String get sheetName {
    if (isCanonical) {
      return type;
    }

    var value = tableName;

    if (value.endsWith('_table')) {
      value = value.substring(
        0,
        value.length - '_table'.length,
      );
    }

    final separatorIndex = value.indexOf('_');

    if (separatorIndex == -1 ||
        separatorIndex == value.length - 1) {
      return value;
    }

    return value.substring(separatorIndex + 1);
  }

  factory WordEntry.fromMap(
    Map<String, Object?> map, {
    required String tableName,
  }) {
    return WordEntry(
      word: _text(map['word']),
      meanings: _text(map['meanings']),
      type: _text(map['type']),
      tableName: tableName,
      details: _decodeDetails(map['data']),
    );
  }

  factory WordEntry.canonical({
    required String lexemeId,
    required String languageCode,
    required String lemma,
    required String partOfSpeech,
    required String meanings,
    required List<DictionarySense> senses,
    required List<MorphologyAnalysis> matchedForms,
    required int formCount,
    String? primaryMatch,
    List<String> matchTypes = const [],
  }) {
    return WordEntry(
      word: lemma,
      meanings: meanings,
      type: partOfSpeech,
      tableName: 'canonical_${partOfSpeech}_table',
      details: const {},
      lexemeId: lexemeId,
      languageCode: languageCode,
      primaryMatch: primaryMatch,
      matchTypes: List.unmodifiable(matchTypes),
      senses: List.unmodifiable(senses),
      matchedForms: List.unmodifiable(matchedForms),
      formCount: formCount,
    );
  }

  WordEntry withAllForms(
    List<MorphologyAnalysis> forms,
  ) {
    return WordEntry(
      word: word,
      meanings: meanings,
      type: type,
      tableName: tableName,
      details: details,
      lexemeId: lexemeId,
      languageCode: languageCode,
      primaryMatch: primaryMatch,
      matchTypes: matchTypes,
      senses: senses,
      matchedForms: matchedForms,
      allForms: List.unmodifiable(forms),
      formCount: formCount,
    );
  }

  static Map<String, dynamic> _decodeDetails(
    Object? value,
  ) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _cleanJsonValue(item),
        ),
      );
    }

    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return const {};
    }

    final normalized = raw.replaceAll(
      RegExp(r'\bNaN\b'),
      'null',
    );

    try {
      final decoded = jsonDecode(normalized);

      if (decoded is! Map) {
        return const {};
      }

      return decoded.map(
        (key, item) => MapEntry(
          key.toString(),
          _cleanJsonValue(item),
        ),
      );
    } on FormatException {
      return const {};
    }
  }

  static dynamic _cleanJsonValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty ||
          text.toLowerCase() == 'nan' ||
          text.toLowerCase() == 'null') {
        return null;
      }

      return text;
    }

    if (value is List) {
      return value
          .map(_cleanJsonValue)
          .where((item) => item != null)
          .toList(growable: false);
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _cleanJsonValue(item),
        ),
      );
    }

    return value;
  }

  static String _text(Object? value) {
    if (value == null) {
      return '';
    }

    final text = value.toString().trim();

    if (text.toLowerCase() == 'nan' ||
        text.toLowerCase() == 'null') {
      return '';
    }

    return text;
  }
}
