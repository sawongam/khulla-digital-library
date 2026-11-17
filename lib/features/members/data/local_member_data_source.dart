// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/database/fts_filter.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/time/calendar_days.dart';
import 'package:khulla/features/circulation/shared/data/circulation_hold_queue.dart';
import 'package:khulla/features/circulation/shared/data/effective_rules_reader.dart';
import 'package:khulla/features/members/data/mappers/member_row_mappers.dart';
import 'package:khulla/features/members/data/member_local_data_source.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/member_deletion_rules.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

/// Drift-backed [MemberLocalDataSource].
///
/// List and detail queries join member types and count open loans and
/// outstanding fines per row, so each [Member] is desk-ready without N+1
/// reads.
@LazySingleton(as: MemberLocalDataSource)
class LocalMemberDataSource implements MemberLocalDataSource {
  LocalMemberDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalMemberDataSource';

  /// The `members_fts` columns a search looks in.
  static const List<String> _searchColumns = [
    'full_name',
    'barcode',
    'email',
    'phone',
    'address',
    'municipality',
    'occupation',
    'institution',
    'id_verification',
    'emergency_contact_name',
    'guardian',
  ];

  /// Circulation figures as per-row subqueries, each an index probe for the
  /// member on that row (`loans_open_by_member`, `loans_member_history`,
  /// `fines_outstanding`). A joined `GROUP BY` would aggregate every loan and
  /// fine ever written before the page was cut.
  ///
  /// Binds one variable - today, as `YYYY-MM-DD` - for the overdue count, so
  /// it must lead the variable list of any query selecting these columns.
  static const String _selectColumns = '''
m.*,
mt.name AS member_type_name,
mt.code AS member_type_code,
(SELECT COUNT(*) FROM loans l
 WHERE l.member_id = m.id AND l.returned_at IS NULL) AS loans_out,
(SELECT COUNT(*) FROM loans l
 WHERE l.member_id = m.id AND l.returned_at IS NULL
   AND l.due_at < ?) AS overdue_loans,
(SELECT COALESCE(SUM(f.assessed - f.paid - f.waived), 0) FROM fines f
 WHERE f.member_id = m.id AND f.paid + f.waived < f.assessed) AS fines_owed,
(SELECT COUNT(*) FROM loans l WHERE l.member_id = m.id) AS borrowed_all_time
''';

  static const String _fromClause = '''
FROM members m
JOIN member_types mt ON mt.id = m.member_type_id
''';

  static const String _hasOpenLoan = '''
EXISTS (SELECT 1 FROM loans l
        WHERE l.member_id = m.id AND l.returned_at IS NULL)''';

  static const String _owesFines = '''
EXISTS (SELECT 1 FROM fines f
        WHERE f.member_id = m.id AND f.paid + f.waived < f.assessed)''';

  @override
  Future<MemberListResult> findMembers(MemberQuery query) => guardDatabase(
    () async {
      final today = dateOnly(DateTime.now());
      final todaySql = _dateToSql(today);
      final expiringEndSql = _dateToSql(addCalendarDays(today, 30));

      final where = StringBuffer(
        query.archived ? 'm.archived_at IS NOT NULL' : 'm.archived_at IS NULL',
      );
      final variables = <Variable<Object>>[];

      final search = ftsFilter(
        search: query.search,
        table: 'members_fts',
        columns: _searchColumns,
        rowid: 'm.rowid',
      );
      if (search != null) {
        where.write(' AND ${search.sql}');
        variables.addAll(search.variables);
      }
      if (query.withLoans) {
        where.write(' AND $_hasOpenLoan');
      }
      if (query.owesFines) {
        where.write(' AND $_owesFines');
      }
      if (query.suspended) {
        where.write(' AND m.suspended_at IS NOT NULL');
      }
      if (query.expiring) {
        where.write(
          ' AND m.suspended_at IS NULL'
          ' AND m.expires_at IS NOT NULL'
          ' AND m.expires_at > ?'
          ' AND m.expires_at <= ?',
        );
        variables.addAll([
          Variable<String>(todaySql),
          Variable<String>(expiringEndSql),
        ]);
      }

      final order = _orderClause(query);
      final countSql = 'SELECT COUNT(*) AS total FROM members m WHERE $where';
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
              Variable<String>(todaySql),
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
    source: '$_source.findMembers',
  );

  String _orderClause(MemberQuery query) {
    final dir = query.sortAscending ? 'ASC' : 'DESC';
    return switch (query.sortColumn) {
      'barcode' => 'm.barcode $dir',
      'card' => 'm.barcode $dir',
      'loans' => 'loans_out $dir',
      'fines' => 'fines_owed $dir',
      'joined' => 'm.joined_at $dir',
      'expires' => 'm.expires_at $dir',
      'name' => 'm.full_name $dir',
      _ => 'm.created_at $dir',
    };
  }

  Member _mapRow(QueryRow row) => Member(
    id: row.read<String>('id'),
    fullName: row.read<String>('full_name'),
    barcode: row.read<String>('barcode'),
    memberTypeId: row.read<String>('member_type_id'),
    memberTypeName: row.read<String>('member_type_name'),
    memberTypeCode: row.readNullable<String>('member_type_code'),
    grade: row.readNullable<String>('grade'),
    joinedAt: row.read<DateTime>('joined_at'),
    createdAt: row.read<DateTime>('created_at'),
    updatedAt: row.read<DateTime>('updated_at'),
    loansOut: row.read<int>('loans_out'),
    overdueLoans: row.read<int>('overdue_loans'),
    finesOwed: Money(row.read<int>('fines_owed')),
    borrowedAllTime: row.read<int>('borrowed_all_time'),
    sendNotices: row.read<bool>('send_notices'),
    gender: row.readNullable<String>('gender') == null
        ? null
        : Gender.values.byName(row.read<String>('gender')),
    dateOfBirth: row.readNullable<DateTime>('date_of_birth'),
    bloodGroup: row.readNullable<String>('blood_group') == null
        ? null
        : BloodGroup.values.byName(row.read<String>('blood_group')),
    email: row.readNullable<String>('email'),
    phone: row.readNullable<String>('phone'),
    address: row.readNullable<String>('address'),
    municipality: row.readNullable<String>('municipality'),
    occupation: row.readNullable<String>('occupation'),
    institution: row.readNullable<String>('institution'),
    idVerification: row.readNullable<String>('id_verification'),
    emergencyContactName: row.readNullable<String>('emergency_contact_name'),
    emergencyContactPhone: row.readNullable<String>('emergency_contact_phone'),
    guardian: row.readNullable<String>('guardian'),
    notes: row.readNullable<String>('notes'),
    expiresAt: row.readNullable<DateTime>('expires_at'),
    suspendedAt: row.readNullable<DateTime>('suspended_at'),
    suspensionReason: row.readNullable<String>('suspension_reason'),
    archivedAt: row.readNullable<DateTime>('archived_at'),
  );

  String _dateToSql(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Future<Member?> findMemberByBarcode(String barcode) => guardDatabase(
    () async {
      final trimmed = barcode.trim();
      if (trimmed.isEmpty) return null;

      final today = dateOnly(DateTime.now());
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE m.archived_at IS NULL
  AND LOWER(m.barcode) = LOWER(?)
''',
            variables: [
              Variable<String>(_dateToSql(today)),
              Variable<String>(trimmed),
            ],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findMemberByBarcode',
  );

  @override
  Future<Member?> findMemberById(String id) => guardDatabase(
    () async {
      final today = dateOnly(DateTime.now());
      final rows = await _db
          .customSelect(
            '''
SELECT $_selectColumns
$_fromClause
WHERE m.id = ?
''',
            variables: [
              Variable<String>(_dateToSql(today)),
              Variable<String>(id),
            ],
          )
          .get();
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    },
    source: '$_source.findMemberById',
  );

  @override
  Future<Member> insertMember(Member member) => guardDatabase(
    () => _db.transaction(() async {
      var toInsert = member;
      if (toInsert.barcode.trim().isEmpty) {
        final settings = await (_db.select(
          _db.librarySettings,
        )..where((s) => s.id.equals(1))).getSingleOrNull();
        if (settings == null) {
          toInsert = toInsert.copyWith(
            barcode: 'MEM-${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          final barcode =
              '${settings.memberBarcodePrefix}${settings.memberBarcodeNextValue}';
          await (_db.update(
            _db.librarySettings,
          )..where((s) => s.id.equals(1))).write(
            LibrarySettingsCompanion(
              memberBarcodeNextValue: Value(
                settings.memberBarcodeNextValue + 1,
              ),
              updatedAt: Value(DateTime.now()),
            ),
          );
          toInsert = toInsert.copyWith(barcode: barcode);
        }
      }
      await _db.into(_db.members).insert(toInsert.toCompanion());
      return (await findMemberById(toInsert.id))!;
    }),
    source: '$_source.insertMember',
  );

  @override
  Future<Member> updateMember(Member member) => guardDatabase(
    () async {
      await (_db.update(
        _db.members,
      )..where((m) => m.id.equals(member.id))).write(member.toCompanion());
      return (await findMemberById(member.id))!;
    },
    source: '$_source.updateMember',
  );

  @override
  Future<void> archiveMember(String id, DateTime archivedAt) => guardDatabase(
    () async {
      await (_db.update(_db.members)..where((m) => m.id.equals(id))).write(
        MembersCompanion(
          archivedAt: Value(archivedAt),
          updatedAt: Value(DateTime.now()),
        ),
      );
    },
    source: '$_source.archiveMember',
  );

  @override
  Future<void> restoreMember(String id) => guardDatabase(
    () async {
      await (_db.update(_db.members)..where((m) => m.id.equals(id))).write(
        MembersCompanion(
          archivedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    },
    source: '$_source.restoreMember',
  );

  @override
  Future<void> deleteMember(String id) => guardDatabase(
    () => _db.transaction(() async {
      final openLoanCount = await _count(
        'SELECT COUNT(*) AS n FROM loans '
        'WHERE member_id = ? AND returned_at IS NULL',
        id,
      );
      final unpaidFineCount = await _count(
        'SELECT COUNT(*) AS n FROM fines '
        'WHERE member_id = ? AND paid + waived < assessed',
        id,
      );
      ensureMemberDeletable(
        openLoanCount: openLoanCount,
        unpaidFineCount: unpaidFineCount,
      );

      // Open holds go the way a cancelled one does - a ready hold gives its
      // copy back and the next member in the queue is offered it - and then
      // the row itself is dropped: a hold with nobody behind it is noise.
      final holdQueue = CirculationHoldQueue(_db, EffectiveRulesReader(_db));
      final openHolds =
          await (_db.select(_db.reservations)..where(
                (hold) => hold.memberId.equals(id) & hold.closedAt.isNull(),
              ))
              .get();
      for (final hold in openHolds) {
        await holdQueue.cancelOpenHold(hold.id);
        await (_db.delete(
          _db.reservations,
        )..where((row) => row.id.equals(hold.id))).go();
      }

      // What is left is history: it outlives the person, without a name.
      for (final table in const ['loans', 'fines', 'reservations']) {
        await _db.customStatement(
          'UPDATE $table SET member_id = NULL WHERE member_id = ?',
          [id],
        );
      }
      await (_db.delete(_db.members)..where((m) => m.id.equals(id))).go();
    }),
    source: '$_source.deleteMember',
  );

  Future<int> _count(String sql, String memberId) async {
    final row = await _db
        .customSelect(sql, variables: [Variable<String>(memberId)])
        .getSingle();
    return row.read<int>('n');
  }
}
