// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';

part 'return_state.freezed.dart';

/// Returns desk basket, check-in options and submit progress.
@freezed
abstract class ReturnState with _$ReturnState {
  const factory ReturnState({
    @Default(<Loan>[]) List<Loan> basket,
    @Default(false) bool waiveFines,
    @Default(CopyCondition.good) CopyCondition condition,
    @Default(false) bool isSubmitting,
    AppException? error,
  }) = _ReturnState;

  const ReturnState._();

  bool get canConfirm => basket.isNotEmpty && !isSubmitting;

  int get lateCount => basket.where((loan) => loan.daysLate > 0).length;

  /// Accrued fines across the basket, zeroed when [waiveFines] is set.
  Money get finesDue => waiveFines
      ? Money.zero
      : Money.sum([for (final loan in basket) loan.accruedFine]);
}
