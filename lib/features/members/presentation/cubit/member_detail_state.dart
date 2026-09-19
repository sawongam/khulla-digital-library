// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'member_detail_state.freezed.dart';

/// One member with loans, history and outstanding fines.
@freezed
abstract class MemberDetailState with _$MemberDetailState {
  const factory MemberDetailState({
    @Default(LoadStatus.initial) LoadStatus status,
    Member? member,
    @Default(<Loan>[]) List<Loan> openLoans,
    @Default(<Loan>[]) List<Loan> historyLoans,
    @Default(<Fine>[]) List<Fine> fines,
    AppException? error,
  }) = _MemberDetailState;

  const MemberDetailState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
}
