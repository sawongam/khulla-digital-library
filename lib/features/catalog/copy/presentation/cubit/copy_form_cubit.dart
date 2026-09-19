// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/catalog/copy/domain/copy_repository.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_form_state.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';
import 'package:khulla/features/catalog/title/domain/models/title_query.dart';
import 'package:khulla/features/catalog/title/domain/title_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Add-copy modal: resolve a title, then insert through [CopyRepository].
@injectable
class CopyFormCubit extends Cubit<CopyFormState> {
  CopyFormCubit(this._copies, this._titles) : super(const CopyFormState());

  final CopyRepository _copies;
  final TitleRepository _titles;

  Timer? _titleLookupTimer;

  /// Loads a fixed title when [titleId] is set; otherwise starts empty.
  Future<void> load({String? titleId}) async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final fixed = titleId == null ? null : await _titles.findTitle(titleId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          fixedTitle: fixed,
          selectedTitle: fixed,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  void titleSearchChanged(String value) {
    if (state.fixedTitle != null) return;
    _titleLookupTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          titleMatches: const [],
          selectedTitle: null,
          error: null,
        ),
      );
      return;
    }
    _titleLookupTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_searchTitles(trimmed));
    });
  }

  void titleSelected(Title? title) {
    emit(state.copyWith(selectedTitle: title, error: null));
  }

  Future<void> _searchTitles(String query) async {
    try {
      final result = await _titles.findTitles(TitleQuery(search: query));
      if (isClosed) return;
      emit(
        state.copyWith(
          titleMatches: result.items,
          selectedTitle: result.items.length == 1 ? result.items.first : null,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(error: error));
    }
  }

  /// Inserts one copy for the chosen title. Rethrows on failure.
  Future<Copy> saveCopy({
    required String shelf,
    required String barcode,
    required String notes,
  }) async {
    final title = state.selectedTitle ?? state.fixedTitle;
    if (title == null) {
      throw const InvalidInputException('Choose a title first.');
    }

    emit(state.copyWith(isSaving: true, error: null));
    try {
      final saved = await _copies.addCopy(
        titleId: title.id,
        titleName: title.title,
        shelf: shelf.trim().isEmpty ? title.shelf : shelf.trim(),
        barcode: barcode.trim().isEmpty ? null : barcode.trim(),
        notes: notes.trim().isEmpty ? null : notes.trim(),
      );
      if (isClosed) return saved;
      emit(state.copyWith(isSaving: false));
      return saved;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }
}
