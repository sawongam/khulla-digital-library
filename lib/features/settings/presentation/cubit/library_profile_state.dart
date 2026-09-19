// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'library_profile_state.freezed.dart';

/// Library profile record and save progress.
@freezed
abstract class LibraryProfileState with _$LibraryProfileState {
  const factory LibraryProfileState({
    @Default(LoadStatus.initial) LoadStatus status,
    LibraryProfile? profile,
    AppException? error,
    @Default(false) bool isSaving,
    Uint8List? logoBytes,
    @Default(false) bool isSavingLogo,
  }) = _LibraryProfileState;

  const LibraryProfileState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;
}
