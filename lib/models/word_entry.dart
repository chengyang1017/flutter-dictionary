import 'dart:convert';

class WordEntry {
  final String word;
  final String meanings;
  final String type;
  final String tableName;
  final Map<String, dynamic> details;

  const WordEntry({
    required this.word,
    required this.meanings,
    required this.type,
    required this.tableName,
    required this.details,
  });

  String get sheetName {
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
