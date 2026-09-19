// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'loan_rules_state.freezed.dart';

/// Loan rules record and save progress.
@freezed
abstract class LoanRulesState with _$LoanRulesState {
  const factory LoanRulesState({
    @Default(LoadStatus.initial) LoadStatus status,
    LoanRules? rules,
    AppException? error,
    @Default(false) bool isSaving,
  }) = _LoanRulesState;

  const LoanRulesState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
}
