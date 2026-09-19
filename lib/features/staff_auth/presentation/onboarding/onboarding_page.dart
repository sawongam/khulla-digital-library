// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/widgets/onboarding_account_step.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/widgets/onboarding_library_step.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/widgets/onboarding_progress.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/widgets/onboarding_recovery_step.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_error_notice.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_header.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_scaffold.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_secondary_action.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// First-run setup: the screen a fresh download opens on.
///
/// The router sends the operator here whenever the catalogue holds no staff
/// account, and nowhere else - there is no route out of this page except
/// finishing it or adopting a backup, because a library with no
/// administrator has nothing to show.
///
/// The last step writes the administrator and signs them in: making someone
/// type the password they just chose, on the next screen, to reach the app
/// they just set up, is a step that exists only because the code found it
/// convenient.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _completeSetup(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await context.read<OnboardingCubit>().completeSetup();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        message: l10n.onboardingSetupFailed,
        description: error.localizedMessage(l10n),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.onboardingRestoreConfirmTitle,
      message: l10n.onboardingRestoreConfirmBody,
      confirmLabel: l10n.settingsBackupRestoreAction,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;

    try {
      // On success this never returns to a running screen - `restartApp()`
      // ends the process (or reloads the page on web) before the wizard
      // could draw another frame over a catalogue that was replaced under it.
      await context.read<OnboardingCubit>().restoreFromBackup();
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  (String title, String description) _header(
    AppLocalizations l10n,
    OnboardingStep step,
  ) => switch (step) {
    OnboardingStep.library => (
      l10n.onboardingLibraryHeading,
      l10n.onboardingLibrarySubtitle,
    ),
    OnboardingStep.account => (
      l10n.onboardingAccountHeading,
      l10n.onboardingAccountSubtitle,
    ),
    OnboardingStep.recovery => (
      l10n.onboardingRecoveryHeading,
      l10n.onboardingRecoverySubtitle,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return AuthScaffold(
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          final header = _header(l10n, state.step);
          // A duplicate address is already shown under the email field, so
          // repeating it above the button would be the same sentence twice.
          final error = state.emailTaken ? null : state.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgress(step: state.step),
              SizedBox(height: spacing.lg),
              AuthHeader(title: header.$1, description: header.$2),
              SizedBox(height: spacing.lg),
              switch (state.step) {
                OnboardingStep.library => OnboardingLibraryStep(state: state),
                OnboardingStep.account => OnboardingAccountStep(state: state),
                OnboardingStep.recovery => OnboardingRecoveryStep(
                  state: state,
                  onCodesSavedChanged: cubit.codesSavedChanged,
                ),
              },
              if (error != null) ...[
                SizedBox(height: spacing.md),
                AuthErrorNotice.exception(error),
              ],
              SizedBox(height: spacing.lg),
              if (state.step.isFirst) ...[
                AppButton(
                  size: AppButtonSize.large,
                  expand: true,
                  trailingIcon: AppIcons.arrowRight,
                  onPressed: cubit.goToNextStep,
                  child: Text(l10n.onboardingContinue),
                ),
                // The fork: adopt an existing library's backup instead of
                // creating a new one. Later steps have typed input worth
                // keeping, so the offer lives only on the first step.
                if (!state.isSubmitting) ...[
                  SizedBox(height: spacing.md),
                  AuthSecondaryAction(
                    label: l10n.onboardingRestoreAction,
                    onTap: () => unawaited(_restore(context)),
                  ),
                ],
              ] else
                Row(
                  children: [
                    AppButton(
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.large,
                      icon: AppIcons.chevronLeft,
                      onPressed: state.isSubmitting
                          ? null
                          : cubit.goToPreviousStep,
                      child: Text(l10n.onboardingBack),
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: state.step.isLast
                          ? AppButton(
                              size: AppButtonSize.large,
                              expand: true,
                              isLoading: state.isSubmitting,
                              onPressed: state.canAdvance
                                  ? () => _completeSetup(context)
                                  : null,
                              child: Text(l10n.onboardingFinish),
                            )
                          : AppButton(
                              size: AppButtonSize.large,
                              expand: true,
                              trailingIcon: AppIcons.arrowRight,
                              onPressed: cubit.goToNextStep,
                              child: Text(l10n.onboardingContinue),
                            ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
