// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/settings/domain/models/loan_rules.dart';
import 'package:khulla/features/settings/presentation/cubit/loan_rules_cubit.dart';
import 'package:khulla/features/settings/presentation/cubit/loan_rules_state.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla/shared/widgets/view_only_notice.dart';
import 'package:khulla_ui/khulla_ui.dart';

class LoanRulesPage extends StatefulWidget {
  const LoanRulesPage({super.key});

  @override
  State<LoanRulesPage> createState() => _LoanRulesPageState();
}

class _LoanRulesPageState extends State<LoanRulesPage> with DisposeBag {
  late final TextEditingController _loanPeriod = textController();
  late final TextEditingController _renewals = textController();
  late final TextEditingController _borrowingLimit = textController();
  late final TextEditingController _finePerDay = textController();
  late final TextEditingController _graceDays = textController();
  late final TextEditingController _maximumFine = textController();
  late final TextEditingController _holdShelfDays = textController();

  late bool _blockOverdue = true;
  late bool _autoRenew = false;
  LoanRules? _loadedRules;

  void _syncFromRules(LoanRules rules) {
    if (_loadedRules?.updatedAt == rules.updatedAt) return;
    _loadedRules = rules;
    _loanPeriod.text = '${rules.loanPeriodDays}';
    _renewals.text = '${rules.renewalLimit}';
    _borrowingLimit.text = '${rules.borrowingLimit}';
    _finePerDay.text = rules.finePerDay.editable;
    _graceDays.text = '${rules.graceDays}';
    _maximumFine.text = rules.maximumFinePerCopy.editable;
    _holdShelfDays.text = '${rules.holdShelfDays}';
    _blockOverdue = rules.blockOverdueBorrowers;
    _autoRenew = rules.autoRenewWhenUnreserved;
  }

  int? _parseInt(String text) => int.tryParse(text.trim());

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<LoanRulesCubit>();
    final loanPeriod = _parseInt(_loanPeriod.text);
    final renewals = _parseInt(_renewals.text);
    final borrowingLimit = _parseInt(_borrowingLimit.text);
    final graceDays = _parseInt(_graceDays.text);
    final holdShelfDays = _parseInt(_holdShelfDays.text);

    if (loanPeriod == null ||
        renewals == null ||
        borrowingLimit == null ||
        graceDays == null ||
        holdShelfDays == null ||
        !_finePerDay.text.isValidMoney ||
        !_maximumFine.text.isValidMoney) {
      AppToast.error(context, message: l10n.validationFieldRequired);
      return;
    }

    try {
      await cubit.saveRules(
        cubit.draftFromForm(
          loanPeriodDays: loanPeriod,
          renewalLimit: renewals,
          borrowingLimit: borrowingLimit,
          finePerDayText: _finePerDay.text,
          graceDays: graceDays,
          maximumFineText: _maximumFine.text,
          holdShelfDays: holdShelfDays,
          blockOverdueBorrowers: _blockOverdue,
          autoRenewWhenUnreserved: _autoRenew,
        ),
      );
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.settingsLoanRulesSave);
      context.go(Routes.settings);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        message: error.localizedMessage(l10n),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    // The library's own settings read at `view` and write at `manage`, so a
    // librarian can answer "how long is a loan" without being able to change
    // the answer. The form stays legible and stops accepting input.
    final viewOnly = !context.canManage(StaffPermission.settings);
    const numberInput = TextInputType.number;

    return BlocConsumer<LoanRulesCubit, LoanRulesState>(
      listenWhen: (previous, current) => current.rules != previous.rules,
      listener: (context, state) {
        final rules = state.rules;
        if (rules != null) _syncFromRules(rules);
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const AppPageBody(
            wide: true,
            child: Center(child: AppSpinner()),
          );
        }
        if (state.hasError) {
          return AppPageBody(
            wide: true,
            child: ErrorRetryView(
              error: state.error,
              onRetry: context.read<LoanRulesCubit>().loadRules,
            ),
          );
        }
        if (state.rules == null) {
          return AppPageBody(
            wide: true,
            child: AppEmptyView(
              icon: AppIcons.settings,
              title: l10n.settingsLoanPeriods,
              message: l10n.settingsLoanPeriodsDescription,
            ),
          );
        }

        return AppPageBody(
          wide: true,
          child: ViewOnlyForm(
            viewOnly: viewOnly,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing.page,
                spacing.lg,
                spacing.page,
                spacing.xlg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (viewOnly) ...[
                    const ViewOnlyNotice(),
                    SizedBox(height: spacing.md),
                  ],
                  AppFormSection(
                    title: l10n.settingsLoanPeriods,
                    description: l10n.settingsLoanPeriodsDescription,
                    children: [
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldLoanPeriodDays,
                            required: true,
                            controller: _loanPeriod,
                            keyboardType: numberInput,
                            onChanged: (_) {},
                          ),
                          AppTextField(
                            label: l10n.fieldRenewalLimit,
                            controller: _renewals,
                            keyboardType: numberInput,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      AppTextField(
                        label: l10n.fieldBorrowingLimit,
                        controller: _borrowingLimit,
                        keyboardType: numberInput,
                        onChanged: (_) {},
                      ),
                      AppSwitchField(
                        value: _autoRenew,
                        label: l10n.settingsLoanAutoRenew,
                        description: l10n.settingsLoanAutoRenewDescription,
                        onChanged: (value) =>
                            setState(() => _autoRenew = value),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  AppFormSection(
                    title: l10n.settingsLoanFines,
                    description: l10n.settingsLoanFinesDescription,
                    children: [
                      AppFormRow(
                        children: [
                          AppTextField(
                            label: l10n.fieldFinePerDay,
                            controller: _finePerDay,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) {},
                          ),
                          AppTextField(
                            label: l10n.fieldGraceDays,
                            controller: _graceDays,
                            keyboardType: numberInput,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      AppTextField(
                        label: l10n.fieldMaximumFine,
                        controller: _maximumFine,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) {},
                      ),
                      AppSwitchField(
                        value: _blockOverdue,
                        label: l10n.settingsLoanBlockOverdue,
                        description: l10n.settingsLoanBlockOverdueDescription,
                        onChanged: (value) =>
                            setState(() => _blockOverdue = value),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  AppFormSection(
                    title: l10n.settingsLoanHolds,
                    description: l10n.settingsLoanHoldsDescription,
                    children: [
                      AppTextField(
                        label: l10n.fieldHoldShelfDays,
                        controller: _holdShelfDays,
                        keyboardType: numberInput,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xlg),
                  if (!viewOnly)
                    Row(
                      children: [
                        const Spacer(),
                        AppButton(
                          size: AppButtonSize.medium,
                          isLoading: state.isSaving,
                          onPressed: state.isSaving
                              ? null
                              : () => unawaited(_save(context)),
                          child: Text(l10n.settingsLoanRulesSave),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
