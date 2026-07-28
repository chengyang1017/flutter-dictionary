import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/word_entry.dart';

class DictionaryDatabase {
  static const int assetDatabaseVersion = 1;

  final Map<String, Database> _openedDatabases = {};

  Future<Database> open(
    String languageCode,
  ) async {
    final normalizedCode =
        languageCode.trim().toLowerCase();

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
    int limit = 500,
  }) async {
    final database =
        await open(languageCode);

    final tables =
        await getDictionaryTables(database);

    if (tables.isEmpty) {
      throw StateError(
        '数据库中没有以 _table 结尾的词典表。',
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
}
