// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/data/title_format_local_data_source.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/members/data/member_type_local_data_source.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/settings/data/loan_rules_local_data_source.dart';
import 'package:khulla/features/settings/data/loan_rules_repository_impl.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:uuid/uuid.dart';

/// [ReferenceDataRepository] backed by the owning sub-feature data sources.
///
/// Coordinates bootstrap seeding across [TitleFormatLocalDataSource],
/// [MemberTypeLocalDataSource] and [LoanRulesLocalDataSource] so bootstrap
/// has one call site. Read paths delegate straight through; no mapping here.
@LazySingleton(as: ReferenceDataRepository)
class ReferenceDataRepositoryImpl implements ReferenceDataRepository {
  ReferenceDataRepositoryImpl(
    this._formats,
    this._memberTypes,
    this._loanRules,
  );

  final TitleFormatLocalDataSource _formats;
  final MemberTypeLocalDataSource _memberTypes;
  final LoanRulesLocalDataSource _loanRules;

  static const Uuid _uuid = Uuid();

  static const _formatCodes = [
    'book',
    'journal',
    'other',
  ];

  static const _memberTypeCodes = [
    'student',
    'teacher',
    'public',
    'child',
    'other',
  ];

  /// Seeds system formats, member types and default loan rules on a fresh catalogue.
  @override
  Future<void> ensureDefaults({
    required String Function(String code) formatName,
    required String Function(String code) memberTypeName,
  }) async {
    final now = DateTime.now();

    if (await _formats.countFormats() == 0) {
      for (var i = 0; i < _formatCodes.length; i++) {
        final code = _formatCodes[i];
        await _formats.insertFormat(
          TitleFormat(
            id: _uuid.v4(),
            code: code,
            name: formatName(code),
            sortOrder: i,
            isSystem: true,
            createdAt: now,
          ),
        );
      }
    }

    if (await _memberTypes.countMemberTypes() == 0) {
      for (var i = 0; i < _memberTypeCodes.length; i++) {
        final code = _memberTypeCodes[i];
        await _memberTypes.insertMemberType(
          MemberType(
            id: _uuid.v4(),
            code: code,
            name: memberTypeName(code),
            sortOrder: i,
            isSystem: true,
            createdAt: now,
          ),
        );
      }
    }

    if (await _loanRules.findRules() == null) {
      await _loanRules.saveRules(
        LoanRulesRepositoryImpl.defaults(updatedAt: now),
      );
    }
  }

  @override
  Future<List<TitleFormat>> findActiveFormats() => _formats.findActiveFormats();

  @override
  Future<TitleFormat> addFormat(String name) async {
    final trimmed = name.trim();
    final formats = await findActiveFormats();
    _ensureUniqueName(formats, trimmed);
    var maxOrder = -1;
    for (final format in formats) {
      if (format.sortOrder > maxOrder) maxOrder = format.sortOrder;
    }
    return await _formats.insertFormat(
      TitleFormat(
        id: _uuid.v4(),
        name: trimmed,
        sortOrder: maxOrder + 1,
        isSystem: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<TitleFormat> saveFormat({
    required String id,
    required String name,
  }) async {
    final trimmed = name.trim();
    final formats = await findActiveFormats();
    TitleFormat? current;
    for (final format in formats) {
      if (format.id == id) current = format;
    }
    if (current == null) {
      throw const NotFoundException();
    }
    _ensureUniqueName(formats, trimmed, exceptId: id);
    return await _formats.updateFormat(current.copyWith(name: trimmed));
  }

  @override
  Future<void> removeFormat(String id) async {
    final formats = await findActiveFormats();
    if (formats.length <= 1) {
      throw const ConflictException();
    }
    final exists = formats.any((format) => format.id == id);
    if (!exists) {
      throw const NotFoundException();
    }
    await _formats.archiveFormat(id, DateTime.now());
  }

  void _ensureUniqueName(
    List<TitleFormat> formats,
    String name, {
    String? exceptId,
  }) {
    if (name.isEmpty) {
      throw const InvalidInputException();
    }
    final needle = name.toLowerCase();
    for (final format in formats) {
      if (format.id == exceptId) continue;
      if (format.name.toLowerCase() == needle) {
        throw const DuplicateRecordException();
      }
    }
  }

  @override
  Future<List<MemberType>> findActiveMemberTypes() =>
      _memberTypes.findActiveMemberTypes();

  @override
  Future<List<MemberType>> findAllMemberTypes() =>
      _memberTypes.findAllMemberTypes();

  @override
  Future<MemberType> addMemberType(MemberType draft) async {
    final name = draft.name.trim();
    final types = await findActiveMemberTypes();
    _ensureUniqueMemberTypeName(types, name);
    var maxOrder = -1;
    for (final type in types) {
      if (type.sortOrder > maxOrder) maxOrder = type.sortOrder;
    }
    return await _memberTypes.insertMemberType(
      draft.copyWith(
        id: _uuid.v4(),
        name: name,
        sortOrder: maxOrder + 1,
        isSystem: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<MemberType> saveMemberType(MemberType draft) async {
    final name = draft.name.trim();
    final current = await _memberTypes.findMemberTypeById(draft.id);
    if (current == null) {
      throw const NotFoundException();
    }
    final types = await findActiveMemberTypes();
    _ensureUniqueMemberTypeName(types, name, exceptId: draft.id);
    return await _memberTypes.updateMemberType(
      draft.copyWith(
        name: name,
        isSystem: current.isSystem,
        createdAt: current.createdAt,
      ),
    );
  }

  @override
  Future<void> removeMemberType(String id) async {
    final types = await findActiveMemberTypes();
    if (types.length <= 1) {
      throw const ConflictException();
    }
    final exists = types.any((type) => type.id == id);
    if (!exists) {
      throw const NotFoundException();
    }
    await _memberTypes.archiveMemberType(id);
  }

  @override
  Future<void> restoreMemberType(String id) =>
      _memberTypes.unarchiveMemberType(id);

  void _ensureUniqueMemberTypeName(
    List<MemberType> types,
    String name, {
    String? exceptId,
  }) {
    if (name.isEmpty) {
      throw const InvalidInputException();
    }
    final needle = name.toLowerCase();
    for (final type in types) {
      if (type.id == exceptId) continue;
      if (type.name.toLowerCase() == needle) {
        throw const DuplicateRecordException();
      }
    }
  }
}
