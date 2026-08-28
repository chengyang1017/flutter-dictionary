import 'package:sqflite/sqflite.dart';

import '../models/word_entry.dart';

class CanonicalMorphologyRepository {
  final Database database;

  const CanonicalMorphologyRepository(
    this.database,
  );

  Future<List<MorphologyAnalysis>> loadForms({
    required String lexemeId,
    required String partOfSpeech,
  }) async {
    switch (partOfSpeech) {
      case 'noun':
        return _loadNounForms(lexemeId);
      case 'verb':
        return _loadVerbForms(lexemeId);
      default:
        return const [];
    }
  }

  Future<List<MorphologyAnalysis>> _loadNounForms(
    String lexemeId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        form,
        canonical_key,
        number,
        possessive,
        case_name,
        interrogative,
        special
      FROM noun_forms
      WHERE lexeme_id = ?
      ORDER BY id
      ''',
      [lexemeId],
    );

    return List.unmodifiable(
      rows.map(
        (row) => MorphologyAnalysis(
          form: _text(row['form']),
          canonicalKey:
              _text(row['canonical_key']),
          partOfSpeech: 'noun',
          features: {
            'number': row['number'],
            'possessive': row['possessive'],
            'case': row['case_name'],
            'interrogative':
                _asBool(row['interrogative']),
            'special': _asBool(row['special']),
          },
        ),
      ),
    );
  }

  Future<List<MorphologyAnalysis>> _loadVerbForms(
    String lexemeId,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        form,
        canonical_key,
        form_type,
        tense,
        person,
        negative
      FROM verb_forms
      WHERE lexeme_id = ?
      ORDER BY id
      ''',
      [lexemeId],
    );

    return List.unmodifiable(
      rows.map(
        (row) => MorphologyAnalysis(
          form: _text(row['form']),
          canonicalKey:
              _text(row['canonical_key']),
          partOfSpeech: 'verb',
          features: {
            'form_type': row['form_type'],
            'tense': row['tense'],
            'person': row['person'],
            'negative':
                _asBool(row['negative']),
          },
        ),
      ),
    );
  }

  static bool _asBool(
    Object? value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value
        ?.toString()
        .trim()
        .toLowerCase();

    return normalized == '1' ||
        normalized == 'true';
  }

  static String _text(
    Object? value,
  ) {
    return value?.toString().trim() ?? '';
  }
}
