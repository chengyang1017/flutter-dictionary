import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/word_entry.dart';

class DictionaryDatabase {
  static const int assetDatabaseVersion = 1;

  static const Set<String> _canonicalTables = {
    'lexemes',
    'senses',
    'glosses',
    'noun_forms',
    'verb_forms',
  };

  final Map<String, Database> _openedDatabases = {};

  Future<Database> open(
    String languageCode,
  ) async {
    final normalizedCode =
        _normalizeLanguageCode(languageCode);

    final cached =
        _openedDatabases[normalizedCode];

    if (cached != null && cached.isOpen) {
      return cached;
    }

    final bytes = await _loadAssetDatabase(
      normalizedCode,
    );

    final databaseDirectory =
        await getDatabasesPath();

    final databasePath = p.join(
      databaseDirectory,
      'glyphora_${normalizedCode}_'
      'v$assetDatabaseVersion.db',
    );

    final databaseFile = File(databasePath);

    if (!await databaseFile.exists()) {
      await databaseFile.parent.create(
        recursive: true,
      );

      await databaseFile.writeAsBytes(
        bytes,
        flush: true,
      );
    }

    final database = await openDatabase(
      databasePath,
      readOnly: true,
    );

    _openedDatabases[normalizedCode] =
        database;

    return database;
  }

  Future<List<WordEntry>> getWords({
    required String languageCode,
    String keyword = '',
    String glossLanguage = 'zh',
    int limit = 500,
  }) async {
    final normalizedLanguage =
        _normalizeLanguageCode(languageCode);

    final database =
        await open(normalizedLanguage);

    if (await isCanonicalDatabase(database)) {
      return _getCanonicalWords(
        database: database,
        languageCode: normalizedLanguage,
        keyword: keyword,
        glossLanguage:
            _normalizeLanguageCode(
          glossLanguage,
        ),
        limit: limit,
      );
    }

    return _getLegacyWords(
      database: database,
      keyword: keyword,
      limit: limit,
    );
  }

  Future<bool> isCanonicalDatabase(
    Database database,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      ''',
    );

    final tableNames = rows
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    return _canonicalTables.every(
      tableNames.contains,
    );
  }

  Future<List<WordEntry>> _getLegacyWords({
    required Database database,
    required String keyword,
    required int limit,
  }) async {
    final tables =
        await getDictionaryTables(database);

    if (tables.isEmpty) {
      throw StateError(
        '数据库既不是 canonical 词典，'
        '也没有以 _table 结尾的旧词典表。',
      );
    }

    final normalizedKeyword =
        keyword.trim();

    final result = <WordEntry>[];

    for (final tableName in tables) {
      final quotedTable =
          _quoteIdentifier(tableName);

      final List<Map<String, Object?>> rows;

      if (normalizedKeyword.isEmpty) {
        rows = await database.rawQuery(
          '''
          SELECT
            word,
            meanings,
            type,
            data
          FROM $quotedTable
          ORDER BY word COLLATE NOCASE
          LIMIT ?
          ''',
          [limit],
        );
      } else {
        final search =
            '%$normalizedKeyword%';

        rows = await database.rawQuery(
          '''
          SELECT
            word,
            meanings,
            type,
            data
          FROM $quotedTable
          WHERE word LIKE ?
             OR meanings LIKE ?
             OR type LIKE ?
             OR data LIKE ?
          ORDER BY word COLLATE NOCASE
          LIMIT ?
          ''',
          [
            search,
            search,
            search,
            search,
            limit,
          ],
        );
      }

      result.addAll(
        rows.map(
          (row) => WordEntry.fromMap(
            row,
            tableName: tableName,
          ),
        ),
      );
    }

    result.sort((a, b) {
      final byWord = a.word
          .toLowerCase()
          .compareTo(b.word.toLowerCase());

      if (byWord != 0) {
        return byWord;
      }

      return a.sheetName.compareTo(
        b.sheetName,
      );
    });

    if (result.length <= limit) {
      return List.unmodifiable(result);
    }

    return List.unmodifiable(
      result.take(limit),
    );
  }

  Future<List<WordEntry>> _getCanonicalWords({
    required Database database,
    required String languageCode,
    required String keyword,
    required String glossLanguage,
    required int limit,
  }) async {
    final normalizedKeyword =
        keyword.trim();

    final candidates =
        LinkedHashMap<String, _CanonicalCandidate>();

    if (normalizedKeyword.isEmpty) {
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
            _candidateFromLexemeRow(row);

        candidates[candidate.id] =
            candidate;
      }
    } else {
      await _collectLemmaMatches(
        database: database,
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedKeyword,
        limit: limit,
        exact: true,
      );

      await _collectFormMatches(
        database: database,
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedKeyword,
        limit: limit,
      );

      await _collectGlossMatches(
        database: database,
        candidates: candidates,
        languageCode: languageCode,
        query: normalizedKeyword,
        limit: limit,
        exact: true,
      );

      if (candidates.isEmpty) {
        await _collectLemmaMatches(
          database: database,
          candidates: candidates,
          languageCode: languageCode,
          query: normalizedKeyword,
          limit: limit,
          exact: false,
        );

        await _collectGlossMatches(
          database: database,
          candidates: candidates,
          languageCode: languageCode,
          query: normalizedKeyword,
          limit: limit,
          exact: false,
        );
      }
    }

    final orderedCandidates =
        candidates.values.toList();

    orderedCandidates.sort((a, b) {
      final aRank = a.primaryMatch == null
          ? 99
          : _matchPriority(
              a.primaryMatch!,
            );
      final bRank = b.primaryMatch == null
          ? 99
          : _matchPriority(
              b.primaryMatch!,
            );

      final byMatch = aRank.compareTo(
        bRank,
      );

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
    });

    final entries = <WordEntry>[];

    for (final candidate
        in orderedCandidates.take(limit)) {
      entries.add(
        await _loadCanonicalEntry(
          database: database,
          candidate: candidate,
          glossLanguage: glossLanguage,
        ),
      );
    }

    return List.unmodifiable(entries);
  }

  Future<void> _collectLemmaMatches({
    required Database database,
    required LinkedHashMap<
        String,
        _CanonicalCandidate
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
        _candidateFromLexemeRow(row),
        'lemma',
      );
    }
  }

  Future<void> _collectGlossMatches({
    required Database database,
    required LinkedHashMap<
        String,
        _CanonicalCandidate
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
        _candidateFromLexemeRow(row),
        'gloss',
      );
    }
  }

  Future<void> _collectFormMatches({
    required Database database,
    required LinkedHashMap<
        String,
        _CanonicalCandidate
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
      final analysis = MorphologyAnalysis(
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
          'special':
              _asBool(row['special']),
        },
      );

      _addMatch(
        candidates,
        _candidateFromLexemeRow(row),
        'form',
        analysis: analysis,
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
      final analysis = MorphologyAnalysis(
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
      );

      _addMatch(
        candidates,
        _candidateFromLexemeRow(row),
        'form',
        analysis: analysis,
      );
    }
  }

  void _addMatch(
    LinkedHashMap<String, _CanonicalCandidate>
        candidates,
    _CanonicalCandidate incoming,
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

  Future<WordEntry> _loadCanonicalEntry({
    required Database database,
    required _CanonicalCandidate candidate,
    required String glossLanguage,
  }) async {
    final senses = await _loadSenses(
      database: database,
      lexemeId: candidate.id,
      glossLanguage: glossLanguage,
    );

    final meaningSet =
        LinkedHashSet<String>();

    for (final sense in senses) {
      meaningSet.addAll(sense.glosses);
    }

    final formTable =
        candidate.partOfSpeech == 'noun'
            ? 'noun_forms'
            : candidate.partOfSpeech == 'verb'
                ? 'verb_forms'
                : null;

    var formCount = 0;

    if (formTable != null) {
      final countRows =
          await database.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM $formTable
        WHERE lexeme_id = ?
        ''',
        [candidate.id],
      );

      formCount = _asInt(
        countRows.isEmpty
            ? null
            : countRows.first['total'],
      );
    }

    return WordEntry.canonical(
      lexemeId: candidate.id,
      languageCode: candidate.languageCode,
      lemma: candidate.lemma,
      partOfSpeech:
          candidate.partOfSpeech,
      meanings: meaningSet.join(' / '),
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

  Future<List<DictionarySense>> _loadSenses({
    required Database database,
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

      final bucket = buckets.putIfAbsent(
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
      final gloss = _text(row['text']);

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
      final values = glosses[fallback];

      if (values != null &&
          values.isNotEmpty) {
        return values;
      }
    }

    for (final values in glosses.values) {
      if (values.isNotEmpty) {
        return values;
      }
    }

    return const [];
  }

  Future<List<String>> getDictionaryTables(
    Database database,
  ) async {
    final rows = await database.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      ORDER BY name
      ''',
    );

    return rows
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .where(
          (name) =>
              !name.startsWith('sqlite_') &&
              name != 'android_metadata' &&
              name.endsWith('_table'),
        )
        .toList(growable: false);
  }

  Future<Uint8List> _loadAssetDatabase(
    String languageCode,
  ) async {
    final candidates =
        _assetCandidates(languageCode);

    Object? lastError;

    for (final assetPath in candidates) {
      try {
        final data =
            await rootBundle.load(assetPath);

        return data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw StateError(
      '找不到 $languageCode 的数据库资源。\n'
      '已尝试：${candidates.join(', ')}\n'
      '最后错误：$lastError',
    );
  }

  List<String> _assetCandidates(
    String languageCode,
  ) {
    switch (languageCode) {
      case 'vi':
        return const [
          'assets/databases/vi.db',
          'assets/databases/vn.db',
        ];
      case 'ja':
        return const [
          'assets/databases/ja.db',
          'assets/databases/jp.db',
        ];
      default:
        return [
          'assets/databases/$languageCode.db',
        ];
    }
  }

  String _quoteIdentifier(
    String identifier,
  ) {
    final escaped =
        identifier.replaceAll('"', '""');

    return '"$escaped"';
  }

  Future<void> closeAll() async {
    final databases =
        _openedDatabases.values.toList();

    _openedDatabases.clear();

    for (final database in databases) {
      if (database.isOpen) {
        await database.close();
      }
    }
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

  static _CanonicalCandidate
      _candidateFromLexemeRow(
    Map<String, Object?> row,
  ) {
    return _CanonicalCandidate(
      id: _text(row['id']),
      languageCode:
          _text(row['language_code']),
      partOfSpeech:
          _text(row['part_of_speech']),
      lemma: _text(row['lemma']),
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized =
        value?.toString().trim().toLowerCase();

    return normalized == '1' ||
        normalized == 'true';
  }

  static int _asInt(Object? value) {
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

  static String _text(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

class _CanonicalCandidate {
  final String id;
  final String languageCode;
  final String partOfSpeech;
  final String lemma;

  String? primaryMatch;
  final List<String> matchTypes = [];
  final List<MorphologyAnalysis>
      matchedForms = [];

  _CanonicalCandidate({
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
            _matchPriority(primaryMatch!)) {
      primaryMatch = matchType;
    }

    if (analysis == null) {
      return;
    }

    final alreadyExists =
        matchedForms.any(
      (item) =>
          item.form == analysis.form &&
          item.canonicalKey ==
              analysis.canonicalKey &&
          item.partOfSpeech ==
              analysis.partOfSpeech,
    );

    if (!alreadyExists) {
      matchedForms.add(analysis);
    }
  }

  List<String> get orderedMatchTypes {
    final result =
        List<String>.from(matchTypes);

    result.sort(
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

int _matchPriority(String value) {
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
