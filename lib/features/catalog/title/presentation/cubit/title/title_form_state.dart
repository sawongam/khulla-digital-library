// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'title_form_state.freezed.dart';

/// Title form: existing record, format picker options, and save progress.
@freezed
abstract class TitleFormState with _$TitleFormState {
  const factory TitleFormState({
    @Default(LoadStatus.initial) LoadStatus status,
    Title? existing,
    @Default(<TitleFormat>[]) List<TitleFormat> formats,
    AppException? error,
    @Default(false) bool isSaving,
  }) = _TitleFormState;

  const TitleFormState._();

  bool get isLoading => status.isLoading;
}
