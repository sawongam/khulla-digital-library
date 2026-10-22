// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/positive_whole_number.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Library identity settings: name, contact details, currency and barcodes.
///
/// Page-scoped `@injectable` cubit. It owns the form as well as the record:
/// [loadProfile] fills the fields, each `<field>Changed` updates one, and
/// [saveProfile] validates and writes them. [loadProfile] is a read -
/// failures emit into [LibraryProfileState.error]. [saveProfile] emits and
/// rethrows.
@injectable
class LibraryProfileCubit extends Cubit<LibraryProfileState> {
  LibraryProfileCubit(this._repository) : super(const LibraryProfileState());

  final LibrarySettingsRepository _repository;

  /// Loads the library profile row and its logo, if any.
  Future<void> loadProfile() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final profile = await _repository.findProfile();
      final logoBytes = await _repository.loadLogoBytes();
      if (isClosed) return;
      emit(
        _withFormFrom(
          profile,
          state.copyWith(
            status: LoadStatus.loaded,
            profile: profile,
            logoBytes: logoBytes,
            error: null,
          ),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Uploads [bytes] as the library's mark. Emits and rethrows on failure so
  /// the settings form can toast.
  Future<void> uploadLogo(Uint8List bytes, String extension) async {
    emit(state.copyWith(isSavingLogo: true, error: null));
    try {
      final saved = await _repository.saveLogo(bytes, extension: extension);
      if (isClosed) return;
      emit(
        state.copyWith(
          profile: saved,
          logoBytes: bytes,
          isSavingLogo: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSavingLogo: false, error: error));
      rethrow;
    }
  }

  /// Clears the library's mark. Emits and rethrows on failure.
  Future<void> removeLogo() async {
    emit(state.copyWith(isSavingLogo: true, error: null));
    try {
      final saved = await _repository.removeLogo();
      if (isClosed) return;
      emit(
        state.copyWith(
          profile: saved,
          logoBytes: null,
          isSavingLogo: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSavingLogo: false, error: error));
      rethrow;
    }
  }

  /// Persists profile edits. Emits and rethrows on failure so the form can toast.
  void libraryNameChanged(String value) =>
      emit(state.copyWith(name: RequiredText.dirty(value)));

  void emailChanged(String value) => emit(state.copyWith(email: value));

  void phoneChanged(String value) => emit(state.copyWith(phone: value));

  void addressChanged(String value) => emit(state.copyWith(address: value));

  void openingHoursChanged(String value) =>
      emit(state.copyWith(openingHours: value));

  void currencyChanged(AppCurrency value) =>
      emit(state.copyWith(currency: value));

  void barcodePrefixChanged(String value) =>
      emit(state.copyWith(barcodePrefix: RequiredText.dirty(value)));

  void barcodeNextValueChanged(String value) =>
      emit(state.copyWith(barcodeNextValue: PositiveWholeNumber.dirty(value)));

  void memberBarcodePrefixChanged(String value) =>
      emit(state.copyWith(memberBarcodePrefix: RequiredText.dirty(value)));

  void memberBarcodeNextValueChanged(String value) => emit(
    state.copyWith(memberBarcodeNextValue: PositiveWholeNumber.dirty(value)),
  );

  void staffBarcodePrefixChanged(String value) =>
      emit(state.copyWith(staffBarcodePrefix: RequiredText.dirty(value)));

  void staffBarcodeNextValueChanged(String value) => emit(
    state.copyWith(staffBarcodeNextValue: PositiveWholeNumber.dirty(value)),
  );

  /// Validates the form and saves it.
  ///
  /// Returns false, with every field marked so its error shows, when the
  /// form is not valid - nothing is written. Emits and rethrows a failed
  /// write so the page can toast it.
  Future<bool> saveProfile() async {
    final existing = state.profile;
    if (existing == null) return false;

    final dirtied = state.copyWith(
      name: RequiredText.dirty(state.name.value),
      barcodePrefix: RequiredText.dirty(state.barcodePrefix.value),
      barcodeNextValue: PositiveWholeNumber.dirty(state.barcodeNextValue.value),
      memberBarcodePrefix: RequiredText.dirty(state.memberBarcodePrefix.value),
      memberBarcodeNextValue: PositiveWholeNumber.dirty(
        state.memberBarcodeNextValue.value,
      ),
      staffBarcodePrefix: RequiredText.dirty(state.staffBarcodePrefix.value),
      staffBarcodeNextValue: PositiveWholeNumber.dirty(
        state.staffBarcodeNextValue.value,
      ),
    );
    if (!Formz.validate(dirtied.inputs)) {
      emit(dirtied);
      return false;
    }

    emit(dirtied.copyWith(isSaving: true, error: null));
    try {
      final saved = await _repository.saveProfile(
        existing.copyWith(
          name: dirtied.name.value.trim(),
          currency: dirtied.currency,
          barcodePrefix: dirtied.barcodePrefix.value.trim(),
          barcodeNextValue: dirtied.barcodeNextValue.number!,
          memberBarcodePrefix: dirtied.memberBarcodePrefix.value.trim(),
          memberBarcodeNextValue: dirtied.memberBarcodeNextValue.number!,
          staffBarcodePrefix: dirtied.staffBarcodePrefix.value.trim(),
          staffBarcodeNextValue: dirtied.staffBarcodeNextValue.number!,
          email: _trimOrNull(dirtied.email),
          phone: _trimOrNull(dirtied.phone),
          address: _trimOrNull(dirtied.address),
          openingHours: _trimOrNull(dirtied.openingHours),
        ),
      );
      if (isClosed) return true;
      emit(
        _withFormFrom(
          saved,
          state.copyWith(profile: saved, isSaving: false, error: null),
        ),
      );
      return true;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }

  /// [base] with its form filled from [profile], and [LibraryProfileState.formRevision]
  /// moved on so the page refreshes its text fields.
  ///
  /// The fields start dirty - they hold real saved values, so an emptied one
  /// shows its error at once rather than only after a failed save.
  LibraryProfileState _withFormFrom(
    LibraryProfile? profile,
    LibraryProfileState base,
  ) {
    if (profile == null) return base;
    return base.copyWith(
      formRevision: base.formRevision + 1,
      name: RequiredText.dirty(profile.name),
      email: profile.email ?? '',
      phone: profile.phone ?? '',
      address: profile.address ?? '',
      openingHours: profile.openingHours ?? '',
      currency: profile.currency,
      barcodePrefix: RequiredText.dirty(profile.barcodePrefix),
      barcodeNextValue: PositiveWholeNumber.dirty(
        '${profile.barcodeNextValue}',
      ),
      memberBarcodePrefix: RequiredText.dirty(profile.memberBarcodePrefix),
      memberBarcodeNextValue: PositiveWholeNumber.dirty(
        '${profile.memberBarcodeNextValue}',
      ),
      staffBarcodePrefix: RequiredText.dirty(profile.staffBarcodePrefix),
      staffBarcodeNextValue: PositiveWholeNumber.dirty(
        '${profile.staffBarcodeNextValue}',
      ),
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
