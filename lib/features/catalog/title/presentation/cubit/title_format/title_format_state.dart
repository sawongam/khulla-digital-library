// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'title_format_state.freezed.dart';

/// Active title formats for the manage-formats modal.
@freezed
abstract class TitleFormatState with _$TitleFormatState {
  const factory TitleFormatState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<TitleFormat>[]) List<TitleFormat> formats,
    AppException? error,
  }) = _TitleFormatState;

  const TitleFormatState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && formats.isEmpty;
}
