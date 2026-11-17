// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// The library's own record: its name and the currency it charges in.
abstract interface class LibrarySettingsRepository {
  /// Every profile this repository saves, as it was saved. App-wide state
  /// that mirrors a setting follows this instead of being told by a page.
  Stream<LibraryProfile> get changes;

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

  /// Turns fine charging on or off and returns the updated profile.
  Future<LibraryProfile> saveChargesFines({required bool chargesFines});

  /// Sets which optional member-form fields are hidden and returns the
  /// updated profile.
  Future<LibraryProfile> saveHiddenMemberFields(
    Set<MemberOptionalField> fields,
  );

  /// The current mark's bytes, or null when none is set.
  Future<Uint8List?> loadLogoBytes();
}
