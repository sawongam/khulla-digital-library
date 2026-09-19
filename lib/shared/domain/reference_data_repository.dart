// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';

/// Seeds and reads reference rows shared across catalogue, members and settings.
///
/// One contract for rows that several features need but none owns alone:
/// formats, member types, and the default loan-rules row at first run.
abstract interface class ReferenceDataRepository {
  /// Inserts default formats, member types and loan rules when absent.
  ///
  /// Called once from bootstrap; [formatName] and [memberTypeName] supply
  /// localized labels for the seeded system codes.
  Future<void> ensureDefaults({
    required String Function(String code) formatName,
    required String Function(String code) memberTypeName,
  });

  /// Active title formats in display order.
  Future<List<TitleFormat>> findActiveFormats();

  /// Inserts an operator-created format and returns it.
  Future<TitleFormat> addFormat(String name);

  /// Renames an active format.
  Future<TitleFormat> saveFormat({required String id, required String name});

  /// Hides a format from pickers. Titles that already use it keep the link.
  Future<void> removeFormat(String id);

  /// Active member types in display order.
  Future<List<MemberType>> findActiveMemberTypes();

  /// Every member type, active and archived, for the management sheet.
  Future<List<MemberType>> findAllMemberTypes();

  /// Inserts an operator-created category. `draft`'s id, sort order,
  /// `isSystem` and `createdAt` are assigned here and may be anything.
  Future<MemberType> addMemberType(MemberType draft);

  /// Replaces an existing category's name and rule overrides. `isSystem`
  /// and `createdAt` are carried over from the stored row regardless of
  /// what `draft` holds.
  Future<MemberType> saveMemberType(MemberType draft);

  /// Hides a category from pickers. Members already on it keep the link.
  /// Refuses to archive the last active category.
  Future<void> removeMemberType(String id);

  /// Brings an archived category back into pickers.
  Future<void> restoreMemberType(String id);
}
