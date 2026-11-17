// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/fts_filter.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/copy/data/copy_local_data_source.dart';
import 'package:khulla/features/catalog/copy/data/local_copy_data_source.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/mappers/title_row_mappers.dart';
import 'package:khulla/features/catalog/title/data/title_local_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';

/// Drift-backed [TitleLocalDataSource].
///
/// List and detail queries use custom SQL so copy and availability counts
/// arrive in one round trip. Sort column names match [TitleQuery.sortColumn].
@LazySingleton(as: TitleLocalDataSource)
class LocalTitleDataSource implements TitleLocalDataSource {
  /// The initial-copies write reuses [LocalCopyDataSource] over the same
  /// connection, so barcode allocation and clash checks run inside the
  /// title's transaction.
  LocalTitleDataSource(this._db) : _copies = LocalCopyDataSource(_db);

  final AppDatabase _db;
  final CopyLocalDataSource _copies;

  static const String _source = 'LocalTitleDataSource';

  /// The `titles_fts` columns a search looks in.
  static const List<String> _searchColumns = [
    'title',
    'author',
    'isbn',
    'publisher',
    'shelf',
  ];

  /// Copy counts as per-row subqueries over `copies_title`, not a joined
  /// `GROUP BY`. A page sorted by title can then read its rows off
  /// `titles_sort` and stop at the limit, instead of grouping every title in
  /// the catalogue first.
  static const String _selectColumns = '''
t.*,
f.name AS format_name,
f.code AS format_code,
(SELECT COUNT(*) FROM copies c
 WHERE c.title_id = t.id AND c.archived_at IS NULL) AS copy_count,
(SELECT COUNT(*) FROM copies c
 WHERE c.title_id = t.id AND c.archived_at IS NULL
   AND c.status = 'available') AS available_count
''';

  static const String _hasAvailableCopy = '''
EXISTS (SELECT 1 FROM copies c
        WHERE c.title_id = t.id AND c.archived_at IS NULL
          AND c.status = 'available')''';

  @override
  Future<TitleListResult> findTitles(TitleQuery query) => guardDatabase(
    () async {
      final where = StringBuffer(
        query.archived ? 't.archived_at IS NOT NULL' : 't.archived_at IS NULL',
      );
      final variables = <Variable<Object>>[];

      final search = ftsFilter(
        search: query.search,
        table: 'titles_fts',
        columns: _searchColumns,
        rowid: 't.rowid',
      );
      if (search != null) {
        where.write(' AND ${search.sql}');
        variables.addAll(search.variables);
      }
      if (query.formatId != null) {
        where.write(' AND t.format_id = ?');
        variables.add(Variable<String>(query.formatId));
      }
      if (query.availableOnly) {
        where.write(' AND $_hasAvailableCopy');
      }

      final order = _orderClause(query);

      final countSql = 'SELECT COUNT(*) AS total FROM titles t WHERE $where';

      final listSql =
          '''
SELECT $_selectColumns
FROM titles t
JOIN title_formats f ON f.id = t.format_id
WHERE $where
ORDER BY $order
LIMIT ? OFFSET ?''';

      final countRow = await _db
          .customSelect(countSql, variables: variables)
          .getSingle();
      final totalCount = countRow.read<int>('total');

      final listVariables = [
        ...variables,
        Variable<int>(query.limit),
        Variable<int>(query.offset),
      ];
      final rows = await _db
          .customSelect(listSql, variables: listVariables)
          .get();

      final items = rows.map(_mapRow).toList();
      return (items: items, totalCount: totalCount);
    },
    source: '$_source.findTitles',
  );

  String _orderClause(TitleQuery query) {
    final dir = query.sortAscending ? 'ASC' : 'DESC';
    return switch (query.sortColumn) {
      'author' => 't.author $dir',
      'publisher' => 't.publisher $dir',
      'year' => 't.published_year $dir',
      'copies' => 'copy_count $dir',
      'available' => 'available_count $dir',
      'title' => 't.title $dir',
      _ => 't.created_at $dir',
    };
  }

  Title _mapRow(QueryRow row) => Title(
    id: row.read<String>('id'),
    title: row.read<String>('title'),
    author: row.read<String>('author'),
    isbn: row.readNullable<String>('isbn'),
    publisher: row.readNullable<String>('publisher'),
    publishedYear: row.readNullable<int>('published_year'),
    edition: row.readNullable<String>('edition'),
    language: row.read<String>('language'),
    pages: row.readNullable<int>('pages'),
    description: row.readNullable<String>('description'),
    shelf: row.readNullable<String>('shelf'),
    formatId: row.read<String>('format_id'),
    formatName: row.read<String>('format_name'),
    formatCode: row.readNullable<String>('format_code'),
    lendable: row.read<bool>('lendable'),
    replacementCost: Money(row.read<int>('replacement_cost')),
    createdAt: row.read<DateTime>('created_at'),
    updatedAt: row.read<DateTime>('updated_at'),
    archivedAt: row.readNullable<DateTime>('archived_at'),
    copyCount: row.read<int>('copy_count'),
    availableCount: row.read<int>('available_count'),
  );

  @override
  Future<Title?> findTitleById(String id) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
FROM titles t
JOIN title_formats f ON f.id = t.format_id
WHERE t.id = ?
''',
            variables: [Variable<String>(id)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findTitleById',
  );

  @override
  Future<Title> insertTitle(Title title) => guardDatabase(
    () async {
      await _db.into(_db.titles).insert(title.toCompanion());
      return (await findTitleById(title.id))!;
    },
    source: '$_source.insertTitle',
  );

  @override
  Future<Title> insertTitleWithCopies(Title title, List<Copy> copies) =>
      guardDatabase(
        () => _db.transaction(() async {
          await _db.into(_db.titles).insert(title.toCompanion());
          for (final copy in copies) {
            await _copies.insertCopy(
              copy: copy,
              barcodeOverride: copy.barcode,
            );
          }
          return (await findTitleById(title.id))!;
        }),
        source: '$_source.insertTitleWithCopies',
      );

  @override
  Future<Title> updateTitle(Title title) => guardDatabase(
    () async {
      await (_db.update(
        _db.titles,
      )..where((t) => t.id.equals(title.id))).write(title.toCompanion());
      return (await findTitleById(title.id))!;
    },
    source: '$_source.updateTitle',
  );

  @override
  Future<void> archiveTitle(String id, DateTime archivedAt) => guardDatabase(
    () => _db.transaction(() async {
      // A copy out on loan or held for a member cannot leave circulation
      // under its borrower, so the title waits until they are back.
      final inUse = _db.copies.id.count();
      final row =
          await (_db.selectOnly(_db.copies)
                ..addColumns([inUse])
                ..where(
                  _db.copies.titleId.equals(id) &
                      _db.copies.archivedAt.isNull() &
                      _db.copies.status.isIn([
                        CopyStatus.onLoan.name,
                        CopyStatus.reserved.name,
                      ]),
                ))
              .getSingle();
      // Status is checked first, but an open loan row is the fact that
      // matters: a copy whose status drifted must not slip through.
      final openLoans = await _db
          .customSelect(
            'SELECT COUNT(*) AS n FROM loans l JOIN copies c ON c.id = l.copy_id '
            'WHERE c.title_id = ? AND l.returned_at IS NULL',
            variables: [Variable<String>(id)],
            readsFrom: {_db.loans, _db.copies},
          )
          .getSingle();
      if ((row.read(inUse) ?? 0) > 0 || openLoans.read<int>('n') > 0) {
        throw const ConflictException.because(
          AppErrorReason.titleHasCopiesOnLoan,
        );
      }
      final now = DateTime.now();
      // The copies take the title's own stamp so a restore can tell them from
      // copies that were withdrawn on their own earlier.
      await (_db.update(_db.copies)..where(
            (c) => c.titleId.equals(id) & c.archivedAt.isNull(),
          ))
          .write(
            CopiesCompanion(
              archivedAt: Value(archivedAt),
              updatedAt: Value(now),
            ),
          );
      await (_db.update(_db.titles)..where((t) => t.id.equals(id))).write(
        TitlesCompanion(
          archivedAt: Value(archivedAt),
          updatedAt: Value(now),
        ),
      );
    }),
    source: '$_source.archiveTitle',
  );

  @override
  Future<void> restoreTitle(String id) => guardDatabase(
    () => _db.transaction(() async {
      final title = await (_db.select(
        _db.titles,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (title == null) {
        throw const NotFoundException.because(AppErrorReason.titleNotFound);
      }
      final archivedAt = title.archivedAt;
      final now = DateTime.now();
      if (archivedAt != null) {
        await (_db.update(_db.copies)..where(
              (c) => c.titleId.equals(id) & c.archivedAt.equals(archivedAt),
            ))
            .write(
              CopiesCompanion(
                archivedAt: const Value(null),
                updatedAt: Value(now),
              ),
            );
      }
      await (_db.update(_db.titles)..where((t) => t.id.equals(id))).write(
        TitlesCompanion(
          archivedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );
    }),
    source: '$_source.restoreTitle',
  );

  @override
  Future<bool> hasDependentCopies(String titleId) => guardDatabase(
    () async {
      final count = _db.copies.id.count();
      final row =
          await (_db.selectOnly(_db.copies)
                ..addColumns([count])
                ..where(_db.copies.titleId.equals(titleId)))
              .getSingle();
      return (row.read(count) ?? 0) > 0;
    },
    source: '$_source.hasDependentCopies',
  );

  @override
  Future<void> deleteTitle(String id) => guardDatabase(
    () async {
      await (_db.delete(_db.titles)..where((t) => t.id.equals(id))).go();
    },
    source: '$_source.deleteTitle',
  );
}
