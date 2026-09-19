// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/catalog/title/data/mappers/title_format_row_mappers.dart';
import 'package:khulla/features/catalog/title/data/title_format_local_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';

/// Drift-backed [TitleFormatLocalDataSource].
@LazySingleton(as: TitleFormatLocalDataSource)
class LocalTitleFormatDataSource implements TitleFormatLocalDataSource {
  LocalTitleFormatDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalTitleFormatDataSource';

  @override
  Future<int> countFormats() => guardDatabase(
    () {
      final count = _db.titleFormats.id.count();
      return (_db.selectOnly(
        _db.titleFormats,
      )..addColumns([count])).getSingle().then((row) => row.read(count) ?? 0);
    },
    source: '$_source.countFormats',
  );

  @override
  Future<List<TitleFormat>> findActiveFormats() => guardDatabase(
    () async {
      final rows =
          await (_db.select(_db.titleFormats)
                ..where((format) => format.archivedAt.isNull())
                ..orderBy([
                  (format) => OrderingTerm(expression: format.sortOrder),
                ]))
              .get();
      return rows.map((row) => row.toDomain()).toList();
    },
    source: '$_source.findActiveFormats',
  );

  @override
  Future<TitleFormat> insertFormat(TitleFormat format) => guardDatabase(
    () async {
      await _db.into(_db.titleFormats).insert(format.toCompanion());
      return format;
    },
    source: '$_source.insertFormat',
  );

  @override
  Future<TitleFormat> updateFormat(TitleFormat format) => guardDatabase(
    () async {
      final count =
          await (_db.update(_db.titleFormats)
                ..where((row) => row.id.equals(format.id)))
              .write(TitleFormatsCompanion(name: Value(format.name)));
      if (count == 0) {
        throw const NotFoundException();
      }
      return format;
    },
    source: '$_source.updateFormat',
  );

  @override
  Future<void> archiveFormat(String id, DateTime archivedAt) => guardDatabase(
    () async {
      final count =
          await (_db.update(_db.titleFormats)..where(
                (row) => row.id.equals(id) & row.archivedAt.isNull(),
              ))
              .write(TitleFormatsCompanion(archivedAt: Value(archivedAt)));
      if (count == 0) {
        throw const NotFoundException();
      }
    },
    source: '$_source.archiveFormat',
  );
}
