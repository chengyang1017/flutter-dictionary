import 'package:flutter_application_1/data/canonical_dictionary_repository.dart';
import 'package:flutter_application_1/data/canonical_morphology_repository.dart';
import 'package:flutter_application_1/data/dictionary_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late CanonicalDictionaryRepository dictionaryRepository;
  late CanonicalMorphologyRepository morphologyRepository;

  setUpAll(() async {
    sqfliteFfiInit();

    final databasePath = p.absolute(
      'assets',
      'databases',
      'ky.db',
    );

    database = await databaseFactoryFfi.openDatabase(
      databasePath,
    );

    dictionaryRepository =
        CanonicalDictionaryRepository(
      database,
    );

    morphologyRepository =
        CanonicalMorphologyRepository(
      database,
    );
  });

  tearDownAll(() async {
    await database.close();
  });

  test(
    'bundled ky.db has canonical schema',
    () async {
      final dictionaryDatabase =
          DictionaryDatabase();

      expect(
        await dictionaryDatabase
            .isCanonicalDatabase(database),
        isTrue,
      );
    },
  );

  test(
    'bundled ky.db resolves алдым to алуу',
    () async {
      final results =
          await dictionaryRepository.search(
        languageCode: 'ky',
        queryLanguage: 'zh',
        query: 'алдым',
        glossLanguage: 'zh',
      );

      final entry = results.firstWhere(
        (item) => item.word == 'алуу',
      );

      expect(
        entry.primaryMatch,
        'form',
      );

      final analysis =
          entry.matchedForms.firstWhere(
        (item) => item.form == 'алдым',
      );

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
    'bundled ky.db resolves glosses in the declared language',
    () async {
      for (final testCase in const {
        'en': 'buy',
        'zh': '买',
        'ru': 'покупать',
      }.entries) {
        final results =
            await dictionaryRepository.search(
          languageCode: 'ky',
          queryLanguage: testCase.key,
          query: testCase.value,
          glossLanguage: 'zh',
        );

        expect(
          results.map((entry) => entry.word),
          contains('алуу'),
          reason:
              'Failed gloss query: '
              '${testCase.key}:${testCase.value}',
        );
      }
    },
  );

  test(
    'bundled ky.db does not cross-match gloss languages',
    () async {
      final results =
          await dictionaryRepository.search(
        languageCode: 'ky',
        queryLanguage: 'zh',
        query: 'buy',
        glossLanguage: 'zh',
      );

      expect(
        results.map((entry) => entry.word),
        isNot(contains('алуу')),
      );
    },
  );

  test(
    'bundled ky.db has complete 46-form verb paradigm',
    () async {
      final results =
          await dictionaryRepository.search(
        languageCode: 'ky',
        queryLanguage: 'zh',
        query: 'айтуу',
        glossLanguage: 'zh',
      );

      final entry = results.firstWhere(
        (item) => item.word == 'айтуу',
      );

      expect(
        entry.formCount,
        46,
      );

      final forms =
          await morphologyRepository.loadForms(
        lexemeId: entry.lexemeId!,
        partOfSpeech: entry.type,
      );

      expect(
        forms,
        hasLength(46),
      );
    },
  );

  test(
    'bundled ky.db has complete 414-form noun paradigm',
    () async {
      final results =
          await dictionaryRepository.search(
        languageCode: 'ky',
        queryLanguage: 'zh',
        query: 'мугалим',
        glossLanguage: 'zh',
      );

      final entry = results.firstWhere(
        (item) => item.word == 'мугалим',
      );

      expect(
        entry.formCount,
        414,
      );

      final forms =
          await morphologyRepository.loadForms(
        lexemeId: entry.lexemeId!,
        partOfSpeech: entry.type,
      );

      expect(
        forms,
        hasLength(414),
      );
    },
  );
}
