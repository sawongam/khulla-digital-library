// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/shared/domain/copy_condition.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/return_copy/presentation/cubit/return_state.dart';
import 'package:khulla/features/circulation/shared/domain/circulation_repository.dart';

/// The returns desk: loan basket, condition, fine waiver and check-in.
///
/// Page-scoped `@injectable` cubit backed by [CirculationRepository].
/// Barcode lookup failures emit and rethrow; [returnCopies] emits and
/// rethrows so the confirm button can toast while keeping the basket.
@injectable
class ReturnCubit extends Cubit<ReturnState> {
  ReturnCubit(this._repository) : super(const ReturnState());

  final CirculationRepository _repository;

  /// Adds an open loan to the basket by barcode. Emits and rethrows on failure.
  Future<void> addLoanByBarcode(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    try {
      final loan = await _repository.findOpenLoanByBarcode(trimmed);
      if (isClosed) return;
      if (loan == null) {
        throw const NotFoundException.because(AppErrorReason.copyNotOnLoan);
      }
      if (state.basket.any((item) => item.id == loan.id)) {
        throw const ConflictException.because(
          AppErrorReason.copyAlreadyInBasket,
        );
      }
      emit(state.copyWith(basket: [...state.basket, loan], error: null));
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Adds a loan directly (for one-click return from the loans list).
  void addLoan(Loan loan) {
    if (state.basket.any((item) => item.id == loan.id)) return;
    emit(state.copyWith(basket: [...state.basket, loan], error: null));
  }

  void removeLoan(Loan loan) {
    emit(
      state.copyWith(
        basket: state.basket.where((item) => item.id != loan.id).toList(),
        error: null,
      ),
    );
  }

  void waiveFinesChanged(bool value) {
    emit(state.copyWith(waiveFines: value, error: null));
  }

  void conditionChanged(CopyCondition value) {
    emit(state.copyWith(condition: value, error: null));
  }

  /// Checks in every loan in the basket, then clears the desk.
  ///
  /// Emits and rethrows on failure so the confirm action can toast.
  Future<void> returnCopies() async {
    if (state.basket.isEmpty) return;

    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      await _repository.returnCopies(
        copies: [
          for (final loan in state.basket)
            (barcode: loan.barcode ?? '', condition: state.condition),
        ],
        waiveFine: state.waiveFines,
      );
      if (isClosed) return;
      emit(const ReturnState());
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, error: error));
      rethrow;
    }
  }
}
