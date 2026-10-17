// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'loan_list_state.freezed.dart';

/// Open loans list, sidebar counts, and load status.
@freezed
abstract class LoanListState with _$LoanListState {
  const factory LoanListState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(LoanQuery(openOnly: true)) LoanQuery query,
    @Default(<Loan>[]) List<Loan> loans,
    @Default(0) int totalCount,
    @Default(0) int onLoanCount,
    @Default(0) int dueTodayCount,
    @Default(0) int overdueCount,
    @Default(0) int holdsCount,
    AppException? error,
  }) = _LoanListState;

  const LoanListState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && loans.isEmpty;
}
