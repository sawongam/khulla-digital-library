// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:drift/drift.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/money/currency.dart';
import 'package:khulla/features/settings/data/tables/library_settings.dart';
import 'package:khulla/features/settings/domain/models/library_profile.dart';

/// Maps [LibrarySettingsRow] to [LibraryProfile] and back for drift writes.
extension LibrarySettingsRowX on LibrarySettingsRow {
  LibraryProfile toDomain() => LibraryProfile(
    name: name,
    currency: AppCurrency(
      code: currency,
      name: currencyName,
      symbol: currencySymbol,
    ),
    createdAt: createdAt,
    email: email,
    phone: phone,
    address: address,
    openingHours: openingHours,
    barcodePrefix: barcodePrefix,
    barcodeNextValue: barcodeNextValue,
    memberBarcodePrefix: memberBarcodePrefix,
    memberBarcodeNextValue: memberBarcodeNextValue,
    staffBarcodePrefix: staffBarcodePrefix,
    staffBarcodeNextValue: staffBarcodeNextValue,
    updatedAt: updatedAt,
    logoRef: logoRef,
  );
}

extension LibraryProfileX on LibraryProfile {
  LibrarySettingsCompanion toCompanion() => LibrarySettingsCompanion(
    id: const Value(LibrarySettings.singletonId),
    name: Value(name),
    currency: Value(currency.code),
    currencyName: Value(currency.name),
    currencySymbol: Value(currency.symbol),
    email: Value(email),
    phone: Value(phone),
    address: Value(address),
    openingHours: Value(openingHours),
    barcodePrefix: Value(barcodePrefix),
    barcodeNextValue: Value(barcodeNextValue),
    memberBarcodePrefix: Value(memberBarcodePrefix),
    memberBarcodeNextValue: Value(memberBarcodeNextValue),
    staffBarcodePrefix: Value(staffBarcodePrefix),
    staffBarcodeNextValue: Value(staffBarcodeNextValue),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    logoRef: Value(logoRef),
  );
}
