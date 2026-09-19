// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/circulation/reservation/data/reservation_local_data_source.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';

/// Drift-backed [ReservationLocalDataSource].
///
/// List rows include a computed [Reservation.queuePosition] per title queue.
@LazySingleton(as: ReservationLocalDataSource)
class LocalReservationDataSource implements ReservationLocalDataSource {
  LocalReservationDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalReservationDataSource';

  static const String _selectColumns = '''
r.*,
t.title AS title_name,
m.full_name AS member_name,
(SELECT COUNT(*)
 FROM reservations r2
 WHERE r2.title_id = r.title_id
   AND r2.closed_at IS NULL
   AND r2.placed_at < r.placed_at) + 1 AS queue_position
''';

  static const String _fromClause = '''
FROM reservations r
JOIN titles t ON t.id = r.title_id
JOIN members m ON m.id = r.member_id
''';

  @override
  Future<ReservationListResult> findReservations(ReservationQuery query) =>
      guardDatabase(
        () async {
          final where = StringBuffer('1 = 1');
          final variables = <Variable<Object>>[];

          if (query.activeOnly) {
            where.write(' AND r.closed_at IS NULL');
          }
          if (query.memberId != null) {
            where.write(' AND r.member_id = ?');
            variables.add(Variable<String>(query.memberId));
          }
          if (query.titleId != null) {
            where.write(' AND r.title_id = ?');
            variables.add(Variable<String>(query.titleId));
          }
          if (query.status != null) {
            where.write(' AND r.status = ?');
            variables.add(Variable<String>(query.status!.name));
          }

          final needle = query.search.trim().toLowerCase();
          if (needle.isNotEmpty) {
            where.write(
              ' AND (LOWER(t.title) LIKE ? OR LOWER(m.full_name) LIKE ?)',
            );
            variables.addAll([
              Variable<String>('%$needle%'),
              Variable<String>('%$needle%'),
            ]);
          }

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
        source: '$_source.findReservations',
      );

  String _orderClause(ReservationQuery query) {
    final dir = query.sortAscending ? 'ASC' : 'DESC';
    return switch (query.sortColumn) {
      'titleName' => 't.title $dir',
      'memberName' => 'm.full_name $dir',
      'queuePosition' => 'queue_position $dir',
      'status' => 'r.status $dir',
      'placedAt' => 'r.placed_at $dir',
      _ => 'r.placed_at $dir',
    };
  }

  Reservation _mapRow(QueryRow row) => Reservation(
    id: row.read<String>('id'),
    titleId: row.read<String>('title_id'),
    memberId: row.read<String>('member_id'),
    placedAt: row.read<DateTime>('placed_at'),
    status: ReservationStatus.values.byName(row.read<String>('status')),
    readyCopyId: row.readNullable<String>('ready_copy_id'),
    readyAt: row.readNullable<DateTime>('ready_at'),
    expiresAt: row.readNullable<DateTime>('expires_at'),
    closedAt: row.readNullable<DateTime>('closed_at'),
    createdAt: row.read<DateTime>('created_at'),
    updatedAt: row.read<DateTime>('updated_at'),
    titleName: row.read<String>('title_name'),
    memberName: row.read<String>('member_name'),
    queuePosition: row.read<int>('queue_position'),
  );

  @override
  Future<Reservation?> findReservationById(String id) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE r.id = ?
''',
            variables: [Variable<String>(id)],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findReservationById',
  );

  @override
  Future<Reservation?> findActiveHoldForMemberOnTitle({
    required String memberId,
    required String titleId,
  }) => guardDatabase(
    () async {
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE r.member_id = ?
  AND r.title_id = ?
  AND r.closed_at IS NULL
''',
            variables: [
              Variable<String>(memberId),
              Variable<String>(titleId),
            ],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findActiveHoldForMemberOnTitle',
  );

  @override
  Future<Reservation?> findFirstWaitingHoldForTitle(String titleId) =>
      guardDatabase(
        () async {
          final rows = await _db
              .customSelect(
                '''
SELECT $_selectColumns
$_fromClause
WHERE r.title_id = ?
  AND r.closed_at IS NULL
  AND r.status = ?
ORDER BY r.placed_at ASC
LIMIT 1
''',
                variables: [
                  Variable<String>(titleId),
                  Variable<String>(ReservationStatus.waiting.name),
                ],
              )
              .get();
          if (rows.isEmpty) return null;
          return _mapRow(rows.first);
        },
        source: '$_source.findFirstWaitingHoldForTitle',
      );

  @override
  Future<int> countActiveHoldsForMember(String memberId) => guardDatabase(
    () {
      final count = _db.reservations.id.count();
      return (_db.selectOnly(_db.reservations)
            ..addColumns([count])
            ..where(
              _db.reservations.memberId.equals(memberId) &
                  _db.reservations.closedAt.isNull(),
            ))
          .getSingle()
          .then((row) => row.read(count) ?? 0);
    },
    source: '$_source.countActiveHoldsForMember',
  );

  @override
  Future<bool> hasEarlierWaitingHold({
    required String titleId,
    required String memberId,
  }) => guardDatabase(
    () async {
      final row = await _db
          .customSelect(
            '''
SELECT 1
FROM reservations earlier
WHERE earlier.title_id = ?
  AND earlier.closed_at IS NULL
  AND earlier.status = ?
  AND earlier.placed_at < (
    SELECT MIN(later.placed_at)
    FROM reservations later
    WHERE later.title_id = ?
      AND later.closed_at IS NULL
      AND later.member_id = ?
  )
LIMIT 1
''',
            variables: [
              Variable<String>(titleId),
              Variable<String>(ReservationStatus.waiting.name),
              Variable<String>(titleId),
              Variable<String>(memberId),
            ],
          )
          .getSingleOrNull();
      return row != null;
    },
    source: '$_source.hasEarlierWaitingHold',
  );
}
