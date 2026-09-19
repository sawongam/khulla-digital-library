// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/shared/models/load_status.dart';
import 'package:khulla/shared/presentation/cubit/library_branding_state.dart';

/// App-wide cache of the library's uploaded mark, read by the shell's brand
/// mark widget.
///
/// A [lazySingleton] — it outlives any one page and is never closed. A
/// failure to read it is not shown anywhere: the shell falls back to the
/// default Khulla mark, which is not worse than an error banner in the
/// chrome for something this decorative.
@lazySingleton
class LibraryBrandingCubit extends Cubit<LibraryBrandingState> {
  LibraryBrandingCubit(this._repository) : super(const LibraryBrandingState());

  final LibrarySettingsRepository _repository;

  /// Loads the current mark for the first paint.
  Future<void> loadLogo() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final logoBytes = await _repository.loadLogoBytes();
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.loaded, logoBytes: logoBytes));
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.loaded, logoBytes: null));
    }
  }

  /// Re-reads the mark after it changes in settings.
  Future<void> refreshLogo() => loadLogo();
}
