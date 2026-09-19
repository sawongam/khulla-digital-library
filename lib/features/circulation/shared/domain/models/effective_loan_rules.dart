// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/money/money.dart';

part 'effective_loan_rules.freezed.dart';

/// The rules that apply to one member after merging type overrides with defaults.
@freezed
abstract class EffectiveLoanRules with _$EffectiveLoanRules {
  const factory EffectiveLoanRules({
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
    int? renewalPeriodDays,
    Money? maxOutstandingFine,
  }) = _EffectiveLoanRules;

  const EffectiveLoanRules._();
}
