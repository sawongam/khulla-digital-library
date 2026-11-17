// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/circulation/shared/data/circulation_copies.dart';
import 'package:khulla/features/circulation/shared/data/circulation_hold_queue.dart';
import 'package:khulla/features/circulation/shared/domain/models/copy_repair_result.dart';

/// Brings each copy's status back in line with the loans on record.
///
/// Transaction-scoped like its siblings: run it on the same [AppDatabase] the
/// caller's transaction uses. The open loan is the truth - a copy cannot be
/// on a shelf while a loan row says a member holds it, and a copy marked on
/// loan with no open loan is stuck until someone fixes it. Copies marked lost
/// or damaged are left alone: that is a deliberate decision at the desk, not
/// drift.
class CirculationCopyRepair {
  CirculationCopyRepair(this._db, this._holdQueue);

  final AppDatabase _db;
  final CirculationHoldQueue _holdQueue;

  Future<CopyRepairResult> repairCopyStatuses() => guardDatabase(
    () async {
      final copies = await _db.select(_db.copies).get();
      final openLoans = await (_db.select(
        _db.loans,
      )..where((loan) => loan.returnedAt.isNull())).get();
      final loanedCopyIds = {for (final loan in openLoans) loan.copyId};

      var repaired = 0;
      for (final copy in copies) {
        if (copy.status == CopyStatus.lost ||
            copy.status == CopyStatus.damaged) {
          continue;
        }
        final hasOpenLoan = loanedCopyIds.contains(copy.id);
        if (hasOpenLoan && copy.status != CopyStatus.onLoan) {
          await setCopyStatus(_db, copy.id, CopyStatus.onLoan);
          repaired++;
        } else if (!hasOpenLoan && copy.status == CopyStatus.onLoan) {
          final hold = await _holdQueue.findReadyHoldForCopy(copy.id);
          await setCopyStatus(
            _db,
            copy.id,
            hold == null ? CopyStatus.available : CopyStatus.reserved,
          );
          repaired++;
        }
      }
      return (checked: copies.length, repaired: repaired);
    },
    source: 'CirculationCopyRepair.repairCopyStatuses',
  );
}
