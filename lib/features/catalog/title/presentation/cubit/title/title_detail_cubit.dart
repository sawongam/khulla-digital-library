// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_detail_state.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan_query.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// A single title record plus its copies and loan history.
///
/// Page-scoped `@injectable` cubit for the title detail page. Pulls the title
/// from [TitleRepository], copies from [CopyRepository], and returned loans
/// from [CirculationRepository]. Reads emit into state; writes ([removeTitle],
/// [addCopies]) rethrow so the gesture can toast.
@injectable
class TitleDetailCubit extends Cubit<TitleDetailState> {
  TitleDetailCubit(this._titles, this._copies, this._circulation)
    : super(const TitleDetailState());

  final TitleRepository _titles;
  final CopyRepository _copies;
  final CirculationRepository _circulation;

  /// Loads the title, its copies, and returned loans for [id].
  ///
  /// A missing title becomes a [NotFoundException] in state. Other read
  /// failures are emitted and swallowed.
  Future<void> loadTitle(String id) async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final title = await _titles.findTitle(id);
      if (isClosed) return;
      if (title == null) {
        emit(
          state.copyWith(
            status: LoadStatus.failure,
            error: const NotFoundException('Title not found.'),
          ),
        );
        return;
      }
      final copies = await _copies.findCopiesByTitleId(id);
      if (isClosed) return;
      final history = await _circulation.findLoans(
        LoanQuery(titleId: id),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          title: title,
          copies: copies,
          historyLoans: [
            for (final loan in history.items)
              if (loan.returnedAt != null) loan,
          ],
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Deletes the title. Rethrows on failure - the confirming dialog toasts.
  Future<void> removeTitle(String id) async {
    await _titles.removeTitle(id);
  }

  /// Adds [count] copies and reloads the detail pane. Rethrows on failure.
  Future<void> addCopies(
    String titleId,
    String titleName, {
    required int count,
    String? shelf,
  }) async {
    for (var index = 0; index < count; index++) {
      await _copies.addCopy(
        titleId: titleId,
        titleName: titleName,
        shelf: shelf,
      );
      if (isClosed) return;
    }
    await loadTitle(titleId);
  }

  /// Marks a copy lost and reloads the detail pane. Rethrows on failure.
  Future<void> markCopyLost(String titleId, Copy copy) async {
    await _copies.updateCopyStatus(copy.id, status: CopyStatus.lost);
    if (isClosed) return;
    await loadTitle(titleId);
  }

  /// Marks a copy damaged and reloads the detail pane. Rethrows on failure.
  Future<void> markCopyDamaged(String titleId, Copy copy) async {
    await _copies.updateCopyStatus(copy.id, status: CopyStatus.damaged);
    if (isClosed) return;
    await loadTitle(titleId);
  }

  /// Withdraws a copy from stock and reloads the detail pane. Rethrows on failure.
  Future<void> withdrawCopy(String titleId, Copy copy) async {
    await _copies.archiveCopy(copy.id);
    if (isClosed) return;
    await loadTitle(titleId);
  }

  /// Queues a hold for [memberId] on the loaded title. Rethrows on failure.
  Future<void> placeHold(String titleId, String memberId) async {
    await _circulation.placeHold(memberId: memberId, titleId: titleId);
    if (isClosed) return;
    await loadTitle(titleId);
  }
}
