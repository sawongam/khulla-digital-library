// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:formz/formz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/form/inputs/confirmed_password.dart';
import 'package:khulla/core/form/inputs/email.dart';
import 'package:khulla/core/form/inputs/full_name.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/shared/models/load_status.dart';

part 'staff_form_state.freezed.dart';

/// What `StaffFormCubit` is doing: adding a new account, editing an existing
/// one's identity and role, setting a new password for one, or updating
/// the signed-in operator's own profile.
///
/// One cubit, four modes, rather than multiple cubits — every mode mutates
/// the same resource and shares the same load/submit shape; only which fields
/// are validated and which repository call runs differs.
enum StaffFormMode { create, edit, resetPassword, profile }

@freezed
abstract class StaffFormState with _$StaffFormState {
  const factory StaffFormState({
    @Default(StaffFormMode.create) StaffFormMode mode,
    @Default(LoadStatus.initial) LoadStatus status,
    StaffMember? existing,
    @Default(FullName.pure()) FullName name,
    @Default(Email.pure()) Email email,
    @Default(UserRole.librarian) UserRole role,
    @Default(Password.pure()) Password password,
    @Default(ConfirmedPassword.pure()) ConfirmedPassword confirmPassword,
    @Default(false) bool emailTaken,
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus submission,
    AppException? error,
  }) = _StaffFormState;

  const StaffFormState._();

  bool get isLoading => status.isLoading;

  bool get isSubmitting => submission == FormzSubmissionStatus.inProgress;

  bool get isSuccess => submission == FormzSubmissionStatus.success;
}
