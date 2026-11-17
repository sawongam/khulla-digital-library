// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';

/// Drift access to `members` and the aggregates shown on list rows.
abstract interface class MemberLocalDataSource {
  Future<MemberListResult> findMembers(MemberQuery query);

  Future<Member?> findMemberById(String id);

  Future<Member?> findMemberByBarcode(String barcode);

  Future<Member> insertMember(Member member);

  Future<Member> updateMember(Member member);

  Future<void> archiveMember(String id, DateTime archivedAt);

  Future<void> restoreMember(String id);

  /// Deletes a member and anonymises what they leave behind, in one
  /// transaction. Throws if they still hold a loan or owe a fine.
  Future<void> deleteMember(String id);
}
