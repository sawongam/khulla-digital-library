// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/circulation/presentation/cubit/loan_list_state.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation_query.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/features/circulation/shared/domain/loan_status.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Open loans list plus circulation headline counts.
///
/// Page-scoped `@injectable` cubit backed by [CirculationRepository].
/// [loadOpenLoans] fetches the filtered list and sidebar totals in one
/// round-trip; failures emit into [LoanListState.error].
@injectable
class LoanListCubit extends Cubit<LoanListState> {
  LoanListCubit(this._repository, this._auth) : super(const LoanListState());

  final CirculationRepository _repository;
  final AuthCubit _auth;

  /// Loads the filtered loan list and on-loan, due-today, overdue and hold counts.
  Future<void> loadOpenLoans() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final results = await Future.wait([
        _repository.findOpenLoans(state.query),
        _repository.findOpenLoans(const LoanQuery()),
        _repository.findOpenLoans(
          const LoanQuery(status: LoanStatus.dueToday),
        ),
        _repository.findOpenLoans(
          const LoanQuery(status: LoanStatus.overdue),
        ),
        _repository.findReservations(const ReservationQuery(limit: 1)),
      ]);
      if (isClosed) return;

      final listResult = results[0] as LoanListResult;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          loans: listResult.items,
          totalCount: listResult.totalCount,
          onLoanCount: (results[1] as LoanListResult).totalCount,
          dueTodayCount: (results[2] as LoanListResult).totalCount,
          overdueCount: (results[3] as LoanListResult).totalCount,
          holdsCount: (results[4] as ReservationListResult).totalCount,
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
    unawaited(loadOpenLoans());
  }

  void statusFilterChanged(LoanStatus? status) {
    emit(
      state.copyWith(
        query: state.query.copyWith(status: status, offset: 0),
      ),
    );
    unawaited(loadOpenLoans());
  }

  void sortChanged(String columnId, bool ascending) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          sortColumn: _mapSortColumn(columnId),
          sortAscending: ascending,
          offset: 0,
        ),
      ),
    );
    unawaited(loadOpenLoans());
  }

  void clearFilters() {
    emit(
      state.copyWith(
        query: LoanQuery(openOnly: true, limit: state.query.limit),
      ),
    );
    unawaited(loadOpenLoans());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadOpenLoans());
  }

  String _mapSortColumn(String columnId) => switch (columnId) {
    'member' => 'memberName',
    'title' => 'titleName',
    'issued' => 'checkedOutAt',
    'barcode' => 'barcode',
    _ => 'dueAt',
  };

  /// Extends the due date for one open loan. Rethrows on failure.
  Future<void> renewLoan(String loanId) async {
    await _repository.renewLoan(loanId, staffId: _auth.state.staff?.id);
    if (isClosed) return;
    await loadOpenLoans();
  }

  /// Returns one copy directly from the loans list. Rethrows on failure.
  Future<void> returnLoan(String barcode) async {
    await _repository.returnCopy(
      barcode: barcode.trim(),
      condition: CopyCondition.good,
      staffId: _auth.state.staff?.id,
    );
    if (isClosed) return;
    await loadOpenLoans();
  }
}
