// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';

const String _source = 'BackupLocalDataSource';

/// The one operation web restore and erase - on every platform - share:
/// wiping every table with no per-table knowledge of what it holds.
///
/// Generic over `AppDatabase.allTables`, the same reasoning
/// `backup_platform_web.dart`'s restore uses: with foreign-key checks
/// suspended, table order does not matter, so nothing here has to be
/// hand-written per table and nothing has to change when a table is added.
@lazySingleton
class BackupLocalDataSource {
  BackupLocalDataSource(this._db);

  final AppDatabase _db;

  Future<void> wipeAllTables() => guardDatabase(
    () async {
      await _db.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await _db.transaction(() async {
          for (final table in _db.allTables) {
            await _db.customStatement(
              'DELETE FROM ${table.actualTableName}',
            );
          }
        });
      } finally {
        await _db.customStatement('PRAGMA foreign_keys = ON');
      }
    },
    source: '$_source.wipeAllTables',
  );
}
