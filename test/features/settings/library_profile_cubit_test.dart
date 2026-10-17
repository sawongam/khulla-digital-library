// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/core/money/money_format.dart';
import 'package:khulla/features/settings/data/library_settings_repository_impl.dart';
import 'package:khulla/features/settings/data/local_library_settings_data_source.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_cubit.dart';

import '../../helpers/test_database.dart';

/// The library profile form: its values and validation are the cubit's,
/// and a save writes nothing until every field is valid.
void main() {
  late AppDatabase db;
  late LibrarySettingsRepositoryImpl repository;
  late LibraryProfileCubit cubit;

  setUp(() async {
    db = await openTestDatabase();
    repository = LibrarySettingsRepositoryImpl(
      LocalLibrarySettingsDataSource(db),
    );
    await repository.saveProfile(
      LibraryProfile(
        name: 'Ward Library',
        currency: AppCurrency.npr,
        createdAt: DateTime(2026),
        email: 'desk@library.test',
      ),
    );
    cubit = LibraryProfileCubit(repository);
    await cubit.loadProfile();
  });

  tearDown(() async {
    await cubit.close();
    await closeTestDatabase(db);
    MoneyFormat.current = MoneyFormat.nepaliRupee;
  });

  test('loading fills the form from the saved profile', () {
    expect(cubit.state.formRevision, 1);
    expect(cubit.state.name.value, 'Ward Library');
    expect(cubit.state.email, 'desk@library.test');
    expect(cubit.state.barcodePrefix.value, 'KH-');
    expect(cubit.state.barcodeNextValue.value, '1');
    expect(cubit.state.currency, AppCurrency.npr);
  });

  test('an invalid form is refused, marked, and not written', () async {
    cubit
      ..libraryNameChanged('   ')
      ..barcodeNextValueChanged('0');

    expect(await cubit.saveProfile(), isFalse);
    expect(cubit.state.name.isNotValid, isTrue);
    expect(cubit.state.barcodeNextValue.isNotValid, isTrue);
    expect((await repository.findProfile())!.name, 'Ward Library');
  });

  test('a valid form is saved and refilled from what was written', () async {
    cubit
      ..libraryNameChanged('  Ward Public Library ')
      ..emailChanged('')
      ..barcodeNextValueChanged('42')
      ..staffBarcodePrefixChanged('STAFF-');

    expect(await cubit.saveProfile(), isTrue);

    final saved = (await repository.findProfile())!;
    expect(saved.name, 'Ward Public Library');
    expect(saved.email, isNull);
    expect(saved.barcodeNextValue, 42);
    expect(saved.staffBarcodePrefix, 'STAFF-');
    expect(cubit.state.formRevision, 2);
    expect(cubit.state.name.value, 'Ward Public Library');
  });
}
