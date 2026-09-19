// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// Reads and writes the library's own record.
abstract interface class LibrarySettingsLocalDataSource {
  /// The profile, or null on a catalogue that has never been set up.
  Future<LibraryProfile?> findProfile();

  /// Writes [profile] over the single row, creating it if it is not there.
  Future<LibraryProfile> saveProfile(LibraryProfile profile);
}
