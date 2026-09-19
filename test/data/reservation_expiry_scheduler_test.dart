// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/circulation/fine/data/local_fine_data_source.dart';
import 'package:khulla/features/circulation/loan/data/local_loan_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/local_reservation_data_source.dart';
import 'package:khulla/features/circulation/reservation/data/reservation_expiry_scheduler.dart';
import 'package:khulla/features/circulation/reservation/presentation/reservation_list_refresh.dart';
import 'package:khulla/features/circulation/shared/data/circulation_repository_impl.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';

import '../helpers/catalog_fixtures.dart';
import '../helpers/test_database.dart';

/// [ReservationExpiryScheduler] against a real database - the periodic timer
/// itself is trivial; what matters is that a single tick actually expires a
/// hold past its pickup window and tells the reservation list to refresh.
void main() {
  late AppDatabase db;
  late CirculationRepositoryImpl repository;
  late ReservationListRefresh refresh;
  late ReservationExpiryScheduler scheduler;

  setUp(() async {
    db = await openTestDatabase();
    repository = CirculationRepositoryImpl(
      db,
      LocalLoanDataSource(db),
      LocalFineDataSource(db),
      LocalReservationDataSource(db),
    );
    refresh = ReservationListRefresh();
    scheduler = ReservationExpiryScheduler(repository, refresh);
  });

  tearDown(() {
    scheduler.dispose();
    return closeTestDatabase(db);
  });

  test(
    'start expires a ready hold past its pickup window and refreshes the list',
    () async {
      final reference = await seedReferenceData(db);
      final seeded = await seedTitleWithCopy(db, formatId: reference.formatId);
      final member = await seedMember(db, memberTypeId: reference.memberTypeId);

      final hold = await repository.placeHold(
        memberId: member.memberId,
        titleId: seeded.titleId,
      );
      final ready = await repository.markHoldReady(hold.id);

      // Backdated directly - `markHoldReady` sets `expiresAt` from today's
      // loan rules, and there is no repository call that ages a hold on
      // purpose.
      await (db.update(
        db.reservations,
      )..where((r) => r.id.equals(ready.id))).write(
        ReservationsCompanion(
          expiresAt: Value(DateTime.now().subtract(const Duration(days: 1))),
        ),
      );

      var notified = false;
      refresh.reload = () => notified = true;

      await scheduler.start();

      final row = await (db.select(
        db.reservations,
      )..where((r) => r.id.equals(ready.id))).getSingle();
      expect(row.status, ReservationStatus.expired);
      expect(notified, isTrue);
    },
  );
}
