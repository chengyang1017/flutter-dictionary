import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/added_language.dart';

class AddedLanguageStore {
  AddedLanguageStore._();

  static final AddedLanguageStore instance =
      AddedLanguageStore._();

  static const String _storageKey =
      'glyphora_added_languages_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AddedLanguage>> load() async {
    final source = await _preferences.getString(
      _storageKey,
    );

    if (source == null ||
        source.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(source);

      if (decoded is! List) {
        return const [];
      }

      final result = decoded
          .whereType<Map>()
          .map(
            (item) =>
                AddedLanguage.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .where(
            (item) =>
                item.countryCode.isNotEmpty &&
                item.languageCode.isNotEmpty,
          )
          .toList();

      return List.unmodifiable(result);
    } on FormatException {
      return const [];
    }
  }

  Future<bool> add(
    AddedLanguage item,
  ) async {
    final current =
        List<AddedLanguage>.of(
      await load(),
    );

    final alreadyExists = current.any(
      (saved) => saved.id == item.id,
    );

    if (alreadyExists) {
      return false;
    }

    current.add(item);

    await _save(current);

    return true;
  }

  Future<void> remove(
    AddedLanguage item,
  ) async {
    final current =
        List<AddedLanguage>.of(
      await load(),
    );

    current.removeWhere(
      (saved) => saved.id == item.id,
    );

    await _save(current);
  }

  Future<void> clear() async {
    await _preferences.remove(
      _storageKey,
    );
  }

  Future<void> _save(
    List<AddedLanguage> items,
  ) async {
    final source = jsonEncode(
      items
          .map((item) => item.toJson())
          .toList(),
    );

    await _preferences.setString(
      _storageKey,
      source,
    );
  }
}