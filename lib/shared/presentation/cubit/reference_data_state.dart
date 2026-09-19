// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'reference_data_state.freezed.dart';

/// Cached title formats and member types for forms and filters app-wide.
@freezed
abstract class ReferenceDataState with _$ReferenceDataState {
  const factory ReferenceDataState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<TitleFormat>[]) List<TitleFormat> formats,
    @Default(<MemberType>[]) List<MemberType> memberTypes,
    AppException? error,
  }) = _ReferenceDataState;

  const ReferenceDataState._();

  bool get isLoading => status.isLoading;
}
