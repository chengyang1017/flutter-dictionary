import 'dart:io';

import 'package:flutter_application_1/data/canonical_dictionary_repository.dart';
import 'package:flutter_application_1/data/canonical_morphology_repository.dart';
import 'package:flutter_application_1/data/dictionary_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late Database database;
  late CanonicalDictionaryRepository dictionaryRepository;
  late CanonicalMorphologyRepository morphologyRepository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'glyphora_canonical_dictionary_test_',
    );

    final databasePath = p.join(
      tempDirectory.path,
      'canonical_test.db',
    );

    database = await databaseFactoryFfi.openDatabase(
      databasePath,
    );

    await _createCanonicalSchema(database);
    await _seedCanonicalFixture(database);

    dictionaryRepository = CanonicalDictionaryRepository(
      database,
    );
    morphologyRepository = CanonicalMorphologyRepository(
      database,
    );
  });

  tearDown(() async {
    await database.close();

    if (await tempDirectory.exists()) {
      await tempDirectory.delete(
        recursive: true,
      );
    }
  });

  test(
    'fixture is recognized as a canonical SQLite database',
    () async {
      final dictionaryDatabase = DictionaryDatabase();

      expect(
        await dictionaryDatabase.isCanonicalDatabase(
          database,
        ),
        isTrue,
      );
    },
  );

  test(
    'lemma lookup returns senses and complete verb form count',
    () async {
      final results = await dictionaryRepository.search(
        languageCode: 'ky',
        query: 'алуу',
        glossLanguage: 'zh',
      );

      expect(results, hasLength(1));

      final entry = results.single;

      expect(entry.word, 'алуу');
      expect(entry.primaryMatch, 'lemma');
      expect(entry.formCount, 46);
      expect(entry.senses, hasLength(2));
      expect(
        entry.senses[0].glosses,
        ['买'],
      );
      expect(
        entry.senses[1].glosses,
        ['拿'],
      );
    },
  );

  test(
    'inflected-form lookup returns lemma and morphology analysis',
    () async {
      final results = await dictionaryRepository.search(
        languageCode: 'ky',
        query: 'алдым',
        glossLanguage: 'zh',
      );

      expect(results, hasLength(1));

      final entry = results.single;

      expect(entry.word, 'алуу');
      expect(entry.primaryMatch, 'form');
      expect(entry.matchedForms, hasLength(1));

      final analysis = entry.matchedForms.single;

      expect(analysis.form, 'алдым');
      expect(
        analysis.features['tense'],
        'past',
      );
      expect(
        analysis.features['person'],
        '1sg',
      );
      expect(
        analysis.features['negative'],
        isFalse,
      );
    },
  );

  test(
    'gloss lookup works for English Chinese and Russian',
    () async {
      for (final query in [
        'buy',
        '买',
        'покупать',
      ]) {
        final results =
            await dictionaryRepository.search(
          languageCode: 'ky',
          query: query,
          glossLanguage: 'zh',
        );

        expect(
          results.map((entry) => entry.word),
          contains('алуу'),
          reason: 'gloss query failed: $query',
        );
      }
    },
  );

  test(
    'ambiguous form returns every matching lexeme',
    () async {
      final results = await dictionaryRepository.search(
        languageCode: 'ky',
        query: 'орток',
        glossLanguage: 'zh',
      );

      expect(results, hasLength(2));

      expect(
        results.map((entry) => entry.word).toSet(),
        {
          'алуу',
          'баруу',
        },
      );

      for (final entry in results) {
        expect(entry.primaryMatch, 'form');
        expect(entry.matchedForms, hasLength(1));
        expect(
          entry.matchedForms.single.form,
          'орток',
        );
      }
    },
  );

  test(
    'preferred gloss language is selected per sense',
    () async {
      final results = await dictionaryRepository.search(
        languageCode: 'ky',
        query: 'алуу',
        glossLanguage: 'en',
      );

      final entry = results.single;

      expect(
        entry.senses[0].glosses,
        ['buy'],
      );
      expect(
        entry.senses[1].glosses,
        ['take'],
      );
      expect(
        entry.meanings,
        'buy / take',
      );
    },
  );

  test(
    'full verb paradigm returns all 46 forms without truncation',
    () async {
      final forms = await morphologyRepository.loadForms(
        lexemeId: 'verb_aluu',
        partOfSpeech: 'verb',
      );

      expect(forms, hasLength(46));
      expect(
        forms.first.canonicalKey,
        'infinitive',
      );

      final pastFirstPerson = forms.singleWhere(
        (form) => form.form == 'алдым',
      );

      expect(
        pastFirstPerson.features['tense'],
        'past',
      );
      expect(
        pastFirstPerson.features['person'],
        '1sg',
      );
    },
  );

  test(
    'full noun paradigm returns all 414 forms without truncation',
    () async {
      final lemmaResults =
          await dictionaryRepository.search(
        languageCode: 'ky',
        query: 'мугалим',
        glossLanguage: 'zh',
      );

      expect(lemmaResults, hasLength(1));
      expect(
        lemmaResults.single.formCount,
        414,
      );

      final forms = await morphologyRepository.loadForms(
        lexemeId: 'noun_mugalim',
        partOfSpeech: 'noun',
      );

      expect(forms, hasLength(414));
      expect(forms.first.form, 'мугалим');
      expect(
        forms.first.features['number'],
        'sg',
      );
      expect(
        forms.first.features['case'],
        'nominative',
      );
    },
  );
}

Future<void> _createCanonicalSchema(
  Database database,
) async {
  await database.execute(
    '''
    CREATE TABLE lexemes (
      id TEXT PRIMARY KEY,
      language_code TEXT NOT NULL,
      part_of_speech TEXT NOT NULL,
      lemma TEXT NOT NULL
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE senses (
      id TEXT PRIMARY KEY,
      lexeme_id TEXT NOT NULL,
      sense_no INTEGER NOT NULL
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE glosses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sense_id TEXT NOT NULL,
      language_code TEXT NOT NULL,
      text TEXT NOT NULL
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE noun_forms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lexeme_id TEXT NOT NULL,
      form TEXT NOT NULL,
      canonical_key TEXT NOT NULL,
      number TEXT,
      possessive TEXT,
      case_name TEXT,
      interrogative INTEGER NOT NULL DEFAULT 0,
      special INTEGER NOT NULL DEFAULT 0
    )
    ''',
  );

  await database.execute(
    '''
    CREATE TABLE verb_forms (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lexeme_id TEXT NOT NULL,
      form TEXT NOT NULL,
      canonical_key TEXT NOT NULL,
      form_type TEXT,
      tense TEXT,
      person TEXT,
      negative INTEGER NOT NULL DEFAULT 0
    )
    ''',
  );
}

Future<void> _seedCanonicalFixture(
  Database database,
) async {
  final batch = database.batch();

  batch.insert(
    'lexemes',
    {
      'id': 'verb_aluu',
      'language_code': 'ky',
      'part_of_speech': 'verb',
      'lemma': 'алуу',
    },
  );

  batch.insert(
    'lexemes',
    {
      'id': 'verb_baruu',
      'language_code': 'ky',
      'part_of_speech': 'verb',
      'lemma': 'баруу',
    },
  );

  batch.insert(
    'lexemes',
    {
      'id': 'noun_mugalim',
      'language_code': 'ky',
      'part_of_speech': 'noun',
      'lemma': 'мугалим',
    },
  );

  batch.insert(
    'senses',
    {
      'id': 'sense_aluu_1',
      'lexeme_id': 'verb_aluu',
      'sense_no': 1,
    },
  );

  batch.insert(
    'senses',
    {
      'id': 'sense_aluu_2',
      'lexeme_id': 'verb_aluu',
      'sense_no': 2,
    },
  );

  batch.insert(
    'senses',
    {
      'id': 'sense_baruu_1',
      'lexeme_id': 'verb_baruu',
      'sense_no': 1,
    },
  );

  batch.insert(
    'senses',
    {
      'id': 'sense_mugalim_1',
      'lexeme_id': 'noun_mugalim',
      'sense_no': 1,
    },
  );

  for (final gloss in const [
    ('sense_aluu_1', 'en', 'buy'),
    ('sense_aluu_1', 'zh', '买'),
    ('sense_aluu_1', 'ru', 'покупать'),
    ('sense_aluu_2', 'en', 'take'),
    ('sense_aluu_2', 'zh', '拿'),
    ('sense_aluu_2', 'ru', 'брать'),
    ('sense_baruu_1', 'en', 'go'),
    ('sense_baruu_1', 'zh', '去'),
    ('sense_baruu_1', 'ru', 'идти'),
    ('sense_mugalim_1', 'en', 'teacher'),
    ('sense_mugalim_1', 'zh', '老师'),
    ('sense_mugalim_1', 'ru', 'учитель'),
  ]) {
    batch.insert(
      'glosses',
      {
        'sense_id': gloss.$1,
        'language_code': gloss.$2,
        'text': gloss.$3,
      },
    );
  }

  for (var index = 0; index < 46; index++) {
    late final String form;
    late final String canonicalKey;
    late final String formType;
    late final String? tense;
    late final String? person;
    late final int negative;

    if (index == 0) {
      form = 'алуу';
      canonicalKey = 'infinitive';
      formType = 'infinitive';
      tense = null;
      person = null;
      negative = 0;
    } else if (index == 1) {
      form = 'алдым';
      canonicalKey = 'past_1sg';
      formType = 'finite';
      tense = 'past';
      person = '1sg';
      negative = 0;
    } else if (index == 2) {
      form = 'орток';
      canonicalKey = 'ambiguous_fixture';
      formType = 'finite';
      tense = 'present';
      person = '3sg';
      negative = 0;
    } else {
      form = 'алуу_fixture_$index';
      canonicalKey = 'fixture_$index';
      formType = 'finite';
      tense = switch (index % 3) {
        0 => 'past',
        1 => 'present',
        _ => 'future',
      };
      person = switch (index % 6) {
        0 => '1sg',
        1 => '2sg',
        2 => '3sg',
        3 => '1pl',
        4 => '2pl',
        _ => '3pl',
      };
      negative = index.isEven ? 0 : 1;
    }

    batch.insert(
      'verb_forms',
      {
        'lexeme_id': 'verb_aluu',
        'form': form,
        'canonical_key': canonicalKey,
        'form_type': formType,
        'tense': tense,
        'person': person,
        'negative': negative,
      },
    );
  }

  batch.insert(
    'verb_forms',
    {
      'lexeme_id': 'verb_baruu',
      'form': 'баруу',
      'canonical_key': 'infinitive',
      'form_type': 'infinitive',
      'tense': null,
      'person': null,
      'negative': 0,
    },
  );

  batch.insert(
    'verb_forms',
    {
      'lexeme_id': 'verb_baruu',
      'form': 'орток',
      'canonical_key': 'ambiguous_fixture',
      'form_type': 'finite',
      'tense': 'present',
      'person': '3sg',
      'negative': 0,
    },
  );

  const cases = [
    'nominative',
    'genitive',
    'dative',
    'accusative',
    'locative',
    'ablative',
    'instrumental',
  ];

  for (var index = 0; index < 414; index++) {
    batch.insert(
      'noun_forms',
      {
        'lexeme_id': 'noun_mugalim',
        'form': index == 0
            ? 'мугалим'
            : 'мугалим_fixture_$index',
        'canonical_key': index == 0
            ? 'sg_none_nominative'
            : 'noun_fixture_$index',
        'number': index.isEven ? 'sg' : 'pl',
        'possessive': index == 0
            ? 'none'
            : index % 4 == 0
                ? '1sg'
                : 'none',
        'case_name': cases[index % cases.length],
        'interrogative':
            index != 0 && index % 5 == 0 ? 1 : 0,
        'special':
            index != 0 && index % 7 == 0 ? 1 : 0,
      },
    );
  }

  await batch.commit(
    noResult: true,
  );
}
