// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'title_state.freezed.dart';

/// Titles list query, page of results, and load status.
@freezed
abstract class TitleState with _$TitleState {
  const factory TitleState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(TitleQuery()) TitleQuery query,
    @Default(<Title>[]) List<Title> titles,
    @Default(0) int totalCount,
    AppException? error,
  }) = _TitleState;

  const TitleState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && titles.isEmpty;
}
