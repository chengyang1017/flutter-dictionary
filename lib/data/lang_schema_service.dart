import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/lang_schema.dart';

class LangSchemaService {
  LangSchemaService._();

  static final LangSchemaService instance =
      LangSchemaService._();

  Map<String, LangSchema>? _schemas;

  Future<DictionaryTypeSchema?> getTypeSchema({
    required String languageCode,
    required String tableName,
  }) async {
    await _ensureLoaded();

    final schemaLanguageCode =
        toSchemaLanguageCode(languageCode);

    final sheetName =
        sheetNameFromTable(tableName);

    return _schemas?[schemaLanguageCode]
        ?.typeOf(sheetName);
  }

  Future<LangSchema?> getLanguageSchema(
    String languageCode,
  ) async {
    await _ensureLoaded();

    return _schemas?[
        toSchemaLanguageCode(languageCode)];
  }

  String toSchemaLanguageCode(
    String languageCode,
  ) {
    switch (languageCode.trim().toLowerCase()) {
      case 'vi':
        return 'vn';
      case 'ja':
        return 'jp';
      default:
        return languageCode.trim().toLowerCase();
    }
  }

  String sheetNameFromTable(
    String tableName,
  ) {
    var value = tableName.trim();

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

  Future<void> _ensureLoaded() async {
    if (_schemas != null) {
      return;
    }

    final source = await rootBundle.loadString(
      'assets/schemas/lang-schemas.json',
    );

    final decoded = jsonDecode(source);

    if (decoded is! Map) {
      throw const FormatException(
        'lang-schemas.json 顶层必须是 JSON 对象。',
      );
    }

    final schemas = <String, LangSchema>{};

    for (final entry in decoded.entries) {
      final value = entry.value;

      if (value is! Map) {
        continue;
      }

      final languageCode = entry.key.toString();

      schemas[languageCode] = LangSchema.fromJson(
        languageCode,
        Map<String, dynamic>.from(value),
      );
    }

    _schemas = schemas;
  }
}
