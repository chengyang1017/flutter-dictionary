import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_application_1/data/asset_database_installer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp(
      'glyphora_asset_db_test_',
    );

    databaseFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}'
      'glyphora_ky.db',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(
        recursive: true,
      );
    }
  });

  test(
    'installs asset when local database is missing',
    () async {
      final installed =
          await AssetDatabaseInstaller.installIfChanged(
        databaseFile: databaseFile,
        assetBytes: Uint8List.fromList(
          [1, 2, 3, 4],
        ),
      );

      expect(installed, isTrue);
      expect(
        await databaseFile.readAsBytes(),
        [1, 2, 3, 4],
      );

      final fingerprintFile = File(
        '${databaseFile.path}.sha256',
      );

      expect(
        await fingerprintFile.exists(),
        isTrue,
      );
      expect(
        (await fingerprintFile.readAsString())
            .trim(),
        hasLength(64),
      );
    },
  );

  test(
    'keeps local database when asset fingerprint is unchanged',
    () async {
      final bytes = Uint8List.fromList(
        [10, 20, 30],
      );

      expect(
        await AssetDatabaseInstaller.installIfChanged(
          databaseFile: databaseFile,
          assetBytes: bytes,
        ),
        isTrue,
      );

      expect(
        await AssetDatabaseInstaller.installIfChanged(
          databaseFile: databaseFile,
          assetBytes: bytes,
        ),
        isFalse,
      );

      expect(
        await databaseFile.readAsBytes(),
        [10, 20, 30],
      );
    },
  );

  test(
    'replaces stale local database when asset changes',
    () async {
      await AssetDatabaseInstaller.installIfChanged(
        databaseFile: databaseFile,
        assetBytes: Uint8List.fromList(
          [1, 1, 1],
        ),
      );

      final oldFingerprint = await File(
        '${databaseFile.path}.sha256',
      ).readAsString();

      final replaced =
          await AssetDatabaseInstaller.installIfChanged(
        databaseFile: databaseFile,
        assetBytes: Uint8List.fromList(
          [2, 2, 2, 2],
        ),
      );

      final newFingerprint = await File(
        '${databaseFile.path}.sha256',
      ).readAsString();

      expect(replaced, isTrue);
      expect(
        await databaseFile.readAsBytes(),
        [2, 2, 2, 2],
      );
      expect(
        newFingerprint,
        isNot(oldFingerprint),
      );
    },
  );

  test(
    'reinstalls asset if fingerprint metadata is missing',
    () async {
      final bytes = Uint8List.fromList(
        [7, 8, 9],
      );

      await AssetDatabaseInstaller.installIfChanged(
        databaseFile: databaseFile,
        assetBytes: bytes,
      );

      await File(
        '${databaseFile.path}.sha256',
      ).delete();

      await databaseFile.writeAsBytes(
        [99, 99],
        flush: true,
      );

      final reinstalled =
          await AssetDatabaseInstaller.installIfChanged(
        databaseFile: databaseFile,
        assetBytes: bytes,
      );

      expect(reinstalled, isTrue);
      expect(
        await databaseFile.readAsBytes(),
        [7, 8, 9],
      );
    },
  );
}
