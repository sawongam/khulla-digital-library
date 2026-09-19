// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/fine/data/local_fine_data_source.dart';
import 'package:khulla/features/circulation/loan/data/local_loan_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/local_reservation_data_source.dart';
import 'package:khulla/features/circulation/shared/data/circulation_repository_impl.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// [DashboardRepositoryImpl] against a real database, seeded through
/// [CirculationRepositoryImpl] so the aggregates are checked against the same
/// writes the app itself produces, not hand-inserted rows.
void main() {
  late AppDatabase db;
  late CirculationRepositoryImpl circulation;
  late DashboardRepositoryImpl dashboard;

  setUp(() async {
    db = await openTestDatabase();
    circulation = CirculationRepositoryImpl(
      db,
      LocalLoanDataSource(db),
      LocalFineDataSource(db),
      LocalReservationDataSource(db),
    );
    dashboard = DashboardRepositoryImpl(db);
  });

  tearDown(() => closeTestDatabase(db));

  test(
    'loadSummary counts a checkout within the period and not before it',
    () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(db, memberTypeId: reference.memberTypeId);

      await circulation.checkOutCopy(
        memberId: member.memberId,
        barcode: seeded.barcode,
      );

      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));
      final earlierStart = start.subtract(const Duration(days: 2));
      final earlierEnd = start.subtract(const Duration(days: 1));

      final summaryWithCheckout = await dashboard.loadSummary(
        start: start,
        end: end,
        previousStart: earlierStart,
        previousEnd: earlierEnd,
      );
      expect(summaryWithCheckout.borrowedCount, 1);
      expect(summaryWithCheckout.collectionByStatus[CopyStatus.onLoan], 1);
      expect(summaryWithCheckout.topTitles, hasLength(1));
      expect(summaryWithCheckout.topTitles.first.count, 1);

      final summaryBefore = await dashboard.loadSummary(
        start: earlierStart,
        end: earlierEnd,
        previousStart: earlierStart.subtract(const Duration(days: 1)),
        previousEnd: earlierStart,
      );
      expect(summaryBefore.borrowedCount, 0);
    },
  );

  test(
    'loadSummary lists the newest eight events across checkouts and returns',
    () async {
      final reference = await seedReferenceData(db);
      final member = await seedMember(db, memberTypeId: reference.memberTypeId);
      for (var i = 0; i < 5; i++) {
        final seeded = await seedTitleWithCopy(
          db,
          formatId: reference.formatId,
          title: 'Title $i',
          barcode: 'TEST-00$i',
        );
        await circulation.checkOutCopy(
          memberId: member.memberId,
          barcode: seeded.barcode,
        );
        await circulation.returnCopy(
          barcode: seeded.barcode,
          condition: CopyCondition.values.first,
        );
      }

      final now = DateTime.now();
      final summary = await dashboard.loadSummary(
        start: now.subtract(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 1)),
        previousStart: now.subtract(const Duration(days: 2)),
        previousEnd: now.subtract(const Duration(days: 1)),
      );

      final activity = summary.recentActivity;
      expect(activity, hasLength(8));
      for (var i = 1; i < activity.length; i++) {
        expect(activity[i].when.isAfter(activity[i - 1].when), isFalse);
      }
      expect(
        activity.map((event) => event.kind).toSet(),
        {DashboardActivityKind.borrow, DashboardActivityKind.returned},
      );
      expect(activity.last.item, isNot('Title 0'));
    },
  );

  test(
    'loadSummary reports outstanding fines and the current overdue count',
    () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(db, memberTypeId: reference.memberTypeId);

      await circulation.checkOutCopy(
        memberId: member.memberId,
        barcode: seeded.barcode,
      );
      await circulation.chargeFine(
        memberId: member.memberId,
        reason: FineReason.lost,
        amount: Money.major(50),
      );

      final now = DateTime.now();
      final summary = await dashboard.loadSummary(
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 1)),
        previousStart: now.subtract(const Duration(days: 3)),
        previousEnd: now.subtract(const Duration(days: 1)),
      );

      expect(summary.finesOutstanding.display(), isNotEmpty);
      expect(summary.finesOutstanding.minorUnits, greaterThan(0));
      expect(summary.overdueCount, 0);
    },
  );
}
