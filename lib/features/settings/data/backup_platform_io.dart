// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';
import 'dart:typed_data';

import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/database_platform.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// The 16-byte magic every valid SQLite file starts with.
const List<int> _sqliteHeader = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // 'SQLite f'
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // 'ormat 3\0'
];

/// Checkpoints WAL into the main file — the change that makes a plain copy
/// of that one file consistent — then reads it.
Future<Uint8List> exportBackupBytes(AppDatabase db, AppConfig config) async {
  await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  final path = await resolveDatabasePath(config.databaseName);
  try {
    return await File(path).readAsBytes();
  } on FileSystemException {
    throw const StorageException('Could not read the catalogue file.');
  }
}

/// Validates [bytes] look like a Khulla backup, closes the live connection,
/// discards stale WAL/SHM sidecars from the file being replaced, and writes
/// [bytes] over the catalogue file.
///
/// Nothing here restarts the app — the caller does that once this returns,
/// since restart is the one step every platform shares.
Future<void> importBackupBytes(
  AppDatabase db,
  AppConfig config,
  Uint8List bytes,
) async {
  await _validateBackupBytes(bytes);

  await db.dispose();

  final path = await resolveDatabasePath(config.databaseName);
  for (final suffix in ['-wal', '-shm']) {
    final sidecar = File('$path$suffix');
    if (sidecar.existsSync()) {
      await sidecar.delete();
    }
  }
  try {
    await File(path).writeAsBytes(bytes, flush: true);
  } on FileSystemException {
    throw const StorageException('Could not write the restored catalogue.');
  }
}

Future<({int? sizeBytes, String? path})> inspectStorage(
  AppConfig config,
) async {
  final path = await resolveDatabasePath(config.databaseName);
  final file = File(path);
  return (sizeBytes: file.existsSync() ? file.lengthSync() : null, path: path);
}

/// Checks the SQLite header, then opens a temporary copy read-only and
/// confirms it holds tables this app expects — a valid-but-unrelated sqlite
/// file (someone else's database) has the right header and the wrong
/// schema, and deserves the same refusal as a file with no header at all.
Future<void> _validateBackupBytes(Uint8List bytes) async {
  if (bytes.length < _sqliteHeader.length ||
      !_startsWith(bytes, _sqliteHeader)) {
    throw const InvalidInputException('That file is not a Khulla backup.');
  }

  final tempDir = await getTemporaryDirectory();
  final tempFile = File(
    p.join(
      tempDir.path,
      'khulla-restore-check-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    ),
  );
  await tempFile.writeAsBytes(bytes);
  try {
    final connection = sqlite3.open(tempFile.path, mode: OpenMode.readOnly);
    try {
      final result = connection.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name IN ('staff', 'titles')",
      );
      if (result.length < 2) {
        throw const InvalidInputException('That file is not a Khulla backup.');
      }
    } finally {
      connection.close();
    }
  } on SqliteException {
    throw const InvalidInputException('That file is not a Khulla backup.');
  } finally {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final sidecar = suffix.isEmpty
          ? tempFile
          : File('${tempFile.path}$suffix');
      if (sidecar.existsSync()) {
        await sidecar.delete();
      }
    }
  }
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}
