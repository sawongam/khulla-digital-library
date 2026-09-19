// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/circulation/fine/data/local_fine_data_source.dart';
import 'package:khulla/features/circulation/loan/data/local_loan_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/local_reservation_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_repository_impl.dart';
import 'package:khulla/features/reports/data/reports_repository_impl.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// [ReportsRepositoryImpl] against a real database, seeded through
/// [CirculationRepositoryImpl] the same way the app writes.
void main() {
  late AppDatabase db;
  late CirculationRepositoryImpl circulation;
  late ReportsRepositoryImpl reports;

  setUp(() async {
    db = await openTestDatabase();
    circulation = CirculationRepositoryImpl(
      db,
      LocalLoanDataSource(db),
      LocalFineDataSource(db),
      LocalReservationDataSource(db),
    );
    reports = ReportsRepositoryImpl(db);
  });

  tearDown(() => closeTestDatabase(db));

  test(
    'loadSummary counts a checkout and ranks its title and member',
    () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(db, memberTypeId: reference.memberTypeId);

      await circulation.checkOutCopy(
        memberId: member.memberId,
        barcode: seeded.barcode,
      );

      final now = DateTime.now();
      final start = DateTime(now.year, now.month);
      final end = now.add(const Duration(days: 1));
      final summary = await reports.loadSummary(
        start: start,
        end: end,
        previousStart: start.subtract(const Duration(days: 30)),
        previousEnd: start,
      );

      expect(summary.borrowedCount, 1);
      expect(summary.topTitles, hasLength(1));
      expect(summary.topTitles.first.count, 1);
      expect(summary.topMembers, hasLength(1));
      expect(summary.topMembers.first.count, 1);
      expect(summary.collectionByFormat.fold(0, (sum, f) => sum + f.count), 1);
    },
  );

  test('loadSummary lists a currently overdue loan', () async {
    final reference = await seedReferenceData(db);
    final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
    final member = await seedMember(db, memberTypeId: reference.memberTypeId);

    final loan = await circulation.checkOutCopy(
      memberId: member.memberId,
      barcode: seeded.barcode,
    );
    await (db.update(db.loans)..where((row) => row.id.equals(loan.id))).write(
      LoansCompanion(
        dueAt: Value(DateTime.now().subtract(const Duration(days: 5))),
      ),
    );

    final now = DateTime.now();
    final summary = await reports.loadSummary(
      start: now.subtract(const Duration(days: 1)),
      end: now.add(const Duration(days: 1)),
      previousStart: now.subtract(const Duration(days: 3)),
      previousEnd: now.subtract(const Duration(days: 1)),
    );

    expect(summary.overdueLoans, hasLength(1));
    expect(summary.overdueLoans.first.daysLate, greaterThan(0));
  });
}
