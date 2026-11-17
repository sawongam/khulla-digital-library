// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:khulla/core/money/money_format.dart';
import 'package:khulla/core/storage/logo_store.dart' as logo_store;
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/settings/data/library_settings_local_data_source.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// [LibrarySettingsRepository] over the local catalogue.
@LazySingleton(as: LibrarySettingsRepository)
class LibrarySettingsRepositoryImpl implements LibrarySettingsRepository {
  LibrarySettingsRepositoryImpl(this._dataSource);

  final LibrarySettingsLocalDataSource _dataSource;
  final StreamController<LibraryProfile> _changes =
      StreamController<LibraryProfile>.broadcast();

  @override
  Stream<LibraryProfile> get changes => _changes.stream;

  LibraryProfile _announce(LibraryProfile profile) {
    _changes.add(profile);
    return profile;
  }

  @override
  Future<LibraryProfile?> findProfile() async {
    final profile = await _dataSource.findProfile();
    if (profile != null) MoneyFormat.current = profile.currency.format;
    return profile;
  }

  @override
  Future<LibraryProfile> saveProfile(LibraryProfile profile) async {
    final existing = await _dataSource.findProfile();
    final now = DateTime.now();
    final saved = await _dataSource.saveProfile(
      profile.copyWith(
        createdAt: existing?.createdAt ?? profile.createdAt,
        updatedAt: now,
      ),
    );
    MoneyFormat.current = saved.currency.format;
    return _announce(saved);
  }

  @override
  Future<LibraryProfile> saveLogo(
    Uint8List bytes, {
    required String extension,
  }) async {
    final existing = await _dataSource.findProfile();
    if (existing == null) {
      throw StateError('Cannot set a logo before the library profile exists.');
    }

    final previousRef = existing.logoRef;
    final ref = await logo_store.saveLogo(bytes, extension: extension);
    if (previousRef != null && previousRef != ref) {
      await logo_store.deleteLogo(previousRef);
    }

    return _announce(
      await _dataSource.saveProfile(
        existing.copyWith(logoRef: ref, updatedAt: DateTime.now()),
      ),
    );
  }

  @override
  Future<LibraryProfile> removeLogo() async {
    final existing = await _dataSource.findProfile();
    if (existing == null) {
      throw StateError(
        'Cannot clear a logo before the library profile exists.',
      );
    }

    final previousRef = existing.logoRef;
    if (previousRef != null) await logo_store.deleteLogo(previousRef);

    return _announce(
      await _dataSource.saveProfile(
        existing.copyWith(logoRef: null, updatedAt: DateTime.now()),
      ),
    );
  }

  @override
  Future<LibraryProfile> saveChargesFines({required bool chargesFines}) async {
    await _dataSource.saveChargesFines(chargesFines: chargesFines);
    return _announce(await _requireProfile());
  }

  @override
  Future<LibraryProfile> saveHiddenMemberFields(
    Set<MemberOptionalField> fields,
  ) async {
    await _dataSource.saveHiddenMemberFields(fields);
    return _announce(await _requireProfile());
  }

  Future<LibraryProfile> _requireProfile() async {
    final profile = await _dataSource.findProfile();
    if (profile == null) {
      throw StateError('The library profile does not exist yet.');
    }
    return profile;
  }

  @override
  Future<Uint8List?> loadLogoBytes() async {
    final ref = (await _dataSource.findProfile())?.logoRef;
    if (ref == null) return null;
    return await logo_store.loadLogo(ref);
  }
}
