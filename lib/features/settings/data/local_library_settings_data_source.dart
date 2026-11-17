// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/settings/data/library_settings_local_data_source.dart';
import 'package:khulla/features/settings/data/mappers/library_settings_row_mappers.dart';
import 'package:khulla/features/settings/data/tables/library_settings.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// Drift-backed [LibrarySettingsLocalDataSource].
@LazySingleton(as: LibrarySettingsLocalDataSource)
class LocalLibrarySettingsDataSource implements LibrarySettingsLocalDataSource {
  LocalLibrarySettingsDataSource(this._db);

  final AppDatabase _db;

  static const String _source = 'LocalLibrarySettingsDataSource';

  @override
  Future<LibraryProfile?> findProfile() => guardDatabase(
    () async {
      final row =
          await (_db.select(_db.librarySettings)..where(
                (settings) => settings.id.equals(LibrarySettings.singletonId),
              ))
              .getSingleOrNull();
      return row?.toDomain();
    },
    source: '$_source.findProfile',
  );

  @override
  Future<LibraryProfile> saveProfile(LibraryProfile profile) => guardDatabase(
    () async {
      // Upsert rather than insert: onboarding can be retried after a failure
      // partway through, and the second attempt must overwrite the row the
      // first one left rather than collide with it.
      await _db
          .into(_db.librarySettings)
          .insertOnConflictUpdate(profile.toCompanion());
      // The row, not [profile]: the columns the profile form leaves alone
      // keep whatever they held.
      final row = await (_db.select(
        _db.librarySettings,
      )..where((s) => s.id.equals(LibrarySettings.singletonId))).getSingle();
      return row.toDomain();
    },
    source: '$_source.saveProfile',
  );

  @override
  Future<void> saveChargesFines({required bool chargesFines}) => guardDatabase(
    () async {
      await (_db.update(
        _db.librarySettings,
      )..where((s) => s.id.equals(LibrarySettings.singletonId))).write(
        LibrarySettingsCompanion(
          chargesFines: Value(chargesFines),
          updatedAt: Value(DateTime.now()),
        ),
      );
    },
    source: '$_source.saveChargesFines',
  );

  @override
  Future<void> saveHiddenMemberFields(Set<MemberOptionalField> fields) =>
      guardDatabase(
        () async {
          await (_db.update(
            _db.librarySettings,
          )..where((s) => s.id.equals(LibrarySettings.singletonId))).write(
            LibrarySettingsCompanion(
              hiddenMemberFields: Value(
                MemberOptionalField.encodeHidden(fields),
              ),
              updatedAt: Value(DateTime.now()),
            ),
          );
        },
        source: '$_source.saveHiddenMemberFields',
      );
}
