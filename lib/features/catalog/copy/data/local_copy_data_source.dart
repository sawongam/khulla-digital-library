// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/catalog/copy/data/copy_local_data_source.dart';
import 'package:khulla/features/catalog/copy/data/mappers/copy_row_mappers.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/settings/data/tables/library_settings.dart';

/// Drift-backed [CopyLocalDataSource].
///
/// List queries join titles and the current open loan for borrower and due
/// date. [insertCopy] can allocate the next barcode from library settings.
@LazySingleton(as: CopyLocalDataSource)
class LocalCopyDataSource implements CopyLocalDataSource {
  LocalCopyDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalCopyDataSource';

  @override
  Future<CopyListResult> findCopies(CopyQuery query) => guardDatabase(
    () async {
      final needle = query.search.trim().toLowerCase();
      final where = StringBuffer(
        query.archived ? 'c.archived_at IS NOT NULL' : 'c.archived_at IS NULL',
      );
      final variables = <Variable<Object>>[];

      if (needle.isNotEmpty) {
        where.write(
          ' AND (LOWER(c.barcode) LIKE ? OR LOWER(t.title) LIKE ?)',
        );
        variables.addAll([
          Variable<String>('%$needle%'),
          Variable<String>('%$needle%'),
        ]);
      }
      if (query.titleId case final titleId?) {
        where.write(' AND c.title_id = ?');
        variables.add(Variable<String>(titleId));
      }
      if (query.statuses.isNotEmpty) {
        where.write(
          ' AND c.status IN (${List.filled(query.statuses.length, '?').join(', ')})',
        );
        for (final status in query.statuses) {
          variables.add(Variable<String>(status.name));
        }
      }

      final order = switch (query.sortColumn) {
        'title' => 't.title ${query.sortAscending ? 'ASC' : 'DESC'}',
        'shelf' => 'c.shelf ${query.sortAscending ? 'ASC' : 'DESC'}',
        'status' => 'c.status ${query.sortAscending ? 'ASC' : 'DESC'}',
        'barcode' => 'c.barcode ${query.sortAscending ? 'ASC' : 'DESC'}',
        _ => 'c.created_at ${query.sortAscending ? 'ASC' : 'DESC'}',
      };

      final countSql =
          'SELECT COUNT(*) AS total FROM copies c JOIN titles t ON t.id = c.title_id WHERE $where';
      final listSql =
          '''
SELECT c.*,
       t.title AS title_name,
       m.full_name AS borrower,
       l.due_at AS due_at
FROM copies c
JOIN titles t ON t.id = c.title_id
LEFT JOIN loans l ON l.copy_id = c.id AND l.returned_at IS NULL
LEFT JOIN members m ON m.id = l.member_id
WHERE $where
ORDER BY $order
LIMIT ? OFFSET ?''';

      final total =
          (await _db.customSelect(countSql, variables: variables).getSingle())
              .read<int>('total');

      final rows = await _db
          .customSelect(
            listSql,
            variables: [
              ...variables,
              Variable<int>(query.limit),
              Variable<int>(query.offset),
            ],
          )
          .get();

      return (
        items: rows.map(_mapRow).toList(),
        totalCount: total,
      );
    },
    source: '$_source.findCopies',
  );

  Copy _mapRow(QueryRow row) {
    final dueRaw = row.readNullable<String>('due_at');
    return Copy(
      id: row.read<String>('id'),
      barcode: row.read<String>('barcode'),
      titleId: row.read<String>('title_id'),
      titleName: row.read<String>('title_name'),
      shelf: row.readNullable<String>('shelf') ?? '',
      status: CopyStatus.values.byName(row.read<String>('status')),
      acquiredAt: row.read<DateTime>('acquired_at'),
      notes: row.readNullable<String>('notes'),
      archivedAt: row.readNullable<DateTime>('archived_at'),
      borrower: row.readNullable<String>('borrower'),
      dueAt: dueRaw == null ? null : DateTime.parse(dueRaw),
    );
  }

  @override
  Future<List<Copy>> findCopiesByTitleId(String titleId) => guardDatabase(
    () async {
      final result = await findCopies(CopyQuery(titleId: titleId, limit: 1000));
      return result.items;
    },
    source: '$_source.findCopiesByTitleId',
  );

  @override
  Future<Copy?> findCopyByBarcode(String barcode) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT c.*,
       t.title AS title_name,
       m.full_name AS borrower,
       l.due_at AS due_at
FROM copies c
JOIN titles t ON t.id = c.title_id
LEFT JOIN loans l ON l.copy_id = c.id AND l.returned_at IS NULL
LEFT JOIN members m ON m.id = l.member_id
WHERE c.archived_at IS NULL AND c.barcode = ?
''',
            variables: [Variable<String>(barcode.trim())],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findCopyByBarcode',
  );

  @override
  Future<Copy?> findCopyHoldingBarcode(String barcode) => guardDatabase(
    () => _holderOf(barcode),
    source: '$_source.findCopyHoldingBarcode',
  );

  Future<Copy?> _holderOf(String barcode, {String? exceptId}) async {
    final rows = await _db
        .customSelect(
          '''
SELECT c.*,
       t.title AS title_name,
       NULL AS borrower,
       NULL AS due_at
FROM copies c
JOIN titles t ON t.id = c.title_id
WHERE c.barcode = ?
''',
          variables: [Variable<String>(barcode.trim())],
        )
        .get();
    for (final row in rows) {
      final copy = _mapRow(row);
      if (copy.id != exceptId) return copy;
    }
    return null;
  }

  /// Refuses [barcode] when another copy already holds it, saying which.
  Future<void> _ensureBarcodeFree(String barcode, {String? exceptId}) async {
    final holder = await _holderOf(barcode, exceptId: exceptId);
    if (holder == null) return;
    throw DuplicateRecordException.because(
      holder.archivedAt == null
          ? AppErrorReason.barcodeInUse
          : AppErrorReason.barcodeInUseByArchivedCopy,
      args: [barcode.trim(), holder.titleName],
    );
  }

  @override
  Future<Copy?> findCopyById(String id) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT c.*,
       t.title AS title_name,
       m.full_name AS borrower,
       l.due_at AS due_at
FROM copies c
JOIN titles t ON t.id = c.title_id
LEFT JOIN loans l ON l.copy_id = c.id AND l.returned_at IS NULL
LEFT JOIN members m ON m.id = l.member_id
WHERE c.id = ?
''',
            variables: [Variable<String>(id)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findCopyById',
  );

  @override
  Future<Copy> insertCopy({
    required Copy copy,
    String? barcodeOverride,
  }) => guardDatabase(
    () => _db.transaction(() async {
      final now = DateTime.now();
      var barcode = barcodeOverride?.trim();
      if (barcode == null || barcode.isEmpty) {
        final settings =
            await (_db.select(_db.librarySettings)..where(
                  (s) => s.id.equals(LibrarySettings.singletonId),
                ))
                .getSingle();
        // Skip over numbers a hand-typed or archived copy already holds, or
        // the counter would stall on the first clash and fail every add after.
        var next = settings.barcodeNextValue;
        while (await _holderOf('${settings.barcodePrefix}$next') != null) {
          next++;
        }
        barcode = '${settings.barcodePrefix}$next';
        await (_db.update(_db.librarySettings)..where(
              (s) => s.id.equals(LibrarySettings.singletonId),
            ))
            .write(
              LibrarySettingsCompanion(
                barcodeNextValue: Value(next + 1),
                updatedAt: Value(now),
              ),
            );
      } else {
        await _ensureBarcodeFree(barcode);
      }

      final toInsert = copy.copyWith(barcode: barcode);
      await _db
          .into(_db.copies)
          .insert(
            toInsert.toCompanion(createdAt: now, updatedAt: now),
          );
      return (await findCopyById(toInsert.id))!;
    }),
    source: '$_source.insertCopy',
  );

  @override
  Future<Copy> updateCopy(Copy copy) => guardDatabase(
    () async {
      final now = DateTime.now();
      await (_db.update(_db.copies)..where((c) => c.id.equals(copy.id))).write(
        copy.toCompanion(createdAt: now, updatedAt: now),
      );
      return (await findCopyById(copy.id))!;
    },
    source: '$_source.updateCopy',
  );

  @override
  Future<Copy> updateCopyDetails(
    String id, {
    required String barcode,
    required String shelf,
    String? notes,
  }) => guardDatabase(
    () => _db.transaction(() async {
      final trimmed = barcode.trim();
      if (trimmed.isEmpty) {
        throw const InvalidInputException.because(
          AppErrorReason.barcodeRequired,
        );
      }
      if (await findCopyById(id) == null) {
        throw const NotFoundException.because(AppErrorReason.copyNotFound);
      }
      await _ensureBarcodeFree(trimmed, exceptId: id);
      final trimmedNotes = notes?.trim();
      await (_db.update(_db.copies)..where((c) => c.id.equals(id))).write(
        CopiesCompanion(
          barcode: Value(trimmed),
          shelf: Value(shelf.trim().isEmpty ? null : shelf.trim()),
          notes: Value(
            trimmedNotes == null || trimmedNotes.isEmpty ? null : trimmedNotes,
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return (await findCopyById(id))!;
    }),
    source: '$_source.updateCopyDetails',
  );

  @override
  Future<void> restoreCopy(String id) => guardDatabase(
    () => _db.transaction(() async {
      final copy = await findCopyById(id);
      if (copy == null) {
        throw const NotFoundException.because(AppErrorReason.copyNotFound);
      }
      final title = await (_db.select(
        _db.titles,
      )..where((t) => t.id.equals(copy.titleId))).getSingleOrNull();
      if (title?.archivedAt != null) {
        throw const ConflictException.because(
          AppErrorReason.restoreTitleFirst,
        );
      }
      await (_db.update(_db.copies)..where((c) => c.id.equals(id))).write(
        CopiesCompanion(
          archivedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }),
    source: '$_source.restoreCopy',
  );

  @override
  Future<void> archiveCopy(String id, DateTime archivedAt) => guardDatabase(
    () async {
      await (_db.update(_db.copies)..where((c) => c.id.equals(id))).write(
        CopiesCompanion(
          archivedAt: Value(archivedAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
    },
    source: '$_source.archiveCopy',
  );
}
