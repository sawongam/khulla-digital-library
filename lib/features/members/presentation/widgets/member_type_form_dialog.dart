// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/widgets/member_type_form_sections.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The category editor behind the category dialog, used for both a new
/// category and an existing one.
///
/// Returns the draft on confirm; the caller writes it through the member
/// type cubit so validation toasts stay at the call site. Blank
/// override fields mean "fall back to the library rules".
class MemberTypeFormDialog extends StatefulWidget {
  const MemberTypeFormDialog({
    required this.heading,
    required this.confirmLabel,
    this.existing,
    super.key,
  });

  final String heading;
  final String confirmLabel;
  final MemberType? existing;

  static Future<MemberType?> show(
    BuildContext context, {
    required String heading,
    required String confirmLabel,
    MemberType? existing,
  }) => AppFormModal.show<MemberType>(
    context: context,
    builder: (_) => MemberTypeFormDialog(
      heading: heading,
      confirmLabel: confirmLabel,
      existing: existing,
    ),
  );

  @override
  State<MemberTypeFormDialog> createState() => _MemberTypeFormDialogState();
}

class _MemberTypeFormDialogState extends State<MemberTypeFormDialog>
    with DisposeBag {
  late final TextEditingController _name = textController(
    widget.existing?.name,
  );
  late final TextEditingController _loanPeriodDays = textController(
    widget.existing?.loanPeriodDays?.toString(),
  );
  late final TextEditingController _borrowingLimit = textController(
    widget.existing?.borrowingLimit?.toString(),
  );
  late final TextEditingController _renewalLimit = textController(
    widget.existing?.renewalLimit?.toString(),
  );
  late final TextEditingController _renewalPeriodDays = textController(
    widget.existing?.renewalPeriodDays?.toString(),
  );
  late final TextEditingController _finePerDay = textController(
    widget.existing?.finePerDay?.editable,
  );
  late final TextEditingController _graceDays = textController(
    widget.existing?.graceDays?.toString(),
  );
  late final TextEditingController _maximumFinePerCopy = textController(
    widget.existing?.maximumFinePerCopy?.editable,
  );
  late final TextEditingController _maxOutstandingFine = textController(
    widget.existing?.maxOutstandingFine?.editable,
  );
  late final TextEditingController _membershipDurationMonths = textController(
    widget.existing?.membershipDurationMonths?.toString(),
  );
  late final TextEditingController _reservationLimit = textController(
    widget.existing?.reservationLimit?.toString(),
  );

  int? _parseInt(String text) =>
      text.trim().isEmpty ? null : int.tryParse(text.trim());

  bool _validMoney(String text) => text.trim().isEmpty || text.isValidMoney;

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty ||
        !_validMoney(_finePerDay.text) ||
        !_validMoney(_maximumFinePerCopy.text) ||
        !_validMoney(_maxOutstandingFine.text)) {
      AppToast.error(context, message: l10n.validationFieldRequired);
      return;
    }

    final existing = widget.existing;
    final draft = MemberType(
      id: existing?.id ?? '',
      name: name,
      sortOrder: existing?.sortOrder ?? 0,
      isSystem: existing?.isSystem ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
      code: existing?.code,
      archivedAt: existing?.archivedAt,
      loanPeriodDays: _parseInt(_loanPeriodDays.text),
      borrowingLimit: _parseInt(_borrowingLimit.text),
      renewalLimit: _parseInt(_renewalLimit.text),
      renewalPeriodDays: _parseInt(_renewalPeriodDays.text),
      finePerDay: _finePerDay.text.trim().isEmpty
          ? null
          : _finePerDay.text.toMoney(),
      graceDays: _parseInt(_graceDays.text),
      maximumFinePerCopy: _maximumFinePerCopy.text.trim().isEmpty
          ? null
          : _maximumFinePerCopy.text.toMoney(),
      maxOutstandingFine: _maxOutstandingFine.text.trim().isEmpty
          ? null
          : _maxOutstandingFine.text.toMoney(),
      membershipDurationMonths: _parseInt(_membershipDurationMonths.text),
      reservationLimit: _parseInt(_reservationLimit.text),
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: widget.heading,
      description: l10n.membersManageCategoriesBody,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: widget.confirmLabel,
          onPressed: _submit,
        ),
      ],
      children: [
        AppTextField(
          label: l10n.fieldCategory,
          required: true,
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {},
        ),
        MemberTypeFormLoanSection(
          loanPeriodDays: _loanPeriodDays,
          borrowingLimit: _borrowingLimit,
          renewalLimit: _renewalLimit,
          renewalPeriodDays: _renewalPeriodDays,
        ),
        MemberTypeFormFineSection(
          finePerDay: _finePerDay,
          graceDays: _graceDays,
          maximumFinePerCopy: _maximumFinePerCopy,
          maxOutstandingFine: _maxOutstandingFine,
        ),
        MemberTypeFormMembershipSection(
          membershipDurationMonths: _membershipDurationMonths,
          reservationLimit: _reservationLimit,
        ),
      ],
    );
  }
}
