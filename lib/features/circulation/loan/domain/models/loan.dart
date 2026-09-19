// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/loan_status.dart';

part 'loan.freezed.dart';

/// One checkout - open while [returnedAt] is null.
@freezed
abstract class Loan with _$Loan {
  const factory Loan({
    required String id,
    required String copyId,
    required String memberId,
    required DateTime checkedOutAt,
    required DateTime dueAt,
    required int renewalCount,
    required int ruleLoanPeriodDays,
    required Money ruleFinePerDay,
    required int ruleGraceDays,
    required Money ruleMaximumFine,
    required DateTime createdAt,
    String? barcode,
    String? titleId,
    String? titleName,
    String? memberName,
    DateTime? returnedAt,
    CopyCondition? returnCondition,
    String? checkedOutByStaffId,
    String? returnedByStaffId,
  }) = _Loan;

  const Loan._();

  bool get isOpen => returnedAt == null;

  LoanStatus get status {
    if (returnedAt != null) return LoanStatus.returned;
    final today = dateOnly(DateTime.now());
    final due = dateOnly(dueAt);
    if (today.isAfter(due)) return LoanStatus.overdue;
    if (today == due) return LoanStatus.dueToday;
    return LoanStatus.onLoan;
  }

  int get daysLate =>
      isOpen ? overdueDays(dueAt: dueAt, asOf: DateTime.now()) : 0;

  Money get accruedFine => isOpen
      ? computeOverdueFine(
          dueAt: dueAt,
          asOf: DateTime.now(),
          finePerDay: ruleFinePerDay,
          graceDays: ruleGraceDays,
          maximumFine: ruleMaximumFine,
        )
      : Money.zero;

  String get issuedOn => AppDateFormat.format(checkedOutAt);

  String get dueOn => AppDateFormat.format(dueAt);
}
