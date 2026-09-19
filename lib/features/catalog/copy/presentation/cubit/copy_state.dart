// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'copy_state.freezed.dart';

/// Copies list query, page of results, and load status.
@freezed
abstract class CopyState with _$CopyState {
  const factory CopyState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(CopyQuery()) CopyQuery query,
    @Default(<Copy>[]) List<Copy> copies,
    @Default(0) int totalCount,
    AppException? error,
  }) = _CopyState;

  const CopyState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && copies.isEmpty;
}
