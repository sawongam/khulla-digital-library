// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/reports/domain/models/reports_summary.dart';
import 'package:khulla/features/reports/presentation/reports_page.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'reports_state.freezed.dart';

@freezed
abstract class ReportsState with _$ReportsState {
  const factory ReportsState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(ReportPeriod.month) ReportPeriod period,
    ReportsSummary? summary,
    AppException? error,
  }) = _ReportsState;

  const ReportsState._();

  bool get isLoading => status.isLoading;
}
