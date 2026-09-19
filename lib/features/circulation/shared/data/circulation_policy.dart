// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';
import 'package:khulla/features/circulation/shared/domain/resolve_loan_rules.dart';
import 'package:khulla/features/members/data/mappers/member_type_row_mappers.dart';
import 'package:khulla/features/settings/data/mappers/loan_rules_row_mappers.dart';
import 'package:khulla/features/settings/data/tables/loan_rules.dart';

/// Eligibility reads shared by checkout, renew and holds.
///
/// Transaction-scoped: constructed with the same [AppDatabase] the caller
/// runs its transaction on, so every read joins that transaction. Each entry
/// is wrapped in [guardDatabase] like any other data-source body.
class CirculationPolicy {
  CirculationPolicy(this._db);

  final AppDatabase _db;

  static const String _source = 'CirculationPolicy';

  Future<EffectiveLoanRules> loadEffectiveRules(String memberTypeId) =>
      guardDatabase(
        () => _loadEffectiveRules(memberTypeId),
        source: '$_source.loadEffectiveRules',
      );

  Future<EffectiveLoanRules> loadEffectiveRulesForMember(String memberId) =>
      guardDatabase(
        () => _loadEffectiveRulesForMember(memberId),
        source: '$_source.loadEffectiveRulesForMember',
      );

  /// Pickup-window length for ready holds, without leaking the drift row.
  Future<int> loadHoldShelfDays() => guardDatabase(
    () => _loadLoanRulesRow().then((row) => row.holdShelfDays),
    source: '$_source.loadHoldShelfDays',
  );

  Future<EffectiveLoanRules> _loadEffectiveRules(String memberTypeId) async {
    final typeRow = await (_db.select(
      _db.memberTypes,
    )..where((type) => type.id.equals(memberTypeId))).getSingleOrNull();
    if (typeRow == null) {
      throw const NotFoundException('That member type was not found.');
    }
    final rulesRow = await _loadLoanRulesRow();
    return resolveLoanRules(rulesRow.toDomain(), typeRow.toDomain());
  }

  Future<EffectiveLoanRules> _loadEffectiveRulesForMember(
    String memberId,
  ) async {
    final memberRow = await (_db.select(
      _db.members,
    )..where((member) => member.id.equals(memberId))).getSingleOrNull();
    if (memberRow == null) {
      throw const NotFoundException('That member was not found.');
    }
    return await _loadEffectiveRules(memberRow.memberTypeId);
  }

  Future<LoanRulesRow> _loadLoanRulesRow() async {
    final rulesRow =
        await (_db.select(_db.loanRules)..where(
              (rules) => rules.id.equals(LoanRules.singletonId),
            ))
            .getSingleOrNull();
    if (rulesRow == null) {
      throw const NotFoundException('Loan rules have not been configured.');
    }
    return rulesRow;
  }

  /// Rejects archived, suspended and expired members in one call so
  /// checkout and hold placement share a single eligibility entry.
  void rejectIneligibleMember({
    required DateTime? archivedAt,
    required DateTime? suspendedAt,
    required DateTime? expiresAt,
    required DateTime today,
  }) {
    rejectArchivedMember(archivedAt);
    rejectSuspendedMember(suspendedAt);
    rejectExpiredMember(expiresAt, today);
  }

  void rejectArchivedMember(DateTime? archivedAt) {
    if (archivedAt != null) {
      throw const ConflictException('That member has been archived.');
    }
  }

  void rejectSuspendedMember(DateTime? suspendedAt) {
    if (suspendedAt != null) {
      throw const ConflictException('That member is suspended.');
    }
  }

  void rejectExpiredMember(DateTime? expiresAt, DateTime today) {
    if (expiresAt != null && dateOnly(expiresAt).isBefore(today)) {
      throw const ConflictException('That member membership has expired.');
    }
  }
}
