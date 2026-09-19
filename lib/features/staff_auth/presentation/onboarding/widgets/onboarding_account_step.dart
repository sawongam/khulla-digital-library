// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/form/inputs/password.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/onboarding/cubit/onboarding_state.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_password_field.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Step two: the administrator account that will run the library.
///
/// Its role is not offered as a choice. The first account is always an
/// administrator - somebody has to be able to add the second - and a picker
/// here would only let a new install lock itself out on its first screen.
class OnboardingAccountStep extends StatefulWidget {
  const OnboardingAccountStep({required this.state, super.key});

  final OnboardingState state;

  @override
  State<OnboardingAccountStep> createState() => _OnboardingAccountStepState();
}

class _OnboardingAccountStepState extends State<OnboardingAccountStep>
    with DisposeBag {
  late final TextEditingController _name = textController(
    widget.state.adminName.value,
  );
  late final TextEditingController _email = textController(
    widget.state.email.value,
  );
  late final TextEditingController _password = textController(
    widget.state.password.value,
  );
  late final TextEditingController _confirmPassword = textController(
    widget.state.confirmPassword.value,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final cubit = context.read<OnboardingCubit>();
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: l10n.fieldFullName,
          required: true,
          autofocus: true,
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          errorText: state.adminName.messageFor(l10n),
          onChanged: cubit.adminNameChanged,
        ),
        SizedBox(height: spacing.sm),
        AppTextField(
          label: l10n.fieldEmail,
          hintText: l10n.onboardingEmailHint,
          required: true,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          // A duplicate address is the one write failure that belongs to a
          // field rather than to the form, so it is shown here instead of in
          // the notice above the button.
          errorText: state.emailTaken
              ? l10n.onboardingEmailTaken
              : state.email.messageFor(l10n),
          onChanged: cubit.emailChanged,
        ),
        SizedBox(height: spacing.sm),
        AppFormRow(
          children: [
            AuthPasswordField(
              label: l10n.fieldPassword,
              controller: _password,
              textInputAction: TextInputAction.next,
              errorText: state.password.messageFor(l10n),
              onChanged: cubit.passwordChanged,
            ),
            AuthPasswordField(
              label: l10n.fieldConfirmPassword,
              controller: _confirmPassword,
              textInputAction: TextInputAction.done,
              errorText: state.confirmPassword.messageFor(l10n),
              onChanged: cubit.confirmPasswordChanged,
            ),
          ],
        ),
        SizedBox(height: spacing.xs),
        Text(
          l10n.onboardingPasswordHelp(Password.minLength),
          style: typography.caption.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}
