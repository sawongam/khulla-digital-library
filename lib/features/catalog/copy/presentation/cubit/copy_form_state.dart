// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'copy_form_state.freezed.dart';

/// Add-copy modal: optional fixed title, title search hits, and save progress.
@freezed
abstract class CopyFormState with _$CopyFormState {
  const factory CopyFormState({
    @Default(LoadStatus.initial) LoadStatus status,
    Title? fixedTitle,
    @Default(<Title>[]) List<Title> titleMatches,
    Title? selectedTitle,
    AppException? error,
    @Default(false) bool isSaving,
  }) = _CopyFormState;

  const CopyFormState._();

  bool get isLoading => status.isLoading;
}
