// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Whether the form shows an optional field - the library's choice, unless
/// the record being edited already holds a value for it.
typedef MemberFieldVisibility = bool Function(MemberOptionalField field);

/// Lays [fields] out [perRow] to a row, padding the last row so a lone field
/// keeps its column width instead of stretching across the form.
List<Widget> _packRows(List<Widget> fields, {int perRow = 2}) => [
  for (var i = 0; i < fields.length; i += perRow)
    AppFormRow(
      children: [
        for (var j = i; j < i + perRow; j++)
          if (j < fields.length) fields[j] else const SizedBox.shrink(),
      ],
    ),
];

/// Who the person is: name, class, gender, birth date, blood group and
/// guardian. Everything but the name can be switched off in settings.
class MemberFormIdentitySection extends StatelessWidget {
  const MemberFormIdentitySection({
    required this.name,
    required this.grade,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
    required this.guardian,
    required this.onPickDateOfBirth,
    required this.onClearDateOfBirth,
    required this.shows,
    super.key,
  });

  final TextEditingController name;
  final TextEditingController grade;
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final String? dateOfBirth;
  final BloodGroup? bloodGroup;
  final ValueChanged<BloodGroup?> onBloodGroupChanged;
  final TextEditingController guardian;
  final VoidCallback onPickDateOfBirth;
  final VoidCallback? onClearDateOfBirth;
  final MemberFieldVisibility shows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberFormIdentity,
      children: _packRows([
        AppTextField(
          label: l10n.fieldFullName,
          required: true,
          controller: name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
        if (shows(MemberOptionalField.grade))
          AppTextField(
            label: l10n.fieldGrade,
            hintText: l10n.fieldGradeHint,
            controller: grade,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {},
          ),
        if (shows(MemberOptionalField.gender))
          AppDropdownField<Gender>(
            label: l10n.fieldGender,
            value: gender,
            items: Gender.values,
            itemLabel: (g) => g.label(l10n),
            onChanged: onGenderChanged,
            emptySearchMessage: l10n.commonNotSet,
          ),
        if (shows(MemberOptionalField.dateOfBirth))
          AppPickerField(
            label: l10n.fieldDateOfBirth,
            value: dateOfBirth,
            icon: AppIcons.calendar,
            onTap: onPickDateOfBirth,
            onClear: onClearDateOfBirth,
            clearTooltip: l10n.commonClear,
          ),
        if (shows(MemberOptionalField.bloodGroup))
          AppDropdownField<BloodGroup>(
            label: l10n.fieldBloodGroup,
            value: bloodGroup,
            items: BloodGroup.values,
            itemLabel: (b) => b.label,
            onChanged: onBloodGroupChanged,
          ),
        if (shows(MemberOptionalField.guardian))
          AppTextField(
            label: l10n.fieldGuardian,
            controller: guardian,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {},
          ),
      ]),
    );
  }
}

/// How to reach them: email, phone, address and municipality. Disappears
/// when the library hides all four.
class MemberFormContactSection extends StatelessWidget {
  const MemberFormContactSection({
    required this.email,
    required this.phone,
    required this.address,
    required this.municipality,
    required this.shows,
    super.key,
  });

  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController municipality;
  final MemberFieldVisibility shows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = [
      if (shows(MemberOptionalField.email))
        AppTextField(
          label: l10n.fieldEmail,
          controller: email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {},
        ),
      if (shows(MemberOptionalField.phone))
        AppTextField(
          label: l10n.fieldPhone,
          controller: phone,
          keyboardType: TextInputType.phone,
          onChanged: (_) {},
        ),
      if (shows(MemberOptionalField.address))
        AppTextField(
          label: l10n.fieldAddress,
          controller: address,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
      if (shows(MemberOptionalField.municipality))
        AppTextField(
          label: l10n.fieldMunicipality,
          controller: municipality,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
    ];
    if (fields.isEmpty) return const SizedBox.shrink();

    return AppFormSection(
      title: l10n.memberDetailContact,
      children: _packRows(fields),
    );
  }
}

/// Occupation, institution/school and ID verification - free text.
class MemberFormAdditionalSection extends StatelessWidget {
  const MemberFormAdditionalSection({
    required this.occupation,
    required this.institution,
    required this.idVerification,
    required this.shows,
    super.key,
  });

  final TextEditingController occupation;
  final TextEditingController institution;
  final TextEditingController idVerification;
  final MemberFieldVisibility shows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = [
      if (shows(MemberOptionalField.occupation))
        AppTextField(
          label: l10n.fieldOccupation,
          controller: occupation,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
      if (shows(MemberOptionalField.institution))
        AppTextField(
          label: l10n.fieldInstitution,
          controller: institution,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
      if (shows(MemberOptionalField.idVerification))
        AppTextField(
          label: l10n.fieldIdVerification,
          controller: idVerification,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
    ];
    if (fields.isEmpty) return const SizedBox.shrink();

    return AppFormSection(
      title: l10n.memberFormAdditional,
      children: _packRows(fields),
    );
  }
}

/// Emergency contact - name and phone.
class MemberFormEmergencySection extends StatelessWidget {
  const MemberFormEmergencySection({
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    super.key,
  });

  final TextEditingController emergencyContactName;
  final TextEditingController emergencyContactPhone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberFormEmergency,
      children: [
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldEmergencyContactName,
              controller: emergencyContactName,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldEmergencyContactPhone,
              controller: emergencyContactPhone,
              keyboardType: TextInputType.phone,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}
