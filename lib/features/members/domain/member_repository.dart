// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

/// Borrowers on the register: search, save, archive and hard-delete.
///
/// [saveMember] resolves the type name, builds search text, and sets
/// membership expiry on first insert from loan rules. [removeMember] refuses
/// when loans or fines exist.

abstract interface class MemberRepository {
  Future<MemberListResult> findMembers(MemberQuery query);

  Future<Member?> findMember(String id);

  Future<Member?> findMemberByBarcode(String barcode);

  Future<Member> saveMember({
    required String fullName,
    required String memberTypeId,
    String? id,
    String? barcode,
    bool sendNotices,
    Gender? gender,
    DateTime? dateOfBirth,
    BloodGroup? bloodGroup,
    String? email,
    String? phone,
    String? address,
    String? municipality,
    String? occupation,
    String? institution,
    String? idVerification,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? guardian,
    String? notes,
  });

  Future<void> archiveMember(String id);

  Future<Member> suspendMember(String id, {String? reason});

  Future<Member> unsuspendMember(String id);

  Future<Member> renewMembership(String id);

  Future<void> removeMember(String id);
}
