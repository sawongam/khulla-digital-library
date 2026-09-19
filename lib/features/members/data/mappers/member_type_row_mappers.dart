// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';

/// Maps [MemberTypeRow] to [MemberType] and back for drift writes.
extension MemberTypeRowX on MemberTypeRow {
  MemberType toDomain() => MemberType(
    id: id,
    code: code,
    name: name,
    sortOrder: sortOrder,
    isSystem: isSystem,
    archivedAt: archivedAt,
    createdAt: createdAt,
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
  );
}

extension MemberTypeDomainX on MemberType {
  MemberTypesCompanion toCompanion() => MemberTypesCompanion(
    id: Value(id),
    code: Value(code),
    name: Value(name),
    sortOrder: Value(sortOrder),
    isSystem: Value(isSystem),
    archivedAt: Value(archivedAt),
    createdAt: Value(createdAt),
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
  );
}
