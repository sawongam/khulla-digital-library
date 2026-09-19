// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member_type.dart';

/// Reference rows for member-type pickers, rule overrides and bootstrap seeding.
abstract interface class MemberTypeLocalDataSource {
  Future<int> countMemberTypes();

  Future<List<MemberType>> findActiveMemberTypes();

  /// Every category, active and archived, for the management sheet.
  Future<List<MemberType>> findAllMemberTypes();

  Future<MemberType?> findMemberTypeById(String id);

  Future<MemberType> insertMemberType(MemberType type);

  /// Replaces every editable field on an existing category.
  Future<MemberType> updateMemberType(MemberType type);

  /// Hides a category from pickers without touching members already on it.
  Future<void> archiveMemberType(String id);

  Future<void> unarchiveMemberType(String id);
}
