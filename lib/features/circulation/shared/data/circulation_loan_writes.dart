// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/loan/data/loan_local_data_source.dart';
import 'package:uuid/uuid.dart';

/// Loan-row writes for checkout, return and renew.
///
/// Transaction-scoped: constructed with the same [AppDatabase] the caller
/// runs its transaction on, so every write joins that transaction. Rule
/// checks and copy-status moves stay with the caller; views are reloaded
/// through [LoanLocalDataSource].
class CirculationLoanWrites {
  CirculationLoanWrites(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();
  static const String _source = 'CirculationLoanWrites';

  /// Inserts the loan row for a checkout that already passed rule checks.
  Future<String> insertCheckoutLoan({
    required String copyId,
    required String memberId,
    required DateTime checkedOutAt,
    required DateTime dueAt,
    required int ruleLoanPeriodDays,
    required Money ruleFinePerDay,
    required int ruleGraceDays,
    required Money ruleMaximumFine,
    String? staffId,
  }) => guardDatabase(
    () async {
      final loanId = _uuid.v4();
      await _db
          .into(_db.loans)
          .insert(
            LoansCompanion.insert(
              id: loanId,
              copyId: copyId,
              memberId: memberId,
              checkedOutAt: checkedOutAt,
              dueAt: dueAt,
              ruleLoanPeriodDays: ruleLoanPeriodDays,
              ruleFinePerDay: ruleFinePerDay,
              ruleGraceDays: ruleGraceDays,
              ruleMaximumFine: ruleMaximumFine,
              createdAt: checkedOutAt,
              checkedOutByStaffId: Value(staffId),
            ),
          );
      return loanId;
    },
    source: '$_source.insertCheckoutLoan',
  );

  Future<void> markLoanReturned({
    required String loanId,
    required CopyCondition condition,
    String? staffId,
  }) => guardDatabase(
    () async {
      final now = DateTime.now();
      await (_db.update(
        _db.loans,
      )..where((loan) => loan.id.equals(loanId))).write(
        LoansCompanion(
          returnedAt: Value(now),
          returnCondition: Value(condition),
          returnedByStaffId: Value(staffId),
        ),
      );
    },
    source: '$_source.markLoanReturned',
  );

  Future<void> extendLoanDue({
    required String loanId,
    required DateTime newDueAt,
  }) => guardDatabase(
    () async {
      final loanRow = await (_db.select(
        _db.loans,
      )..where((loan) => loan.id.equals(loanId))).getSingleOrNull();
      if (loanRow == null) {
        throw const NotFoundException('That loan was not found.');
      }
      await (_db.update(
        _db.loans,
      )..where((loan) => loan.id.equals(loanId))).write(
        LoansCompanion(
          dueAt: Value(newDueAt),
          renewalCount: Value(loanRow.renewalCount + 1),
        ),
      );
    },
    source: '$_source.extendLoanDue',
  );
}
