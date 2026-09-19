// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/settings/presentation/cubit/library_profile_state.dart';
import 'package:khulla/shared/models/load_status.dart';

/// Library identity settings: name, contact details, currency and barcodes.
///
/// Page-scoped `@injectable` cubit. [loadProfile] is a read — failures emit
/// into [LibraryProfileState.error]. [saveProfile] emits and rethrows.
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
        state.copyWith(
          status: LoadStatus.loaded,
          profile: profile,
          logoBytes: logoBytes,
          error: null,
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
  Future<void> saveProfile({
    required String name,
    required AppCurrency currency,
    required String barcodePrefix,
    required int barcodeNextValue,
    required String memberBarcodePrefix,
    required int memberBarcodeNextValue,
    required String staffBarcodePrefix,
    required int staffBarcodeNextValue,
    String? email,
    String? phone,
    String? address,
    String? openingHours,
  }) async {
    final existing = state.profile;
    if (existing == null) return;

    emit(state.copyWith(isSaving: true, error: null));
    try {
      final saved = await _repository.saveProfile(
        existing.copyWith(
          name: name.trim(),
          currency: currency,
          barcodePrefix: barcodePrefix.trim(),
          barcodeNextValue: barcodeNextValue,
          memberBarcodePrefix: memberBarcodePrefix.trim(),
          memberBarcodeNextValue: memberBarcodeNextValue,
          staffBarcodePrefix: staffBarcodePrefix.trim(),
          staffBarcodeNextValue: staffBarcodeNextValue,
          email: _trimOrNull(email),
          phone: _trimOrNull(phone),
          address: _trimOrNull(address),
          openingHours: _trimOrNull(openingHours),
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          profile: saved,
          isSaving: false,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
