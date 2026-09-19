// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/settings/data/tables/loan_rules.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart'
    as domain;

/// Maps [LoanRulesRow] to [domain.LoanRules] and back for drift writes.
extension LoanRulesRowX on LoanRulesRow {
  domain.LoanRules toDomain() => domain.LoanRules(
    loanPeriodDays: loanPeriodDays,
    borrowingLimit: borrowingLimit,
    renewalLimit: renewalLimit,
    renewalPeriodDays: renewalPeriodDays,
    finePerDay: finePerDay,
    graceDays: graceDays,
    maximumFinePerCopy: maximumFinePerCopy,
    maxOutstandingFine: maxOutstandingFine,
    membershipDurationMonths: membershipDurationMonths,
    reservationLimit: reservationLimit,
    holdShelfDays: holdShelfDays,
    blockOverdueBorrowers: blockOverdueBorrowers,
    autoRenewWhenUnreserved: autoRenewWhenUnreserved,
    updatedAt: updatedAt,
  );
}

extension LoanRulesDomainX on domain.LoanRules {
  LoanRulesCompanion toCompanion() => LoanRulesCompanion(
    id: const Value(LoanRules.singletonId),
    loanPeriodDays: Value(loanPeriodDays),
    borrowingLimit: Value(borrowingLimit),
    renewalLimit: Value(renewalLimit),
    renewalPeriodDays: Value(renewalPeriodDays),
    finePerDay: Value(finePerDay),
    graceDays: Value(graceDays),
    maximumFinePerCopy: Value(maximumFinePerCopy),
    maxOutstandingFine: Value(maxOutstandingFine),
    membershipDurationMonths: Value(membershipDurationMonths),
    reservationLimit: Value(reservationLimit),
    holdShelfDays: Value(holdShelfDays),
    blockOverdueBorrowers: Value(blockOverdueBorrowers),
    autoRenewWhenUnreserved: Value(autoRenewWhenUnreserved),
    updatedAt: Value(updatedAt),
  );
}
