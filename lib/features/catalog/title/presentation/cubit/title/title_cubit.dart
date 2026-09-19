// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The titles list: search, filters, sort and pagination.
///
/// Page-scoped `@injectable` cubit for the title list page. Delegates reads to
/// [TitleRepository]; [loadTitles] failures emit into [TitleState.error].
@injectable
class TitleCubit extends Cubit<TitleState> {
  TitleCubit(this._repository) : super(const TitleState());

  final TitleRepository _repository;

  /// Fetches the current page of titles using [TitleState.query].
  ///
  /// Failures are emitted into state and swallowed — the list screen already
  /// watches [TitleState.error].
  Future<void> loadTitles() async {
    emit(
      state.copyWith(status: state.status.forCollectionFetch(), error: null),
    );
    try {
      final result = await _repository.findTitles(state.query);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          titles: result.items,
          totalCount: result.totalCount,
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
    unawaited(loadTitles());
  }

  void formatFilterChanged(String? formatId) {
    emit(
      state.copyWith(
        query: state.query.copyWith(formatId: formatId, offset: 0),
      ),
    );
    unawaited(loadTitles());
  }

  void availableOnlyChanged(bool value) {
    emit(
      state.copyWith(
        query: state.query.copyWith(availableOnly: value, offset: 0),
      ),
    );
    unawaited(loadTitles());
  }

  void sortChanged(String columnId, bool ascending) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          sortColumn: columnId,
          sortAscending: ascending,
          offset: 0,
        ),
      ),
    );
    unawaited(loadTitles());
  }

  void clearFilters() {
    emit(
      state.copyWith(
        query: TitleQuery(limit: state.query.limit),
      ),
    );
    unawaited(loadTitles());
  }

  void limitChanged(int limit) {
    if (state.query.limit == limit) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(limit: limit, offset: 0),
      ),
    );
    unawaited(loadTitles());
  }

  void pageChanged(int page) {
    emit(
      state.copyWith(
        query: state.query.copyWith(
          offset: page * state.query.limit,
        ),
      ),
    );
    unawaited(loadTitles());
  }
}
