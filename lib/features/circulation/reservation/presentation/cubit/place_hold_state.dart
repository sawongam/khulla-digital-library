// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'place_hold_state.freezed.dart';

/// Place-hold modal: member lookup, optional fixed title, and save progress.
@freezed
abstract class PlaceHoldState with _$PlaceHoldState {
  const factory PlaceHoldState({
    @Default(LoadStatus.initial) LoadStatus status,
    Member? member,
    Title? fixedTitle,
    @Default(<Title>[]) List<Title> titleMatches,
    Title? selectedTitle,
    @Default(false) bool isLookingUpMember,
    @Default(<Member>[]) List<Member> memberMatches,
    @Default('') String memberQuery,
    AppException? error,
    @Default(false) bool isSaving,
  }) = _PlaceHoldState;

  const PlaceHoldState._();

  bool get isLoading => status.isLoading;
}
