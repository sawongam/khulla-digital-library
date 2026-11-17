// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/members/data/local_member_data_source.dart';
import 'package:khulla/features/members/domain/member_deletion_rules.dart';
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  group('ensureMemberDeletable', () {
    test('allows a member with nothing open or owed', () {
      expect(
        () => ensureMemberDeletable(openLoanCount: 0, unpaidFineCount: 0),
        returnsNormally,
      );
    });

    test('refuses open loans first', () {
      expect(
        () => ensureMemberDeletable(openLoanCount: 1, unpaidFineCount: 1),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.memberHasOpenLoans,
          ),
        ),
      );
    });

    test('refuses unpaid fines', () {
      expect(
        () => ensureMemberDeletable(openLoanCount: 0, unpaidFineCount: 2),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.reason,
            'reason',
            AppErrorReason.memberHasUnpaidFines,
          ),
        ),
      );
    });
  });

  group('MemberOptionalField', () {
    test('round-trips keys and ignores unknown ones', () {
      final fields = MemberOptionalField.parseHidden(
        'grade, email,nonsense,,notes',
      );
      expect(fields, {
        MemberOptionalField.grade,
        MemberOptionalField.email,
        MemberOptionalField.notes,
      });
      expect(
        MemberOptionalField.encodeHidden(fields),
        'grade,email,notes',
      );
      expect(MemberOptionalField.parseHidden(''), isEmpty);
    });
  });

  group('deleteMember', () {
    late AppDatabase db;
    late LocalMemberDataSource members;
    late ReferenceSeed reference;

    setUp(() async {
      db = await openTestDatabase();
      members = LocalMemberDataSource(db);
      reference = await seedReferenceData(db);
    });

    tearDown(() => closeTestDatabase(db));

    Future<void> insertLoan(
      String id,
      String copyId,
      String memberId, {
      DateTime? returnedAt,
    }) {
      final now = DateTime.now();
      return db
          .into(db.loans)
          .insert(
            LoansCompanion.insert(
              id: id,
              copyId: copyId,
              memberId: Value(memberId),
              checkedOutAt: now.subtract(const Duration(days: 3)),
              dueAt: now.add(const Duration(days: 10)),
              returnedAt: Value(returnedAt),
              ruleLoanPeriodDays: 14,
              ruleFinePerDay: Money.major(5),
              ruleGraceDays: 1,
              ruleMaximumFine: Money.major(500),
              createdAt: now,
            ),
          );
    }

    Future<void> insertFine(String memberId, {required Money paid}) {
      final now = DateTime.now();
      return db
          .into(db.fines)
          .insert(
            FinesCompanion.insert(
              id: 'fine',
              memberId: Value(memberId),
              reason: FineReason.damage,
              assessed: Money.major(50),
              paid: Value(paid),
              raisedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    test('refuses while a loan is open', () async {
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
      );
      final copy = await seedTitleWithCopy(db, formatId: reference.formatId);
      await insertLoan('open', copy.copyId, member.memberId);

      await expectLater(
        members.deleteMember(member.memberId),
        throwsA(isA<ConflictException>()),
      );
      expect(await members.findMemberById(member.memberId), isNotNull);
    });

    test('refuses while a fine is unpaid', () async {
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
      );
      await insertFine(member.memberId, paid: Money.major(10));

      await expectLater(
        members.deleteMember(member.memberId),
        throwsA(isA<ConflictException>()),
      );
    });

    test('keeps history without a name and drops open holds', () async {
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
      );
      final copy = await seedTitleWithCopy(db, formatId: reference.formatId);
      final other = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        barcode: 'TEST-002',
      );
      final now = DateTime.now();
      await insertLoan('done', copy.copyId, member.memberId, returnedAt: now);
      await insertFine(member.memberId, paid: Money.major(50));
      Future<void> hold(String id, ReservationStatus status) => db
          .into(db.reservations)
          .insert(
            ReservationsCompanion.insert(
              id: id,
              titleId: other.titleId,
              memberId: Value(member.memberId),
              placedAt: now,
              status: status,
              closedAt: Value(
                status == ReservationStatus.waiting ? null : now,
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await hold('past', ReservationStatus.fulfilled);
      await hold('open', ReservationStatus.waiting);

      await members.deleteMember(member.memberId);

      expect(await members.findMemberById(member.memberId), isNull);
      final loan = await db.select(db.loans).getSingle();
      expect(loan.memberId, isNull);
      final fine = await db.select(db.fines).getSingle();
      expect(fine.memberId, isNull);
      final holds = await db.select(db.reservations).get();
      expect(holds.map((h) => h.id), ['past']);
      expect(holds.single.memberId, isNull);
    });

    test('archived members list only under the archived filter', () async {
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
      );
      await members.archiveMember(member.memberId, DateTime.now());

      expect(
        (await members.findMembers(const MemberQuery())).totalCount,
        0,
      );
      expect(
        (await members.findMembers(const MemberQuery(archived: true)))
            .totalCount,
        1,
      );

      await members.restoreMember(member.memberId);
      expect(
        (await members.findMembers(const MemberQuery())).totalCount,
        1,
      );
    });
  });
}
