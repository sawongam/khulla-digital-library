// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'member_type_state.freezed.dart';

/// Every member category, active and archived, for the manage-categories modal.
@freezed
abstract class MemberTypeState with _$MemberTypeState {
  const factory MemberTypeState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<MemberType>[]) List<MemberType> types,
    AppException? error,
  }) = _MemberTypeState;

  const MemberTypeState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && types.isEmpty;
}
