// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'fine_list_state.freezed.dart';

/// Fines list, summary totals, and load status.
@freezed
abstract class FineListState with _$FineListState {
  const factory FineListState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(FineQuery()) FineQuery query,
    @Default(<Fine>[]) List<Fine> fines,
    @Default(0) int totalCount,
    @Default(Money.zero) Money outstandingTotal,
    @Default(Money.zero) Money collectedTotal,
    @Default(Money.zero) Money waivedTotal,
    @Default(0) int membersOwing,
    AppException? error,
  }) = _FineListState;

  const FineListState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
  bool get isEmpty => status.isLoaded && fines.isEmpty;
}
