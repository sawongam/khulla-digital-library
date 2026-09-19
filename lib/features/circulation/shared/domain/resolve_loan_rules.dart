// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart';

/// Merges global defaults with nullable member-type overrides.
///
/// Null on a type field means "use the library default from [LoanRules]".
EffectiveLoanRules resolveLoanRules(
  LoanRules defaults,
  MemberType type,
) => EffectiveLoanRules(
  loanPeriodDays: type.loanPeriodDays ?? defaults.loanPeriodDays,
  borrowingLimit: type.borrowingLimit ?? defaults.borrowingLimit,
  renewalLimit: type.renewalLimit ?? defaults.renewalLimit,
  renewalPeriodDays: type.renewalPeriodDays ?? defaults.renewalPeriodDays,
  finePerDay: type.finePerDay ?? defaults.finePerDay,
  graceDays: type.graceDays ?? defaults.graceDays,
  maximumFinePerCopy: type.maximumFinePerCopy ?? defaults.maximumFinePerCopy,
  maxOutstandingFine: type.maxOutstandingFine ?? defaults.maxOutstandingFine,
  membershipDurationMonths:
      type.membershipDurationMonths ?? defaults.membershipDurationMonths,
  reservationLimit: type.reservationLimit ?? defaults.reservationLimit,
  holdShelfDays: defaults.holdShelfDays,
  blockOverdueBorrowers: defaults.blockOverdueBorrowers,
  autoRenewWhenUnreserved: defaults.autoRenewWhenUnreserved,
);
