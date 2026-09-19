// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart'
    show dateOnly;
import 'package:khulla/features/reports/domain/reports_repository.dart';
import 'package:khulla/features/reports/presentation/cubit/reports_state.dart';
import 'package:khulla/features/reports/presentation/reports_page.dart';
import 'package:khulla/shared/models/load_status.dart';

typedef _Range = ({DateTime start, DateTime end});

/// Loads the report's figures for a period, and reloads them when the
/// operator switches periods.
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository) : super(const ReportsState());

  final ReportsRepository _repository;

  Future<void> load() => _load(state.period);

  Future<void> changePeriod(ReportPeriod period) => _load(period);

  Future<void> _load(ReportPeriod period) async {
    emit(
      state.copyWith(
        status: state.status.forCollectionFetch(),
        period: period,
        error: null,
      ),
    );
    try {
      final range = _rangeFor(period);
      final previous = _previousRangeFor(range);
      final summary = await _repository.loadSummary(
        start: range.start,
        end: range.end,
        previousStart: previous.start,
        previousEnd: previous.end,
      );
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.loaded, summary: summary));
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  _Range _rangeFor(ReportPeriod period) {
    final today = dateOnly(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return switch (period) {
      ReportPeriod.month => (
        start: DateTime(today.year, today.month),
        end: end,
      ),
      ReportPeriod.quarter => (
        start: DateTime(today.year, today.month - 2),
        end: end,
      ),
      ReportPeriod.year => (start: DateTime(today.year), end: end),
    };
  }

  _Range _previousRangeFor(_Range range) {
    final length = range.end.difference(range.start);
    return (start: range.start.subtract(length), end: range.start);
  }
}
