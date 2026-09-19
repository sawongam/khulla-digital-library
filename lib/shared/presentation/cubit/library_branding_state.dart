// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'library_branding_state.freezed.dart';

/// The library's uploaded mark, cached for the shell's brand slot.
@freezed
abstract class LibraryBrandingState with _$LibraryBrandingState {
  const factory LibraryBrandingState({
    @Default(LoadStatus.initial) LoadStatus status,
    Uint8List? logoBytes,
  }) = _LibraryBrandingState;
}
