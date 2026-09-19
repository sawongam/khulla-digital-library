// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// The library's own record: its name and the currency it charges in.
abstract interface class LibrarySettingsRepository {
  /// The profile, or null on a catalogue that has never been set up.
  Future<LibraryProfile?> findProfile();

  /// Creates or replaces the profile and applies its currency to the app's
  /// money formatting.
  Future<LibraryProfile> saveProfile(LibraryProfile profile);

  /// Stores [bytes] as the library's mark and points the profile at it,
  /// replacing whatever logo was there before.
  Future<LibraryProfile> saveLogo(Uint8List bytes, {required String extension});

  /// Clears the library's mark.
  Future<LibraryProfile> removeLogo();

  /// The current mark's bytes, or null when none is set.
  Future<Uint8List?> loadLogoBytes();
}
