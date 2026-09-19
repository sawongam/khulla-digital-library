// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'member_form_state.freezed.dart';

/// Member form: existing record, type picker options, and save progress.
@freezed
abstract class MemberFormState with _$MemberFormState {
  const factory MemberFormState({
    @Default(LoadStatus.initial) LoadStatus status,
    Member? existing,
    @Default(<MemberType>[]) List<MemberType> memberTypes,
    AppException? error,
    @Default(false) bool isSaving,
  }) = _MemberFormState;

  const MemberFormState._();

  bool get isLoading => status.isLoading;
}
