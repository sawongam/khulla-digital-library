// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/staff_auth/presentation/auth_labels.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/cubit/sign_in_cubit.dart';
import 'package:khulla/features/staff_auth/presentation/sign_in/cubit/sign_in_state.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_error_notice.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_header.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_scaffold.dart';
import 'package:khulla/features/staff_auth/presentation/widgets/auth_secondary_action.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Sign-in for a library that has already been set up.
///
/// The router sends the operator here whenever staff accounts exist and
/// nobody is signed in on this device; there is no way to reach it otherwise,
/// and no link from here to onboarding - a second administrator is created
/// from the staff section, not from this screen.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with DisposeBag {
  late final TextEditingController _email = textController();
  late final TextEditingController _password = textController();
  bool _passwordRevealed = false;

  void _submit() => context.read<SignInCubit>().signIn();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final typography = context.appTextStyles;

    return AuthScaffold(
      child: BlocBuilder<SignInCubit, SignInState>(
        builder: (context, state) {
          final cubit = context.read<SignInCubit>();
          final error = state.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: l10n.signInHeading,
                description: l10n.signInSubtitle,
              ),
              SizedBox(height: spacing.lg),
              AppTextField(
                label: l10n.fieldEmail,
                hintText: l10n.signInEmailHint,
                required: true,
                controller: _email,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: state.email.messageFor(l10n),
                onChanged: cubit.emailChanged,
              ),
              SizedBox(height: spacing.sm),
              AppTextField(
                label: l10n.fieldPassword,
                hintText: l10n.signInPasswordHint,
                required: true,
                controller: _password,
                obscureText: !_passwordRevealed,
                textInputAction: TextInputAction.done,
                errorText: state.password.messageFor(l10n),
                onChanged: cubit.passwordChanged,
                onSubmitted: (_) => _submit(),
                suffixIcon: AppIconButton(
                  icon: _passwordRevealed
                      ? AppIcons.hidePassword
                      : AppIcons.revealPassword,
                  tooltip: _passwordRevealed
                      ? l10n.authHidePassword
                      : l10n.authRevealPassword,
                  size: AppIconButtonSize.small,
                  onPressed: () =>
                      setState(() => _passwordRevealed = !_passwordRevealed),
                ),
              ),
              if (state.credentialsRejected) ...[
                SizedBox(height: spacing.md),
                AuthErrorNotice(message: l10n.signInRejected),
              ],
              if (error != null) ...[
                SizedBox(height: spacing.md),
                AuthErrorNotice.exception(error),
              ],
              SizedBox(height: spacing.lg),
              AppButton(
                size: AppButtonSize.large,
                expand: true,
                isLoading: state.isSubmitting,
                onPressed: _submit,
                child: Text(l10n.signInAction),
              ),
              if (state.recoveryAvailabilityLoaded) ...[
                SizedBox(height: spacing.lg),
                if (state.canRecoverPassword)
                  AuthSecondaryAction(
                    label: l10n.signInForgotPasswordAction,
                    onTap: () => context.go(Routes.recoverPassword),
                  )
                else
                  Text(
                    l10n.signInForgotPasswordUnavailable,
                    textAlign: TextAlign.center,
                    style: typography.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
