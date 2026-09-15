// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/loan/data/loan_local_data_source.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/loan_status.dart';

@LazySingleton(as: LoanLocalDataSource)
class LocalLoanDataSource implements LoanLocalDataSource {
  LocalLoanDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalLoanDataSource';

  static const String _selectColumns = '''
l.*,
c.barcode AS barcode,
c.title_id AS title_id,
t.title AS title_name,
m.full_name AS member_name
''';

  static const String _fromClause = '''
FROM loans l
JOIN copies c ON c.id = l.copy_id
JOIN titles t ON t.id = c.title_id
JOIN members m ON m.id = l.member_id
''';

  @override
  Future<LoanListResult> findLoans(LoanQuery query) => guardDatabase(
    () => _queryLoans(query, openOnly: query.openOnly),
    source: '$_source.findLoans',
  );

  @override
  Future<LoanListResult> findOpenLoans(LoanQuery query) => guardDatabase(
    () => _queryLoans(query.copyWith(openOnly: true), openOnly: true),
    source: '$_source.findOpenLoans',
  );

  Future<LoanListResult> _queryLoans(
    LoanQuery query, {
    required bool openOnly,
  }) async {
    final where = StringBuffer('1 = 1');
    final variables = <Variable<Object>>[];

    if (openOnly) {
      where.write(' AND l.returned_at IS NULL');
    }
    if (query.memberId != null) {
      where.write(' AND l.member_id = ?');
      variables.add(Variable<String>(query.memberId));
    }
    if (query.copyId != null) {
      where.write(' AND l.copy_id = ?');
      variables.add(Variable<String>(query.copyId));
    }
    if (query.titleId != null) {
      where.write(' AND c.title_id = ?');
      variables.add(Variable<String>(query.titleId));
    }

    final needle = query.search.trim().toLowerCase();
    if (needle.isNotEmpty) {
      where.write(
        ' AND (LOWER(c.barcode) LIKE ? OR LOWER(t.title) LIKE ?'
        ' OR LOWER(m.full_name) LIKE ?)',
      );
      variables.addAll([
        Variable<String>('%$needle%'),
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

    return (items: rows.map(_mapRow).toList(), totalCount: totalCount);
  }

  void _appendStatusFilter(StringBuffer where, LoanStatus? status) {
    if (status == null) return;
    final today = _todaySql();
    switch (status) {
      case LoanStatus.returned:
        where.write(' AND l.returned_at IS NOT NULL');
      case LoanStatus.overdue:
        where.write(
          " AND l.returned_at IS NULL AND l.due_at < '$today'",
        );
      case LoanStatus.dueToday:
        where.write(
          " AND l.returned_at IS NULL AND l.due_at = '$today'",
        );
      case LoanStatus.onLoan:
        where.write(
          " AND l.returned_at IS NULL AND l.due_at > '$today'",
        );
    }
  }

  String _orderClause(LoanQuery query) {
    final dir = query.sortAscending ? 'ASC' : 'DESC';
    return switch (query.sortColumn) {
      'dueAt' => 'l.due_at $dir',
      'checkedOutAt' => 'l.checked_out_at $dir',
      'memberName' => 'm.full_name $dir',
      'titleName' => 't.title $dir',
      'barcode' => 'c.barcode $dir',
      _ => 'l.checked_out_at $dir',
    };
  }

  String _todaySql() {
    final today = dateOnly(DateTime.now());
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }

  Loan _mapRow(QueryRow row) {
    final returnRaw = row.readNullable<String>('return_condition');
    return Loan(
      id: row.read<String>('id'),
      copyId: row.read<String>('copy_id'),
      memberId: row.read<String>('member_id'),
      checkedOutAt: row.read<DateTime>('checked_out_at'),
      dueAt: DateTime.parse(row.read<String>('due_at')),
      returnedAt: row.readNullable<DateTime>('returned_at'),
      renewalCount: row.read<int>('renewal_count'),
      returnCondition: returnRaw == null
          ? null
          : CopyCondition.values.byName(returnRaw),
      checkedOutByStaffId: row.readNullable<String>('checked_out_by_staff_id'),
      returnedByStaffId: row.readNullable<String>('returned_by_staff_id'),
      ruleLoanPeriodDays: row.read<int>('rule_loan_period_days'),
      ruleFinePerDay: Money(row.read<int>('rule_fine_per_day')),
      ruleGraceDays: row.read<int>('rule_grace_days'),
      ruleMaximumFine: Money(row.read<int>('rule_maximum_fine')),
      createdAt: row.read<DateTime>('created_at'),
      barcode: row.read<String>('barcode'),
      titleId: row.read<String>('title_id'),
      titleName: row.read<String>('title_name'),
      memberName: row.read<String>('member_name'),
    );
  }

  @override
  Future<Loan?> findLoanById(String id) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE l.id = ?
''',
            variables: [Variable<String>(id)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findLoanById',
  );

  @override
  Future<Loan?> findOpenLoanByCopyId(String copyId) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE l.copy_id = ? AND l.returned_at IS NULL
''',
            variables: [Variable<String>(copyId)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findOpenLoanByCopyId',
  );

  @override
  Future<Loan?> findOpenLoanByBarcode(String barcode) => guardDatabase(
    () async {
      final trimmed = barcode.trim();
      if (trimmed.isEmpty) return null;
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE LOWER(c.barcode) = LOWER(?) AND l.returned_at IS NULL
''',
            variables: [Variable<String>(trimmed)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findOpenLoanByBarcode',
  );

  @override
  Future<int> countOpenLoansForMember(String memberId) => guardDatabase(
    () {
      final count = _db.loans.id.count();
      return (_db.selectOnly(_db.loans)
            ..addColumns([count])
            ..where(
              _db.loans.memberId.equals(memberId) &
                  _db.loans.returnedAt.isNull(),
            ))
          .getSingle()
          .then((row) => row.read(count) ?? 0);
    },
    source: '$_source.countOpenLoansForMember',
  );

  @override
  Future<bool> memberHasOverdueLoans(String memberId) => guardDatabase(
    () async {
      final today = _todaySql();
      final row = await _db
          .customSelect(
            '''
SELECT 1
FROM loans
WHERE member_id = ?
  AND returned_at IS NULL
  AND due_at < ?
LIMIT 1
''',
            variables: [
              Variable<String>(memberId),
              Variable<String>(today),
            ],
          )
          .getSingleOrNull();
      return row != null;
    },
    source: '$_source.memberHasOverdueLoans',
  );
}
