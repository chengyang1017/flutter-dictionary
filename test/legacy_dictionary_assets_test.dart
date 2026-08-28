import 'package:flutter_application_1/data/dictionary_database.dart';
import 'package:flutter_application_1/models/word_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  for (final languageCode in const [
    'ru',
    'vi',
  ]) {
    test(
      'bundled $languageCode.db remains readable as legacy dictionary',
      () async {
        final databasePath = p.absolute(
          'assets',
          'databases',
          '$languageCode.db',
        );

        final database =
            await databaseFactoryFfi.openDatabase(
          databasePath,
        );

        try {
          final quickCheck =
              await database.rawQuery(
            'PRAGMA quick_check',
          );

          expect(
            quickCheck.single.values.single,
            'ok',
          );

          final dictionaryDatabase =
              DictionaryDatabase();

          expect(
            await dictionaryDatabase
                .isCanonicalDatabase(database),
            isFalse,
          );

          final tables =
              await dictionaryDatabase
                  .getDictionaryTables(database);

          expect(
            tables,
            isNotEmpty,
            reason:
                '$languageCode.db must keep at least one *_table legacy dictionary table',
          );

          var totalRows = 0;
          WordEntry? sampleEntry;

          for (final tableName in tables) {
            final quotedTable =
                _quoteIdentifier(tableName);

            final columns =
                await database.rawQuery(
              'PRAGMA table_info($quotedTable)',
            );

            final columnNames = columns
                .map(
                  (row) =>
                      row['name']?.toString(),
                )
                .whereType<String>()
                .toSet();

            expect(
              columnNames,
              containsAll(
                const [
                  'word',
                  'meanings',
                  'type',
                  'data',
                ],
              ),
              reason:
                  '$languageCode legacy table $tableName changed schema',
            );

            final countRows =
                await database.rawQuery(
              '''
              SELECT COUNT(*) AS total
              FROM $quotedTable
              ''',
            );

            final rowCount = _asInt(
              countRows.single['total'],
            );

            totalRows += rowCount;

            if (sampleEntry == null &&
                rowCount > 0) {
              final rows =
                  await database.rawQuery(
                '''
                SELECT
                  word,
                  meanings,
                  type,
                  data
                FROM $quotedTable
                LIMIT 1
                ''',
              );

              sampleEntry = WordEntry.fromMap(
                rows.single,
                tableName: tableName,
              );
            }
          }

          expect(
            totalRows,
            greaterThan(0),
            reason:
                '$languageCode.db must still contain legacy dictionary rows',
          );

          expect(
            sampleEntry,
            isNotNull,
          );

          expect(
            sampleEntry!.word.trim(),
            isNotEmpty,
          );

          expect(
            sampleEntry!.isCanonical,
            isFalse,
          );

          expect(
            sampleEntry!.sheetName.trim(),
            isNotEmpty,
          );
        } finally {
          await database.close();
        }
      },
    );
  }
}

String _quoteIdentifier(
  String identifier,
) {
  final escaped =
      identifier.replaceAll('"', '""');

  return '"$escaped"';
}

int _asInt(
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
