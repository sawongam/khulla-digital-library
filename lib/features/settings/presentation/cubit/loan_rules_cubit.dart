// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/domain/loan_rules_repository.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart';
import 'package:khulla/features/settings/presentation/cubit/loan_rules_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Circulation policy settings: loan periods, limits and fine rates.
///
/// Page-scoped `@injectable` cubit backed by [LoanRulesRepository].
/// [loadRules] failures emit into state; [saveRules] emits and rethrows.
@injectable
class LoanRulesCubit extends Cubit<LoanRulesState> {
  LoanRulesCubit(this._repository, this._settings)
    : super(const LoanRulesState());

  final LoanRulesRepository _repository;
  final LibrarySettingsRepository _settings;

  /// Loads the single loan-rules row.
  Future<void> loadRules() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final rules = await _repository.findRules();
      final profile = await _settings.findProfile();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          rules: rules,
          profile: profile,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Persists edited rules. Emits and rethrows on failure.
  ///
  /// The library-wide switches the page edits beside the rules - whether fines
  /// are charged, which member-form fields are hidden - save with them.
  Future<void> saveRules(
    LoanRules rules, {
    required bool chargesFines,
    required Set<MemberOptionalField> hiddenMemberFields,
  }) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final saved = await _repository.saveRules(rules);
      await _settings.saveChargesFines(chargesFines: chargesFines);
      final profile = await _settings.saveHiddenMemberFields(
        hiddenMemberFields,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          rules: saved,
          profile: profile,
          isSaving: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }

  /// Builds a [LoanRules] draft from form fields, parsing money at the edge.
  LoanRules draftFromForm({
    required int loanPeriodDays,
    required int renewalLimit,
    required int borrowingLimit,
    required String finePerDayText,
    required int graceDays,
    required String maximumFineText,
    required int holdShelfDays,
    required bool blockOverdueBorrowers,
    required bool autoRenewWhenUnreserved,
  }) {
    final existing = state.rules!;
    return existing.copyWith(
      loanPeriodDays: loanPeriodDays,
      renewalLimit: renewalLimit,
      borrowingLimit: borrowingLimit,
      finePerDay: finePerDayText.toMoney(),
      graceDays: graceDays,
      maximumFinePerCopy: maximumFineText.toMoney(),
      holdShelfDays: holdShelfDays,
      blockOverdueBorrowers: blockOverdueBorrowers,
      autoRenewWhenUnreserved: autoRenewWhenUnreserved,
    );
  }
}
