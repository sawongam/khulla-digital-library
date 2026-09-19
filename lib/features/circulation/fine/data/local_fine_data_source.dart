// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/fine/data/fine_local_data_source.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';

/// Drift-backed [FineLocalDataSource].
///
/// Joins members and, via the loan chain, title names for list display.
/// The outstanding-only filter compares assessed, paid and waived in SQL.
@LazySingleton(as: FineLocalDataSource)
class LocalFineDataSource implements FineLocalDataSource {
  LocalFineDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalFineDataSource';

  static const String _selectColumns = '''
f.*,
m.full_name AS member_name,
t.title AS title_name
''';

  static const String _fromClause = '''
FROM fines f
JOIN members m ON m.id = f.member_id
LEFT JOIN loans l ON l.id = f.loan_id
LEFT JOIN copies c ON c.id = l.copy_id
LEFT JOIN titles t ON t.id = c.title_id
''';

  @override
  Future<FineListResult> findFines(FineQuery query) => guardDatabase(
    () async {
      final where = StringBuffer('1 = 1');
      final variables = <Variable<Object>>[];

      if (query.memberId != null) {
        where.write(' AND f.member_id = ?');
        variables.add(Variable<String>(query.memberId));
      }
      if (query.outstandingOnly) {
        where.write(' AND f.paid + f.waived < f.assessed');
      }

      final needle = query.search.trim().toLowerCase();
      if (needle.isNotEmpty) {
        where.write(
          ' AND (LOWER(m.full_name) LIKE ? OR LOWER(t.title) LIKE ?)',
        );
        variables.addAll([
          Variable<String>('%$needle%'),
          Variable<String>('%$needle%'),
        ]);
      }

      _appendStatusFilter(where, query.status);

      final order = _orderClause(query);
      final countSql = 'SELECT COUNT(*) AS total $_fromClause WHERE $where';
      final listSql =
          '''
SELECT $_selectColumns
$_fromClause
WHERE $where
ORDER BY $order
LIMIT ? OFFSET ?
''';

      final totalCount = await _db
          .customSelect(countSql, variables: variables)
          .getSingle()
          .then((row) => row.read<int>('total'));

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
        totalCount: totalCount,
      );
    },
    source: '$_source.findFines',
  );

  void _appendStatusFilter(StringBuffer where, FineStatus? status) {
    if (status == null) return;
    switch (status) {
      case FineStatus.unpaid:
        where.write(' AND f.paid + f.waived < f.assessed');
      case FineStatus.waived:
        where.write(
          ' AND f.paid + f.waived >= f.assessed AND f.waived > 0',
        );
      case FineStatus.paid:
        where.write(
          ' AND f.paid + f.waived >= f.assessed AND f.waived = 0',
        );
    }
  }

  String _orderClause(FineQuery query) {
    final dir = query.sortAscending ? 'ASC' : 'DESC';
    return switch (query.sortColumn) {
      'memberName' => 'm.full_name $dir',
      'assessed' => 'f.assessed $dir',
      'outstanding' => '(f.assessed - f.paid - f.waived) $dir',
      'raisedAt' => 'f.raised_at $dir',
      _ => 'f.raised_at $dir',
    };
  }

  Fine _mapRow(QueryRow row) => Fine(
    id: row.read<String>('id'),
    memberId: row.read<String>('member_id'),
    loanId: row.readNullable<String>('loan_id'),
    reason: FineReason.values.byName(row.read<String>('reason')),
    assessed: Money(row.read<int>('assessed')),
    paid: Money(row.read<int>('paid')),
    waived: Money(row.read<int>('waived')),
    raisedAt: row.read<DateTime>('raised_at'),
    settledAt: row.readNullable<DateTime>('settled_at'),
    note: row.readNullable<String>('note'),
    createdAt: row.read<DateTime>('created_at'),
    updatedAt: row.read<DateTime>('updated_at'),
    memberName: row.read<String>('member_name'),
    titleName: row.readNullable<String>('title_name'),
  );

  @override
  Future<Fine?> findFineById(String id) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE f.id = ?
''',
            variables: [Variable<String>(id)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findFineById',
  );

  @override
  Future<Money> outstandingForMember(String memberId) => guardDatabase(
    () async {
      final row = await _db
          .customSelect(
            '''
SELECT COALESCE(SUM(assessed - paid - waived), 0) AS outstanding
FROM fines
WHERE member_id = ?
  AND paid + waived < assessed
''',
            variables: [Variable<String>(memberId)],
          )
          .getSingle();
      return Money(row.read<int>('outstanding'));
    },
    source: '$_source.outstandingForMember',
  );
}
