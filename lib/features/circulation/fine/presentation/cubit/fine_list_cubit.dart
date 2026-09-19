// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine_query.dart';
import 'package:khulla/features/circulation/fine/presentation/cubit/fine_list_state.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Fines list plus outstanding, collected and waived totals.
///
/// Page-scoped `@injectable` cubit backed by [CirculationRepository].
/// [loadFines] fetches the filtered list and summary money in parallel;
/// failures emit into [FineListState.error].
@injectable
class FineListCubit extends Cubit<FineListState> {
  FineListCubit(this._repository) : super(const FineListState());

  final CirculationRepository _repository;

  /// Loads the filtered fine list and summary totals by status.
  Future<void> loadFines() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final results = await Future.wait<FineListResult>([
        _repository.findFines(state.query),
        _repository.findFines(
          const FineQuery(status: FineStatus.unpaid, limit: 500),
        ),
        _repository.findFines(
          const FineQuery(status: FineStatus.paid, limit: 500),
        ),
        _repository.findFines(
          const FineQuery(status: FineStatus.waived, limit: 500),
        ),
      ]);
      if (isClosed) return;

      final listResult = results[0];
      final unpaid = results[1];
      final paid = results[2];
      final waived = results[3];

      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          fines: listResult.items,
          totalCount: listResult.totalCount,
          outstandingTotal: Money.sum([
            for (final fine in unpaid.items) fine.outstanding,
          ]),
          collectedTotal: Money.sum([for (final fine in paid.items) fine.paid]),
          waivedTotal: Money.sum([
            for (final fine in waived.items) fine.waived,
          ]),
          membersOwing: {
            for (final fine in unpaid.items)
              if (fine.outstanding.isPositive) fine.memberId,
          }.length,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  void searchChanged(String value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(search: value, offset: 0),
      ),
    );
    unawaited(loadFines());
  }

  void statusFilterChanged(FineStatus? status) {
    emit(
      state.copyWith(
        query: state.query.copyWith(status: status, offset: 0),
      ),
    );
    unawaited(loadFines());
  }

  void clearFilters() {
    emit(state.copyWith(query: FineQuery(limit: state.query.limit)));
    unawaited(loadFines());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadFines());
  }

  /// Records full payment on one fine and reloads the list. Rethrows on failure.
  Future<void> collectFine(String fineId) async {
    await _repository.collectFine(fineId);
    if (isClosed) return;
    await loadFines();
  }

  /// Waives the outstanding balance on one fine and reloads the list. Rethrows on failure.
  Future<void> waiveFine(String fineId) async {
    await _repository.waiveFine(fineId);
    if (isClosed) return;
    await loadFines();
  }
}
