// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/database_platform.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:sqlite3/sqlite3.dart';

const String _source = 'BackupPlatformIo';

/// The 16-byte magic every valid SQLite file starts with.
const List<int> _sqliteHeader = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // 'SQLite f'
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // 'ormat 3\0'
];

/// Suffix of the copy of the catalogue taken just before a restore replaces
/// it. One generation is kept, beside the catalogue, until the next restore:
/// if the backup that was restored turns out to be the wrong one, this is
/// what the library had a moment before.
const String preRestoreSuffix = '.pre-restore';

/// A consistent snapshot of the catalogue, as the bytes of a SQLite file.
Future<Uint8List> exportBackupBytes(AppDatabase db, AppConfig config) async =>
    await exportDatabaseSnapshot(
      db,
      databasePath: await resolveDatabasePath(config.databaseName),
    );

/// Replaces the catalogue with the backup in [bytes].
///
/// Throws an `InvalidInputException` - before anything is touched - when
/// [bytes] are not a Khulla backup this build can open. Nothing here
/// restarts the app; the caller does that once this returns, since restart
/// is the one step every platform shares.
Future<void> importBackupBytes(
  AppDatabase db,
  AppConfig config,
  Uint8List bytes,
) async => await replaceDatabaseFile(
  db,
  bytes,
  databasePath: await resolveDatabasePath(config.databaseName),
);

Future<({int? sizeBytes, String? path})> inspectStorage(
  AppConfig config,
) async {
  final path = await resolveDatabasePath(config.databaseName);
  final file = File(path);
  return (sizeBytes: file.existsSync() ? file.lengthSync() : null, path: path);
}

/// Writes a snapshot of [db] with `VACUUM INTO` and reads it back.
///
/// `VACUUM INTO` is SQLite's own consistent copy: it reads the database in
/// one transaction, write-ahead log included, so a loan issued while the
/// export runs is either wholly in the backup or wholly out of it. Copying
/// the file after a checkpoint could not promise that - a write or an
/// automatic checkpoint landing between the two steps tears the copy.
@visibleForTesting
Future<Uint8List> exportDatabaseSnapshot(
  AppDatabase db, {
  required String databasePath,
}) async {
  final snapshot = File(
    '$databasePath.export-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await db.customStatement('VACUUM INTO ?', [snapshot.path]);
    return await snapshot.readAsBytes();
  } on FileSystemException {
    throw const StorageException('Could not read the backup snapshot.');
  } finally {
    await _deleteIfExists(snapshot);
  }
}

/// Puts the backup in [bytes] in place of the catalogue at [databasePath].
///
/// Ordered so that the library's catalogue is never at risk:
///
/// 1. The backup is written beside the catalogue and checked there - it is
///    a SQLite file, it passes `PRAGMA integrity_check`, it holds this
///    app's tables, and it was not made by a newer build (which would
///    refuse to open after the restart, with the old catalogue gone). Any
///    failure deletes it and throws, with the catalogue untouched.
/// 2. A consistent copy of the current catalogue is kept at
///    [preRestoreSuffix], so even a successful restore of the wrong file is
///    recoverable.
/// 3. The connection is closed, the catalogue's journal files are removed so
///    the old log cannot be replayed into the new file, and the checked
///    backup is renamed over the catalogue. A rename on the same volume is
///    atomic: after a crash the catalogue is either the old file or the new
///    one, never half of each.
@visibleForTesting
Future<void> replaceDatabaseFile(
  AppDatabase db,
  Uint8List bytes, {
  required String databasePath,
}) async {
  if (bytes.length < _sqliteHeader.length ||
      !_startsWith(bytes, _sqliteHeader)) {
    throw const InvalidInputException.because(AppErrorReason.notABackup);
  }

  final incoming = File('$databasePath.restore-incoming');
  await _deleteWithSidecars(incoming.path);
  try {
    await incoming.writeAsBytes(bytes, flush: true);
    validateBackupFile(incoming.path, appSchemaVersion: db.schemaVersion);
  } on Object {
    await _deleteWithSidecars(incoming.path);
    rethrow;
  }

  final preRestore = File('$databasePath$preRestoreSuffix');
  await _deleteWithSidecars(preRestore.path);
  await db.customStatement('VACUUM INTO ?', [preRestore.path]);

  await db.dispose();

  for (final suffix in _sidecarSuffixes) {
    await _deleteIfExists(File('$databasePath$suffix'));
  }
  try {
    await incoming.rename(databasePath);
  } on FileSystemException catch (error, stackTrace) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      source: '$_source.replaceDatabaseFile',
    );
    await _deleteWithSidecars(incoming.path);
    throw const StorageException.because(AppErrorReason.restoreNotApplied);
  }
}

/// Refuses a file that is not a Khulla backup this build can open.
///
/// Opens the file directly (it is a private copy, never the catalogue) and
/// switches it to a rollback journal, so the file that gets renamed into
/// place is complete on its own with no write-ahead log beside it.
@visibleForTesting
void validateBackupFile(String path, {required int appSchemaVersion}) {
  final Database connection;
  try {
    connection = sqlite3.open(path, mode: OpenMode.readWrite);
  } on SqliteException {
    throw const InvalidInputException.because(AppErrorReason.notABackup);
  }
  try {
    final integrity = connection.select('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.first.values.first != 'ok') {
      throw const InvalidInputException.because(AppErrorReason.backupDamaged);
    }

    final tables = connection.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name IN ('staff', 'titles')",
    );
    final version = connection.userVersion;
    if (tables.length < 2 || version < 1) {
      throw const InvalidInputException.because(AppErrorReason.notABackup);
    }
    if (version > appSchemaVersion) {
      throw const InvalidInputException.because(
        AppErrorReason.backupFromNewerVersion,
      );
    }

    connection.execute('PRAGMA journal_mode = DELETE');
  } on SqliteException catch (error) {
    throw InvalidInputException.because(
      error.resultCode == SqlError.SQLITE_CORRUPT
          ? AppErrorReason.backupDamaged
          : AppErrorReason.notABackup,
    );
  } finally {
    connection.close();
  }
}

const List<String> _sidecarSuffixes = ['-wal', '-shm', '-journal'];

Future<void> _deleteWithSidecars(String path) async {
  await _deleteIfExists(File(path));
  for (final suffix in _sidecarSuffixes) {
    await _deleteIfExists(File('$path$suffix'));
  }
}

Future<void> _deleteIfExists(File file) async {
  if (file.existsSync()) await file.delete();
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}
