// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/member_repository.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/cubit/member_form_state.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:khulla/shared/models/load_status.dart';

/// The create/edit member modal: member types for the picker and the record being edited.
///
/// Page-scoped `@injectable` cubit for the member form modal. [load] failures
/// stay in [MemberFormState.error]; [saveMember] emits and rethrows.
@injectable
class MemberFormCubit extends Cubit<MemberFormState> {
  MemberFormCubit(this._members, this._referenceData)
    : super(const MemberFormState());

  final MemberRepository _members;
  final ReferenceDataRepository _referenceData;

  /// Loads member-type options and, when [memberId] is set, the existing member.
  Future<void> load({String? memberId}) async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final memberTypes = await _referenceData.findActiveMemberTypes();
      final existing = memberId == null
          ? null
          : await _members.findMember(memberId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoadStatus.loaded,
          existing: existing,
          memberTypes: memberTypes,
          error: null,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(status: LoadStatus.failure, error: error));
    }
  }

  /// Inserts a category, refreshes the picker list, and rethrows on failure.
  ///
  /// Quick-add from the member form only names the category; every rule
  /// override stays null so the library defaults apply until tuned in
  /// the manage-categories sheet.
  Future<MemberType> addMemberType(String name) async {
    try {
      final draft = MemberType(
        id: '',
        name: name,
        sortOrder: 0,
        isSystem: false,
        createdAt: DateTime.now(),
      );
      final type = await _referenceData.addMemberType(draft);
      if (isClosed) return type;
      final memberTypes = await _referenceData.findActiveMemberTypes();
      if (isClosed) return type;
      emit(state.copyWith(memberTypes: memberTypes, error: null));
      return type;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(error: error));
      rethrow;
    }
  }

  /// Persists the member. Emits [MemberFormState.isSaving] and rethrows on failure.
  ///
  /// [dateOfBirthText] is the `d MMM y` display string from the form field;
  /// blank means unknown, anything else must parse or the save is refused.
  Future<Member> saveMember({
    required String fullName,
    required String memberTypeId,
    required bool sendNotices,
    String? barcode,
    Gender? gender,
    BloodGroup? bloodGroup,
    String? municipality,
    String? occupation,
    String? institution,
    String? idVerification,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? email,
    String? phone,
    String? address,
    String? dateOfBirthText,
    String? guardian,
    String? notes,
  }) async {
    emit(state.copyWith(isSaving: true, error: null));
    try {
      final trimmedDob = dateOfBirthText?.trim();
      final dateOfBirth = trimmedDob == null || trimmedDob.isEmpty
          ? null
          : AppDateFormat.display.tryParse(trimmedDob);
      if (trimmedDob != null && trimmedDob.isNotEmpty && dateOfBirth == null) {
        throw const InvalidInputException(
          'That date of birth could not be read.',
        );
      }
      final saved = await _members.saveMember(
        id: state.existing?.id,
        barcode: barcode,
        fullName: fullName,
        memberTypeId: memberTypeId,
        sendNotices: sendNotices,
        gender: gender,
        bloodGroup: bloodGroup,
        municipality: municipality,
        occupation: occupation,
        institution: institution,
        idVerification: idVerification,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        email: email,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        guardian: guardian,
        notes: notes,
      );
      if (isClosed) return saved;
      emit(state.copyWith(isSaving: false, existing: saved));
      return saved;
    } on AppException catch (error) {
      if (isClosed) rethrow;
      emit(state.copyWith(isSaving: false, error: error));
      rethrow;
    }
  }
}
