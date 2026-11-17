// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/members/domain/member_status.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Localized names and semantic tones for the register's enums.
extension MemberStatusX on MemberStatus {
  String label(AppLocalizations l10n) => switch (this) {
    MemberStatus.active => l10n.membersStatusActive,
    MemberStatus.expiring => l10n.membersStatusExpiring,
    MemberStatus.expired => l10n.membersStatusExpired,
    MemberStatus.suspended => l10n.membersStatusSuspended,
  };

  AppStatusTone get tone => switch (this) {
    MemberStatus.active => AppStatusTone.success,
    MemberStatus.expiring => AppStatusTone.warning,
    MemberStatus.expired => AppStatusTone.neutral,
    MemberStatus.suspended => AppStatusTone.danger,
  };
}

extension MemberTypeCodeX on String? {
  AppIconSpec get memberTypeIcon => switch (this) {
    'student' => AppIcons.education,
    'teacher' => AppIcons.teacher,
    'child' => AppIcons.child,
    _ => AppIcons.person,
  };
}

extension GenderX on Gender {
  String label(AppLocalizations l10n) => switch (this) {
    Gender.male => l10n.genderMale,
    Gender.female => l10n.genderFemale,
    Gender.other => l10n.genderOther,
    Gender.preferNotToSay => l10n.genderPreferNotToSay,
  };
}

extension BloodGroupX on BloodGroup {
  String get label => switch (this) {
    BloodGroup.aPositive => 'A+',
    BloodGroup.aNegative => 'A-',
    BloodGroup.bPositive => 'B+',
    BloodGroup.bNegative => 'B-',
    BloodGroup.abPositive => 'AB+',
    BloodGroup.abNegative => 'AB-',
    BloodGroup.oPositive => 'O+',
    BloodGroup.oNegative => 'O-',
  };
}

extension MemberOptionalFieldX on MemberOptionalField {
  String label(AppLocalizations l10n) => switch (this) {
    MemberOptionalField.grade => l10n.fieldGrade,
    MemberOptionalField.gender => l10n.fieldGender,
    MemberOptionalField.dateOfBirth => l10n.fieldDateOfBirth,
    MemberOptionalField.bloodGroup => l10n.fieldBloodGroup,
    MemberOptionalField.email => l10n.fieldEmail,
    MemberOptionalField.phone => l10n.fieldPhone,
    MemberOptionalField.address => l10n.fieldAddress,
    MemberOptionalField.municipality => l10n.fieldMunicipality,
    MemberOptionalField.occupation => l10n.fieldOccupation,
    MemberOptionalField.institution => l10n.fieldInstitution,
    MemberOptionalField.idVerification => l10n.fieldIdVerification,
    MemberOptionalField.emergencyContact => l10n.memberFormEmergency,
    MemberOptionalField.guardian => l10n.fieldGuardian,
    MemberOptionalField.notes => l10n.fieldNotes,
    MemberOptionalField.sendNotices => l10n.memberFormNotifications,
  };
}
