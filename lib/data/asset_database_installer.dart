import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AssetDatabaseInstaller {
  const AssetDatabaseInstaller._();

  static Future<bool> installIfChanged({
    required File databaseFile,
    required Uint8List assetBytes,
  }) async {
    final fingerprint =
        sha256.convert(assetBytes).toString();

    final fingerprintFile = File(
      '${databaseFile.path}.sha256',
    );

    final installedFingerprint =
        await _readFingerprint(
      fingerprintFile,
    );

    if (await databaseFile.exists() &&
        installedFingerprint == fingerprint) {
      return false;
    }

    await databaseFile.parent.create(
      recursive: true,
    );

    await databaseFile.writeAsBytes(
      assetBytes,
      flush: true,
    );

    await fingerprintFile.writeAsString(
      fingerprint,
      flush: true,
    );

    return true;
  }

  static Future<String?> _readFingerprint(
    File fingerprintFile,
  ) async {
    if (!await fingerprintFile.exists()) {
      return null;
    }

    try {
      final value =
          await fingerprintFile.readAsString();

      final normalized = value.trim();

      return normalized.isEmpty
          ? null
          : normalized;
    } on FileSystemException {
      return null;
    }
  }
}
