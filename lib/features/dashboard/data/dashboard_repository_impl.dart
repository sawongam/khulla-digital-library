// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/converters/date_only_converter.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart'
    show dateOnly;
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/dashboard/domain/dashboard_repository.dart';
import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart';

const String _source = 'DashboardRepositoryImpl';

/// [DashboardRepository] over the local catalogue.
///
/// Every query here crosses loans, fines, reservations, copies, titles and
/// members - none of it belongs to a single feature's repository, which is
/// why this reads `AppDatabase` directly rather than composing
/// `CirculationRepository`/`MemberRepository`/`TitleRepository` calls. A
/// composed version would still need a second round trip per figure; this
/// way every figure in one [DashboardSummary] is one `guardDatabase` call.
@LazySingleton(as: DashboardRepository)
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._db);

  final AppDatabase _db;

  static const DateOnlyConverter _dates = DateOnlyConverter();

  /// Rows the recent-activity list shows.
  static const int _activityLimit = 8;

  @override
  Future<DashboardSummary> loadSummary({
    required DateTime start,
    required DateTime end,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) => guardDatabase(
    () async {
      return DashboardSummary(
        borrowedCount: await _countByColumn('checked_out_at', start, end),
        borrowedPreviousCount: await _countByColumn(
          'checked_out_at',
          previousStart,
          previousEnd,
        ),
        returnedCount: await _countByColumn('returned_at', start, end),
        returnedPreviousCount: await _countByColumn(
          'returned_at',
          previousStart,
          previousEnd,
        ),
        overdueCount: await _countOverdueAsOf(end),
        overduePreviousCount: await _countOverdueAsOf(previousEnd),
        finesOutstanding: await _outstandingFines(),
        finesAssessed: await _assessedFines(start, end),
        finesAssessedPrevious: await _assessedFines(previousStart, previousEnd),
        checkOutsByWeekday: await _weekdayCounts('checked_out_at', start, end),
        returnsByWeekday: await _weekdayCounts('returned_at', start, end),
        finesByMonth: await _finesByMonth(end),
        collectionByStatus: await _collectionByStatus(),
        categoryShares: await _categoryShares(),
        recentActivity: await _recentActivity(),
        holdsReadyCount: await _countReservationsReady(),
        expiringMembershipsCount: await _countExpiringMemberships(),
        damagedCopiesCount: await _countCopiesByStatus(CopyStatus.damaged),
        topTitles: await _topTitles(start, end),
        topMembers: await _topMembers(start, end),
      );
    },
    source: '$_source.loadSummary',
  );

  /// Loans in `[start, end)` by [column] - `checked_out_at` for borrows,
  /// `returned_at` for returns.
  Future<int> _countByColumn(String column, DateTime start, DateTime end) => _db
      .customSelect(
        'SELECT COUNT(*) AS c FROM loans WHERE $column >= ? AND $column < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => row.read<int>('c'));

  /// Open loans whose due date had already passed at [asOf].
  Future<int> _countOverdueAsOf(DateTime asOf) => _db
      .customSelect(
        '''
SELECT COUNT(*) AS c FROM loans
WHERE due_at < ?
  AND (returned_at IS NULL OR returned_at >= ?)
''',
        variables: [
          Variable<String>(_dates.toSql(dateOnly(asOf))),
          Variable<DateTime>(asOf),
        ],
      )
      .getSingle()
      .then((row) => row.read<int>('c'));

  /// The total owed right now - a snapshot, not bound to any period.
  Future<Money> _outstandingFines() => _db
      .customSelect(
        'SELECT COALESCE(SUM(assessed - paid - waived), 0) AS total '
        'FROM fines WHERE paid + waived < assessed',
      )
      .getSingle()
      .then((row) => Money(row.read<int>('total')));

  /// What was assessed in `[start, end)` - the fines stat tile's trend
  /// compares this, not the outstanding balance (see [DashboardSummary]).
  Future<Money> _assessedFines(DateTime start, DateTime end) => _db
      .customSelect(
        'SELECT COALESCE(SUM(assessed), 0) AS total FROM fines '
        'WHERE raised_at >= ? AND raised_at < ?',
        variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
      )
      .getSingle()
      .then((row) => Money(row.read<int>('total')));

  /// Loans in `[start, end)` by [column], grouped by weekday (`0` = Sunday).
  Future<List<DashboardWeekdayCount>> _weekdayCounts(
    String column,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT CAST(strftime('%w', $column) AS INTEGER) AS wd, COUNT(*) AS c
FROM loans
WHERE $column >= ? AND $column < ?
GROUP BY wd
''',
          variables: [Variable<DateTime>(start), Variable<DateTime>(end)],
        )
        .get();
    return [
      for (final row in rows)
        (weekday: row.read<int>('wd'), count: row.read<int>('c')),
    ];
  }

  /// Fines assessed per month, for the eight months up to and including
  /// [end]'s month.
  Future<List<DashboardMonthAmount>> _finesByMonth(DateTime end) async {
    final monthsBack = DateTime(end.year, end.month - 7);
    final rows = await _db
        .customSelect(
          '''
SELECT strftime('%Y-%m-01', raised_at) AS ym, COALESCE(SUM(assessed), 0) AS total
FROM fines
WHERE raised_at >= ?
GROUP BY ym
ORDER BY ym
''',
          variables: [Variable<DateTime>(monthsBack)],
        )
        .get();
    return [
      for (final row in rows)
        (
          month: DateTime.parse(row.read<String>('ym')),
          amount: Money(row.read<int>('total')),
        ),
    ];
  }

  Future<Map<CopyStatus, int>> _collectionByStatus() async {
    final rows = await _db
        .customSelect(
          'SELECT status, COUNT(*) AS c FROM copies '
          'WHERE archived_at IS NULL GROUP BY status',
        )
        .get();
    return {
      for (final row in rows)
        CopyStatus.values.byName(row.read<String>('status')): row.read<int>(
          'c',
        ),
    };
  }

  /// Titles by format, the closest categorical dimension a title carries -
  /// there is no separate subject/genre column (see ADR 0007).
  Future<List<DashboardCategoryShare>> _categoryShares() async {
    final rows = await _db.customSelect(
      '''
SELECT tf.name AS name, COUNT(t.id) AS c
FROM titles t
JOIN title_formats tf ON tf.id = t.format_id
WHERE t.archived_at IS NULL
GROUP BY tf.name
ORDER BY c DESC
LIMIT 6
''',
    ).get();
    final total = rows.fold<int>(0, (sum, row) => sum + row.read<int>('c'));
    return [
      for (final row in rows)
        (
          label: row.read<String>('name'),
          count: row.read<int>('c'),
          share: total == 0 ? 0.0 : row.read<int>('c') / total,
        ),
    ];
  }

  /// The last few things that happened at the desk, most recent first.
  ///
  /// Each arm takes its own newest [_activityLimit] rows before the arms are
  /// merged. The overall newest rows must be among them, and it lets every
  /// arm walk its date index backwards and stop, instead of joining and
  /// sorting the whole circulation history on each dashboard open.
  Future<List<DashboardActivityEvent>> _recentActivity() async {
    final rows = await _db
        .customSelect(
          '''
SELECT * FROM (
  SELECT * FROM (
    SELECT 'borrow' AS kind, t.title AS item, c.barcode AS item_code,
           m.full_name AS member, m.barcode AS member_code,
           l.checked_out_at AS at, l.due_at AS due
    FROM loans l
    JOIN copies c ON c.id = l.copy_id
    JOIN titles t ON t.id = c.title_id
    JOIN members m ON m.id = l.member_id
    ORDER BY l.checked_out_at DESC
    LIMIT ?1
  )

  UNION ALL

  SELECT * FROM (
    SELECT 'returned', t.title, c.barcode, m.full_name, m.barcode,
           l.returned_at, NULL
    FROM loans l
    JOIN copies c ON c.id = l.copy_id
    JOIN titles t ON t.id = c.title_id
    JOIN members m ON m.id = l.member_id
    WHERE l.returned_at IS NOT NULL
    ORDER BY l.returned_at DESC
    LIMIT ?1
  )

  UNION ALL

  SELECT * FROM (
    SELECT 'reserved', t.title, '', m.full_name, m.barcode,
           r.placed_at, NULL
    FROM reservations r
    JOIN titles t ON t.id = r.title_id
    JOIN members m ON m.id = r.member_id
    ORDER BY r.placed_at DESC
    LIMIT ?1
  )

  UNION ALL

  SELECT * FROM (
    SELECT 'fine', COALESCE(t.title, ''), COALESCE(c.barcode, ''),
           m.full_name, m.barcode, f.raised_at, NULL
    FROM fines f
    JOIN members m ON m.id = f.member_id
    LEFT JOIN loans l ON l.id = f.loan_id
    LEFT JOIN copies c ON c.id = l.copy_id
    LEFT JOIN titles t ON t.id = c.title_id
    ORDER BY f.raised_at DESC
    LIMIT ?1
  )
)
ORDER BY at DESC
LIMIT ?1
''',
          variables: const [Variable<int>(_activityLimit)],
        )
        .get();
    return [
      for (final row in rows)
        (
          kind: switch (row.read<String>('kind')) {
            'borrow' => DashboardActivityKind.borrow,
            'returned' => DashboardActivityKind.returned,
            'reserved' => DashboardActivityKind.reserved,
            _ => DashboardActivityKind.fine,
          },
          item: row.read<String>('item'),
          itemCode: row.read<String>('item_code'),
          member: row.read<String>('member'),
          memberCode: row.read<String>('member_code'),
          when: row.read<DateTime>('at'),
          due: row.read<DateTime?>('due'),
        ),
    ];
  }

  Future<int> _countReservationsReady() {
    final count = _db.reservations.id.count(
      filter: _db.reservations.status.equalsValue(ReservationStatus.ready),
    );
    return (_db.selectOnly(
      _db.reservations,
    )..addColumns([count])).getSingle().then((row) => row.read(count) ?? 0);
  }

  /// Active memberships expiring within 30 days - the same window
  /// `Member.status` uses to compute `MemberStatus.expiring`.
  Future<int> _countExpiringMemberships() {
    final today = dateOnly(DateTime.now());
    final horizon = today.add(const Duration(days: 30));
    return _db
        .customSelect(
          '''
SELECT COUNT(*) AS c FROM members
WHERE archived_at IS NULL
  AND suspended_at IS NULL
  AND expires_at IS NOT NULL
  AND expires_at >= ?
  AND expires_at <= ?
''',
          variables: [
            Variable<String>(_dates.toSql(today)),
            Variable<String>(_dates.toSql(horizon)),
          ],
        )
        .getSingle()
        .then((row) => row.read<int>('c'));
  }

  Future<int> _countCopiesByStatus(CopyStatus status) {
    final count = _db.copies.id.count(
      filter:
          _db.copies.status.equalsValue(status) &
          _db.copies.archivedAt.isNull(),
    );
    return (_db.selectOnly(
      _db.copies,
    )..addColumns([count])).getSingle().then((row) => row.read(count) ?? 0);
  }

  Future<List<DashboardRanking>> _topTitles(
    DateTime start,
    DateTime end,
  ) async {
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

  Future<List<DashboardRanking>> _topMembers(
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
}
