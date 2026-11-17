// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/shared/data/circulation_copy_repair.dart';
import 'package:khulla/features/circulation/shared/data/circulation_hold_queue.dart';
import 'package:khulla/features/circulation/shared/data/effective_rules_reader.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late CirculationCopyRepair repair;
  final now = DateTime(2026, 1, 10);

  setUp(() async {
    db = await openTestDatabase();
    // Rows are inserted without their parents: only status logic is tested.
    await db.customStatement('PRAGMA foreign_keys = OFF');
    repair = CirculationCopyRepair(
      db,
      CirculationHoldQueue(db, EffectiveRulesReader(db)),
    );
  });

  tearDown(() => closeTestDatabase(db));

  Future<void> insertCopy(String id, CopyStatus status) => db
      .into(db.copies)
      .insert(
        CopiesCompanion.insert(
          id: id,
          titleId: 't',
          barcode: id,
          status: status,
          acquiredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

  Future<void> insertOpenLoan(String copyId) => db
      .into(db.loans)
      .insert(
        LoansCompanion.insert(
          id: 'loan-$copyId',
          copyId: copyId,
          checkedOutAt: now,
          dueAt: DateTime(2026, 1, 24),
          ruleLoanPeriodDays: 14,
          ruleFinePerDay: Money.zero,
          ruleGraceDays: 0,
          ruleMaximumFine: Money.zero,
          createdAt: now,
        ),
      );

  Future<CopyStatus> statusOf(String id) async => (await (db.select(
    db.copies,
  )..where((c) => c.id.equals(id))).getSingle()).status;

  test('repairs both directions and leaves consistent copies alone', () async {
    await insertCopy('ghost-available', CopyStatus.available);
    await insertOpenLoan('ghost-available');
    await insertCopy('stuck-on-loan', CopyStatus.onLoan);
    await insertCopy('fine-on-loan', CopyStatus.onLoan);
    await insertOpenLoan('fine-on-loan');
    await insertCopy('fine-shelf', CopyStatus.available);
    await insertCopy('lost', CopyStatus.lost);

    final result = await repair.repairCopyStatuses();

    expect(result, (checked: 5, repaired: 2));
    expect(await statusOf('ghost-available'), CopyStatus.onLoan);
    expect(await statusOf('stuck-on-loan'), CopyStatus.available);
    expect(await statusOf('fine-on-loan'), CopyStatus.onLoan);
    expect(await statusOf('lost'), CopyStatus.lost);
  });
}
