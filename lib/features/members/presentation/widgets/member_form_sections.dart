// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/members/domain/blood_group.dart';
import 'package:khulla/features/members/domain/gender.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Who the person is: name, gender, birth date, blood group and guardian.
class MemberFormIdentitySection extends StatelessWidget {
  const MemberFormIdentitySection({
    required this.name,
    required this.gender,
    required this.onGenderChanged,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
    required this.guardian,
    required this.onPickDateOfBirth,
    required this.onClearDateOfBirth,
    super.key,
  });

  final TextEditingController name;
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final String? dateOfBirth;
  final BloodGroup? bloodGroup;
  final ValueChanged<BloodGroup?> onBloodGroupChanged;
  final TextEditingController guardian;
  final VoidCallback onPickDateOfBirth;
  final VoidCallback? onClearDateOfBirth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberFormIdentity,
      children: [
        AppFormRow(
          flexes: const [3, 2],
          children: [
            AppTextField(
              label: l10n.fieldFullName,
              required: true,
              controller: name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
            AppDropdownField<Gender>(
              label: l10n.fieldGender,
              value: gender,
              items: Gender.values,
              itemLabel: (g) => g.label(l10n),
              onChanged: onGenderChanged,
              emptySearchMessage: l10n.commonNotSet,
            ),
          ],
        ),
        AppFormRow(
          flexes: const [2, 2, 3],
          children: [
            AppPickerField(
              label: l10n.fieldDateOfBirth,
              value: dateOfBirth,
              icon: AppIcons.calendar,
              onTap: onPickDateOfBirth,
              onClear: onClearDateOfBirth,
              clearTooltip: l10n.commonClear,
            ),
            AppDropdownField<BloodGroup>(
              label: l10n.fieldBloodGroup,
              value: bloodGroup,
              items: BloodGroup.values,
              itemLabel: (b) => b.label,
              onChanged: onBloodGroupChanged,
            ),
            AppTextField(
              label: l10n.fieldGuardian,
              controller: guardian,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

/// How to reach them: email, phone, address and municipality.
class MemberFormContactSection extends StatelessWidget {
  const MemberFormContactSection({
    required this.email,
    required this.phone,
    required this.address,
    required this.municipality,
    super.key,
  });

  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController address;
  final TextEditingController municipality;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberDetailContact,
      children: [
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldEmail,
              controller: email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldPhone,
              controller: phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) {},
            ),
          ],
        ),
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldAddress,
              controller: address,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldMunicipality,
              controller: municipality,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Occupation, institution/school and ID verification — free text.
class MemberFormAdditionalSection extends StatelessWidget {
  const MemberFormAdditionalSection({
    required this.occupation,
    required this.institution,
    required this.idVerification,
    super.key,
  });

  final TextEditingController occupation;
  final TextEditingController institution;
  final TextEditingController idVerification;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberFormAdditional,
      children: [
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldOccupation,
              controller: occupation,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldInstitution,
              controller: institution,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
          ],
        ),
        AppTextField(
          label: l10n.fieldIdVerification,
          controller: idVerification,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

/// Emergency contact — name and phone.
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
