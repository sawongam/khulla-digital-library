// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/fine/data/local_fine_data_source.dart';
import 'package:khulla/features/circulation/loan/data/local_loan_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/local_reservation_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_repository_impl.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// Integration tests for [CirculationRepositoryImpl] against a real database.
///
/// Loan reads go through the real [LocalLoanDataSource] so checkout/return
/// views reload the rows the transaction just wrote; these tests focus on
/// transactional writes — duplicate loans, fines on return, and copy
/// status changes — without also asserting loan-list queries.
void main() {
  late AppDatabase db;
  late CirculationRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = CirculationRepositoryImpl(
      db,
      LocalLoanDataSource(db),
      LocalFineDataSource(db),
      LocalReservationDataSource(db),
    );
  });

  tearDown(() => closeTestDatabase(db));

  Future<CopyRow> copyByBarcode(String barcode) => (db.select(
    db.copies,
  )..where((copy) => copy.barcode.equals(barcode))).getSingle();

  group('CirculationRepositoryImpl', () {
    test(
      'second open loan on same copy throws DuplicateRecordException',
      () async {
        final reference = await seedReferenceData(db);
        final seeded = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
        );
        final member = await seedMember(
          db,
          memberTypeId: reference.memberTypeId,
        );

        await repository.checkOutCopy(
          memberId: member.memberId,
          barcode: seeded.barcode,
        );

        await (db.update(
          db.copies,
        )..where((c) => c.id.equals(seeded.copyId))).write(
          CopiesCompanion(
            status: const Value(CopyStatus.available),
            updatedAt: Value(DateTime.now()),
          ),
        );

        expect(
          () => repository.checkOutCopy(
            memberId: member.memberId,
            barcode: seeded.barcode,
          ),
          throwsA(isA<DuplicateRecordException>()),
        );
      },
    );

    test('checkout past borrowing limit throws ConflictException', () async {
      final reference = await seedReferenceData(db);
      await updateLoanRules(db, borrowingLimit: 1);

      final firstCopy = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        barcode: 'LIMIT-001',
      );
      final secondCopy = await seedTitleWithCopy(
        db,
        formatId: reference.formatId,
        barcode: 'LIMIT-002',
        title: 'Second Title',
      );
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'LIMIT-MEM',
      );

      await repository.checkOutCopy(
        memberId: member.memberId,
        barcode: firstCopy.barcode,
      );

      expect(
        () => repository.checkOutCopy(
          memberId: member.memberId,
          barcode: secondCopy.barcode,
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('checkout for suspended member throws ConflictException', () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'SUSP-MEM',
        suspendedAt: DateTime.now(),
      );

      expect(
        () => repository.checkOutCopy(
          memberId: member.memberId,
          barcode: seeded.barcode,
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('checkout for expired member throws ConflictException', () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(
        db,
        memberTypeId: reference.memberTypeId,
        barcode: 'EXP-MEM',
        expiresAt: addCalendarDays(dateOnly(DateTime.now()), -1),
      );

      expect(
        () => repository.checkOutCopy(
          memberId: member.memberId,
          barcode: seeded.barcode,
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test(
      'return fine uses loan snapshot not current rules',
      () async {
        final reference = await seedReferenceData(db);
        final seeded = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
          barcode: 'FINE-001',
        );
        final member = await seedMember(
          db,
          memberTypeId: reference.memberTypeId,
          barcode: 'FINE-MEM',
        );

        final loan = await repository.checkOutCopy(
          memberId: member.memberId,
          barcode: seeded.barcode,
        );

        await updateLoanRules(db, finePerDay: Money.major(10));

        final overdueDue = addCalendarDays(dateOnly(DateTime.now()), -5);
        await (db.update(db.loans)..where((l) => l.id.equals(loan.id))).write(
          LoansCompanion(dueAt: Value(overdueDue)),
        );

        await repository.returnCopy(
          barcode: seeded.barcode,
          condition: CopyCondition.good,
        );

        final fines = await db.select(db.fines).get();
        expect(fines, hasLength(1));

        final expected = computeOverdueFine(
          dueAt: overdueDue,
          asOf: dateOnly(DateTime.now()),
          finePerDay: Money.major(5),
          graceDays: 1,
          maximumFine: Money.major(500),
        );
        expect(fines.single.assessed, expected);
        expect(fines.single.assessed, isNot(Money.major(10) * 4));
      },
    );

    test(
      'failed checkout at limit leaves copy available',
      () async {
        final reference = await seedReferenceData(db);
        await updateLoanRules(db, borrowingLimit: 1);

        final onLoan = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
          barcode: 'ROLL-001',
        );
        final blocked = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
          barcode: 'ROLL-002',
          title: 'Rollback Title',
        );
        final member = await seedMember(
          db,
          memberTypeId: reference.memberTypeId,
          barcode: 'ROLL-MEM',
        );

        await repository.checkOutCopy(
          memberId: member.memberId,
          barcode: onLoan.barcode,
        );

        await expectLater(
          repository.checkOutCopy(
            memberId: member.memberId,
            barcode: blocked.barcode,
          ),
          throwsA(isA<ConflictException>()),
        );

        final copy = await copyByBarcode(blocked.barcode);
        expect(copy.status, CopyStatus.available);
      },
    );

    test(
      'return on copy not on loan throws without side effects',
      () async {
        final reference = await seedReferenceData(db);
        final seeded = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
          barcode: 'RET-001',
        );

        await expectLater(
          repository.returnCopy(
            barcode: seeded.barcode,
            condition: CopyCondition.good,
          ),
          throwsA(isA<NotFoundException>()),
        );

        final copy = await copyByBarcode(seeded.barcode);
        expect(copy.status, CopyStatus.available);

        final fines = await db.select(db.fines).get();
        expect(fines, isEmpty);
      },
    );
  });
}
