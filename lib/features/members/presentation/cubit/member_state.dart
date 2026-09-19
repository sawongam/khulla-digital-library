// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'member_state.freezed.dart';

/// Members list query, page of results, and load status.
@freezed
abstract class MemberState with _$MemberState {
  const factory MemberState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(MemberQuery()) MemberQuery query,
    @Default(<Member>[]) List<Member> members,
    @Default(0) int totalCount,
    AppException? error,
  }) = _MemberState;

  const MemberState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && members.isEmpty;
}
