// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/data/local_title_format_data_source.dart';
import 'package:khulla/features/members/data/local_member_type_data_source.dart';
import 'package:khulla/features/settings/data/loan_rules_repository_impl.dart';
import 'package:khulla/features/settings/data/local_loan_rules_data_source.dart';
import 'package:khulla/shared/data/reference_data_repository_impl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

typedef ReferenceSeed = ({
  String formatId,
  String memberTypeId,
});

typedef TitleWithCopySeed = ({
  String titleId,
  String copyId,
  String barcode,
});

typedef MemberSeed = ({
  String memberId,
  String barcode,
});

/// Seeds the reference rows every catalogue test needs.
///
/// Formats, member types and loan rules are inserted through
/// [ReferenceDataRepositoryImpl.ensureDefaults] when missing, so tests start
/// from the same baseline the app does on first open.
Future<ReferenceSeed> seedReferenceData(AppDatabase db) async {
  final formats = LocalTitleFormatDataSource(db);
  final memberTypes = LocalMemberTypeDataSource(db);
  final loanRules = LocalLoanRulesDataSource(db);
  final reference = ReferenceDataRepositoryImpl(
    formats,
    memberTypes,
    loanRules,
  );

  await reference.ensureDefaults(
    formatName: (code) => code,
    memberTypeName: (code) => code,
  );

  final formatId = (await formats.findActiveFormats()).first.id;
  final memberTypeId = (await memberTypes.findActiveMemberTypes()).first.id;

  return (formatId: formatId, memberTypeId: memberTypeId);
}

/// One lendable title and an available copy — the smallest checkout scenario.
Future<TitleWithCopySeed> seedTitleWithCopy(
  AppDatabase db, {
  required String formatId,
  String barcode = 'TEST-001',
  String title = 'Test Title',
}) async {
  final now = DateTime.now();
  final titleId = _uuid.v4();
  final copyId = _uuid.v4();

  await db
      .into(db.titles)
      .insert(
        TitlesCompanion.insert(
          id: titleId,
          title: title,
          author: 'Test Author',
          formatId: formatId,
          createdAt: now,
          updatedAt: now,
        ),
      );

  await db
      .into(db.copies)
      .insert(
        CopiesCompanion.insert(
          id: copyId,
          titleId: titleId,
          barcode: barcode,
          status: CopyStatus.available,
          acquiredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

  return (titleId: titleId, copyId: copyId, barcode: barcode);
}

/// A member barcode on the register, optionally expired or suspended.
Future<MemberSeed> seedMember(
  AppDatabase db, {
  required String memberTypeId,
  String barcode = 'MEM-001',
  String fullName = 'Test Member',
  DateTime? expiresAt,
  DateTime? suspendedAt,
}) async {
  final now = DateTime.now();
  final memberId = _uuid.v4();

  await db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: memberId,
          barcode: barcode,
          fullName: fullName,
          memberTypeId: memberTypeId,
          joinedAt: now,
          createdAt: now,
          updatedAt: now,
          expiresAt: Value(expiresAt),
          suspendedAt: Value(suspendedAt),
        ),
      );

  return (memberId: memberId, barcode: barcode);
}

/// Tweaks the singleton loan-rules row without going through a repository.
Future<void> updateLoanRules(
  AppDatabase db, {
  int? borrowingLimit,
  Money? finePerDay,
}) async {
  final dataSource = LocalLoanRulesDataSource(db);
  final current =
      await dataSource.findRules() ?? LoanRulesRepositoryImpl.defaults();
  await dataSource.saveRules(
    current.copyWith(
      borrowingLimit: borrowingLimit ?? current.borrowingLimit,
      finePerDay: finePerDay ?? current.finePerDay,
      updatedAt: DateTime.now(),
    ),
  );
}
