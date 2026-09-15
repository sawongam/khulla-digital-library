// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Which rules the card runs under: the category, the read-only expiry, the
/// notes and the notice switch.
///
/// Expiry is set from the loan rules on registration and extended by
/// renewing the membership, so the picker is disabled and the hint says
/// where the date comes from.
class MemberFormMembershipSection extends StatelessWidget {
  const MemberFormMembershipSection({
    required this.memberTypes,
    required this.selectedType,
    required this.expires,
    required this.barcode,
    required this.notes,
    required this.sendNotices,
    required this.onTypeChanged,
    required this.onAddCategory,
    required this.onSendNoticesChanged,
    super.key,
  });

  final List<MemberType> memberTypes;
  final MemberType? selectedType;
  final String expires;
  final String barcode;
  final TextEditingController notes;
  final bool sendNotices;
  final ValueChanged<MemberType?> onTypeChanged;
  final VoidCallback onAddCategory;
  final ValueChanged<bool> onSendNoticesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.memberDetailMembership,
      children: [
        AppFormRow(
          children: [
            AppDropdownField<MemberType>(
              label: l10n.fieldCategory,
              required: true,
              value: selectedType,
              items: memberTypes,
              itemLabel: (type) => type.name,
              itemIcon: (type) => type.code.memberTypeIcon,
              footerActionLabel: l10n.memberTypeAddCategory,
              onFooterAction: onAddCategory,
              onChanged: onTypeChanged,
            ),
            AppPickerField(
              label: l10n.fieldBarcode,
              value: barcode.isEmpty ? l10n.memberFormBarcodeHint : barcode,
              icon: AppIcons.scan,
              enabled: false,
              onTap: null,
            ),
          ],
        ),
        AppFormRow(
          children: [
            AppPickerField(
              label: l10n.fieldExpires,
              value: expires.isEmpty ? l10n.commonNotSet : expires,
              icon: AppIcons.calendar,
              enabled: false,
              onTap: null,
            ),
            const SizedBox.shrink(),
          ],
        ),
        MemberExpiresHint(message: l10n.memberFormExpiresHint),
        AppTextField(
          label: l10n.fieldNotes,
          controller: notes,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: AppSwitchField(
              value: sendNotices,
              label: l10n.memberFormNotifications,
              description: l10n.memberFormNotificationsDescription,
              stacked: true,
              onChanged: onSendNoticesChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fine print under the read-only expiry field: an info glyph plus one
/// line saying the date comes from the category, so the disabled picker
/// reads as information rather than a control that failed to open.
class MemberExpiresHint extends StatelessWidget {
  const MemberExpiresHint({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(
          AppIcons.info,
          size: context.appMetrics.icon,
          color: colors.mutedForeground,
        ),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Text(
            message,
            style: context.appTextStyles.micro.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
