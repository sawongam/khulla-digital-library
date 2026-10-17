// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:typed_data';

import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/positive_whole_number.dart';
import 'package:khulla/core/form/inputs/required_text.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'library_profile_state.freezed.dart';

/// Library profile record, the form editing it, and save progress.
///
/// The form fields are the cubit's, not the page's: every keystroke goes
/// through a `<field>Changed` method, and `saveProfile` validates what is
/// here. [formRevision] counts the times the form was (re)filled from a
/// saved [profile] - on load and after a save - so the page knows when to
/// copy the fields into its text controllers, and never does so mid-edit.
@freezed
abstract class LibraryProfileState with _$LibraryProfileState {
  const factory LibraryProfileState({
    @Default(LoadStatus.initial) LoadStatus status,
    LibraryProfile? profile,
    AppException? error,
    @Default(false) bool isSaving,
    Uint8List? logoBytes,
    @Default(false) bool isSavingLogo,
    @Default(0) int formRevision,
    @Default(RequiredText.pure()) RequiredText name,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String address,
    @Default('') String openingHours,
    @Default(AppCurrency.npr) AppCurrency currency,
    @Default(RequiredText.pure()) RequiredText barcodePrefix,
    @Default(PositiveWholeNumber.pure()) PositiveWholeNumber barcodeNextValue,
    @Default(RequiredText.pure()) RequiredText memberBarcodePrefix,
    @Default(PositiveWholeNumber.pure())
    PositiveWholeNumber memberBarcodeNextValue,
    @Default(RequiredText.pure()) RequiredText staffBarcodePrefix,
    @Default(PositiveWholeNumber.pure())
    PositiveWholeNumber staffBarcodeNextValue,
  }) = _LibraryProfileState;

  const LibraryProfileState._();

  bool get isLoading => status.isLoading;
  bool get hasError => status.hasError;

  /// Every validated field, for `Formz.validate`.
  List<FormzInput<String, Object>> get inputs => [
    name,
    barcodePrefix,
    barcodeNextValue,
    memberBarcodePrefix,
    memberBarcodeNextValue,
    staffBarcodePrefix,
    staffBarcodeNextValue,
  ];
}
