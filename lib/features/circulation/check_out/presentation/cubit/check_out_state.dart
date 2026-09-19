// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/circulation/shared/domain/models/effective_loan_rules.dart';
import 'package:khulla/features/members/domain/models/member.dart';

part 'check_out_state.freezed.dart';

/// Check-out desk: selected member, basket, and effective loan rules.
@freezed
abstract class CheckOutState with _$CheckOutState {
  const factory CheckOutState({
    Member? member,
    EffectiveLoanRules? rules,
    @Default(<Copy>[]) List<Copy> basket,
    @Default(false) bool isSubmitting,
    @Default(false) bool isLookingUpMember,
    @Default(<Member>[]) List<Member> memberMatches,
    @Default('') String memberQuery,
    AppException? error,
  }) = _CheckOutState;

  const CheckOutState._();

  /// True when a member is set, the basket is non-empty, and no submit is in flight.
  bool get canConfirm => member != null && basket.isNotEmpty && !isSubmitting;

  int get borrowingLimit => rules?.borrowingLimit ?? 0;

  int get loanPeriodDays => rules?.loanPeriodDays ?? 0;

  /// Open loans plus basket size — compared against [borrowingLimit].
  int get copiesAfterCheckout => (member?.loansOut ?? 0) + basket.length;

  /// Whether confirming would exceed the member's borrowing limit.
  bool get isOverBorrowingLimit =>
      rules != null && copiesAfterCheckout > rules!.borrowingLimit;
}
