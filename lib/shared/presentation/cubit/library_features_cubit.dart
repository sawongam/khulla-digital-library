// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/shared/presentation/cubit/library_features_state.dart';

/// App-wide mirror of the library's feature switches, read by the shell,
/// the router and every screen that would otherwise mention fines.
///
/// A mirror of [LibrarySettingsRepository], which owns the profile: this
/// cubit follows its `changes`, so the loan rules page saving a switch
/// updates the whole app with no cubit calling another. A [lazySingleton],
/// never closed - no `isClosed` guards. A failed read keeps the defaults:
/// everything shown, which is the safe side for a desk.
@lazySingleton
class LibraryFeaturesCubit extends Cubit<LibraryFeaturesState> {
  LibraryFeaturesCubit(this._repository) : super(const LibraryFeaturesState()) {
    _subscription = _repository.changes.listen(_apply);
  }

  final LibrarySettingsRepository _repository;
  late final StreamSubscription<LibraryProfile> _subscription;

  /// Reads the profile once, for the first frame.
  Future<void> loadFeatures() async {
    try {
      final profile = await _repository.findProfile();
      if (profile != null) _apply(profile);
    } on Object {
      // Keep the defaults.
    }
  }

  void _apply(LibraryProfile profile) =>
      emit(state.copyWith(chargesFines: profile.chargesFines));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
