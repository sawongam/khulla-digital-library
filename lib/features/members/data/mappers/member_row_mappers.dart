// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/members/domain/models/member.dart';

/// Maps [MemberRow] to [Member] and back for drift writes.
///
/// Loan and fine aggregates are supplied by the list query, not stored on the
/// member row itself.
extension MemberRowMapper on MemberRow {
  Member toDomain({
    required String memberTypeName,
    required int loansOut,
    required int overdueLoans,
    required Money finesOwed,
    required int borrowedAllTime,
    String? memberTypeCode,
  }) => Member(
    id: id,
    fullName: fullName,
    barcode: barcode,
    memberTypeId: memberTypeId,
    memberTypeName: memberTypeName,
    memberTypeCode: memberTypeCode,
    joinedAt: joinedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    loansOut: loansOut,
    overdueLoans: overdueLoans,
    finesOwed: finesOwed,
    borrowedAllTime: borrowedAllTime,
    sendNotices: sendNotices,
    gender: gender,
    dateOfBirth: dateOfBirth,
    bloodGroup: bloodGroup,
    email: email,
    phone: phone,
    address: address,
    municipality: municipality,
    occupation: occupation,
    institution: institution,
    idVerification: idVerification,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    guardian: guardian,
    notes: notes,
    expiresAt: expiresAt,
    suspendedAt: suspendedAt,
    suspensionReason: suspensionReason,
    archivedAt: archivedAt,
  );
}

extension MemberDomainMapper on Member {
  MembersCompanion toCompanion() => MembersCompanion(
    id: Value(id),
    barcode: Value(barcode),
    fullName: Value(fullName),
    memberTypeId: Value(memberTypeId),
    gender: Value(gender),
    dateOfBirth: Value(dateOfBirth),
    bloodGroup: Value(bloodGroup),
    email: Value(email),
    phone: Value(phone),
    address: Value(address),
    municipality: Value(municipality),
    occupation: Value(occupation),
    institution: Value(institution),
    idVerification: Value(idVerification),
    emergencyContactName: Value(emergencyContactName),
    emergencyContactPhone: Value(emergencyContactPhone),
    guardian: Value(guardian),
    notes: Value(notes),
    joinedAt: Value(joinedAt),
    expiresAt: Value(expiresAt),
    suspendedAt: Value(suspendedAt),
    suspensionReason: Value(suspensionReason),
    sendNotices: Value(sendNotices),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    archivedAt: Value(archivedAt),
  );
}
