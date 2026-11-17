// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_features_state.freezed.dart';

/// Which optional parts of the app this library has switched on.
@freezed
abstract class LibraryFeaturesState with _$LibraryFeaturesState {
  const factory LibraryFeaturesState({
    /// Whether fines appear anywhere in the interface. On until the library's
    /// profile says otherwise, so nothing disappears while it loads.
    @Default(true) bool chargesFines,
  }) = _LibraryFeaturesState;
}
