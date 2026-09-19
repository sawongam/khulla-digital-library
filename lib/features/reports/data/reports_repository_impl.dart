// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart'
    show dateOnly;
import 'package:khulla/features/reports/domain/models/reports_summary.dart';
import 'package:khulla/features/reports/domain/reports_repository.dart';

const String _source = 'ReportsRepositoryImpl';

/// [ReportsRepository] over the local catalogue.
///
/// The monthly trend charts and the overdue/acquisitions exports read a
/// fixed eight-month or current-snapshot window regardless of the selected
/// period — only the stat tiles, fine totals and rankings are scoped to
/// `[start, end)`. See [ReportsRepository.loadSummary].
///
/// The overdue snapshot is capped at the 100 most overdue loans
/// (`ORDER BY due_at ASC LIMIT 100`): the CSV export writes exactly what
/// this snapshot holds, so a larger overdue backlog is silently truncated.
@LazySingleton(as: ReportsRepository)
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._db);

  final AppDatabase _db;

  static const DateOnlyConverter _dates = DateOnlyConverter();

  @override
  Future<ReportsSummary> loadSummary({
    required DateTime start,
    required DateTime end,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) => guardDatabase(
    () async {
      final monthsBack = DateTime(end.year, end.month - 7);

      return ReportsSummary(
        borrowedCount: await _countLoansByColumn('checked_out_at', start, end),
        borrowedPreviousCount: await _countLoansByColumn(
          'checked_out_at',
          previousStart,
          previousEnd,
        ),
        returnedCount: await _countLoansByColumn('returned_at', start, end),
        returnedPreviousCount: await _countLoansByColumn(
          'returned_at',
          previousStart,
          previousEnd,
        ),
        newMembersCount: await _countNewMembers(start, end),
        newMembersPreviousCount: await _countNewMembers(
          previousStart,
          previousEnd,
        ),
        finesRaised: await _sumFines('assessed', 'raised_at', start, end),
        finesRaisedPrevious: await _sumFines(
          'assessed',
          'raised_at',
          previousStart,
          previousEnd,
        ),
        finesCollected: await _sumSettledFines('paid', start, end),
        finesWaived: await _sumSettledFines('waived', start, end),
        circulationBorrowedByMonth: await _loansByMonth(
          'checked_out_at',
          monthsBack,
        ),
        circulationReturnedByMonth: await _loansByMonth(
          'returned_at',
          monthsBack,
        ),
        membershipGrowthByMonth: await _membershipGrowthByMonth(monthsBack),
        collectionByFormat: await _collectionByFormat(),
        topTitles: await _topTitles(start, end),
        topMembers: await _topMembers(start, end),
        overdueLoans: await _overdueLoans(),
        acquisitionsByMonth: await _acquisitionsByMonth(monthsBack),
      );
    },
    source: '$_source.loadSummary',
  );

  Future<int> _countLoansByColumn(
    String column,
    DateTime start,
    DateTime end,
  ) => _db
      .customSelect(
        'SELECT COUNT(*) AS c FROM loans WHERE $column >= ? AND $column < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => row.read<int>('c'));

  Future<int> _countNewMembers(DateTime start, DateTime end) => _db
      .customSelect(
        'SELECT COUNT(*) AS c FROM members '
        'WHERE joined_at >= ? AND joined_at < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => row.read<int>('c'));

  Future<Money> _sumFines(
    String column,
    String dateColumn,
    DateTime start,
    DateTime end,
  ) => _db
      .customSelect(
        'SELECT COALESCE(SUM($column), 0) AS total FROM fines '
        'WHERE $dateColumn >= ? AND $dateColumn < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => Money(row.read<int>('total')));

  /// Fines fully settled within `[start, end)` — the only point a fine's
  /// paid/waived split is known to be final, since a payment carries no
  /// timestamp of its own.
  Future<Money> _sumSettledFines(
    String column,
    DateTime start,
    DateTime end,
  ) => _db
      .customSelect(
        'SELECT COALESCE(SUM($column), 0) AS total FROM fines '
        'WHERE settled_at IS NOT NULL AND settled_at >= ? AND settled_at < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => Money(row.read<int>('total')));

  Future<List<ReportsMonthCount>> _loansByMonth(
    String column,
    DateTime since,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT strftime('%Y-%m-01', $column) AS ym, COUNT(*) AS c
FROM loans
WHERE $column >= ?
GROUP BY ym
ORDER BY ym
''',
          variables: [Variable<DateTime>(since)],
        )
        .get();
    return [
      for (final row in rows)
        (
          month: DateTime.parse(row.read<String>('ym')),
          count: row.read<int>('c'),
        ),
    ];
  }

  Future<List<ReportsMonthCount>> _membershipGrowthByMonth(
    DateTime since,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT strftime('%Y-%m-01', joined_at) AS ym, COUNT(*) AS c
FROM members
WHERE joined_at >= ?
GROUP BY ym
ORDER BY ym
''',
          variables: [Variable<DateTime>(since)],
        )
        .get();
    return [
      for (final row in rows)
        (
          month: DateTime.parse(row.read<String>('ym')),
          count: row.read<int>('c'),
        ),
    ];
  }

  /// Copies by their title's format — a snapshot of the catalogue as it
  /// stands, not scoped to the report period.
  Future<List<ReportsFormatCount>> _collectionByFormat() async {
    final rows = await _db.customSelect(
      '''
SELECT tf.name AS name, COUNT(c.id) AS c
FROM copies c
JOIN titles t ON t.id = c.title_id
JOIN title_formats tf ON tf.id = t.format_id
WHERE c.archived_at IS NULL
GROUP BY tf.name
ORDER BY c DESC
''',
    ).get();
    return [
      for (final row in rows)
        (label: row.read<String>('name'), count: row.read<int>('c')),
    ];
  }

  Future<List<ReportsRanking>> _topTitles(DateTime start, DateTime end) async {
    final rows = await _db
        .customSelect(
          '''
SELECT t.title AS name, t.author AS detail, COUNT(*) AS c
FROM loans l
JOIN copies c ON c.id = l.copy_id
JOIN titles t ON t.id = c.title_id
WHERE l.checked_out_at >= ? AND l.checked_out_at < ?
GROUP BY t.id
ORDER BY c DESC
LIMIT 5
''',
          variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
        )
        .get();
    return [
      for (final row in rows)
        (
          name: row.read<String>('name'),
          detail: row.read<String>('detail'),
          count: row.read<int>('c'),
        ),
    ];
  }

  Future<List<ReportsRanking>> _topMembers(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT m.full_name AS name, m.barcode AS detail, COUNT(*) AS c
FROM loans l
JOIN members m ON m.id = l.member_id
WHERE l.checked_out_at >= ? AND l.checked_out_at < ?
GROUP BY m.id
ORDER BY c DESC
LIMIT 5
''',
          variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
        )
        .get();
    return [
      for (final row in rows)
        (
          name: row.read<String>('name'),
          detail: row.read<String>('detail'),
          count: row.read<int>('c'),
        ),
    ];
  }

  Future<List<ReportsOverdueLoan>> _overdueLoans() async {
    final today = dateOnly(DateTime.now());
    final rows = await _db
        .customSelect(
          '''
SELECT t.title AS title, m.full_name AS member, l.due_at AS due_at
FROM loans l
JOIN copies c ON c.id = l.copy_id
JOIN titles t ON t.id = c.title_id
JOIN members m ON m.id = l.member_id
WHERE l.returned_at IS NULL AND l.due_at < ?
ORDER BY l.due_at ASC
LIMIT 100
''',
          variables: [Variable<String>(_dates.toSql(today))],
        )
        .get();
    return [
      for (final row in rows)
        (
          title: row.read<String>('title'),
          member: row.read<String>('member'),
          dueDate: DateTime.parse(row.read<String>('due_at')),
          daysLate: today
              .difference(DateTime.parse(row.read<String>('due_at')))
              .inDays,
        ),
    ];
  }

  Future<List<ReportsAcquisitionMonth>> _acquisitionsByMonth(
    DateTime since,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT strftime('%Y-%m-01', acquired_at) AS ym, COUNT(*) AS c
FROM copies
WHERE acquired_at >= ?
GROUP BY ym
ORDER BY ym
''',
          variables: [Variable<DateTime>(since)],
        )
        .get();
    return [
      for (final row in rows)
        (
          month: DateTime.parse(row.read<String>('ym')),
          count: row.read<int>('c'),
        ),
    ];
  }
}
