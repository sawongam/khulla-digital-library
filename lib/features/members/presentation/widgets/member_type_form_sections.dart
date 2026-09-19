// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Loan-rule overrides in the category form: period, limits and the
/// renewal pair.
class MemberTypeFormLoanSection extends StatelessWidget {
  const MemberTypeFormLoanSection({
    required this.loanPeriodDays,
    required this.borrowingLimit,
    required this.renewalLimit,
    required this.renewalPeriodDays,
    super.key,
  });

  final TextEditingController loanPeriodDays;
  final TextEditingController borrowingLimit;
  final TextEditingController renewalLimit;
  final TextEditingController renewalPeriodDays;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const numberInput = TextInputType.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldLoanPeriodDays,
              controller: loanPeriodDays,
              keyboardType: numberInput,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldBorrowingLimit,
              controller: borrowingLimit,
              keyboardType: numberInput,
              onChanged: (_) {},
            ),
          ],
        ),
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldRenewalLimit,
              controller: renewalLimit,
              keyboardType: numberInput,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldRenewalPeriodDays,
              controller: renewalPeriodDays,
              keyboardType: numberInput,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Fine-rule overrides in the category form: the daily rate, the grace
/// window and the two ceilings.
class MemberTypeFormFineSection extends StatelessWidget {
  const MemberTypeFormFineSection({
    required this.finePerDay,
    required this.graceDays,
    required this.maximumFinePerCopy,
    required this.maxOutstandingFine,
    super.key,
  });

  final TextEditingController finePerDay;
  final TextEditingController graceDays;
  final TextEditingController maximumFinePerCopy;
  final TextEditingController maxOutstandingFine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const numberInput = TextInputType.number;
    const moneyInput = TextInputType.numberWithOptions(decimal: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldFinePerDay,
              controller: finePerDay,
              keyboardType: moneyInput,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldGraceDays,
              controller: graceDays,
              keyboardType: numberInput,
              onChanged: (_) {},
            ),
          ],
        ),
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldMaximumFine,
              controller: maximumFinePerCopy,
              keyboardType: moneyInput,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldMaxOutstandingFine,
              controller: maxOutstandingFine,
              keyboardType: moneyInput,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Membership-rule overrides in the category form: how long a card
/// lasts and how many holds it may carry.
class MemberTypeFormMembershipSection extends StatelessWidget {
  const MemberTypeFormMembershipSection({
    required this.membershipDurationMonths,
    required this.reservationLimit,
    super.key,
  });

  final TextEditingController membershipDurationMonths;
  final TextEditingController reservationLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const numberInput = TextInputType.number;

    return AppFormRow(
      children: [
        AppTextField(
          label: l10n.fieldMembershipDurationMonths,
          controller: membershipDurationMonths,
          keyboardType: numberInput,
          onChanged: (_) {},
        ),
        AppTextField(
          label: l10n.fieldReservationLimit,
          controller: reservationLimit,
          keyboardType: numberInput,
          onChanged: (_) {},
        ),
      ],
    );
  }
}
