// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_fine.dart'
    show dateOnly;
import 'package:khulla/features/dashboard/domain/dashboard_repository.dart';
import 'package:khulla/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:khulla/shared/models/load_status.dart';

/// One period's window, half-open — `[start, end)`.
typedef _Range = ({DateTime start, DateTime end});

/// Loads the board's figures for a period, and reloads them when the
/// operator switches periods.
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;

  Future<void> load() => _load(state.period);

  Future<void> changePeriod(DashboardPeriod period) => _load(period);

  Future<void> _load(DashboardPeriod period) async {
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

  _Range _rangeFor(DashboardPeriod period) {
    final today = dateOnly(DateTime.now());
    final end = today.add(const Duration(days: 1));
    return switch (period) {
      DashboardPeriod.today => (start: today, end: end),
      // Sunday-first week, matching the usage chart's weekday labels.
      DashboardPeriod.week => (
        start: today.subtract(Duration(days: today.weekday % 7)),
        end: end,
      ),
      DashboardPeriod.month => (
        start: DateTime(today.year, today.month),
        end: end,
      ),
    };
  }

  /// The immediately preceding period of the same length — what a stat
  /// tile's trend compares against.
  _Range _previousRangeFor(_Range range) {
    final length = range.end.difference(range.start);
    return (start: range.start.subtract(length), end: range.start);
  }
}
