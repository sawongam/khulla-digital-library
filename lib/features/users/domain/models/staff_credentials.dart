// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';

part 'staff_credentials.freezed.dart';

/// A staff account together with the stored hash of its password.
///
/// This is the one shape the password hash travels in, and it exists so the
/// comparison can happen in one place: the data source reads the row, the
/// repository verifies, and nothing above the repository ever sees
/// [passwordHash]. Keep it out of cubit state and out of logs.
@freezed
abstract class StaffCredentials with _$StaffCredentials {
  const factory StaffCredentials({
    required StaffMember staff,
    required String passwordHash,
  }) = _StaffCredentials;
}
