// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:file_selector/file_selector.dart' show XTypeGroup, openFile;
import 'package:injectable/injectable.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/files/save_binary_file.dart';
import 'package:khulla/core/lifecycle/restart_app.dart';
import 'package:khulla/features/settings/data/backup_local_data_source.dart';
import 'package:khulla/features/settings/data/backup_platform.dart';
import 'package:khulla/features/settings/data/backup_session_storage.dart';
import 'package:khulla/features/settings/domain/backup_repository.dart';
import 'package:khulla/features/settings/domain/models/backup_info.dart';

const String _source = 'BackupRepositoryImpl';

/// [BackupRepository] over the local catalogue.
///
/// Every write here ends by restarting the app (see `restart_app.dart`) —
/// restore and erase both replace what is underneath the running
/// `AppDatabase` connection, and there is no supported way to swap that out
/// from under `get_it`'s cached singleton in place.
@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db, this._config, this._local, this._sessions);

  final AppDatabase _db;
  final AppConfig _config;
  final BackupLocalDataSource _local;
  final BackupSessionStorage _sessions;

  @override
  Future<BackupInfo> describeBackup() async {
    final storage = await inspectStorage(_config);
    return BackupInfo(
      lastBackupAt: _sessions.readLastBackupAt(),
      lastRestoreAt: _sessions.readLastRestoreAt(),
      databaseSizeBytes: storage.sizeBytes,
      storagePath: storage.path,
    );
  }

  @override
  Future<bool> exportBackup() => guardDatabase(
    () async {
      final bytes = await exportBackupBytes(_db, _config);
      final timestamp = DateTime.now();
      final stamp =
          '${timestamp.year}${_two(timestamp.month)}${_two(timestamp.day)}'
          '-${_two(timestamp.hour)}${_two(timestamp.minute)}';
      final saved = await saveBinaryFile(
        filename: 'khulla-backup-$stamp.sqlite',
        bytes: bytes,
        mimeType: 'application/vnd.sqlite3',
      );
      if (saved == null) return false;
      await _sessions.saveLastBackupAt(timestamp);
      return true;
    },
    source: '$_source.exportBackup',
  );

  @override
  Future<bool> restoreBackup() => guardDatabase(
    () async {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Khulla backup', extensions: ['sqlite']),
        ],
      );
      if (picked == null) return false;

      final bytes = await picked.readAsBytes();
      await importBackupBytes(_db, _config, bytes);
      await _sessions.saveLastRestoreAt(DateTime.now());
      restartApp();
      return true;
    },
    source: '$_source.restoreBackup',
  );

  @override
  Future<void> eraseCatalogue() => guardDatabase(
    () async {
      await _local.wipeAllTables();
      restartApp();
    },
    source: '$_source.eraseCatalogue',
  );

  static String _two(int value) => value.toString().padLeft(2, '0');
}
