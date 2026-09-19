// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'staff_list_state.freezed.dart';

/// The staff register, as the accounts and roles screens read it.
@freezed
abstract class StaffListState with _$StaffListState {
  const factory StaffListState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<StaffMember>[]) List<StaffMember> staff,
    AppException? error,
  }) = _StaffListState;

  const StaffListState._();

  bool get isLoading => status.isLoading;
}
