// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/money/money.dart';

part 'loan_rules.freezed.dart';

/// The library-wide lending policy stored in the singleton row.
@freezed
abstract class LoanRules with _$LoanRules {
  const factory LoanRules({
    required int loanPeriodDays,
    required int borrowingLimit,
    required int renewalLimit,
    required Money finePerDay,
    required int graceDays,
    required Money maximumFinePerCopy,
    required int membershipDurationMonths,
    required int reservationLimit,
    required int holdShelfDays,
    required bool blockOverdueBorrowers,
    required bool autoRenewWhenUnreserved,
    required DateTime updatedAt,
    int? renewalPeriodDays,
    Money? maxOutstandingFine,
  }) = _LoanRules;

  const LoanRules._();
}
