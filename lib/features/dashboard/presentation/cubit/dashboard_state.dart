// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'dashboard_state.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(DashboardPeriod.week) DashboardPeriod period,
    DashboardSummary? summary,
    AppException? error,
  }) = _DashboardState;

  const DashboardState._();

  bool get isLoading => status.isLoading;
}
