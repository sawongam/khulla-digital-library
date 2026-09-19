// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/features/circulation/shared/domain/fine_reason.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What a librarian filled in on [ChargeFineDialog], ready to hand to
/// `MemberDetailCubit.chargeFine`.
typedef ChargeFineResult = ({FineReason reason, Money amount, String? note});

/// A one-off fine a librarian charges by hand — a lost or damaged copy, or a
/// membership fee. The automatic overdue fine on return is the only reason
/// not offered here.
///
/// Collects the fields and pops them; it never touches a cubit itself; the
/// caller decides how to persist and reports success or failure at its own
/// call site, same as [ChargeFineDialog]'s sibling confirmations on this page.
class ChargeFineDialog extends StatefulWidget {
  const ChargeFineDialog({super.key});

  static const List<FineReason> _chargeableReasons = [
    FineReason.lost,
    FineReason.damage,
    FineReason.membership,
  ];

  static Future<ChargeFineResult?> show(BuildContext context) =>
      showDialog<ChargeFineResult>(
        context: context,
        builder: (_) => const ChargeFineDialog(),
      );

  @override
  State<ChargeFineDialog> createState() => _ChargeFineDialogState();
}

class _ChargeFineDialogState extends State<ChargeFineDialog> with DisposeBag {
  late final TextEditingController _amount = textController();
  late final TextEditingController _note = textController();
  FineReason _reason = ChargeFineDialog._chargeableReasons.first;

  void _submit() {
    final l10n = context.l10n;
    if (!_amount.text.isValidMoney || !_amount.text.toMoney().isPositive) {
      AppToast.error(context, message: l10n.finesChargeAmountInvalid);
      return;
    }
    Navigator.of(context).pop((
      reason: _reason,
      amount: _amount.text.toMoney(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormModal(
      title: l10n.finesChargeTitle,
      description: l10n.finesChargeDescription,
      width: AppDialogWidth.xxxl,
      actions: [
        AppDialog.secondaryAction(
          context: context,
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialog.primaryAction(
          context: context,
          label: l10n.finesChargeAction,
          onPressed: _submit,
        ),
      ],
      children: [
        AppFormRow(
          flexes: const [3, 2],
          children: [
            AppDropdownField<FineReason>(
              label: l10n.fieldReason,
              required: true,
              value: _reason,
              items: ChargeFineDialog._chargeableReasons,
              itemLabel: (reason) => reason.label(l10n),
              itemIcon: (reason) => reason.icon,
              onChanged: (reason) =>
                  setState(() => _reason = reason ?? _reason),
            ),
            AppTextField(
              label: l10n.fieldAmount,
              required: true,
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {},
            ),
          ],
        ),
        AppTextField(
          label: l10n.fieldNotes,
          controller: _note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
      ],
    );
  }
}
