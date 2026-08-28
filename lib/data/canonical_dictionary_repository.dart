import 'dart:collection';

import 'package:sqflite/sqflite.dart';

import '../models/word_entry.dart';

class CanonicalDictionaryRepository {
  final Database database;

  const CanonicalDictionaryRepository(
    this.database,
  );

  Future<List<WordEntry>> search({
    required String languageCode,
    String query = '',
    String glossLanguage = 'zh',
    int limit = 500,
  }) async {
    final normalizedQuery =
        query.trim();

    final candidates =
        LinkedHashMap<String, _Candidate>();

    if (normalizedQuery.isEmpty) {
      await _collectBrowseEntries(
        candidates: candidates,
        languageCode: languageCode,
        limit: limit,
      );
    } else {
      await _collectLemmaMatches(
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedQuery,
        limit: limit,
        exact: true,
      );

      await _collectFormMatches(
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedQuery,
        limit: limit,
      );

      await _collectGlossMatches(
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedQuery,
        limit: limit,
        exact: true,
      );

      if (candidates.isEmpty) {
        await _collectLemmaMatches(
          candidates: candidates,
          languageCode: languageCode,
          query: normalizedQuery,
          limit: limit,
          exact: false,
        );

        await _collectGlossMatches(
          candidates: candidates,
          languageCode: languageCode,
          query: normalizedQuery,
          limit: limit,
          exact: false,
        );
      }
    }

    final ordered =
        candidates.values.toList()
          ..sort(_compareCandidates);

    final entries = <WordEntry>[];

    for (final candidate
        in ordered.take(limit)) {
      entries.add(
        await _loadEntry(
          candidate: candidate,
          glossLanguage:
              _normalizeLanguageCode(
            glossLanguage,
          ),
        ),
      );
    }

    return List.unmodifiable(entries);
  }

  Future<void> _collectBrowseEntries({
    required LinkedHashMap<
        String,
        _Candidate
    > candidates,
    required String languageCode,
    required int limit,
  }) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        id,
        language_code,
        part_of_speech,
        lemma
      FROM lexemes
      WHERE language_code = ?
      ORDER BY lemma COLLATE NOCASE, id
      LIMIT ?
      ''',
      [
        languageCode,
        limit,
      ],
    );

    for (final row in rows) {
      final candidate =
          _candidateFromRow(row);

      candidates[candidate.id] =
          candidate;
    }
  }

  Future<void> _collectLemmaMatches({
    required LinkedHashMap<
        String,
        _Candidate
    > candidates,
    required String languageCode,
    required String query,
    required int limit,
    required bool exact,
  }) async {
    final rows = await database.rawQuery(
      exact
          ? '''
            SELECT
              id,
              language_code,
              part_of_speech,
              lemma
            FROM lexemes
            WHERE language_code = ?
              AND lemma = ? COLLATE NOCASE
            ORDER BY lemma COLLATE NOCASE, id
            LIMIT ?
            '''
          : '''
            SELECT
              id,
              language_code,
              part_of_speech,
              lemma
            FROM lexemes
            WHERE language_code = ?
              AND lemma LIKE ? COLLATE NOCASE
            ORDER BY lemma COLLATE NOCASE, id
            LIMIT ?
            ''',
      [
        languageCode,
        exact ? query : '$query%',
        limit,
      ],
    );

    for (final row in rows) {
      _addMatch(
        candidates,
        _candidateFromRow(row),
        'lemma',
      );
    }
  }

  Future<void> _collectGlossMatches({
    required LinkedHashMap<
        String,
        _Candidate
    > candidates,
    required String languageCode,
    required String query,
    required int limit,
    required bool exact,
  }) async {
    final rows = await database.rawQuery(
      exact
          ? '''
            SELECT DISTINCT
              lexemes.id,
              lexemes.language_code,
              lexemes.part_of_speech,
              lexemes.lemma
            FROM glosses
            JOIN senses
              ON senses.id = glosses.sense_id
            JOIN lexemes
              ON lexemes.id = senses.lexeme_id
            WHERE lexemes.language_code = ?
              AND glosses.text = ? COLLATE NOCASE
            ORDER BY lexemes.lemma COLLATE NOCASE,
                     lexemes.id
            LIMIT ?
            '''
          : '''
            SELECT DISTINCT
              lexemes.id,
              lexemes.language_code,
              lexemes.part_of_speech,
              lexemes.lemma
            FROM glosses
            JOIN senses
              ON senses.id = glosses.sense_id
            JOIN lexemes
              ON lexemes.id = senses.lexeme_id
            WHERE lexemes.language_code = ?
              AND glosses.text LIKE ? COLLATE NOCASE
            ORDER BY lexemes.lemma COLLATE NOCASE,
                     lexemes.id
            LIMIT ?
            ''',
      [
        languageCode,
        exact ? query : '$query%',
        limit,
      ],
    );

    for (final row in rows) {
      _addMatch(
        candidates,
        _candidateFromRow(row),
        'gloss',
      );
    }
  }

  Future<void> _collectFormMatches({
    required LinkedHashMap<
        String,
        _Candidate
    > candidates,
    required String languageCode,
    required String query,
    required int limit,
  }) async {
    final nounRows = await database.rawQuery(
      '''
      SELECT
        lexemes.id,
        lexemes.language_code,
        lexemes.part_of_speech,
        lexemes.lemma,
        noun_forms.form,
        noun_forms.canonical_key,
        noun_forms.number,
        noun_forms.possessive,
        noun_forms.case_name,
        noun_forms.interrogative,
        noun_forms.special
      FROM noun_forms
      JOIN lexemes
        ON lexemes.id = noun_forms.lexeme_id
      WHERE lexemes.language_code = ?
        AND noun_forms.form = ?
      ORDER BY noun_forms.id
      LIMIT ?
      ''',
      [
        languageCode,
        query,
        limit,
      ],
    );

    for (final row in nounRows) {
      _addMatch(
        candidates,
        _candidateFromRow(row),
        'form',
        analysis: MorphologyAnalysis(
          form: _text(row['form']),
          canonicalKey:
              _text(row['canonical_key']),
          partOfSpeech: 'noun',
          features: {
            'number': row['number'],
            'possessive':
                row['possessive'],
            'case': row['case_name'],
            'interrogative':
                _asBool(
              row['interrogative'],
            ),
            'special': _asBool(
              row['special'],
            ),
          },
        ),
      );
    }

    final verbRows = await database.rawQuery(
      '''
      SELECT
        lexemes.id,
        lexemes.language_code,
        lexemes.part_of_speech,
        lexemes.lemma,
        verb_forms.form,
        verb_forms.canonical_key,
        verb_forms.form_type,
        verb_forms.tense,
        verb_forms.person,
        verb_forms.negative
      FROM verb_forms
      JOIN lexemes
        ON lexemes.id = verb_forms.lexeme_id
      WHERE lexemes.language_code = ?
        AND verb_forms.form = ?
      ORDER BY verb_forms.id
      LIMIT ?
      ''',
      [
        languageCode,
        query,
        limit,
      ],
    );

    for (final row in verbRows) {
      _addMatch(
        candidates,
        _candidateFromRow(row),
        'form',
        analysis: MorphologyAnalysis(
          form: _text(row['form']),
          canonicalKey:
              _text(row['canonical_key']),
          partOfSpeech: 'verb',
          features: {
            'form_type':
                row['form_type'],
            'tense': row['tense'],
            'person': row['person'],
            'negative': _asBool(
              row['negative'],
            ),
          },
        ),
      );
    }
  }

  void _addMatch(
    LinkedHashMap<String, _Candidate>
        candidates,
    _Candidate incoming,
    String matchType, {
    MorphologyAnalysis? analysis,
  }) {
    final candidate =
        candidates.putIfAbsent(
      incoming.id,
      () => incoming,
    );

    candidate.addMatch(
      matchType,
      analysis: analysis,
    );
  }

  Future<WordEntry> _loadEntry({
    required _Candidate candidate,
    required String glossLanguage,
  }) async {
    final senses = await _loadSenses(
      lexemeId: candidate.id,
      glossLanguage: glossLanguage,
    );

    final meanings =
        LinkedHashSet<String>();

    for (final sense in senses) {
      meanings.addAll(sense.glosses);
    }

    final formCount =
        await _loadFormCount(candidate);

    return WordEntry.canonical(
      lexemeId: candidate.id,
      languageCode: candidate.languageCode,
      lemma: candidate.lemma,
      partOfSpeech:
          candidate.partOfSpeech,
      meanings: meanings.join(' / '),
      senses: senses,
      matchedForms:
          candidate.matchedForms,
      formCount: formCount,
      primaryMatch:
          candidate.primaryMatch,
      matchTypes:
          candidate.orderedMatchTypes,
    );
  }

  Future<int> _loadFormCount(
    _Candidate candidate,
  ) async {
    final table =
        candidate.partOfSpeech == 'noun'
            ? 'noun_forms'
            : candidate.partOfSpeech == 'verb'
                ? 'verb_forms'
                : null;

    if (table == null) {
      return 0;
    }

    final rows = await database.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $table
      WHERE lexeme_id = ?
      ''',
      [candidate.id],
    );

    if (rows.isEmpty) {
      return 0;
    }

    return _asInt(
      rows.first['total'],
    );
  }

  Future<List<DictionarySense>> _loadSenses({
    required String lexemeId,
    required String glossLanguage,
  }) async {
    final rows = await database.rawQuery(
      '''
      SELECT
        senses.id AS sense_id,
        senses.sense_no,
        glosses.language_code,
        glosses.text
      FROM senses
      LEFT JOIN glosses
        ON glosses.sense_id = senses.id
      WHERE senses.lexeme_id = ?
      ORDER BY senses.sense_no, glosses.id
      ''',
      [lexemeId],
    );

    final buckets =
        LinkedHashMap<String, _SenseBucket>();

    for (final row in rows) {
      final senseId =
          _text(row['sense_id']);

      if (senseId.isEmpty) {
        continue;
      }

      final bucket =
          buckets.putIfAbsent(
        senseId,
        () => _SenseBucket(
          number:
              _asInt(row['sense_no']),
        ),
      );

      final language =
          _normalizeLanguageCode(
        _text(row['language_code']),
      );
      final gloss =
          _text(row['text']);

      if (language.isEmpty ||
          gloss.isEmpty) {
        continue;
      }

      bucket.glossesByLanguage
          .putIfAbsent(
            language,
            () => <String>[],
          )
          .add(gloss);
    }

    return buckets.values
        .map(
          (bucket) => DictionarySense(
            number: bucket.number,
            glosses: List.unmodifiable(
              _selectGlosses(
                bucket.glossesByLanguage,
                glossLanguage,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<String> _selectGlosses(
    Map<String, List<String>> glosses,
    String preferredLanguage,
  ) {
    final preferred =
        glosses[preferredLanguage];

    if (preferred != null &&
        preferred.isNotEmpty) {
      return preferred;
    }

    for (final fallback
        in const ['en', 'zh', 'ru']) {
      final values =
          glosses[fallback];

      if (values != null &&
          values.isNotEmpty) {
        return values;
      }
    }

    for (final values
        in glosses.values) {
      if (values.isNotEmpty) {
        return values;
      }
    }

    return const [];
  }

  static _Candidate _candidateFromRow(
    Map<String, Object?> row,
  ) {
    return _Candidate(
      id: _text(row['id']),
      languageCode:
          _text(row['language_code']),
      partOfSpeech:
          _text(row['part_of_speech']),
      lemma: _text(row['lemma']),
    );
  }

  static int _compareCandidates(
    _Candidate a,
    _Candidate b,
  ) {
    final aRank =
        a.primaryMatch == null
            ? 99
            : _matchPriority(
                a.primaryMatch!,
              );
    final bRank =
        b.primaryMatch == null
            ? 99
            : _matchPriority(
                b.primaryMatch!,
              );

    final byMatch =
        aRank.compareTo(bRank);

    if (byMatch != 0) {
      return byMatch;
    }

    final byLemma = a.lemma
        .toLowerCase()
        .compareTo(
          b.lemma.toLowerCase(),
        );

    if (byLemma != 0) {
      return byLemma;
    }

    return a.id.compareTo(b.id);
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

    final normalized =
        value?.toString()
            .trim()
            .toLowerCase();

    return normalized == '1' ||
        normalized == 'true';
  }

  static int _asInt(
    Object? value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static String _text(
    Object? value,
  ) {
    return value?.toString()
            .trim() ??
        '';
  }

  static String _normalizeLanguageCode(
    String value,
  ) {
    final normalized =
        value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return '';
    }

    return normalized
        .split(RegExp('[-_]'))
        .first;
  }
}

class _Candidate {
  final String id;
  final String languageCode;
  final String partOfSpeech;
  final String lemma;

  String? primaryMatch;
  final List<String> matchTypes = [];
  final List<MorphologyAnalysis>
      matchedForms = [];

  _Candidate({
    required this.id,
    required this.languageCode,
    required this.partOfSpeech,
    required this.lemma,
  });

  void addMatch(
    String matchType, {
    MorphologyAnalysis? analysis,
  }) {
    if (!matchTypes.contains(matchType)) {
      matchTypes.add(matchType);
    }

    if (primaryMatch == null ||
        _matchPriority(matchType) <
            _matchPriority(
              primaryMatch!,
            )) {
      primaryMatch = matchType;
    }

    if (analysis != null) {
      // One row represents one grammatical analysis.
      // Preserve all analyses for ambiguous surface forms.
      matchedForms.add(analysis);
    }
  }

  List<String> get orderedMatchTypes {
    final result =
        List<String>.from(matchTypes)
          ..sort(
            (a, b) => _matchPriority(a)
                .compareTo(
              _matchPriority(b),
            ),
          );

    return result;
  }
}

class _SenseBucket {
  final int number;
  final Map<String, List<String>>
      glossesByLanguage = {};

  _SenseBucket({
    required this.number,
  });
}

int _matchPriority(
  String value,
) {
  switch (value) {
    case 'lemma':
      return 0;
    case 'form':
      return 1;
    case 'gloss':
      return 2;
    default:
      return 99;
  }
}
